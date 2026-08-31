# The KillerPDF Corpus

The KillerPDF Corpus is an open test collection for PDF software. Any PDF editor, viewer, library, or command-line tool can use the same files to find bugs, measure progress, and compare repeatable results. KillerPDF is one implementation tested against it.

PDFs are far more varied than they look. They can contain damaged data, unusual fonts, forms, signatures, annotations, layers, color profiles, enormous pages, old features, and combinations that ordinary sample files never cover.

## How this makes PDF software easier to test

The files can be opened manually in any PDF application. The guided runner can also automate tools for which the project has a supported adapter. A file that does not open becomes a clear bug to fix. A slow file shows where performance needs work. A file that changes after being saved can reveal damaged output before it reaches a user.

Repeating the same collections against a new version or a different tool shows which problems were fixed, which files became faster, and whether a change broke something that worked before. As the collection grows, PDF software gets more difficult real-world goals to hit and reliability can be measured instead of assumed.

## What is in it now

The collection is still growing but it currently has:

- 17,248 PDFs that can legally be included and shared
- 16,696 general reliability tests and 552 PDF standards tests
- 29,599 additional stressful PDFs that people can fetch from the official source but that this project does not republish
- 97 additional Altona and Ghent files for color and printing tests, also fetched from their official publishers instead of republished here
- Tests collected from veraPDF, qpdf, PDFBox, PDF.js, PDFium, iText, and other public PDF projects
- 80 deliberately damaged files kept separate for security and crash testing
- A record of every file's size, source, and SHA-256 fingerprint
- qpdf results showing which files are already damaged before KillerPDF touches them

Files are added only when their source and redistribution terms are clear.<br>
Each file is tracked by its SHA-256 hash so test results can be repeated against the exact same input.

## Developer quick start

The guided benchmark runner requires Windows PowerShell 5.1 or PowerShell 7 and an internet connection for anything it needs to download. Download [`benchmark_corpus.ps1`](scripts/benchmark_corpus.ps1), open PowerShell in the folder containing it, and run:

```powershell
powershell -ExecutionPolicy Bypass -File .\benchmark_corpus.ps1
```

The runner guides you through four decisions:

1. **Tool:** Test KillerPDF, qpdf, both built-in tools, or another command-line PDF tool.
2. **Collections:** Select general regression files, standards files, malformed security files, or every public collection.
3. **Runs:** Choose how many measured passes to perform. Five is the recommended comparison baseline.
4. **Tool setup:** If a built-in tool was not found, locate its executable or allow the runner to download and verify it.

KillerPDF is checked in its standard Windows install locations. qpdf is checked on `PATH`, in the runner's own tool cache, or at the path supplied with `-QpdfExe`. If qpdf is not found automatically, the guided runner offers to locate an existing `qpdf.exe` or download the latest official Windows build.

The runner downloads and verifies the selected corpus collections, performs a warmup followed by the requested measured runs, isolates malformed files behind a timeout, checks that outcome counts remain consistent, and writes detailed and summary CSV files. Downloads use temporary `.partial` files. Press Esc during a download or benchmark to cancel cleanly and return to the main menu. Press Esc again from the main menu to quit.

### Test another PDF tool

PDF applications do not share a standard automation interface. The runner can adapt another tool when that tool can accept an input PDF, write a separate output PDF, and finish without interactive prompts.

Choose **Custom command-line tool**, then choose **Create a new adapter**. The wizard asks for:

1. The full path to the tool's executable.
2. The name to show in benchmark results.
3. The command-line arguments, entered one at a time and in their required order.
4. Exit codes that mean the file was saved successfully or saved with a warning.
5. The maximum number of seconds allowed for each PDF.

Use `{input}` wherever the tool expects the source PDF and `{output}` wherever it expects the saved PDF. For this command:

```text
PdfTool.exe --repair source.pdf --output repaired.pdf
```

enter these arguments in the wizard:

```text
--repair
{input}
--output
{output}
```

The runner starts the executable directly once per PDF. It does not evaluate a shell command. It replaces the placeholders with full temporary paths, applies the timeout, records the exit code, and confirms that the output PDF exists before counting the file as saved. Before the full benchmark begins, it tests the adapter with one corpus file and asks whether to continue.

Created adapters are saved under `%LOCALAPPDATA%\KillerPDF-Corpus\adapters` and appear in the menu on later runs. They can also be used without the menu:

```powershell
.\benchmark_corpus.ps1 -Tools custom -AdapterFile .\my-tool.json -Collections regression -Runs 5
```

See the [custom adapter developer guide](adapters/README.md) for the complete JSON format and a reusable example.

Applications without a reliable command-line or automation interface can still use the corpus for manual testing, but the runner cannot produce a reproducible automated benchmark for them.

### Storage and unattended runs

By default, corpus files are stored under `%LOCALAPPDATA%\KillerPDF-Corpus\corpus` and results are written under `%LOCALAPPDATA%\KillerPDF-Corpus\benchmarks`. Use `-CorpusDirectory` to keep the large corpus on another drive:

```powershell
.\benchmark_corpus.ps1 -CorpusDirectory "D:\PDF-Corpus"
```

Developers can bypass the menus by supplying the tool, collections, and run count:

```powershell
.\benchmark_corpus.ps1 -Tools qpdf -QpdfExe "C:\Tools\qpdf\bin\qpdf.exe" -Collections regression,standards -Runs 5 -CorpusDirectory "D:\PDF-Corpus"
```

Run `Get-Help .\benchmark_corpus.ps1 -Detailed` for every available option.

## Published benchmark

The [KillerPDF v1.8.1 benchmark](BENCHMARKS.md) records the first full baseline: the exact executable, test machine, five measured runs, outcome counts, public coverage, and the additional restricted collections used on the maintainer workstation.

## Comparing results

To make a comparison useful to other people:

1. Record the PDF tool, its version, and the computer used for the test.
2. Test the original files without changing them first.
3. Run the same test at least five times and report the middle result.
4. Report how many files succeeded, failed, or were skipped.
5. Keep deliberately damaged security test files separate from normal PDF tests.

## What the folders contain

- [`manifests/`](manifests/) lists every test file, its size, its source, and its SHA-256 hash.
- [`baselines/`](baselines/) records what the files look like before KillerPDF processes them.
- [`BENCHMARKS.md`](BENCHMARKS.md) publishes KillerPDF's reproducible performance and reliability baseline.
- [`scripts/`](scripts/) contains tools used to check and organize the collection.
- [`adapters/`](adapters/) explains how to test another command-line PDF tool.
- [`SOURCES.md`](SOURCES.md) explains where each group of files came from.
- [`CONTRIBUTING.md`](CONTRIBUTING.md) explains how to suggest more test files.
- [`RELEASING.md`](RELEASING.md) documents the maintainer release procedure.

## Licensing

Each group of PDFs keeps its original license. Files without clear permission to share them are not included here. See [`SOURCES.md`](SOURCES.md) and [`LICENSES/README.md`](LICENSES/README.md) for the details.

The repository's original documentation, manifests, and scripts may be reused under the terms stated in [`LICENSES/README.md`](LICENSES/README.md).
