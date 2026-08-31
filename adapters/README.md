# Custom PDF tool adapters

The benchmark runner has built-in support for KillerPDF and qpdf. A custom adapter lets it test another command-line PDF application without changing the runner.

Choose **Custom command-line tool** in the guided menu. You can select a saved adapter or create one by answering a few questions. New adapters are stored under `%LOCALAPPDATA%\KillerPDF-Corpus\adapters` and appear in the menu the next time the runner starts.

The setup asks for:

1. The full path to the tool's executable.
2. A name for the tool.
3. Its command-line arguments, entered one at a time.
4. Exit codes that mean saved or saved with a warning.
5. A timeout for each PDF.

The argument list must contain `{input}` and `{output}`. The runner replaces those placeholders with the source PDF and temporary output PDF. It starts the executable directly and never evaluates the arguments as a PowerShell or command prompt command.

For a tool invoked like this:

```text
PdfTool.exe --repair source.pdf --output repaired.pdf
```

enter these four arguments:

```text
--repair
{input}
--output
{output}
```

The runner validates the adapter with one PDF before starting the full benchmark. It then records saved files, warnings, failures, timeouts, timing, the executable version, and its SHA-256 hash.

## Adapter file format

[`example.json`](example.json) contains every supported field:

- `name`: Name shown in the runner and result files.
- `executable`: Absolute path to the executable, or a path relative to the adapter file.
- `versionArguments`: Reserved for tools that report their version through command-line arguments.
- `runArguments`: Ordered arguments containing both `{input}` and `{output}`.
- `savedExitCodes`: Exit codes that mean the output was saved successfully.
- `warningExitCodes`: Exit codes that mean an output was saved with a warning.
- `outputRequired`: Whether the output file must exist before a save is counted.
- `timeoutSeconds`: Per-file limit from 1 through 300 seconds.

Run a saved adapter without the guided menu:

```powershell
.\scripts\benchmark_corpus.ps1 -Tools custom -AdapterFile .\my-tool.json -Collections regression -Runs 5
```

## GUI-only PDF applications

An application without a documented command-line or automation interface cannot be benchmarked reliably by launching its executable. Use the corpus files manually for those applications and record the results separately. Screen-coordinate automation and simulated clicks are not accepted as reproducible adapters.
