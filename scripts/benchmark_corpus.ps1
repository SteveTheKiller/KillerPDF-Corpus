<#
.SYNOPSIS
Runs a guided benchmark against The KillerPDF Corpus.

.DESCRIPTION
Asks which supported PDF tools and public collections to test, then asks how
many measured runs to perform. The script finds or downloads the selected
tools, downloads and verifies the selected corpus collections,
performs warmup and measured passes, runs malformed inputs with a timeout, and
writes detailed CSV results.

.EXAMPLE
powershell -ExecutionPolicy Bypass -File .\benchmark_corpus.ps1

.EXAMPLE
.\benchmark_corpus.ps1 -Tools killerpdf,qpdf -Collections regression,standards -Runs 5

.EXAMPLE
.\benchmark_corpus.ps1 -Tools qpdf -Collections stress -Runs 5 `
    -PrivateStressDirectory C:\corpus\stress

.EXAMPLE
.\benchmark_corpus.ps1 -Tools custom -AdapterFile .\my-tool.json `
    -Collections regression -Runs 5
#>
[CmdletBinding()]
param(
    [string] $KillerPdfExe,

    [string] $QpdfExe,

    [string] $AdapterFile,

    [string] $CorpusVersion,

    [string] $CorpusDirectory = (Join-Path $env:LOCALAPPDATA 'KillerPDF-Corpus\corpus'),

    [string] $PrivateStressDirectory,

    [string] $ResultDirectory,

    [ValidateRange(0, 25)]
    [int] $Runs = 0,

    [ValidateSet('regression', 'standards', 'fuzz', 'stress', 'all')]
    [string[]] $Collections,

    [ValidateSet('killerpdf', 'qpdf', 'custom', 'all')]
    [string[]] $Tools,

    [ValidateRange(1, 300)]
    [int] $FuzzTimeoutSeconds = 30,

    [switch] $SkipDownload
)

$ErrorActionPreference = 'Stop'
$script:collectionsWereProvided = $PSBoundParameters.ContainsKey('Collections')
$script:toolsWereProvided = $PSBoundParameters.ContainsKey('Tools')
$corpusRoot = [System.IO.Path]::GetFullPath($CorpusDirectory)

if ([string]::IsNullOrWhiteSpace($ResultDirectory)) {
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $ResultDirectory = Join-Path $env:LOCALAPPDATA "KillerPDF-Corpus\benchmarks\$stamp"
}
$resultRoot = [System.IO.Path]::GetFullPath($ResultDirectory)

function Write-Heading {
    param([string] $Text)
    Write-Host ''
    Write-Host ('=' * 68) -ForegroundColor DarkGreen
    Write-Host "  $Text" -ForegroundColor Green
    Write-Host ('=' * 68) -ForegroundColor DarkGreen
}

function Write-Banner {
    $killer = @(
        '  _  ___ _ _ _            ',
        ' | |/ (_) | | | ___ _ __  ',
        " | ' /| | | | |/ _ \ '__| ",
        ' | . \| | | | |  __/ |    ',
        ' |_|\_\_|_|_|_|\___|_|    '
    )
    $pdf = @(
        ' ____  ____  _____',
        '|  _ \|  _ \|  ___|',
        '| |_) | | | | |_   ',
        '|  __/| |_| |  _|  ',
        '|_|   |____/|_|    '
    )

    Write-Host ''
    Write-Host '  THE' -ForegroundColor DarkGray
    for ($line = 0; $line -lt $killer.Count; $line++) {
        Write-Host $killer[$line] -NoNewline -ForegroundColor White
        Write-Host $pdf[$line] -ForegroundColor Green
    }
    Write-Host '                              C O R P U S' -ForegroundColor Green
    Write-Host '  Reproducible PDF reliability benchmark' -ForegroundColor DarkGray
}

function Write-Step {
    param([string] $Text)
    Write-Host "  > $Text" -ForegroundColor Cyan
}

function Read-KeyLine {
    param([string] $Prompt)
    Write-Host $Prompt -NoNewline -ForegroundColor White
    $text = ''
    while ($true) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape) {
            Write-Host ''
            return $null
        }
        if ($key.Key -eq [ConsoleKey]::Enter) {
            Write-Host ''
            return $text
        }
        if ($key.Key -eq [ConsoleKey]::Backspace -and $text.Length -gt 0) {
            $text = $text.Substring(0, $text.Length - 1)
            Write-Host "`b `b" -NoNewline
        }
        elseif (-not [char]::IsControl($key.KeyChar)) {
            $text += $key.KeyChar
            Write-Host $key.KeyChar -NoNewline
        }
    }
}

function ConvertTo-AdapterId {
    param([Parameter(Mandatory)][string] $Name)
    $id = $Name.ToLowerInvariant() -replace '[^a-z0-9]+', '-'
    $id = $id.Trim('-')
    if ([string]::IsNullOrWhiteSpace($id)) { $id = 'custom-pdf-tool' }
    return $id
}

function ConvertTo-ExitCodes {
    param(
        [string] $Value,
        [int[]] $Default = @()
    )
    if ([string]::IsNullOrWhiteSpace($Value)) { return @($Default) }
    $codes = [System.Collections.Generic.List[int]]::new()
    foreach ($part in $Value.Split(',')) {
        $parsed = 0
        if (-not [int]::TryParse($part.Trim(), [ref]$parsed)) {
            throw "Exit code is not a number: $part"
        }
        $codes.Add($parsed)
    }
    return @($codes | Select-Object -Unique)
}

function Import-CustomAdapter {
    param([Parameter(Mandatory)][string] $Path)
    $resolvedPath = [System.IO.Path]::GetFullPath($Path.Trim().Trim('"'))
    if (-not (Test-Path -LiteralPath $resolvedPath -PathType Leaf)) {
        throw "Adapter file was not found: $resolvedPath"
    }
    $adapter = Get-Content -Raw -LiteralPath $resolvedPath | ConvertFrom-Json
    foreach ($property in @('name', 'executable', 'runArguments', 'savedExitCodes',
            'warningExitCodes', 'outputRequired', 'timeoutSeconds')) {
        if ($null -eq $adapter.$property) {
            throw "Adapter is missing the required property: $property"
        }
    }
    $executable = [string]$adapter.executable
    if (-not [System.IO.Path]::IsPathRooted($executable)) {
        $executable = Join-Path (Split-Path $resolvedPath) $executable
    }
    $executable = [System.IO.Path]::GetFullPath($executable)
    if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) {
        throw "Adapter executable was not found: $executable"
    }
    $arguments = @($adapter.runArguments | ForEach-Object { [string]$_ })
    if (-not ($arguments -match '\{input\}') -or -not ($arguments -match '\{output\}')) {
        throw 'Adapter runArguments must include both {input} and {output}.'
    }
    $timeout = 0
    if (-not [int]::TryParse([string]$adapter.timeoutSeconds, [ref]$timeout) -or
        $timeout -lt 1 -or $timeout -gt 300) {
        throw 'Adapter timeoutSeconds must be between 1 and 300.'
    }
    $adapter | Add-Member -NotePropertyName sourcePath -NotePropertyValue $resolvedPath -Force
    $adapter | Add-Member -NotePropertyName executable -NotePropertyValue $executable -Force
    $adapter | Add-Member -NotePropertyName id `
        -NotePropertyValue (ConvertTo-AdapterId ([string]$adapter.name)) -Force
    return $adapter
}

function New-CustomAdapter {
    Write-Heading 'Create a custom command-line adapter'
    Write-Host '  The runner starts the executable directly. It never evaluates a shell command.' `
        -ForegroundColor DarkGray
    do {
        $answer = Read-KeyLine '  Full path to the PDF tool executable: '
        if ($null -eq $answer) { return $null }
        $executable = $answer.Trim().Trim('"')
    } until (Test-Path -LiteralPath $executable -PathType Leaf)
    $executable = [System.IO.Path]::GetFullPath($executable)

    $defaultName = (Get-Item -LiteralPath $executable).VersionInfo.ProductName
    if ([string]::IsNullOrWhiteSpace($defaultName)) {
        $defaultName = [System.IO.Path]::GetFileNameWithoutExtension($executable)
    }
    $answer = Read-KeyLine "  Tool name [$defaultName]: "
    if ($null -eq $answer) { return $null }
    $name = if ([string]::IsNullOrWhiteSpace($answer)) { $defaultName } else { $answer.Trim() }

    Write-Host ''
    Write-Host '  Enter one command-line argument at a time.' -ForegroundColor White
    Write-Host '  Use {input} for the source PDF and {output} for the saved PDF.' -ForegroundColor Cyan
    Write-Host '  Press Enter on an empty argument when finished.' -ForegroundColor DarkGray
    $arguments = [System.Collections.Generic.List[string]]::new()
    while ($true) {
        $argument = Read-KeyLine "  Argument $($arguments.Count + 1): "
        if ($null -eq $argument) { return $null }
        if ([string]::IsNullOrWhiteSpace($argument)) { break }
        $arguments.Add($argument)
    }
    if (-not (@($arguments) -match '\{input\}') -or -not (@($arguments) -match '\{output\}')) {
        Write-Host '  The arguments must include both {input} and {output}.' -ForegroundColor Red
        return New-CustomAdapter
    }

    $answer = Read-KeyLine '  Successful exit codes, separated by commas [0]: '
    if ($null -eq $answer) { return $null }
    $savedExitCodes = @(ConvertTo-ExitCodes -Value $answer -Default @(0))
    $answer = Read-KeyLine '  Warning exit codes, separated by commas [none]: '
    if ($null -eq $answer) { return $null }
    $warningExitCodes = @(ConvertTo-ExitCodes -Value $answer)
    do {
        $answer = Read-KeyLine '  Timeout per PDF in seconds [30]: '
        if ($null -eq $answer) { return $null }
        if ([string]::IsNullOrWhiteSpace($answer)) { $timeout = 30; break }
        $timeout = 0
    } until ([int]::TryParse($answer, [ref]$timeout) -and $timeout -ge 1 -and $timeout -le 300)

    $adapterDirectory = Join-Path $env:LOCALAPPDATA 'KillerPDF-Corpus\adapters'
    New-Item -ItemType Directory -Force -Path $adapterDirectory | Out-Null
    $adapterPath = Join-Path $adapterDirectory "$(ConvertTo-AdapterId $name).json"
    [ordered]@{
        schemaVersion = 1
        name = $name
        executable = $executable
        versionArguments = @()
        runArguments = @($arguments)
        savedExitCodes = $savedExitCodes
        warningExitCodes = $warningExitCodes
        outputRequired = $true
        timeoutSeconds = $timeout
    } | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $adapterPath -Encoding utf8
    Write-Host "  Saved adapter: $adapterPath" -ForegroundColor Green
    return Import-CustomAdapter -Path $adapterPath
}

function Select-CustomAdapter {
    if (-not [string]::IsNullOrWhiteSpace($AdapterFile)) {
        return Import-CustomAdapter -Path $AdapterFile
    }
    $adapterDirectory = Join-Path $env:LOCALAPPDATA 'KillerPDF-Corpus\adapters'
    $saved = @(Get-ChildItem -LiteralPath $adapterDirectory -Filter '*.json' -File `
        -ErrorAction SilentlyContinue | Sort-Object Name)
    Write-Host ''
    Write-Host '  Custom command-line adapters' -ForegroundColor White
    for ($index = 0; $index -lt $saved.Count; $index++) {
        Write-Host "    $($index + 1)  $($saved[$index].BaseName)" -ForegroundColor Cyan
    }
    Write-Host '    N  Create a new adapter' -ForegroundColor Green
    Write-Host '    Esc  Back' -ForegroundColor DarkGray
    while ($true) {
        $answer = Read-KeyLine '  Choose an adapter: '
        if ($null -eq $answer) { return $null }
        if ($answer.Trim().ToLowerInvariant() -eq 'n') { return New-CustomAdapter }
        $choice = 0
        if ([int]::TryParse($answer, [ref]$choice) -and
            $choice -ge 1 -and $choice -le $saved.Count) {
            return Import-CustomAdapter -Path $saved[$choice - 1].FullName
        }
    }
}

function Wait-ProcessWithEscape {
    param(
        [Parameter(Mandatory)] $Process,
        [int] $TimeoutMilliseconds = 0
    )
    $started = [Environment]::TickCount
    while (-not $Process.WaitForExit(150)) {
        if (-not [Console]::IsInputRedirected -and [Console]::KeyAvailable -and
            [Console]::ReadKey($true).Key -eq [ConsoleKey]::Escape) {
            Stop-Process -Id $Process.Id -Force
            $Process.WaitForExit()
            throw [OperationCanceledException]::new('Benchmark canceled.')
        }
        if ($TimeoutMilliseconds -gt 0 -and
            ([Environment]::TickCount - $started) -ge $TimeoutMilliseconds) {
            return $false
        }
    }
    return $true
}

function Format-DownloadBytes {
    param([long] $Bytes)
    if ($Bytes -ge 1GB) { return ('{0:N2} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ('{0:N1} KB' -f ($Bytes / 1KB)) }
    return "$Bytes B"
}

function Save-RemoteFile {
    param(
        [Parameter(Mandatory)][string] $Uri,
        [Parameter(Mandatory)][string] $Destination
    )
    $partial = "$Destination.partial"
    if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial -Force }
    $destinationDirectory = Split-Path $Destination
    New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
    $handler = [System.Net.Http.HttpClientHandler]::new()
    $handler.AllowAutoRedirect = $true
    $client = [System.Net.Http.HttpClient]::new($handler)
    $client.DefaultRequestHeaders.UserAgent.ParseAdd('KillerPDF-Corpus-benchmark')
    $cancellation = [System.Threading.CancellationTokenSource]::new()
    $response = $null
    $inputStream = $null
    $outputStream = $null
    $completed = $false
    $fileName = [System.IO.Path]::GetFileName($Destination)
    try {
        $response = $client.GetAsync($Uri,
            [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead,
            $cancellation.Token).GetAwaiter().GetResult()
        $null = $response.EnsureSuccessStatusCode()
        $lengthHeader = $response.Content.Headers.ContentLength
        $totalBytes = if ($null -eq $lengthHeader) { 0L } else { [long]$lengthHeader }
        $inputStream = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        $outputStream = [System.IO.File]::Open($partial, [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        $buffer = New-Object byte[] (1MB)
        $downloaded = 0L
        while ($true) {
            $readTask = $inputStream.ReadAsync($buffer, 0, $buffer.Length, $cancellation.Token)
            while (-not $readTask.Wait(100)) {
                if (-not [Console]::IsInputRedirected -and [Console]::KeyAvailable -and
                    [Console]::ReadKey($true).Key -eq [ConsoleKey]::Escape) {
                    $cancellation.Cancel()
                    throw [OperationCanceledException]::new('Download canceled.')
                }
            }
            $read = $readTask.GetAwaiter().GetResult()
            if ($read -eq 0) { break }
            $outputStream.Write($buffer, 0, $read)
            $downloaded += $read
            $status = if ($totalBytes -gt 0) {
                "$(Format-DownloadBytes $downloaded) of $(Format-DownloadBytes $totalBytes). Esc cancels."
            } else {
                "$(Format-DownloadBytes $downloaded) downloaded. Esc cancels."
            }
            $percent = if ($totalBytes -gt 0) {
                [math]::Min(100, [math]::Round(($downloaded / $totalBytes) * 100))
            } else { 0 }
            Write-Progress -Activity "Downloading $fileName" -Status $status -PercentComplete $percent
        }
        $outputStream.Flush()
        $outputStream.Dispose()
        $outputStream = $null
        if (Test-Path -LiteralPath $Destination) { Remove-Item -LiteralPath $Destination -Force }
        Move-Item -LiteralPath $partial -Destination $Destination
        $completed = $true
        Write-Progress -Activity "Downloading $fileName" -Completed
        return $Destination
    }
    finally {
        if ($outputStream) { $outputStream.Dispose() }
        if ($inputStream) { $inputStream.Dispose() }
        if ($response) { $response.Dispose() }
        $cancellation.Dispose()
        $client.Dispose()
        $handler.Dispose()
        if (-not $completed -and (Test-Path -LiteralPath $partial)) {
            Remove-Item -LiteralPath $partial -Force
        }
        if (-not $completed) { Write-Progress -Activity "Downloading $fileName" -Completed }
    }
}

function ConvertTo-WindowsProcessArgument {
    param([AllowEmptyString()][string] $Value)
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }
    $builder = [System.Text.StringBuilder]::new()
    $null = $builder.Append('"')
    $backslashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq '\') {
            $backslashes++
            continue
        }
        if ($character -eq '"') {
            $null = $builder.Append(('\' * ($backslashes * 2 + 1)))
            $null = $builder.Append('"')
        }
        else {
            $null = $builder.Append(('\' * $backslashes))
            $null = $builder.Append($character)
        }
        $backslashes = 0
    }
    $null = $builder.Append(('\' * ($backslashes * 2)))
    $null = $builder.Append('"')
    return $builder.ToString()
}

function Set-ProcessArguments {
    param(
        [Parameter(Mandatory)] $StartInfo,
        [Parameter(Mandatory)][string[]] $Arguments
    )
    if ($StartInfo.PSObject.Properties.Name -contains 'ArgumentList') {
        foreach ($argument in $Arguments) { $StartInfo.ArgumentList.Add($argument) }
        return
    }
    $StartInfo.Arguments = (@($Arguments | ForEach-Object {
        ConvertTo-WindowsProcessArgument $_
    }) -join ' ')
}

function Read-BenchmarkChoices {
    if (-not $Tools -or $Tools.Count -eq 0) {
        $killerPdfStatus = if (Find-InstalledKillerPdf) { 'installed' } else { 'download available' }
        $qpdfStatus = if (Find-InstalledQpdf) { 'installed' } else { 'not found automatically' }
        Write-Host ''
        Write-Host '  Which supported PDF tools would you like to test?' -ForegroundColor White
        Write-Host "    1  KillerPDF ($killerPdfStatus)" -ForegroundColor Green
        Write-Host "    2  qpdf ($qpdfStatus)" -ForegroundColor Cyan
        Write-Host '    3  Both built-in tools' -ForegroundColor Yellow
        Write-Host '    4  Custom command-line tool' -ForegroundColor Magenta
        Write-Host '    Esc  Quit' -ForegroundColor DarkGray
        do {
            $choice = Read-KeyLine '  Choose 1, 2, 3, or 4: '
            if ($null -eq $choice) { return 'Quit' }
            $choice = $choice.Trim()
        } until ($choice -in @('1', '2', '3', '4'))
        $script:selectedTools = switch ($choice) {
            '1' { @('killerpdf') }
            '2' { @('qpdf') }
            '3' { @('killerpdf', 'qpdf') }
            '4' { @('custom') }
        }
    }
    elseif ($Tools -contains 'all') {
        $script:selectedTools = @('killerpdf', 'qpdf')
    }
    else {
        $script:selectedTools = @($Tools | Select-Object -Unique)
    }
    if ($script:selectedTools -contains 'custom' -and -not $script:customAdapter) {
        $script:customAdapter = Select-CustomAdapter
        if (-not $script:customAdapter) { return 'Back' }
    }

    if (-not $Collections -or $Collections.Count -eq 0) {
        Write-Host ''
        Write-Host '  Which collections would you like to test?' -ForegroundColor White
        Write-Host '    1  General regression PDFs' -ForegroundColor Cyan
        Write-Host '    2  PDF standards and conformance files' -ForegroundColor Yellow
        Write-Host '    3  Malformed security and crash tests' -ForegroundColor Magenta
        Write-Host '    4  Everything (recommended)' -ForegroundColor Green
        Write-Host '    Esc  Quit' -ForegroundColor DarkGray
        do {
            $choice = Read-KeyLine '  Choose 1, 2, 3, or 4: '
            if ($null -eq $choice) { return 'Quit' }
            $choice = $choice.Trim()
        } until ($choice -in @('1', '2', '3', '4'))
        $script:selectedCollections = switch ($choice) {
            '1' { @('regression') }
            '2' { @('standards') }
            '3' { @('fuzz') }
            '4' { @('regression', 'standards', 'fuzz') }
        }
    }
    elseif ($Collections -contains 'all') {
        $script:selectedCollections = @('regression', 'standards', 'fuzz')
    }
    else {
        $script:selectedCollections = @($Collections | Select-Object -Unique)
    }

    if ($Runs -eq 0 -and @($script:selectedCollections | Where-Object { $_ -ne 'fuzz' }).Count -gt 0) {
        do {
            Write-Host '  Press Esc to return to the collection menu.' -ForegroundColor DarkGray
            $answer = Read-KeyLine '  How many measured runs? [5]: '
            if ($null -eq $answer) { return 'Back' }
            $answer = $answer.Trim()
            if ([string]::IsNullOrWhiteSpace($answer)) {
                $script:measuredRuns = 5
            }
            else {
                $parsed = 0
                if ([int]::TryParse($answer, [ref]$parsed) -and $parsed -ge 1 -and $parsed -le 25) {
                    $script:measuredRuns = $parsed
                }
                else {
                    $script:measuredRuns = 0
                }
            }
        } until ($script:measuredRuns -ge 1)
    }
    elseif ($Runs -eq 0) {
        $script:measuredRuns = 1
    }
    else {
        $script:measuredRuns = $Runs
    }

    return 'Run'
}

function Find-InstalledKillerPdf {
    if (-not [string]::IsNullOrWhiteSpace($KillerPdfExe) -and
        (Test-Path -LiteralPath $KillerPdfExe -PathType Leaf)) {
        return [System.IO.Path]::GetFullPath($KillerPdfExe)
    }
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\KillerPDF\KillerPDF.App.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\KillerPDF\KillerPDF.exe'),
        (Join-Path $env:ProgramFiles 'KillerPDF\KillerPDF.App.exe'),
        (Join-Path $env:ProgramFiles 'KillerPDF\KillerPDF.exe'),
        (Join-Path $PSScriptRoot 'KillerPDF-Portable.exe'),
        (Join-Path (Get-Location) 'KillerPDF-Portable.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate -PathType Leaf) {
            return [System.IO.Path]::GetFullPath($candidate)
        }
    }
    return $null
}

function Find-InstalledQpdf {
    if (-not [string]::IsNullOrWhiteSpace($script:qpdfSelectedExe) -and
        (Test-Path -LiteralPath $script:qpdfSelectedExe -PathType Leaf)) {
        return [System.IO.Path]::GetFullPath($script:qpdfSelectedExe)
    }
    if (-not [string]::IsNullOrWhiteSpace($QpdfExe) -and
        (Test-Path -LiteralPath $QpdfExe -PathType Leaf)) {
        return [System.IO.Path]::GetFullPath($QpdfExe)
    }
    $command = Get-Command qpdf -ErrorAction SilentlyContinue
    if ($command -and (Test-Path -LiteralPath $command.Source -PathType Leaf)) {
        return [System.IO.Path]::GetFullPath($command.Source)
    }
    $localTools = Join-Path $env:LOCALAPPDATA 'KillerPDF-Corpus\tools'
    $candidate = Get-ChildItem -LiteralPath $localTools -Filter 'qpdf.exe' -File -Recurse `
        -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($candidate) { return $candidate.FullName }
    return $null
}

function Select-QpdfSource {
    Write-Host ''
    Write-Host '  qpdf was not found on PATH or in the runner cache.' -ForegroundColor Yellow
    Write-Host '    D  Download and verify qpdf automatically' -ForegroundColor Green
    Write-Host '    L  Locate an existing qpdf.exe' -ForegroundColor Cyan
    Write-Host '    Esc  Return to the main menu' -ForegroundColor DarkGray
    while ($true) {
        $answer = Read-KeyLine '  Choose D or L: '
        if ($null -eq $answer) {
            throw [OperationCanceledException]::new('Benchmark canceled.')
        }
        switch ($answer.Trim().ToLowerInvariant()) {
            'd' { return $null }
            'l' {
                while ($true) {
                    $path = Read-KeyLine '  Full path to qpdf.exe: '
                    if ($null -eq $path) { break }
                    $path = $path.Trim().Trim('"')
                    if (Test-Path -LiteralPath $path -PathType Leaf) {
                        $script:qpdfSelectedExe = [System.IO.Path]::GetFullPath($path)
                        return $script:qpdfSelectedExe
                    }
                    Write-Host '  That file was not found.' -ForegroundColor Red
                }
            }
        }
    }
}

function Resolve-KillerPdf {
    if (-not [string]::IsNullOrWhiteSpace($KillerPdfExe)) {
        if (-not (Test-Path -LiteralPath $KillerPdfExe -PathType Leaf)) {
            throw "KillerPDF was not found at: $KillerPdfExe"
        }
        return [System.IO.Path]::GetFullPath($KillerPdfExe)
    }

    $installed = Find-InstalledKillerPdf
    if ($installed) { return $installed }

    if ($SkipDownload) {
        throw 'KillerPDF was not found and downloads are disabled.'
    }

    Write-Step 'KillerPDF is not installed. Downloading the latest portable release.'
    $release = Invoke-RestMethod `
        -Uri 'https://api.github.com/repos/SteveTheKiller/KillerPDF/releases/latest' `
        -Headers @{ 'User-Agent' = 'KillerPDF-Corpus benchmark' }
    $asset = @($release.assets | Where-Object name -eq 'KillerPDF-Portable.exe')[0]
    if (-not $asset) {
        throw 'The latest KillerPDF release does not contain KillerPDF-Portable.exe.'
    }
    $toolDirectory = Join-Path $env:LOCALAPPDATA "KillerPDF-Corpus\tools\$($release.tag_name)"
    New-Item -ItemType Directory -Force -Path $toolDirectory | Out-Null
    $portable = Join-Path $toolDirectory 'KillerPDF-Portable.exe'
    Save-RemoteFile -Uri $asset.browser_download_url -Destination $portable | Out-Null
    $expected = ([string]$asset.digest).Replace('sha256:', '')
    $actual = (Get-FileHash -LiteralPath $portable -Algorithm SHA256).Hash
    if ([string]::IsNullOrWhiteSpace($expected) -or $actual -ne $expected) {
        Remove-Item -LiteralPath $portable -Force
        throw 'SHA-256 verification failed for KillerPDF-Portable.exe.'
    }
    Write-Host '    Verified KillerPDF-Portable.exe' -ForegroundColor Green
    return $portable
}

function Resolve-Qpdf {
    if (-not [string]::IsNullOrWhiteSpace($QpdfExe)) {
        if (-not (Test-Path -LiteralPath $QpdfExe -PathType Leaf)) {
            throw "qpdf was not found at: $QpdfExe"
        }
        return [System.IO.Path]::GetFullPath($QpdfExe)
    }

    $installed = Find-InstalledQpdf
    if ($installed) { return $installed }
    $localTools = Join-Path $env:LOCALAPPDATA 'KillerPDF-Corpus\tools'

    if ($SkipDownload) {
        throw 'qpdf was not found and downloads are disabled.'
    }

    if ($interactive) {
        $selected = Select-QpdfSource
        if ($selected) { return $selected }
    }

    Write-Step 'Downloading the latest official Windows build of qpdf.'
    $release = Invoke-RestMethod `
        -Uri 'https://api.github.com/repos/qpdf/qpdf/releases/latest' `
        -Headers @{ 'User-Agent' = 'KillerPDF-Corpus benchmark' }
    $asset = @($release.assets | Where-Object name -Match '-msvc64\.zip$')[0]
    if (-not $asset) {
        throw 'The latest qpdf release does not contain an msvc64 ZIP archive.'
    }
    $expected = ([string]$asset.digest).Replace('sha256:', '').ToUpperInvariant()
    if ([string]::IsNullOrWhiteSpace($expected)) {
        throw 'The qpdf release asset does not publish a SHA-256 digest.'
    }

    $toolDirectory = Join-Path $localTools "qpdf-$($release.tag_name)"
    $archive = Join-Path $localTools $asset.name
    New-Item -ItemType Directory -Force -Path $localTools | Out-Null
    Save-RemoteFile -Uri $asset.browser_download_url -Destination $archive | Out-Null
    $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash
    if ($actual -ne $expected) {
        Remove-Item -LiteralPath $archive -Force
        throw "SHA-256 verification failed for $($asset.name)."
    }
    Write-Host "    Verified $($asset.name)" -ForegroundColor Green

    if (Test-Path -LiteralPath $toolDirectory) {
        Remove-GeneratedDirectory -Path $toolDirectory -RequiredParent $localTools
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $toolDirectory -Force
    Remove-Item -LiteralPath $archive -Force
    $resolved = Get-ChildItem -LiteralPath $toolDirectory -Filter 'qpdf.exe' -File -Recurse |
        Select-Object -First 1
    if (-not $resolved) {
        throw 'The verified qpdf archive did not contain qpdf.exe.'
    }
    return $resolved.FullName
}

function Get-GitHubRelease {
    $endpoint = if ([string]::IsNullOrWhiteSpace($CorpusVersion)) {
        'https://api.github.com/repos/SteveTheKiller/KillerPDF-Corpus/releases/latest'
    }
    else {
        "https://api.github.com/repos/SteveTheKiller/KillerPDF-Corpus/releases/tags/$CorpusVersion"
    }
    return Invoke-RestMethod -Uri $endpoint -Headers @{ 'User-Agent' = 'KillerPDF-Corpus benchmark' }
}

function Save-ReleaseAsset {
    param(
        [Parameter(Mandatory)] $Assets,
        [Parameter(Mandatory)][string] $Name,
        [Parameter(Mandatory)][string] $Directory
    )
    $asset = @($Assets | Where-Object name -eq $Name)[0]
    if (-not $asset) {
        throw "Release asset not found: $Name"
    }
    New-Item -ItemType Directory -Force -Path $Directory | Out-Null
    $destination = Join-Path $Directory $Name
    Write-Step "Downloading $Name"
    Save-RemoteFile -Uri $asset.browser_download_url -Destination $destination | Out-Null
    return $destination
}

function Confirm-ArchiveHash {
    param(
        [Parameter(Mandatory)][string] $Archive,
        [Parameter(Mandatory)][string] $DigestFile,
        [Parameter(Mandatory)][string] $IndexDigest
    )
    $expected = ((Get-Content -LiteralPath $DigestFile -Raw).Trim() -split '\s+')[0]
    $actual = (Get-FileHash -LiteralPath $Archive -Algorithm SHA256).Hash
    if ($actual -ne $expected -or $actual -ne $IndexDigest) {
        throw "SHA-256 verification failed for $([System.IO.Path]::GetFileName($Archive))."
    }
    Write-Host "    Verified $([System.IO.Path]::GetFileName($Archive))" -ForegroundColor Green
}

function Invoke-CorpusDownload {
    $folderNames = @{ regression = 'regression'; standards = 'conformance'; fuzz = 'fuzz' }
    $required = @($script:selectedCollections | Where-Object { $folderNames.ContainsKey($_) } | ForEach-Object {
        [pscustomobject]@{
            Category = $_
            Path = (Join-Path $corpusRoot $folderNames[$_])
        }
    })

    $missing = @($required | Where-Object {
        -not (Test-Path -LiteralPath $_.Path -PathType Container) -or
        @(Get-ChildItem -LiteralPath $_.Path -File -Recurse -ErrorAction SilentlyContinue).Count -eq 0
    })

    if ($missing.Count -eq 0) {
        Write-Step 'The published corpus is already present.'
        return
    }
    if ($SkipDownload) {
        throw "A required corpus collection is missing: $($missing[0].Path)"
    }

    $release = Get-GitHubRelease
    $script:resolvedCorpusVersion = $release.tag_name
    $downloads = Join-Path $corpusRoot 'downloads'
    $indexName = "killerpdf-corpus-$($release.tag_name)-assets.json"
    $indexPath = Save-ReleaseAsset -Assets $release.assets -Name $indexName -Directory $downloads
    $index = Get-Content -LiteralPath $indexPath -Raw | ConvertFrom-Json
    if ($index.version -ne $release.tag_name) {
        throw "Release index version is $($index.version), expected $($release.tag_name)."
    }

    foreach ($category in $missing.Category) {
        $collection = $index.collections.$category
        if (-not $collection) {
            throw "Release collection not found: $category"
        }
        $destinationName = $folderNames[$category]
        foreach ($archiveInfo in $collection.assets) {
            $archive = Save-ReleaseAsset -Assets $release.assets -Name $archiveInfo.name -Directory $downloads
            $digest = Save-ReleaseAsset -Assets $release.assets -Name "$($archiveInfo.name).sha256" -Directory $downloads
            Confirm-ArchiveHash -Archive $archive -DigestFile $digest -IndexDigest $archiveInfo.sha256
            $destination = Join-Path $corpusRoot $destinationName
            New-Item -ItemType Directory -Force -Path $destination | Out-Null
            Write-Step "Extracting $($archiveInfo.name)"
            Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
        }
    }
}

function Remove-GeneratedDirectory {
    param(
        [Parameter(Mandatory)][string] $Path,
        [Parameter(Mandatory)][string] $RequiredParent
    )

    $resolvedPath = [System.IO.Path]::GetFullPath($Path)
    $resolvedParent = [System.IO.Path]::GetFullPath($RequiredParent)
    if (-not $resolvedPath.StartsWith(
            $resolvedParent + [System.IO.Path]::DirectorySeparatorChar,
            [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove an unsafe generated path: $resolvedPath"
    }
    if (Test-Path -LiteralPath $resolvedPath) {
        Remove-Item -LiteralPath $resolvedPath -Recurse -Force
    }
}

function Invoke-CollectionRun {
    param(
        [Parameter(Mandatory)][string] $Collection,
        [Parameter(Mandatory)][string] $InputDirectory,
        [Parameter(Mandatory)][int] $Number,
        [Parameter(Mandatory)][bool] $Measured,
        [Parameter(Mandatory)][int] $TotalPasses
    )

    $label = if ($Measured) { "run-$Number" } else { 'warmup' }
    $collectionRoot = Join-Path $resultRoot $Collection
    $outputDirectory = Join-Path $collectionRoot "output-$label"
    $logPath = Join-Path $collectionRoot "$label.csv"
    New-Item -ItemType Directory -Force -Path $collectionRoot | Out-Null
    Remove-GeneratedDirectory -Path $outputDirectory -RequiredParent $collectionRoot
    if (Test-Path -LiteralPath $logPath) {
        Remove-Item -LiteralPath $logPath -Force
    }
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null

    $activity = "Benchmarking $Collection"
    $status = if ($Measured) { "Measured pass $Number of $TotalPasses" } else { 'Warmup pass' }
    $percent = if ($Measured) {
        [math]::Round((($Number + 1) / ($TotalPasses + 1)) * 100)
    }
    else { 0 }
    Write-Progress -Activity $activity -Status $status -PercentComplete $percent
    Write-Step "${Collection}: $status"

    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $process = Start-Process -FilePath $script:exe -ArgumentList @(
        '--batch-resave',
        $InputDirectory,
        $outputDirectory,
        '--log',
        $logPath,
        '--quiet'
    ) -WindowStyle Hidden -PassThru
    Write-Host '    Esc cancels and returns to the main menu.' -ForegroundColor DarkGray
    $null = Wait-ProcessWithEscape -Process $process
    $stopwatch.Stop()

    if (-not (Test-Path -LiteralPath $logPath -PathType Leaf)) {
        throw "$Collection $label did not create a result log."
    }

    $rows = @(Import-Csv -LiteralPath $logPath)
    $ok = @($rows | Where-Object Status -eq 'OK').Count
    $skipped = @($rows | Where-Object Status -eq 'SKIP').Count
    $failed = @($rows | Where-Object Status -eq 'FAIL').Count
    $seconds = $stopwatch.Elapsed.TotalSeconds
    $record = [pscustomobject]@{
        Collection = $Collection
        Run = $label
        Measured = $Measured
        Seconds = [math]::Round($seconds, 3)
        Total = $rows.Count
        OK = $ok
        Skipped = $skipped
        Failed = $failed
        FilesPerSecond = [math]::Round($rows.Count / $seconds, 2)
        SuccessfulPerSecond = [math]::Round($ok / $seconds, 2)
        ExitCode = $process.ExitCode
    }

    Remove-GeneratedDirectory -Path $outputDirectory -RequiredParent $collectionRoot
    Write-Host ('    {0:N3} s  {1:N2} files/s  OK {2:N0}  SKIP {3:N0}  FAIL {4:N0}' -f
        $record.Seconds, $record.FilesPerSecond, $ok, $skipped, $failed) -ForegroundColor Gray
    return $record
}

function Invoke-FuzzGate {
    param([Parameter(Mandatory)][string] $InputDirectory)

    $fuzzRoot = Join-Path $resultRoot 'public-fuzz'
    $temporaryRoot = Join-Path $fuzzRoot 'temporary-output'
    New-Item -ItemType Directory -Force -Path $fuzzRoot | Out-Null
    Remove-GeneratedDirectory -Path $temporaryRoot -RequiredParent $fuzzRoot
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

    $files = @(Get-ChildItem -LiteralPath $InputDirectory -File -Recurse | Sort-Object FullName)
    $records = [System.Collections.Generic.List[object]]::new()
    for ($index = 0; $index -lt $files.Count; $index++) {
        $file = $files[$index]
        $itemRoot = Join-Path $temporaryRoot $index
        $outputPath = Join-Path $itemRoot 'output.pdf'
        $logPath = Join-Path $itemRoot 'result.csv'
        New-Item -ItemType Directory -Path $itemRoot | Out-Null
        Write-Progress -Activity 'Running the malformed-input safety gate' `
            -Status "$($index + 1) of $($files.Count): $($file.Name)" `
            -PercentComplete ([math]::Round((($index + 1) / $files.Count) * 100))

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $process = Start-Process -FilePath $script:exe -ArgumentList @(
            '--batch-resave',
            $file.FullName,
            $outputPath,
            '--log',
            $logPath,
            '--quiet'
        ) -WindowStyle Hidden -PassThru
        $completed = Wait-ProcessWithEscape -Process $process `
            -TimeoutMilliseconds ($FuzzTimeoutSeconds * 1000)
        $stopwatch.Stop()
        $timedOut = -not $completed
        if ($timedOut) {
            Stop-Process -Id $process.Id -Force
            $process.WaitForExit()
        }

        $status = 'NOLOG'
        $detail = ''
        if ($timedOut) {
            $status = 'TIMEOUT'
            $detail = "Exceeded $FuzzTimeoutSeconds seconds."
        }
        elseif (Test-Path -LiteralPath $logPath -PathType Leaf) {
            $row = @(Import-Csv -LiteralPath $logPath)[0]
            $status = $row.Status
            $detail = $row.Detail
        }

        $records.Add([pscustomobject]@{
            File = $file.FullName.Substring($InputDirectory.Length + 1)
            Extension = $file.Extension
            Bytes = $file.Length
            Status = $status
            Detail = $detail
            Seconds = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
            ExitCode = if ($timedOut) { $null } else { $process.ExitCode }
        })
        Remove-GeneratedDirectory -Path $itemRoot -RequiredParent $temporaryRoot
    }

    Write-Progress -Activity 'Running the malformed-input safety gate' -Completed
    $resultsPath = Join-Path $fuzzRoot 'fuzz-results.csv'
    $summaryPath = Join-Path $fuzzRoot 'fuzz-summary.csv'
    $records | Export-Csv -LiteralPath $resultsPath -NoTypeInformation
    $summary = @($records | Group-Object Status | Sort-Object Name | ForEach-Object {
        [pscustomobject]@{ Status = $_.Name; Count = $_.Count }
    })
    $summary | Export-Csv -LiteralPath $summaryPath -NoTypeInformation
    Remove-GeneratedDirectory -Path $temporaryRoot -RequiredParent $fuzzRoot
    return $summary
}

function Invoke-QpdfCollectionRun {
    param(
        [Parameter(Mandatory)][string] $Collection,
        [Parameter(Mandatory)][string] $InputDirectory,
        [Parameter(Mandatory)][int] $Number,
        [Parameter(Mandatory)][bool] $Measured,
        [Parameter(Mandatory)][int] $TotalPasses,
        [int] $TimeoutMilliseconds = 0
    )

    $label = if ($Measured) { "run-$Number" } else { 'warmup' }
    $collectionRoot = Join-Path $resultRoot "qpdf-$Collection"
    $temporaryRoot = Join-Path $collectionRoot "output-$label"
    $detailPath = Join-Path $collectionRoot "$label.csv"
    New-Item -ItemType Directory -Force -Path $collectionRoot | Out-Null
    Remove-GeneratedDirectory -Path $temporaryRoot -RequiredParent $collectionRoot
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

    $files = @(Get-ChildItem -LiteralPath $InputDirectory -File -Recurse |
        Sort-Object FullName)
    $details = [System.Collections.Generic.List[object]]::new()
    $saved = 0
    $warnings = 0
    $failed = 0
    $timedOut = 0
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Step "qpdf ${Collection}: $label"
    Write-Host '    qpdf is launched once per PDF. Esc cancels and returns to the main menu.' `
        -ForegroundColor DarkGray
    try {
        for ($index = 0; $index -lt $files.Count; $index++) {
            if (-not [Console]::IsInputRedirected -and [Console]::KeyAvailable -and
                [Console]::ReadKey($true).Key -eq [ConsoleKey]::Escape) {
                throw [OperationCanceledException]::new('Benchmark canceled.')
            }
            $file = $files[$index]
            $outputPath = Join-Path $temporaryRoot 'output.pdf'
            if (Test-Path -LiteralPath $outputPath) {
                Remove-Item -LiteralPath $outputPath -Force
            }
            if ($index % 100 -eq 0 -or $index -eq $files.Count - 1) {
                Write-Progress -Activity "qpdf adapter: $Collection" `
                    -Status "$label, file $($index + 1) of $($files.Count)" `
                    -PercentComplete ([math]::Round((($index + 1) / $files.Count) * 100))
            }

            $itemWatch = [System.Diagnostics.Stopwatch]::StartNew()
            $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
            $startInfo.FileName = $script:qpdfExe
            $startInfo.UseShellExecute = $false
            $startInfo.CreateNoWindow = $true
            $startInfo.RedirectStandardOutput = $true
            $startInfo.RedirectStandardError = $true
            Set-ProcessArguments -StartInfo $startInfo -Arguments @($file.FullName, $outputPath)
            $process = [System.Diagnostics.Process]::new()
            $process.StartInfo = $startInfo
            $null = $process.Start()
            $process.BeginOutputReadLine()
            $process.BeginErrorReadLine()
            $completed = Wait-ProcessWithEscape -Process $process `
                -TimeoutMilliseconds $TimeoutMilliseconds
            $itemWatch.Stop()

            if (-not $completed) {
                Stop-Process -Id $process.Id -Force
                $process.WaitForExit()
                $status = 'TIMEOUT'
                $timedOut++
                $exitCode = $null
            }
            else {
                $exitCode = $process.ExitCode
                if ($exitCode -eq 0 -and (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
                    $status = 'SAVED'
                    $saved++
                }
                elseif ($exitCode -eq 3 -and (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
                    $status = 'WARNING'
                    $warnings++
                }
                else {
                    $status = 'FAILED'
                    $failed++
                }
            }

            $details.Add([pscustomobject]@{
                File = $file.FullName.Substring($InputDirectory.Length + 1)
                Status = $status
                ExitCode = $exitCode
                Seconds = [math]::Round($itemWatch.Elapsed.TotalSeconds, 3)
            })
        }
    }
    finally {
        $stopwatch.Stop()
        Write-Progress -Activity "qpdf adapter: $Collection" -Completed
        Remove-GeneratedDirectory -Path $temporaryRoot -RequiredParent $collectionRoot
    }

    $details | Export-Csv -LiteralPath $detailPath -NoTypeInformation
    $seconds = $stopwatch.Elapsed.TotalSeconds
    $record = [pscustomobject]@{
        Tool = 'qpdf'
        Collection = $Collection
        Run = $label
        Measured = $Measured
        Seconds = [math]::Round($seconds, 3)
        Total = $files.Count
        Saved = $saved
        Warnings = $warnings
        Failed = $failed
        Timeouts = $timedOut
        TimeoutSecondsPerFile = [math]::Round($TimeoutMilliseconds / 1000, 3)
        FilesPerSecond = [math]::Round($files.Count / $seconds, 2)
        SuccessfulPerSecond = [math]::Round(($saved + $warnings) / $seconds, 2)
        ExecutableSHA256 = $script:qpdfHash
        Version = $script:qpdfVersion
    }
    Write-Host ('    {0:N3} s  {1:N2} files/s  SAVED {2:N0}  WARN {3:N0}  FAIL {4:N0}  TIMEOUT {5:N0}' -f
        $record.Seconds, $record.FilesPerSecond, $saved, $warnings, $failed, $timedOut) `
        -ForegroundColor Gray
    return $record
}

function New-QpdfSummary {
    param([Parameter(Mandatory)] $Runs)

    return @($Runs | Where-Object Measured | Group-Object Collection | ForEach-Object {
        $group = @($_.Group)
        $times = @($group.Seconds | Sort-Object)
        $rates = @($group.FilesPerSecond | Sort-Object)
        $successfulRates = @($group.SuccessfulPerSecond | Sort-Object)
        $middle = [math]::Floor($group.Count / 2)
        $signatures = @($group | ForEach-Object {
            "$($_.Total)|$($_.Saved)|$($_.Warnings)|$($_.Failed)|$($_.Timeouts)"
        } | Select-Object -Unique)
        if ($signatures.Count -ne 1) {
            throw "qpdf outcome counts changed between measured runs for $($_.Name)."
        }
        [pscustomobject]@{
            Tool = 'qpdf'
            Version = $script:qpdfVersion
            Collection = $_.Name
            Files = $group[0].Total
            Runs = $group.Count
            MedianSeconds = $times[$middle]
            MinimumSeconds = $times[0]
            MaximumSeconds = $times[-1]
            MedianFilesPerSecond = $rates[$middle]
            MedianSuccessfulPerSecond = $successfulRates[$middle]
            Saved = $group[0].Saved
            Warnings = $group[0].Warnings
            Failed = $group[0].Failed
            Timeouts = $group[0].Timeouts
            TimeoutSecondsPerFile = $group[0].TimeoutSecondsPerFile
            ExecutableSHA256 = $script:qpdfHash
            TimingIncludesProcessStartupPerFile = $true
        }
    })
}

function Invoke-CustomAdapterFile {
    param(
        [Parameter(Mandatory)][string] $InputPath,
        [Parameter(Mandatory)][string] $OutputPath
    )
    if (Test-Path -LiteralPath $OutputPath) {
        Remove-Item -LiteralPath $OutputPath -Force
    }
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = [string]$script:customAdapter.executable
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $expandedArguments = @($script:customAdapter.runArguments | ForEach-Object {
        ([string]$_).Replace('{input}', $InputPath).Replace('{output}', $OutputPath)
    })
    Set-ProcessArguments -StartInfo $startInfo -Arguments $expandedArguments
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    $null = $process.Start()
    $process.BeginOutputReadLine()
    $process.BeginErrorReadLine()
    $completed = Wait-ProcessWithEscape -Process $process `
        -TimeoutMilliseconds ([int]$script:customAdapter.timeoutSeconds * 1000)
    $watch.Stop()
    if (-not $completed) {
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit()
        return [pscustomobject]@{
            Status = 'TIMEOUT'; ExitCode = $null; Seconds = $watch.Elapsed.TotalSeconds
        }
    }
    $exitCode = $process.ExitCode
    $outputExists = Test-Path -LiteralPath $OutputPath -PathType Leaf
    $outputAccepted = -not [bool]$script:customAdapter.outputRequired -or $outputExists
    $status = if (@($script:customAdapter.savedExitCodes) -contains $exitCode -and $outputAccepted) {
        'SAVED'
    }
    elseif (@($script:customAdapter.warningExitCodes) -contains $exitCode -and $outputAccepted) {
        'WARNING'
    }
    else {
        'FAILED'
    }
    return [pscustomobject]@{
        Status = $status
        ExitCode = $exitCode
        Seconds = $watch.Elapsed.TotalSeconds
    }
}

function Get-CustomAdapterVersion {
    $versionArguments = @($script:customAdapter.versionArguments | ForEach-Object { [string]$_ })
    if ($versionArguments.Count -gt 0) {
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = [string]$script:customAdapter.executable
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        Set-ProcessArguments -StartInfo $startInfo -Arguments $versionArguments
        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        $null = $process.Start()
        $standardOutput = $process.StandardOutput.ReadToEnd()
        $standardError = $process.StandardError.ReadToEnd()
        if (-not $process.WaitForExit(5000)) {
            Stop-Process -Id $process.Id -Force
            $process.WaitForExit()
        }
        else {
            $line = @($standardOutput, $standardError) -split "`r?`n" |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -First 1
            if ($line) { return ([string]$line).Trim() }
        }
    }
    $productVersion = (Get-Item -LiteralPath $script:customAdapter.executable).VersionInfo.ProductVersion
    if ([string]::IsNullOrWhiteSpace($productVersion)) { return 'unknown' }
    return $productVersion.Split('+')[0]
}

function Test-CustomAdapter {
    param([Parameter(Mandatory)][string] $InputDirectory)
    $probe = Get-ChildItem -LiteralPath $InputDirectory -File -Recurse |
        Sort-Object FullName | Select-Object -First 1
    if (-not $probe) { throw 'The selected collection contains no files for adapter validation.' }
    $validationRoot = Join-Path $resultRoot "adapter-validation-$($script:customAdapter.id)"
    New-Item -ItemType Directory -Force -Path $validationRoot | Out-Null
    $outputPath = Join-Path $validationRoot 'output.pdf'
    Write-Step "Validating the $($script:customAdapter.name) adapter with $($probe.Name)"
    try {
        $result = Invoke-CustomAdapterFile -InputPath $probe.FullName -OutputPath $outputPath
        Write-Host "    Process started successfully. Result: $($result.Status)" -ForegroundColor Green
    }
    finally {
        Remove-GeneratedDirectory -Path $validationRoot -RequiredParent $resultRoot
    }
    if ($interactive) {
        do {
            $answer = Read-KeyLine '  Continue with the full benchmark? [Y/n]: '
            if ($null -eq $answer) { throw [OperationCanceledException]::new('Benchmark canceled.') }
            $answer = $answer.Trim().ToLowerInvariant()
        } until ($answer -in @('', 'y', 'yes', 'n', 'no'))
        if ($answer -in @('n', 'no')) {
            throw [OperationCanceledException]::new('Benchmark canceled.')
        }
    }
}

function Invoke-CustomAdapterCollectionRun {
    param(
        [Parameter(Mandatory)][string] $Collection,
        [Parameter(Mandatory)][string] $InputDirectory,
        [Parameter(Mandatory)][int] $Number,
        [Parameter(Mandatory)][bool] $Measured
    )
    $label = if ($Measured) { "run-$Number" } else { 'warmup' }
    $collectionRoot = Join-Path $resultRoot "$($script:customAdapter.id)-$Collection"
    $temporaryRoot = Join-Path $collectionRoot "output-$label"
    $detailPath = Join-Path $collectionRoot "$label.csv"
    New-Item -ItemType Directory -Force -Path $collectionRoot | Out-Null
    Remove-GeneratedDirectory -Path $temporaryRoot -RequiredParent $collectionRoot
    New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
    $files = @(Get-ChildItem -LiteralPath $InputDirectory -File -Recurse | Sort-Object FullName)
    $details = [System.Collections.Generic.List[object]]::new()
    $counts = @{ SAVED = 0; WARNING = 0; FAILED = 0; TIMEOUT = 0 }
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-Step "$($script:customAdapter.name) ${Collection}: $label"
    Write-Host '    The tool is launched once per PDF. Esc cancels and returns to the main menu.' `
        -ForegroundColor DarkGray
    try {
        for ($index = 0; $index -lt $files.Count; $index++) {
            if (-not [Console]::IsInputRedirected -and [Console]::KeyAvailable -and
                [Console]::ReadKey($true).Key -eq [ConsoleKey]::Escape) {
                throw [OperationCanceledException]::new('Benchmark canceled.')
            }
            $file = $files[$index]
            $outputPath = Join-Path $temporaryRoot 'output.pdf'
            if ($index % 100 -eq 0 -or $index -eq $files.Count - 1) {
                Write-Progress -Activity "$($script:customAdapter.name) adapter: $Collection" `
                    -Status "$label, file $($index + 1) of $($files.Count)" `
                    -PercentComplete ([math]::Round((($index + 1) / $files.Count) * 100))
            }
            $result = Invoke-CustomAdapterFile -InputPath $file.FullName -OutputPath $outputPath
            $counts[$result.Status]++
            $details.Add([pscustomobject]@{
                File = $file.FullName.Substring($InputDirectory.Length + 1)
                Status = $result.Status
                ExitCode = $result.ExitCode
                Seconds = [math]::Round($result.Seconds, 3)
            })
        }
    }
    finally {
        $watch.Stop()
        Write-Progress -Activity "$($script:customAdapter.name) adapter: $Collection" -Completed
        Remove-GeneratedDirectory -Path $temporaryRoot -RequiredParent $collectionRoot
    }
    $details | Export-Csv -LiteralPath $detailPath -NoTypeInformation
    $seconds = $watch.Elapsed.TotalSeconds
    $record = [pscustomobject]@{
        Tool = [string]$script:customAdapter.name
        AdapterId = [string]$script:customAdapter.id
        Collection = $Collection
        Run = $label
        Measured = $Measured
        Seconds = [math]::Round($seconds, 3)
        Total = $files.Count
        Saved = $counts.SAVED
        Warnings = $counts.WARNING
        Failed = $counts.FAILED
        Timeouts = $counts.TIMEOUT
        TimeoutSecondsPerFile = [int]$script:customAdapter.timeoutSeconds
        FilesPerSecond = [math]::Round($files.Count / $seconds, 2)
        SuccessfulPerSecond = [math]::Round(($counts.SAVED + $counts.WARNING) / $seconds, 2)
        ExecutableSHA256 = $script:customAdapterHash
        Version = $script:customAdapterVersion
    }
    Write-Host ('    {0:N3} s  {1:N2} files/s  SAVED {2:N0}  WARN {3:N0}  FAIL {4:N0}  TIMEOUT {5:N0}' -f
        $record.Seconds, $record.FilesPerSecond, $record.Saved, $record.Warnings,
        $record.Failed, $record.Timeouts) -ForegroundColor Gray
    return $record
}

function New-CustomAdapterSummary {
    param([Parameter(Mandatory)] $Runs)
    return @($Runs | Where-Object Measured | Group-Object Collection | ForEach-Object {
        $group = @($_.Group)
        $times = @($group.Seconds | Sort-Object)
        $rates = @($group.FilesPerSecond | Sort-Object)
        $successfulRates = @($group.SuccessfulPerSecond | Sort-Object)
        $middle = [math]::Floor($group.Count / 2)
        $signatures = @($group | ForEach-Object {
            "$($_.Total)|$($_.Saved)|$($_.Warnings)|$($_.Failed)|$($_.Timeouts)"
        } | Select-Object -Unique)
        if ($signatures.Count -ne 1) {
            throw "Adapter outcome counts changed between measured runs for $($_.Name)."
        }
        [pscustomobject]@{
            Tool = [string]$script:customAdapter.name
            Version = $script:customAdapterVersion
            Collection = $_.Name
            Files = $group[0].Total
            Runs = $group.Count
            MedianSeconds = $times[$middle]
            MinimumSeconds = $times[0]
            MaximumSeconds = $times[-1]
            MedianFilesPerSecond = $rates[$middle]
            MedianSuccessfulPerSecond = $successfulRates[$middle]
            Saved = $group[0].Saved
            Warnings = $group[0].Warnings
            Failed = $group[0].Failed
            Timeouts = $group[0].Timeouts
            TimeoutSecondsPerFile = $group[0].TimeoutSecondsPerFile
            ExecutableSHA256 = $script:customAdapterHash
            TimingIncludesProcessStartupPerFile = $true
        }
    })
}

function Invoke-BenchmarkSession {
if ($script:selectedTools -contains 'killerpdf') {
    $script:exe = Resolve-KillerPdf
    $version = (Get-Item -LiteralPath $script:exe).VersionInfo.ProductVersion
    if ([string]::IsNullOrWhiteSpace($version)) {
        $version = 'unknown'
    }
    $version = $version.Split('+')[0]
    $exeHash = (Get-FileHash -LiteralPath $script:exe -Algorithm SHA256).Hash
    Write-Host "  KillerPDF : $version" -ForegroundColor White
    Write-Host "  Executable: $script:exe" -ForegroundColor DarkGray
    Write-Host "  SHA-256   : $exeHash" -ForegroundColor DarkGray
}
Write-Host "  Results   : $resultRoot" -ForegroundColor DarkGray

if ($script:selectedTools -contains 'qpdf') {
    $script:qpdfExe = Resolve-Qpdf
    $script:qpdfHash = (Get-FileHash -LiteralPath $script:qpdfExe -Algorithm SHA256).Hash
    $qpdfVersionLine = @(& $script:qpdfExe --version)[0]
    $script:qpdfVersion = ([string]$qpdfVersionLine).Replace('qpdf version ', '').Trim()
    Write-Host "  qpdf     : $script:qpdfVersion" -ForegroundColor White
    Write-Host "  Executable: $script:qpdfExe" -ForegroundColor DarkGray
    Write-Host "  SHA-256   : $script:qpdfHash" -ForegroundColor DarkGray
}
if ($script:selectedTools -contains 'custom') {
    $script:customAdapterHash = (Get-FileHash `
        -LiteralPath $script:customAdapter.executable -Algorithm SHA256).Hash
    $script:customAdapterVersion = Get-CustomAdapterVersion
    Write-Host "  Custom tool: $($script:customAdapter.name) $script:customAdapterVersion" `
        -ForegroundColor White
    Write-Host "  Executable : $($script:customAdapter.executable)" -ForegroundColor DarkGray
    Write-Host "  SHA-256    : $script:customAdapterHash" -ForegroundColor DarkGray
}

Write-Heading 'Preparing the corpus'
Invoke-CorpusDownload
New-Item -ItemType Directory -Force -Path $resultRoot | Out-Null

$collections = @()
if ($script:selectedCollections -contains 'regression') {
    $collections += [pscustomobject]@{
        Name = 'public-regression'
        Path = (Join-Path $corpusRoot 'regression')
    }
}
if ($script:selectedCollections -contains 'standards') {
    $collections += [pscustomobject]@{
        Name = 'public-standards'
        Path = (Join-Path $corpusRoot 'conformance')
    }
}
if ($script:selectedCollections -contains 'stress' -and
    [string]::IsNullOrWhiteSpace($PrivateStressDirectory)) {
    throw '-Collections stress requires -PrivateStressDirectory.'
}
if (-not [string]::IsNullOrWhiteSpace($PrivateStressDirectory)) {
    $stressPath = [System.IO.Path]::GetFullPath($PrivateStressDirectory)
    if (-not (Test-Path -LiteralPath $stressPath -PathType Container)) {
        throw "The private stress collection was not found at: $stressPath"
    }
    $collections += [pscustomobject]@{
        Name = 'private-stress'
        Path = $stressPath
    }
}
$customProbeDirectory = if ($collections.Count -gt 0) {
    $collections[0].Path
} elseif ($script:selectedCollections -contains 'fuzz') {
    Join-Path $corpusRoot 'fuzz'
} else { $null }
if ($script:selectedTools -contains 'custom') {
    Test-CustomAdapter -InputDirectory $customProbeDirectory
}
$allRuns = [System.Collections.Generic.List[object]]::new()

if ($script:selectedTools -contains 'killerpdf' -and $collections.Count -gt 0) {
    Write-Heading 'Running the KillerPDF adapter'
    foreach ($collection in $collections) {
        $allRuns.Add((Invoke-CollectionRun -Collection $collection.Name `
            -InputDirectory $collection.Path -Number 0 -Measured $false `
            -TotalPasses $script:measuredRuns))
        for ($run = 1; $run -le $script:measuredRuns; $run++) {
            $allRuns.Add((Invoke-CollectionRun -Collection $collection.Name `
                -InputDirectory $collection.Path -Number $run -Measured $true `
                -TotalPasses $script:measuredRuns))
        }
        Write-Progress -Activity "Benchmarking $($collection.Name)" -Completed
    }
}

$runsPath = Join-Path $resultRoot 'benchmark-runs.csv'
$summaryPath = Join-Path $resultRoot 'benchmark-summary.csv'
if ($allRuns.Count -gt 0) {
    $allRuns | Export-Csv -LiteralPath $runsPath -NoTypeInformation
}
$summary = @($allRuns | Where-Object Measured | Group-Object Collection | ForEach-Object {
    $group = @($_.Group)
    $times = @($group.Seconds | Sort-Object)
    $rates = @($group.FilesPerSecond | Sort-Object)
    $successfulRates = @($group.SuccessfulPerSecond | Sort-Object)
    $middle = [math]::Floor($group.Count / 2)
    $signatures = @($group | ForEach-Object { "$($_.Total)|$($_.OK)|$($_.Skipped)|$($_.Failed)" } | Select-Object -Unique)
    if ($signatures.Count -ne 1) {
        throw "Outcome counts changed between measured runs for $($_.Name)."
    }
    [pscustomobject]@{
        Version = $version
        Collection = $_.Name
        Files = $group[0].Total
        Runs = $group.Count
        MedianSeconds = $times[$middle]
        MinimumSeconds = $times[0]
        MaximumSeconds = $times[-1]
        MedianFilesPerSecond = $rates[$middle]
        MedianSuccessfulPerSecond = $successfulRates[$middle]
        OK = $group[0].OK
        Skipped = $group[0].Skipped
        Failed = $group[0].Failed
        ExecutableSHA256 = $exeHash
    }
})
if ($summary.Count -gt 0) {
    $summary | Export-Csv -LiteralPath $summaryPath -NoTypeInformation
}

$fuzzSummary = @()
if ($script:selectedTools -contains 'killerpdf' -and $script:selectedCollections -contains 'fuzz') {
    Write-Heading 'Running the malformed-input safety gate'
    $fuzzSummary = @(Invoke-FuzzGate -InputDirectory (Join-Path $corpusRoot 'fuzz'))
}

$qpdfRuns = [System.Collections.Generic.List[object]]::new()
$qpdfSummary = @()
$qpdfRunsPath = Join-Path $resultRoot 'qpdf-benchmark-runs.csv'
$qpdfSummaryPath = Join-Path $resultRoot 'qpdf-benchmark-summary.csv'
if ($script:selectedTools -contains 'qpdf') {
    Write-Heading 'Running the qpdf adapter'
    foreach ($collection in $collections) {
        $qpdfRecord = Invoke-QpdfCollectionRun -Collection $collection.Name `
            -InputDirectory $collection.Path -Number 0 -Measured $false `
            -TotalPasses $script:measuredRuns `
            -TimeoutMilliseconds ($FuzzTimeoutSeconds * 1000)
        $qpdfRuns.Add($qpdfRecord)
        $qpdfRuns | Export-Csv -LiteralPath $qpdfRunsPath -NoTypeInformation
        for ($run = 1; $run -le $script:measuredRuns; $run++) {
            $qpdfRecord = Invoke-QpdfCollectionRun -Collection $collection.Name `
                -InputDirectory $collection.Path -Number $run -Measured $true `
                -TotalPasses $script:measuredRuns `
                -TimeoutMilliseconds ($FuzzTimeoutSeconds * 1000)
            $qpdfRuns.Add($qpdfRecord)
            $qpdfRuns | Export-Csv -LiteralPath $qpdfRunsPath -NoTypeInformation
        }
    }
    if ($script:selectedCollections -contains 'fuzz') {
        $qpdfRecord = Invoke-QpdfCollectionRun -Collection 'public-fuzz' `
            -InputDirectory (Join-Path $corpusRoot 'fuzz') -Number 1 -Measured $true `
            -TotalPasses 1 -TimeoutMilliseconds ($FuzzTimeoutSeconds * 1000)
        $qpdfRuns.Add($qpdfRecord)
        $qpdfRuns | Export-Csv -LiteralPath $qpdfRunsPath -NoTypeInformation
    }
    if ($qpdfRuns.Count -gt 0) {
        $qpdfRuns | Export-Csv -LiteralPath $qpdfRunsPath -NoTypeInformation
        $qpdfSummary = @(New-QpdfSummary -Runs $qpdfRuns)
        $qpdfSummary | Export-Csv -LiteralPath $qpdfSummaryPath -NoTypeInformation
    }
}

$customRuns = [System.Collections.Generic.List[object]]::new()
$customSummary = @()
$customRunsPath = Join-Path $resultRoot "$($script:customAdapter.id)-benchmark-runs.csv"
$customSummaryPath = Join-Path $resultRoot "$($script:customAdapter.id)-benchmark-summary.csv"
if ($script:selectedTools -contains 'custom') {
    Write-Heading "Running the $($script:customAdapter.name) adapter"
    foreach ($collection in $collections) {
        $customRecord = Invoke-CustomAdapterCollectionRun -Collection $collection.Name `
            -InputDirectory $collection.Path -Number 0 -Measured $false
        $customRuns.Add($customRecord)
        $customRuns | Export-Csv -LiteralPath $customRunsPath -NoTypeInformation
        for ($run = 1; $run -le $script:measuredRuns; $run++) {
            $customRecord = Invoke-CustomAdapterCollectionRun -Collection $collection.Name `
                -InputDirectory $collection.Path -Number $run -Measured $true
            $customRuns.Add($customRecord)
            $customRuns | Export-Csv -LiteralPath $customRunsPath -NoTypeInformation
        }
    }
    if ($script:selectedCollections -contains 'fuzz') {
        $customRecord = Invoke-CustomAdapterCollectionRun -Collection 'public-fuzz' `
            -InputDirectory (Join-Path $corpusRoot 'fuzz') -Number 1 -Measured $true
        $customRuns.Add($customRecord)
        $customRuns | Export-Csv -LiteralPath $customRunsPath -NoTypeInformation
    }
    if ($customRuns.Count -gt 0) {
        $customSummary = @(New-CustomAdapterSummary -Runs $customRuns)
        $customSummary | Export-Csv -LiteralPath $customSummaryPath -NoTypeInformation
    }
}

Write-Heading 'Benchmark complete'
if ($summary.Count -gt 0) {
    $summary | Format-Table Collection, Files, MedianSeconds, MedianFilesPerSecond, OK, Skipped, Failed -AutoSize
}
if ($fuzzSummary.Count -gt 0) {
    Write-Host '  Fuzz results' -ForegroundColor Green
    $fuzzSummary | Format-Table -AutoSize
}
if ($qpdfSummary.Count -gt 0) {
    Write-Host '  qpdf adapter results' -ForegroundColor Green
    $qpdfSummary | Format-Table Collection, Files, MedianSeconds, MedianFilesPerSecond, Saved, Warnings, Failed, Timeouts -AutoSize
}
if ($customSummary.Count -gt 0) {
    Write-Host "  $($script:customAdapter.name) adapter results" -ForegroundColor Green
    $customSummary | Format-Table Collection, Files, MedianSeconds, MedianFilesPerSecond,
        Saved, Warnings, Failed, Timeouts -AutoSize
}
if ($summary.Count -gt 0) {
    Write-Host "  Detailed runs : $runsPath" -ForegroundColor White
    Write-Host "  Summary       : $summaryPath" -ForegroundColor White
}
if ($qpdfSummary.Count -gt 0) {
    Write-Host "  qpdf runs     : $qpdfRunsPath" -ForegroundColor White
    Write-Host "  qpdf summary  : $qpdfSummaryPath" -ForegroundColor White
}
if ($customSummary.Count -gt 0) {
    Write-Host "  Adapter runs   : $customRunsPath" -ForegroundColor White
    Write-Host "  Adapter summary: $customSummaryPath" -ForegroundColor White
}
Write-Host "  Result folder : $resultRoot" -ForegroundColor White
}

$interactive = -not ($script:collectionsWereProvided -and $script:toolsWereProvided)
while ($true) {
    Write-Banner
    $choiceResult = Read-BenchmarkChoices
    if ($choiceResult -eq 'Quit') { break }
    if ($choiceResult -eq 'Back') { continue }
    try {
        Invoke-BenchmarkSession
    }
    catch [OperationCanceledException] {
        Write-Progress -Activity 'Benchmark' -Completed
        Write-Host ''
        Write-Host '  Benchmark canceled. Returning to the main menu.' -ForegroundColor Yellow
        if (-not $interactive) { break }
        continue
    }
    if (-not $interactive) { break }
    Write-Host ''
    Write-Host '  Press Enter to return to the main menu, or Esc to quit.' -ForegroundColor DarkGray
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq [ConsoleKey]::Escape) { break }
}
