# KillerPDF 1.8.3 corpus benchmark

Test date: 2026-09-02

The batch open/save comparison passed against the recorded 1.8.2 baseline: no previously successful input became a skip or failure. KillerPDF 1.8.3 saved 1,485 additional files. All five measured passes agreed on every file's status and diagnostic detail. The damaged-file gate had zero crashes and zero timeouts.

## Results

| Collection | Inputs | Saved | Skipped | Save failures | Median seconds |
| --- | ---: | ---: | ---: | ---: | ---: |
| Public regression | 16,696 | 15,171 | 1,233 | 292 | 182.093 |
| Standards and color | 649 | 377 | 235 | 37 | 5.666 |
| Private stress | 29,599 | 25,015 | 2,957 | 1,627 | 523.400 |
| Damaged-file safety | 80 | 0 | 78 | 2 | Not timed as a batch |

The three normal collections contain 46,944 inputs, with 40,563 saved, 4,425 skipped, and 1,956 save failures per pass. Including the separate safety collection gives 47,024 inputs.

These are hostile collections, not a zero-failure workload. All normal batch processes returned exit code 1 because their logs contain save failures. The runner completed normally; this result is based on per-file comparison, not on treating the batch exit code as success.

## Comparison with 1.8.2

| Status transition | Regression | Standards/color | Stress |
| --- | ---: | ---: | ---: |
| Previously OK, still OK | 15,013 | 367 | 23,698 |
| Previously OK, now skipped or failed | 0 | 0 | 0 |
| Previously skipped, now OK | 158 | 10 | 1,316 |
| Previously failed, now OK | 0 | 0 | 1 |
| Previously skipped, now failed during saving | 5 | 1 | 13 |
| Previously failed, still failed | 287 | 36 | 1,614 |
| Previously skipped, still skipped | 1,233 | 235 | 2,957 |

All paths match the baseline without missing, added, or duplicate inputs. Continuing failures have unchanged diagnostic details. The 19 skip-to-failure transitions previously failed opening; they now open but encounter save-time checks for invalid signatures, malformed object references, deep catalog graphs, or repeated form fields. They do not represent loss of a previously successful save.

Most recoveries were previously rejected hybrid cross-reference or incremental-generation structures. The recovered stress failure is `pdf-association/GHOSTSCRIPT/GHOSTSCRIPT-700987-0.pdf`.

Damaged-file statuses, details, and exit codes match 1.8.2 exactly: 78 skips and two reported failures, with no missing logs, crashes, or timeouts.

| Collection | 1.8.2 median seconds | 1.8.3 median seconds | Change |
| --- | ---: | ---: | ---: |
| Public regression | 167.891 | 182.093 | 8.5% longer |
| Standards and color | 5.695 | 5.666 | 0.5% shorter |
| Private stress | 512.967 | 523.400 | 2.0% longer |

KillerPDF 1.8.3 performs more successful saves. These figures compare the same input collections with an earlier recorded baseline, not an alternating same-session rerun of both executables.

## Build and method

- Source commit: `d091fff62238b39782342ea576debceb61119f12`.
- Version: 1.8.3, Release, win-x64, framework-dependent installed-payload build.
- Fresh payload published with `KillerPayloadBuild=true`; no release or installation was performed.
- Executable SHA-256: `4E43B0CAAED62B4F7A1B5E6751A36D46F1FF482F3DF197B1E92A22DA949A58A1`.
- Application DLL SHA-256: `F0C6678FAE7A5A1964A772A6AFDC5F4C215C444124713EFFDA11FA430480BA27`.
- Engine DLL SHA-256: `33379D444C00A7F6AB9244ECA6B1FFE6256D8DA58963FBC72B326178BB175757`.
- Runner: `KillerPDF-Corpus/scripts/benchmark_corpus.ps1`, existing local collections, downloads disabled.
- One warmup and five measured passes per normal collection, run sequentially.
- All 80 damaged inputs tested individually with a 30-second timeout.
- No other builds or test jobs ran during measured passes.
- Full per-file logs remain at `C:\Users\steve\code\KillerPDF-Corpus-Work\baseline-v1.8.3-20260902`.
- Candidate payload remains at `C:\Users\steve\code\KillerPDF-Corpus-Work\candidate-1.8.3-20260902`.

The committed [run data](killerpdf-v1.8.3/benchmark-runs.csv) and [summary](killerpdf-v1.8.3/benchmark-summary.csv) preserve the measurements. The comparison baseline is `KillerPDF-Corpus/benchmarks/killerpdf-v1.8.2`.

This run tests batch opening and saving plus malformed-input process safety. It does not replace interactive rendering checks or a separate qpdf/veraPDF before-and-after conformance sweep.
