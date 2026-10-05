# KillerPDF 1.8.71 corpus benchmark

Test date: 2026-10-04

KillerPDF 1.8.71 was measured alongside 1.8.80 in the same session. Both versions received one warmup and five measured passes per collection, alternating which version ran first. This report records the measured 1.8.71 baseline separately from the [1.8.80 result](killerpdf-v1.8.80.md).

## Results

| Collection | Inputs | Saved | Skipped | Save failures | 1.8.71 median seconds |
| --- | ---: | ---: | ---: | ---: | ---: |
| Public regression | 16,696 | 15,171 | 1,233 | 292 | 234.392 |
| Standards and color | 649 | 377 | 235 | 37 | 5.765 |
| Private stress | 29,599 | 25,015 | 2,957 | 1,627 | 566.869 |
| Damaged-file safety | 80 | 0 | 78 | 2 | Not timed as a batch |

The three normal collections contain 46,944 inputs, with 40,563 saved, 4,425 skipped, and 1,956 save failures per pass. Including the separate safety collection gives 47,024 inputs. Damaged inputs produced zero crashes and zero timeouts.

These are deliberately hostile collections. All normal batch processes returned exit code 1 because their logs contain save failures. The comparison checks every recorded path, status, diagnostic detail, and process exit code.

## Paired comparison

| Collection | 1.8.71 median seconds | 1.8.80 median seconds | 1.8.80 change |
| --- | ---: | ---: | ---: |
| Public regression | 234.392 | 236.493 | 0.90% longer |
| Standards and color | 5.765 | 5.785 | 0.35% longer |
| Private stress | 566.869 | 563.538 | 0.59% shorter |

All paired warmup and measured logs agree on their per-file outcomes and diagnostic details. Both versions produced 78 skips and two failures in the damaged-file gate. The [execution-order CSV](killerpdf-v1.8.80/alternating-runs.csv) preserves the paired run sequence.

## Build and method

- Version: KillerPDF 1.8.71 Release, win-x64, built from the v1.8.71 source.
- Source commit: `25244f0ed8300caefd63b0af68416855bf8ca93e`.
- Executable SHA-256: `32AB58753963B4EBEA01EC26558196C53E5E2416246F59B422A6D82013A41424`.
- Runner: KillerPDF's `validation/Benchmark-Versions.ps1`, using the same existing input collections for both versions.
- One warmup and five measured passes per normal collection and version, with run order alternated.
- All 80 damaged inputs tested individually with a 30-second timeout.
- Per-file logs are retained at `C:\Users\steve\kp-bench-render\release-1.8.80-vs-1.8.71-alternating-20261004`.

The [run data](killerpdf-v1.8.71/benchmark-runs.csv) and [summary](killerpdf-v1.8.71/benchmark-summary.csv) contain this version's measurements. Total inputs and successful saves have separate count and throughput columns.

This measures batch opening and saving and malformed-input process safety. Rendering accuracy and PDF conformance require separate checks.
