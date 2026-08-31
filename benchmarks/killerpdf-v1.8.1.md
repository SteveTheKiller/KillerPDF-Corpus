# KillerPDF v1.8.1 benchmark

This is the first published KillerPDF baseline for The KillerPDF Corpus. It records the exact released executable, the test machine, the method, and the outcome counts so later releases can be compared against the same work.

## Headline results

| Collection | Inputs | Median time | Rate | OK | Skipped | Failed |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Public regression | 16,696 | 133.298 s | 125.25 files/s | 15,013 | 1,396 | 287 |
| Standards and private color suites | 649 | 5.911 s | 109.80 files/s | 367 | 246 | 36 |
| Private stress overlay | 29,599 | 575.057 s | 51.47 files/s | 23,698 | 4,286 | 1,615 |
| Malformed fuzz inputs | 80 | Not timed as a batch | Not applicable | 0 | 78 | 2 |

Across all 46,944 PDFs, KillerPDF completed 39,078 saves, skipped 5,928 inputs, and reported 1,938 save failures. The separate malformed-input gate contained 80 fuzz inputs. It produced no application crash or timeout: 78 inputs were safely rejected or skipped, and 2 reached the save path and failed.

The median times for the three PDF collections total 714.266 seconds. This combined figure is useful as a workstation reference, but it is not a single timed run.

## What the statuses mean

- **OK** means KillerPDF opened and saved the input through the tested batch path.
- **Skipped** means the input was intentionally refused or could not enter that path, such as an encrypted, unsupported, or unreadable file.
- **Failed** means the input entered the operation but the save did not complete. It does not mean the application crashed.

These numbers measure safe batch open and save behavior. They do not measure rendering, text extraction, layout reconstruction, or semantic table recovery.

## Public and private coverage

The public v1.8.1 release contains 16,696 regression PDFs, 552 standards PDFs, and 80 malformed fuzz inputs. Anyone can download these 17,328 inputs and reproduce the public part of the baseline.

The maintainer workstation adds 29,599 PDF Association Stressful PDF files and 97 Altona and Ghent color-suite files. Their manifests, source information, hashes, and external qpdf baselines are recorded in this repository, but the files themselves are not republished. The full local gate therefore covers 47,024 inputs.

The combined conformance row above contains two groups:

| Group | Inputs | OK | Skipped | Failed |
| --- | ---: | ---: | ---: | ---: |
| Public standards | 552 | 278 | 239 | 35 |
| Private Altona and Ghent color suites | 97 | 89 | 7 | 1 |

## Method

1. Use the signed KillerPDF v1.8.1 release payload.
2. Warm each PDF collection once.
3. Run each PDF collection five measured times without writing results into the input tree.
4. Confirm that every measured pass produces identical outcome counts.
5. Report the median elapsed time, plus the minimum and maximum measured times.
6. Run malformed fuzz inputs separately with crash and timeout detection.

All five measured passes produced identical outcome counts. Detailed measured run times are in [`baselines/killerpdf-v1.8.1-runs.csv`](../baselines/killerpdf-v1.8.1-runs.csv), and the comparison-ready collection summary is in [`baselines/killerpdf-v1.8.1-summary.csv`](../baselines/killerpdf-v1.8.1-summary.csv).

## Test environment

- KillerPDF: 1.8.1
- Executable SHA-256: `44210D412DA013C403CDADA8A6D8F7CE817560D3E54D113C6BBD301EE2E344FF`
- Operating system: Windows 11 Pro, build 26200
- Processor: AMD Ryzen 5 3600, 6 cores and 12 logical processors
- Memory: 32 GB
- Corpus storage: NVMe SSD

The machine was kept otherwise idle during measured runs. Process peak-memory data was not captured reliably, so no memory figure is published for this baseline.

## Fuzz failures

The two fuzz failures were deterministic save errors, not crashes:

- `qpdf/fuzz/qpdf_extra/23642-mod.fuzz`: a cross-reference entry pointed to a different object at byte offset 0.
- `qpdf/fuzz/qpdf_extra/23642.fuzz`: a FlateDecode stream contained invalid zlib data.
