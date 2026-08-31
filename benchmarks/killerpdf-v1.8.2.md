# KillerPDF v1.8.2 release record

This file preserves the completed KillerPDF v1.8.2 corpus run from 2026-08-30. It identifies the tested executable, the five measured passes, the aggregate results, and the complete per-file CSV logs.

## Headline results

| Collection | Inputs | Median time | Rate | Saved | Skipped | Save failed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Downloadable regression set | 16,696 | 167.891 s | 99.45 files/s | 15,013 | 1,396 | 287 |
| Standards and color set | 649 | 5.695 s | 113.97 files/s | 367 | 246 | 36 |
| Private stress set | 29,599 | 512.967 s | 57.70 files/s | 23,698 | 4,286 | 1,615 |
| Damaged-file safety test | 80 | Not timed as a batch | Not applicable | 0 | 78 | 2 |

All five measured runs returned identical outcome totals for each normal PDF collection. The malformed-file gate recorded zero application crashes and zero timeouts.

## Saved data

- [`killerpdf-v1.8.2/`](killerpdf-v1.8.2/) contains the original runner output: five measured passes and one warmup for each normal collection, the combined run and summary CSVs, and the per-file fuzz result.
- [`benchmark-runs.csv`](killerpdf-v1.8.2/benchmark-runs.csv) contains every measured run and warmup.
- [`benchmark-summary.csv`](killerpdf-v1.8.2/benchmark-summary.csv) contains the median, minimum, and maximum times with the outcome totals.
- [`public-fuzz/fuzz-results.csv`](killerpdf-v1.8.2/public-fuzz/fuzz-results.csv) contains the outcome for every malformed input.

## Test environment

- KillerPDF: 1.8.2
- Executable SHA-256: `825AEF9D42F5C53E0A785D766A045030268F910D57D885C3A4073884BA854883`
- Operating system: Windows 11 Pro, build 26200
- Processor: AMD Ryzen 5 3600, 6 cores and 12 logical processors
- Memory: 32 GB
- Corpus storage: NVMe SSD
