# KillerPDF Corpus

KillerPDF Corpus is an open, reproducible collection of PDF documents for
benchmarking, regression testing, parser validation, rendering, repair,
accessibility, archival, and conformance work.

The project brings independently licensed public PDF suites into one versioned,
deduplicated corpus with stable SHA-256 manifests and preserved provenance. It is
intended for PDF library authors, application developers, security researchers,
and anyone who needs repeatable tests across a broad range of PDF structures.

## Current release

The initial corpus contains:

- 3,592 unique regression PDFs
- veraPDF, Isartor, TWG, PDF/A, PDF/UA, and ISO 32000 conformance material
- 685 additional qpdf regression documents
- 78 malformed qpdf fuzz inputs distributed separately
- Per-file SHA-256 hashes, sizes, sources, and upstream revisions
- A qpdf structural baseline for the imported qpdf regression set

The corpus archives are published as GitHub Release assets. The PDF binaries are
not committed to Git history, so cloning this repository remains fast.

## Download

Python 3.9 or newer is sufficient. No third-party packages are required.

```text
python scripts/download_corpus.py
```

The command downloads the latest regression archive, verifies its published
SHA-256 digest, and extracts it into `corpus/regression/`.

To include the isolated malformed-input collection:

```text
python scripts/download_corpus.py --include-fuzz
```

To download a specific corpus release:

```text
python scripts/download_corpus.py --version v0.1.0
```

## Benchmarking rules

For results that other people can reproduce:

1. Record the corpus release, application version, executable hash, operating
   system, processor, memory, and storage device.
2. Use the unmodified corpus files as input.
3. Write output to a separate directory.
4. Give each implementation one unmeasured warmup run.
5. Alternate implementation order between measured runs.
6. Report the median of at least five runs.
7. Report successful files, skipped files, failures, elapsed time, and throughput.
8. Compare structural health before and after processing instead of requiring
   intentionally malformed inputs to begin clean.
9. Keep fuzz results separate from ordinary regression and performance results.

## Repository contents

- `manifests/` contains the complete per-file inventory for each release.
- `baselines/` records known structural results before processing.
- `scripts/` contains download, verification, and inventory tools.
- `SOURCES.md` records provenance and licensing for every imported collection.
- `CONTRIBUTING.md` explains how to propose new corpus material.

## Licensing

There is no blanket license covering every PDF. Each imported collection retains
its upstream license and attribution requirements. See `SOURCES.md` and
`LICENSES/README.md` before redistributing individual files or derived bundles.

The repository's original documentation, manifests, and scripts may be reused
under the terms stated in `LICENSES/README.md`.

