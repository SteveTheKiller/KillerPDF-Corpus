# KillerPDF Test Library

This is the test library behind KillerPDF. It is a large collection of PDFs that helps find bugs, measure progress, and make each version of the app more reliable.

PDFs are far more varied than they look. They can contain damaged data, unusual fonts, forms, signatures, annotations, layers, color profiles, enormous pages, old features, and combinations that ordinary sample files never cover.

## How this makes KillerPDF better

KillerPDF is tested against every file in this collection. A file that does not open becomes a clear bug to fix. A slow file shows where performance needs work. A file that changes after being saved can reveal damaged output before it reaches a user.

The same tests are repeated as KillerPDF changes. That shows which problems were fixed, which files became faster, and whether a new change broke something that worked before. As this collection grows, KillerPDF gets more difficult real-world goals to hit and its reliability can be measured instead of assumed.

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

## Download a release

The repository contains the manifests, baselines, licenses, and download tools. The PDFs are distributed as verified GitHub release assets so cloning the repository stays small.

Download the general regression collection:

```powershell
python scripts/download_corpus.py --version v0.2.0
```

Add the PDF standards collection or the deliberately malformed fuzz collection when needed:

```powershell
python scripts/download_corpus.py --version v0.2.0 --include-standards
python scripts/download_corpus.py --version v0.2.0 --include-fuzz
```

Use both options to download every published collection. The downloader reads the release asset index, downloads every numbered part, verifies its SHA-256 digest, and extracts it under `corpus/`.

## Comparing results

To make a comparison useful to other people:

1. Record the KillerPDF version and the computer used for the test.
2. Test the original files without changing them first.
3. Run the same test at least five times and report the middle result.
4. Report how many files succeeded, failed, or were skipped.
5. Keep deliberately damaged security test files separate from normal PDF tests.

## What the folders contain

- `manifests/` lists every test file, its size, its source, and its SHA-256 hash.
- `baselines/` records what the files look like before KillerPDF processes them.
- `scripts/` contains tools used to check and organize the collection.
- `SOURCES.md` explains where each group of files came from.
- `CONTRIBUTING.md` explains how to suggest more test files.
- `RELEASING.md` documents the maintainer release procedure.

## Licensing

Each group of PDFs keeps its original license. Files without clear permission to share them are not included here. See `SOURCES.md` and `LICENSES/README.md` for the details.

The repository's original documentation, manifests, and scripts may be reused under the terms stated in `LICENSES/README.md`.
