# Corpus sources

Every corpus release is assembled from pinned upstream revisions. Files are
deduplicated by SHA-256 digest while their original relative paths remain recorded
in the release manifest.

## veraPDF corpus

- Project: https://github.com/veraPDF/veraPDF-corpus
- Revision: `49de56c`
- License: Creative Commons Attribution 4.0 International
- Included material: veraPDF, Isartor, TWG, PDF/A, PDF/UA, ISO 32000-1, and
  ISO 32000-2 conformance documents

The initial import contains 2,907 unique PDFs from this source.

## qpdf

- Project: https://github.com/qpdf/qpdf
- Revision: `c37f83ae468abb6cc741f43b2f6fdeb66e550ffb`
- License: Apache License 2.0
- Included material: qpdf regression fixtures, examples, comparison fixtures, and
  isolated fuzz inputs

The initial import considered 716 PDFs. Thirty-one were already present in the
veraPDF corpus and were skipped. The release therefore adds 685 unique qpdf
regression PDFs. Seventy-eight `.fuzz` inputs are distributed as a separate asset.

## Source acceptance policy

New sources must provide:

- A public, stable origin
- Clear redistribution terms
- A pinned source revision or dated release
- Per-file SHA-256 hashes
- Useful coverage not already represented by existing files
- Separation of ordinary regression inputs from intentionally hostile fuzz inputs

Files with unclear ownership, personal information, confidential content, or
ambiguous redistribution rights are not accepted.

