# Published KillerPDF benchmarks

This is the central index for completed KillerPDF benchmark reports and their measured run data.

| Version | Test date | Workload | Report |
| --- | --- | --- | --- |
| 1.8.80 | 2026-10-04 | Full corpus, alternating with 1.8.71 | [Report and CSVs](killerpdf-v1.8.80.md) |
| 1.8.71 | 2026-10-04 | Full corpus, alternating with 1.8.80 | [Report and CSVs](killerpdf-v1.8.71.md) |
| 1.8.70 | 2026-09-24 | Full corpus | [Report and CSVs](killerpdf-v1.8.70.md) |
| 1.8.6 | 2026-09-22 | Full corpus | [Report and CSVs](killerpdf-v1.8.6.md) |
| 1.8.4 | 2026-09-07 | Full corpus | [Report and CSVs](killerpdf-v1.8.4.md) |
| 1.8.3 | 2026-09-02 | Full corpus | [Report and CSVs](killerpdf-v1.8.3.md) |
| 1.8.2 | 2026-08-30 | Full corpus | [Report and CSVs](killerpdf-v1.8.2.md) |
| 1.8.1 | See report | Full corpus | [Report and data](killerpdf-v1.8.1.md) |

The full gate contains 46,944 normal inputs and 80 damaged inputs. Separate historical performance comparisons of a 2,236-file subset are preserved under [shared-subset](shared-subset/README.md); they are not full-corpus runs.

1.8.71 and 1.8.80 were measured together with alternating run order. Older report timings came from separate sessions. Compare the recorded method and build before interpreting timing differences.

Reports for 1.8.3, 1.8.4, 1.8.6, and 1.8.70 were previously stored in the application repository. They are collected here with their original measurements and test dates. The old application copies remain as historical snapshots so existing links and Git history still work.

The [baselines directory](../baselines/) contains original-input checks and the earliest reference data. New application benchmark results belong here in `benchmarks/`.
