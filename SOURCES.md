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

## Apache PDFBox

- Project: https://github.com/apache/pdfbox
- Revision: `f0bb91daa907e790fe899bec7e058c22bb6ffaad`
- License: Apache License 2.0
- Included material: committed example and test-resource PDFs

The import considered 167 PDFs. Four duplicate records were skipped, leaving 163
unique PDFBox regression files. Every imported file matches its recorded SHA-256
digest and byte count.

## Mozilla PDF.js

- Project: https://github.com/mozilla/pdf.js
- Revision: `22b0b86441f35f984271057483033283cff30b0e`
- License: Apache License 2.0
- Included material: PDFs committed directly to the examples and test fixture trees

The import considered 979 PDFs. Two duplicate records were skipped, leaving 977
unique PDF.js regression files. Network-fetched fixtures are not included. Every
imported file matches its recorded SHA-256 digest and byte count.

## PDFium test corpus

- Project: https://pdfium.googlesource.com/pdfium_tests
- Revision: `d4ec3e1987a094b1eae612943b57782d3b0038ff`
- License: BSD 3-Clause, with separately documented third-party fixtures
- Included material: PDFium regression, rendering, form, XFA, JBIG2, Skia, and
  TCPDF test PDFs

The import considered 836 PDFs. One hundred ten duplicate records were skipped,
leaving 726 unique PDFium regression files. The third-party portion contains 8
JBIG2, 13 Skia, and 65 TCPDF fixtures. Their upstream licenses are preserved in
`LICENSES`. Every imported file matches its recorded SHA-256 digest and byte
count.

## Synthetic PDF Testset for File Format Validation

- Project: https://doi.org/10.22000/53
- Revision: RADAR published dataset version, archived November 5, 2017
- License: Creative Commons Attribution-ShareAlike 4.0 International
- Creators: Michelle Lindlar, Yvonne Tunnat, and Wilson Carl
- Included material: 88 synthetic malformed PDFs covering headers, trailers,
  cross-reference tables, catalogs, page trees, resources, and content streams

All 88 PDFs were imported as validation fixtures. Every file matches its recorded
SHA-256 digest and byte count. The accompanying qpdf baseline intentionally records
the structural errors and warnings produced by these malformed test cases.

## OpenPreserve Format Corpus

- Project: https://github.com/openpreserve/format-corpus
- Revision: `366f068cec399d0cdfd61fa473de3ab6dc858098`
- License: CC0 1.0 Universal by default; Creative Commons
  Attribution-ShareAlike 4.0 International for the Synthetic PDF Testset files
- Included material: hand-built validation cases, JHOVE error fixtures, malformed
  PDF examples, office exports, ebooks, and format variations

The import considered 293 PDFs. Ten duplicate records were skipped. Fifty GovDocs
files were excluded because their redistribution terms could not be verified to the
same standard as the rest of the corpus. The accepted set therefore contains 233
files: 144 under CC0 and 89 Synthetic PDF Testset files under CC BY-SA 4.0. Every
accepted file matches its recorded SHA-256 digest and byte count. The development
manifest records accepted, duplicate, and excluded files separately.

## iText 7

- Project: https://github.com/itext/itext-java
- Revision: `732d6c756417d6b7fccbc043bffbbfd8bbe5b789`
- License: GNU Affero General Public License version 3 or later, with preserved
  third-party notices for included test resources
- Included material: barcode, forms, kernel, layout, PDF/A, PDF/UA, signing, SVG,
  Brotli, WebP, and general PDF test fixtures

The import considered 6,877 PDFs. One hundred eighty-three duplicate records were
skipped. Ten Adobe or explicitly third-party PDFs were excluded because individual
redistribution permission was not documented. The accepted set therefore contains
6,684 regression files. Every accepted file matches its recorded SHA-256 digest and
byte count. The excluded files are recorded separately in the development exclusion
manifest.

## PDF Association Stressful PDF Corpus

- Project: https://labs.pdfa.org/stressful-corpus/
- Dataset: November 2020 Issue Tracker Corpus, six archived batches
- Redistribution status: external benchmark only
- Included material: public issue-tracker attachments collected from 35 projects
  covering 32 PDF technologies

The local overlay considered 32,573 PDFs. Two thousand nine hundred sixty-eight
duplicates were skipped, six files were blocked by antivirus, and 29,599 unique PDFs
were imported for local testing. The source does not provide a corpus-wide license
for republishing the individual issue attachments. These files are therefore not
part of The KillerPDF Corpus release archives. Users obtain the overlay from the official
source. Its per-file manifest and qpdf baseline make local results reproducible.

## Altona Test Suite

- Project: https://www.eci.org/doku.php?id=en:downloads
- Dataset: Altona Test Suite 1.2 and 2.0 online materials
- Redistribution status: external benchmark only
- Included material: four unique technical, visual, and measurement PDFs

The source is available for workflow testing but does not provide a clear open license
for repackaging the test PDFs, and some color-profile material has separate terms. The
files are therefore excluded from release archives and remain an official-download
color benchmark overlay.

## Ghent PDF Output Suite 5.0

- Project: https://gwg.org/gos5/
- Dataset: Ghent PDF Output Suite 5.0 test pages and individual patches
- Redistribution status: external benchmark only
- Included material: 93 unique PDF/X-4 print-production tests and documentation files

The suite is freely downloadable for testing, but no clear open redistribution license
is supplied for repackaging it. The files are therefore excluded from release archives
and remain an official-download print-production benchmark overlay.

## PDF Differences

- Project: https://github.com/pdf-association/pdf-differences
- Revision: `26caa8795933269f3a38530369c70813486eabee`
- License: Creative Commons Attribution 4.0 International for PDF files
- Included material: 34 targeted interoperability tests covering drawing, color,
  dashing, clipping, fonts, page labels, PDF versions, filters, and vertical text

The import considered 37 PDFs. Three exact duplicates were already present through
the iText fixtures, leaving 34 new files. Every imported file matches its recorded
SHA-256 digest and byte count. The pinned source archive has SHA-256
`512F87567AF922651C9EFA9417D35F8738A506F52D148B230864ABDBEB2EB611`.

## PDF 2.0 examples

- Project: https://github.com/pdf-association/pdf20examples
- Revision: `c20f2c17bfcc4baab7cfe62e70fae64caf14d5fa`
- License: Creative Commons Attribution-ShareAlike 4.0 International
- Included material: seven compact PDF 2.0 examples covering UTF-8 strings,
  annotations, black point compensation, incremental updates, offset starts, and
  page-level output intents

All seven PDFs were new to the corpus. Every imported file matches its recorded
SHA-256 digest and byte count, and all seven pass the qpdf structural check. The
pinned source archive has SHA-256
`129D161F4D08E2F098FF1FF46DAA8B60BB9D3E4D94B7D2447E7ABCB31640D314`.

## Techniques for Accessible PDF

- Project: https://github.com/pdf-association/techniques-for-accessible-pdf
- Revision: `9772af3c93ce6409b945c1c60a4cd7c8e74c8c40`
- License: Creative Commons Attribution 4.0 International
- Included material: 82 paired PDF/UA examples covering tags, text extraction,
  Unicode mapping, artifacts, reading order, annotations, tables, lists, links,
  headings, forms, metadata, and other accessibility structures

All 82 PDFs were new to the corpus. The qpdf baseline records 24 structurally clean
files and 58 deliberately incorrect teaching examples that qpdf rejects. Every file
matches its recorded SHA-256 digest and byte count. The pinned source archive has
SHA-256
`3C9B6E0A15CCC274AC32DEB97401599FE328120FD17A1D5849A4394AF5EBBEB8`.

## PDF Association SafeDocs artifacts

- Project: https://github.com/pdf-association/safedocs
- Revision: `a6fd37308c91a0d2c17ebcace970367181bc0da7`
- License: Creative Commons Attribution 4.0 International for documentation
- Included material: 23 targeted tests covering compacted syntax, PDF dialects,
  URI actions, Type 3 fonts, annotations, empty page content, UTF-16 text, and
  Unicode passwords

The import considered 26 PDFs. Three exact duplicates were already present, leaving
23 new standards files. The qpdf baseline records 14 clean files, 6 files with
warnings, and 3 files with structural errors. Every imported file matches its
recorded SHA-256 digest and byte count. The pinned source archive has SHA-256
`89C0C5FF0FF0A215057E7314AFED6B90E87A9E792D93DBCA88E9AD66B2F680B1`.

## Apache Tika

- Project: https://github.com/apache/tika
- Revision: `1a8b2efd59f5322671c9b922fd23b932b7af46eb`
- License: Apache License 2.0 for the accepted project fixtures
- Included material: 28 parser, metadata, security, annotation, embedded-content,
  image-compression, rotation, language, color, and malformed-input tests

The audit considered 83 PDF paths. Thirty-seven were already in the corpus and 12
were repeated inside Tika. Six journal, GovDocs, corporate, or unexplained design
files were excluded because their individual redistribution rights were not clear
enough. The accepted set contains 28 new files. Its qpdf baseline records 15 clean
files, 3 files with warnings, and 10 files with structural errors.

The original pinned GitHub archive has SHA-256
`FCD2AFAE45880FDB3F70CAC46D7EC55F480BDEAEC971C9C23FB232152DAA4B52`.
It is not redistributed because it contains the excluded material. The curated
archive contains only the 28 accepted PDFs plus the upstream license and notice. It
has SHA-256
`E470ADD2BE6276A567BD692B29D0A0657A39F782942ADE13001A7A87223CDE61`.

## Apache FOP

- Project: https://github.com/apache/xmlgraphics-fop
- Revision: `2a8efc165a8769e6b57ab9dfa2ae152c9046f14d`
- License: Apache License 2.0
- Included material: 26 generated PDF 1.5, font, image, language, link, table,
  region, role, and accessibility fixtures

All 26 PDFs were new to the corpus. The qpdf baseline records 24 structurally clean
files and 2 structural error cases. Every file matches its recorded SHA-256 digest
and byte count.

The original pinned GitHub archive has SHA-256
`2586ACDDCE451BC57337F085AA946864B14150B8615068605C188AC933B9AF44`.
The curated archive contains only the 26 PDFs plus the upstream license and notice.
It has SHA-256
`F7C392CFDF50D05E98FDEA25C17906668CA66B16A7C9E7DC4C54EF5DB92E5A4B`.

## pdfcpu

- Project: https://github.com/pdfcpu/pdfcpu
- Revision: `105c0c28727afe7f85eb3179d03e9810d8774981`
- License: Apache License 2.0
- Included material: 453 generated samples covering annotations, bookmarks, forms,
  fonts, images, signatures, page creation, resizing, stamps, watermarks, booklet
  layouts, and multilingual text

The audit considered all 511 PDFs in the pinned repository. The 56 files under
`pkg/testdata` were excluded because that folder contains fixtures from mixed and
third-party origins. The 455 project-generated files under `pkg/samples` were
eligible. Two exact duplicates were already present, leaving 453 new files.

The qpdf baseline records 410 structurally clean files and 43 structural error
cases. Every imported file matches its recorded SHA-256 digest and byte count.

The original pinned GitHub archive has SHA-256
`AFEF9AAE2C30EA2C807CA6B94804FFBCC0A94160A51CED28FF3B4A7F217B1B13`.
It is not redistributed because it contains the excluded test data. The curated
archive contains only the 453 accepted PDFs plus the upstream license. It has
SHA-256
`FC91CD0BD2C1AADA1F3B0E9F3A7FCE82ABB58CD5495F7591CF1760E83CB85E7B`.

## py-pdf sample files

- Project: https://github.com/py-pdf/sample-files
- Revision: `89039b6078fd0c9f98bf3d6fcb5583fac6b0ecaf`
- License: Creative Commons Attribution-ShareAlike 4.0 International
- Included material: 34 purpose-built samples covering forms, passwords, outlines,
  images, annotations, attachments, metadata, PDF/A, Arabic text, page geometry,
  and several PDF creation tools

The source repository explicitly places every PDF under CC BY-SA 4.0 and asks
contributors to submit files they created themselves. All 34 PDFs were new to the
corpus. The qpdf baseline records 31 structurally clean files, 2 files with
warnings, and 1 structural error case. Every file matches its recorded SHA-256
digest and byte count.

The pinned source archive is preserved without modification. It has SHA-256
`3AB32475236BB56D6E6360D842CD33CDD346D186E40271AB9FFAD96E540F2F1B`.

## OCRmyPDF

- Project: https://github.com/ocrmypdf/OCRmyPDF
- Revision: `05431fb9f4ccd38ace836333ef3ca8b634f45864`
- Licenses: CC BY-SA 1.0 through 4.0, GFDL 1.2 or later, MIT, and public domain
- Included material: 31 OCR and image-heavy tests covering scanned pages, PDF/A,
  forms, masks, JBIG2, CCITT, unusual resolutions, skew, color spaces, metadata,
  missing structures, fonts, links, overlays, and tagged content

The audit considered 42 PDFs. Ten exact duplicates were already in the corpus. One
file without an entry in the source repository's file-level licensing record was
excluded. The accepted set therefore contains 31 new files. The qpdf baseline
records 26 structurally clean files, 1 file with warnings, and 4 structural error
cases. Every imported file matches its recorded SHA-256 digest and byte count.

The original pinned GitHub archive has SHA-256
`54262174DE045087FA307EE7EF4C23281AF6230E7B09004CC42AC1211BF8B164`.
It is not redistributed because it contains the excluded file. The curated archive
contains only the 31 accepted PDFs, the exact REUSE attribution map, and all license
texts required by those files. It has SHA-256
`4A9AFDDBB34C09D0FB8B3C9951416E7937E061772F47C86A5E7D056744B28374`.

## libHaru

- Project: https://github.com/libharu/libharu
- Revision: `3467749fd1c0ab6ca6ed424d053b1ea53c1bf67c`
- License: ZLIB/LIBPNG license
- Included material: 20 generated demonstration PDFs covering encryption,
  permissions, fonts, CJK encodings, images, transparency, annotations, outlines,
  slide shows, graphics states, arcs, lines, and text layout

All 20 demonstration PDFs were new to the corpus. The qpdf baseline records 19
structurally clean files and 1 file with warnings. Every file matches its recorded
SHA-256 digest and byte count.

The pinned source archive is preserved without modification. It has SHA-256
`98E058F9AC66BF4E964A3B1423A4177A57C5F351D7D2702A7658C8667DBC504A`.

## pikepdf

- Project: https://github.com/pikepdf/pikepdf
- Revision: `96ab3e100cd941c46993aca4c3e852833b7f2bc5`
- Licenses: CC BY, CC BY-SA, CC0, CC public-domain dedication, GFDL,
  Apache 2.0, and MPL 2.0
- Included material: 32 regression PDFs covering color profiles, image encodings,
  forms, content-stream errors, page trees, encryption, JBIG2, palettes, PDF/X,
  outlines, and veraPDF cases, plus 1 isolated fuzz input

The audit considered 36 PDFs. Three exact duplicates were already in the corpus.
The accepted set contains 32 new regression files and 1 fuzz file kept in the
separate fuzz collection. The regression qpdf baseline records 25 structurally
clean files, 2 files with warnings, and 5 structural error cases. Every imported
file matches its recorded SHA-256 digest and byte count.

The original pinned GitHub archive has SHA-256
`35C1EE683219637501ECFCEB05F4C91830ABBE409C848C5E8A4DA3E4A9CBCF2C`.
The curated archive contains only the 33 accepted PDFs, the exact REUSE attribution
map, and the complete upstream license directory. It has SHA-256
`5D502BE8B88E8DB25E2078040987060AA7B5A7DC5ACDD0033CD0118E6C3A16A0`.

## img2pdf

- Project: https://github.com/josch/img2pdf
- Revision: `0fafa2c312be50c68a07e2331a89bf4adbd274ed`
- License: GNU Lesser General Public License version 3
- Included material: 9 generated reference PDFs covering animated GIF, CMYK JPEG
  and TIFF, grayscale PNG, JBIG2, monochrome PNG and TIFF, and ordinary JPEG and
  PNG image conversion

All 9 reference outputs were new to the corpus. The qpdf baseline records 8
structurally clean files and 1 file with warnings. Every file matches its recorded
SHA-256 digest and byte count.

The pinned source archive is preserved without modification. It has SHA-256
`BFEE417ED42793A904B75ADF49D6BE66D8C01135A7D07CE24927EE93B0716BF7`.

## OpenPrinting sample files

- Project: https://github.com/OpenPrinting/sample-files
- Revision: `d98da078afcd824f6f59df24f18e494a2cad56fe`
- License: Apache License 2.0
- Included material: 7 vector and color printing tests in 4x6, A3, A4, A6,
  legal, letter, and tabloid page sizes

All 7 PDFs were new to the corpus, and qpdf reports all 7 as structurally clean.
Every file matches its recorded SHA-256 digest and byte count.

The full pinned source archive has SHA-256
`543894C91DE6919082BC37D35BF36DB96FB161EAF2A4D77899C8F190A08D6DA7`.
It is not redistributed because most of its 179 MB contains non-PDF image test
files. The curated archive contains the 7 PDFs, upstream license and notice, and
the upstream README. It has SHA-256
`D9B306198B1BCED8AFF692ABF0AD6C0FBB4DA8D64449C6705EFD8C0375ABB50A`.

## pdf-email-optimizer synthetic fixtures

- Project: https://github.com/petehottelet/pdf-email-optimizer
- Revision: `08ecc5ece0821d8ea39543ab69f747b8de07f07e`
- License: CC0 public-domain dedication
- Included material: 12 synthetic PDFs covering metadata, encryption, forms,
  annotations, design-tool exports, transparency, photographs, repeated images,
  scans, screenshots, and vector text

All 12 PDFs were new to the corpus. qpdf reports 11 as structurally clean. The
remaining file is deliberately encrypted and cannot be checked without its
password. Every file matches its recorded SHA-256 digest and byte count.

The full pinned source archive has SHA-256
`5C011C9FC91B6B605837D20AE41CE4F15FFD4841C6FF9F70F5238E53ADADD534`.
The curated archive contains the 12 fixtures, their generator, the upstream
license, and the upstream README. It has SHA-256
`40622E8121AD9E8ADBF38D407AD184305EF35BC63721409981A7ECBB414B58B3`.

## Asymptote official gallery

- Gallery: https://asymptote.sourceforge.io/gallery/
- Capture date: `2026-08-29`
- Project: https://github.com/vectorgraphics/asymptote
- Pinned project revision: `2f1f70fcf812256368abc96ecfff31972b4a48f3`
- License: GNU Lesser General Public License version 3 or later
- Included material: 33 generated examples covering Gouraud and lattice
  shading, patterns, clipping, layers, images, contours, technical diagrams,
  vector text, 3D views, PDF movies, and embedded animation

All 33 PDFs were new to the corpus. The qpdf baseline records 27 structurally
clean files and 6 files with warnings caused by animation or unusual content.
Every file matches its recorded SHA-256 digest and byte count.

The curated archive contains the 33 captured PDFs, 37 matching source examples,
the upstream README, and both upstream license texts. It has SHA-256
`42F36394791D79E68D2472A4ED5E14E10D631380A7B936C174442EF344ACA7BB`.

## pdf-lib generated examples

- Project: https://github.com/Hopding/pdf-lib
- Revision: `93dd36e85aa659a3bca09867d2d8fac172501fbe`
- Licenses: MIT, plus the Ubuntu Font License for the embedded font example
- Included material: 5 generated examples covering basic creation, forms, SVG
  paths, embedded font measurement, and document metadata

All 5 PDFs were new to the corpus, and qpdf reports all 5 as structurally clean.
Every file matches its recorded SHA-256 digest and byte count. Other PDFs in the
upstream assets folder were excluded because they do not have a file-level
license map.

The full pinned source archive has SHA-256
`B9A324AB45974ED4E7E8C63B84EED7A9BE4CAA7DCFEA71FD0CE0E27E5C298FB6`.
The curated archive contains only the 5 generated outputs, the upstream README
and license, and the Ubuntu font license and copyright notice. It has SHA-256
`796722657EA7E391642A0049C4C108FC73CEC417EC7B48CEDF72F9D102E46313`.

## OpenPDF generated examples

- Project: https://github.com/LibrePDF/OpenPDF
- Revision: `b9c17f76e2e2525aa501fb423257c66d2c8c164c`
- License: Mozilla Public License 2.0 or GNU Lesser General Public License 2.1
  or later
- Included material: 6 generated pdf-toolbox examples covering transparency
  groups, optional-content layers, patterns, reusable templates, and font-layout
  forms

All 6 PDFs were new to the corpus, and qpdf reports all 6 as structurally clean.
Every file matches its recorded SHA-256 digest and byte count. Other upstream
test resources were excluded because they include issue attachments and
third-party fixtures without a file-level license map.

The full pinned source archive has SHA-256
`0588F080463CFADDF94CE1B2AA999085D4DDF6A3BB814327DA689D13D4A6FD19`.
The curated archive contains only the 6 generated outputs, their example source
files, and the complete upstream license texts. It has SHA-256
`709B071D339FA0F59055F9852BF36E1CBB0DCDB95CFF1CC6D8B7C9A2C003076A`.

## HummusJS test materials

- Project: https://github.com/galkahana/HummusJS
- Revision: `097196a3e3924d27fc74d29ebf801206b43e39cd`
- License: Apache License 2.0
- Included material: 14 test PDFs covering incremental updates, added and
  removed items and pages, JPEG and TIFF images, linearization, object streams,
  encryption, document information values, and reusable page content

All 14 PDFs were new to the collection. The qpdf baseline records 11
structurally clean files, 1 file with a linearization warning, and 2 encrypted
files that cannot be checked without their passwords. Every file matches its
recorded SHA-256 digest and byte count.

The full pinned source archive has SHA-256
`615603C590A1A36E81762B605AD8931ADEA44CC34F8A0BC297B188659006862A`.
The curated archive contains the 14 PDFs, matching test source files, the
upstream README, and the complete Apache 2.0 license. It has SHA-256
`E70C6EC5916E29CA7B41E8E0BD5B592A74F9009071C9537EFBE1FD1397EBABFA`.

## PDFKit generated examples

- Project: https://github.com/foliojs/pdfkit
- Revision: `70c9ad5adc5264c82f87805e1448b2028307fd13`
- License: MIT
- Included material: 2 generated examples covering interactive forms and
  text link annotations

Both PDFs were new to the collection, and qpdf reports both as structurally
clean. Every file matches its recorded SHA-256 digest and byte count. Six other
committed PDFs were excluded because they depend on bundled images or
nonstandard font files without a clear file-level license map.

The full pinned source archive has SHA-256
`11CB611FA8D7CD8F7CF7E659BA62543238FDA3627D936DFEBFC45369EE48D2C1`.
The curated archive contains only the 2 generated outputs, their matching
JavaScript source files, the upstream README, and the complete MIT license. It
has SHA-256
`4B4F9C4105F5B39B51AB60CA3C08FE255381287ACA7C19AAC9A7DE4CF6112D66`.

## Apache FOP PDF Images fixtures

- Project: https://github.com/apache/xmlgraphics-fop-pdf-images
- Revision: `7dc1190faad6af16e70d47029bccd57b1140c99c`
- License: Apache License 2.0
- Included material: 55 PDF image test fixtures covering embedded and subset
  fonts, annotations, bookmarks, tagged structure, masks, shading, forms,
  rotation, patterns, images, and reusable page content

The upstream project contains 80 PDF fixtures. Twenty-five exact duplicates of
files already present in the locally fetched PDF Association Stressful overlay
were excluded. The remaining 55 were new to the collection. The qpdf baseline
records 38 structurally clean files, 16 files with warnings, and 1 broken test
input. Every imported file matches its recorded SHA-256 digest and byte count.

The full pinned source archive has SHA-256
`6401879775300FB4265578F21573F0E257B9C95B628037453B9E96654FE1E1D3`.
The curated archive contains the 55 unique PDFs and the upstream LICENSE,
NOTICE, and README. It has SHA-256
`57978DC2A670EDCE714DBEAA9C39FB89CED8434889A410AAAF6112139B8AE18F`.

## BFO PDF/A Test Suite

- Project: https://github.com/bfosupport/pdfa-testsuite
- Revision: `c22d80260c7ec975a511f9bfcc6590b7ceb1cf18`
- License: Creative Commons Attribution 3.0 Unported
- Included material: 33 targeted PDF/A-2 conformance files with expected pass
  or fail results covering metadata, color spaces, fonts, transparency,
  annotations, actions, files, and structural requirements

All 33 PDFs were new to the collection. The qpdf baseline records 32
structurally clean files and 1 file with a warning. The filenames and upstream
description identify whether each file is expected to pass or fail PDF/A
validation. Every file matches its recorded SHA-256 digest and byte count.

The full pinned source archive has SHA-256
`173881DEF613D1EACFF3599B4198525D7ED56A7F39A0AF6C3D1C535DF3675887`.
The curated archive contains the 33 PDFs, upstream README and description, and
the complete CC BY 3.0 license text. It has SHA-256
`C5757798F186D6DCBABA0048FD63FACB8EF93C1FF99C8A41A3795B9270E43E2B`.

## PDF Association PDF COS Syntax fixtures

- Project: https://github.com/pdf-association/pdf-cos-syntax
- Revision: `bdadc6122ae4192b90a1f501acf9315379b4a8d6`
- License: Apache License 2.0
- Included material: 2 project-created parser fixtures covering compacted PDF
  syntax and deliberately invalid COS syntax

Both PDFs were new to the collection, and both produce expected qpdf warnings.
Seven other committed PDFs were excluded because their underlying publication
or transformed-document content did not have a file-level provenance map. Every
imported file matches its recorded SHA-256 digest and byte count.

The full pinned source archive has SHA-256
`82F27D9DF8FFD222DC2A7767789081C958C25C13D9FAA92A942BAC92FB900C17`.
The curated archive contains only the 2 project-created fixtures, the upstream
README, and the complete Apache 2.0 license. It has SHA-256
`6CD1FE858AE012DAD4EBA42405FA33FF8BBBF814A3CC093BED329EB6DC21820B`.

## gendx hand-crafted PDF fixtures

- Project: https://github.com/gendx/pdf-corpus
- Revision: `a811e9b82a8d14058625ac4285625d0c22a56239`
- License: MIT
- Included material: 25 generated parser and graphics fixtures covering
  graphics-state stacks, colors, transformation matrices, escaped names, and
  unusual numeric syntax

All 25 PDFs were new to the collection. The qpdf baseline records 24
structurally clean files and 1 file with a warning for scientific-number
syntax. Every file matches its recorded SHA-256 digest and byte count.

The full pinned source archive has SHA-256
`8FF649D70C1BAEC4088CACFEF8B3CAA33AB25C9A3F087F3C615640B16A79B497`.
The curated archive preserves the complete upstream source, the generated
PDFs, and the Python 3-compatible generator copy used to create them. It has
SHA-256
`F083ABB61626D791CE6103085DEF44C269171B40A178D0880F048CC53FC6F8A9`.

## PDF Tools Kit generated samples

- Project: https://github.com/tinytoolkit-org/pdf-sample-files
- Revision: `4fd733c47ead5446b06372ab910cb78d1c7da55e`
- License: CC0 1.0 Universal
- Included material: 18 generated samples covering known page counts, blank
  pages, exact file sizes, forms, encryption and permissions, attachments,
  scanned pages, and deliberate truncation

All 18 PDFs were new to the collection. Seventeen ordinary samples are in the
regression collection. The deliberately truncated sample is isolated with the
damaged inputs. The qpdf baseline records 16 structurally clean files, 1
encrypted file, and 1 expected warning for the truncated file. Every file
matches its recorded SHA-256 digest and byte count.

The pinned source archive contains the generated outputs, deterministic
generator, verifier, README, and complete CC0 license. It has SHA-256
`A846ECB4AAC4E350A99F2DD53956474CA54EA62CF99BF7340CCA1B933BFE6BAB`.

## xberg regression collection

- Project: https://github.com/xberg-io/test_documents
- Revision: `9f9e3d4d4ba27b11099cf632508162ef3dab10c5`
- Licenses: CC BY 4.0, CC BY 3.0, CC0 1.0, and United States public domain
- Included material: 204 permissively licensed arXiv papers and 98 public-domain GovDocs1 files

The upstream project separates its regression material into vendored and
reference lanes. Only PDFs in the vendored lane with a matching entry in both
`REGRESSION_PROVENANCE.md` and `scripts/regression-objects.json` were
considered. Reference-lane documents and every file without explicit
file-level permission were excluded.

The pinned records identify 310 redistributable PDFs. Eight GovDocs1 files were
already present in this collection with the same SHA-256 digest, so 302 new
files were imported. The qpdf baseline records 234 structurally clean files and
68 files with warnings. Every imported file matches the upstream SHA-256 digest
and byte count.

The pinned source archive has SHA-256
`2865B248EB72F71D44773FBE56460BEA791A079556207A1DE1860656AAE91B5F`.
It preserves the complete upstream license policy, per-file provenance table,
download manifest, and fetcher used to obtain the exact bytes.


## xberg mathematics PDFs

- Project: https://github.com/xberg-io/test_documents
- Revision: `9f9e3d4d4ba27b11099cf632508162ef3dab10c5`
- Licenses: CC BY 4.0, LPPL 1.3c, MIT, and United States public domain
- Included material: 10 math-heavy PDFs covering scanned equations, scientific papers, textbooks, NASA reports, AMS examples, and Typst output

All 11 PDF entries in the pinned mathematics binary manifest have explicit
permissive licenses and matching file-level provenance. One CC BY 4.0 arXiv
paper was already present with the same SHA-256 digest, so 10 new files were
imported. The qpdf baseline records 5 structurally clean files and 5 files with
warnings. Every imported file matches the upstream SHA-256 digest and byte
count.

This group uses the same pinned source archive as the xberg regression
collection. Its SHA-256 is
`2865B248EB72F71D44773FBE56460BEA791A079556207A1DE1860656AAE91B5F`.


## xberg generated mathematics scans

- Project: https://github.com/xberg-io/test_documents
- Revision: `9f9e3d4d4ba27b11099cf632508162ef3dab10c5`
- License: MIT
- Included material: 4 project-generated scanned PDFs containing rasterized equations with no text layer

Only the four scanned files explicitly described as generated for the upstream
corpus and licensed under MIT were selected. Eighteen other files in the
upstream scanned folder were excluded because the pinned records do not provide
equally clear file-level origin and redistribution evidence.

All four files were new to this collection and pass qpdf structural checks.
Every file matches the pinned SHA-256 digest and byte count. This group uses the
same pinned source archive as the other xberg imports, with SHA-256
`2865B248EB72F71D44773FBE56460BEA791A079556207A1DE1860656AAE91B5F`.


## xberg generated diagram PDFs

- Project: https://github.com/xberg-io/test_documents
- Revision: `9f9e3d4d4ba27b11099cf632508162ef3dab10c5`
- License: MIT
- Included material: 10 project-authored diagram fixtures rendered by Graphviz, Mermaid, LibreOffice, cairo, or Skia

The upstream project preserves each diagram's source definition, renderer and
version, expected graph structure, and embedded-font audit. All 10 PDF objects
were new to this collection, pass qpdf structural checks, and match their
pinned SHA-256 digests and byte counts.

This group uses the same pinned source archive as the other xberg imports, with
SHA-256
`2865B248EB72F71D44773FBE56460BEA791A079556207A1DE1860656AAE91B5F`.


## arXiv explicit Creative Commons batch, January 2025

- Metadata source: https://export.arxiv.org/oai2
- Metadata format: arXivRaw
- OAI datestamp window: 2025-01-01 through 2025-01-07
- Licenses: CC BY 4.0 and CC0 1.0
- Included material: 497 versioned research papers across the arXiv subject range

The saved OAI window contains 3,495 records. Exactly 1,414 records explicitly
declare CC BY 4.0 or CC0 in their file-level arXivRaw metadata. The first 500
eligible records after ordinal sorting by versioned identifier formed this
deterministic batch. Permanent versioned PDF URLs succeeded for 497 records.
Three returned HTTP 404 after repeated attempts and are recorded as exclusions.

All 497 imported files are distinct and were new to the collection. The qpdf
baseline records 486 structurally clean PDFs and 11 with warnings. Every
imported file was validated as a PDF and matches its recorded SHA-256 digest and
byte count.

The pinned provenance archive preserves the raw OAI responses, full eligible
list, deterministic batch selection, OAI format declaration, and downloader.
Its SHA-256 is
`091C11064DB4C3C58AA7ED7E3D005F185AA5CC5162D6808A00DE0FE5896C0EE2`.

## arXiv explicit Creative Commons batch 2, January 2025

- Metadata source: https://export.arxiv.org/oai2
- Metadata format: arXivRaw
- OAI datestamp window: 2025-01-01 through 2025-01-07
- Licenses: CC BY 4.0 and CC0 1.0
- Included material: 496 versioned research papers across the arXiv subject range

The second deterministic batch selected eligible records 501 through 1000
after ordinal sorting by versioned identifier. Permanent versioned PDF URLs
succeeded for 496 records. Four returned HTTP 404 after repeated attempts and
are recorded as exclusions.

All 496 imported files are distinct and were new to the collection. The qpdf
baseline records 480 structurally clean PDFs and 16 with warnings. The imported
files include 483 papers under CC BY 4.0 and 13 under CC0 1.0. Every file was
validated as a PDF and matches its recorded SHA-256 digest and byte count.

The pinned provenance archive preserves the raw OAI responses, full eligible
list, deterministic batch 2 selection, OAI format declaration, and downloader.
Its SHA-256 is
`CCDE3533F7611C813E593CF74AEE0972DF6393ABBDEE762422C09665812449D7`.

## arXiv explicit Creative Commons batch 3, January 2025

- Metadata source: https://export.arxiv.org/oai2
- Metadata format: arXivRaw
- OAI datestamp window: 2025-01-01 through 2025-01-07
- Licenses: CC BY 4.0 and CC0 1.0
- Included material: 414 versioned research papers across the arXiv subject range

The final deterministic batch selected eligible records 1001 through 1414
after ordinal sorting by versioned identifier. All 414 permanent versioned PDF
URLs succeeded.

All 414 imported files are distinct and were new to the collection. The qpdf
baseline records 394 structurally clean PDFs and 20 with warnings. The imported
files include 402 papers under CC BY 4.0 and 12 under CC0 1.0. Every file was
validated as a PDF and matches its recorded SHA-256 digest and byte count.

The pinned provenance archive preserves the raw OAI responses, full eligible
list, deterministic batch 3 selection, OAI format declaration, and downloader.
Its SHA-256 is
`0DD835E2724B3702AB58267B5F34C3E908A96687AEAB2DE6D7A01019A20343F1`.

## arXiv explicit Creative Commons batch 1, January 8 through 14

- Metadata source: https://export.arxiv.org/oai2
- Metadata format: arXivRaw
- OAI datestamp window: 2025-01-08 through 2025-01-14
- Licenses: CC BY 4.0 and CC0 1.0
- Included material: 498 versioned research papers across the arXiv subject range

The saved OAI window contains 4,877 records. Exactly 2,010 records explicitly
declare CC BY 4.0 or CC0 in their file-level arXivRaw metadata. The first 500
eligible records after ordinal sorting by versioned identifier formed this
deterministic batch. Permanent versioned PDF URLs succeeded for 498 records.
Two returned HTTP 404 after repeated attempts and are recorded as exclusions.

All 498 imported files are distinct and were new to the collection. The qpdf
baseline records 488 structurally clean PDFs and 10 with warnings. The imported
files include 482 papers under CC BY 4.0 and 16 under CC0 1.0. Every file was
validated as a PDF and matches its recorded SHA-256 digest and byte count.

The pinned provenance archive preserves the four raw OAI responses, full
eligible list, deterministic batch 1 selection, OAI format declaration,
harvester, and downloader. Its SHA-256 is
`D985E9FB27B808D4992BC1ADB016A037E92D466543FA1A71B63E5350C3978AAB`.

## arXiv explicit Creative Commons batch 2, January 8 through 14

- Metadata source: https://export.arxiv.org/oai2
- Metadata format: arXivRaw
- OAI datestamp window: 2025-01-08 through 2025-01-14
- Licenses: CC BY 4.0 and CC0 1.0
- Included material: 495 versioned research papers across the arXiv subject range

The second deterministic batch selected eligible records 501 through 1,000
after ordinal sorting by versioned identifier. Permanent versioned PDF URLs
succeeded for 496 records. Four returned HTTP 404 after repeated attempts and
are recorded as exclusions. One successful file was byte-identical to a PDF
already in the collection and was also excluded.

The 495 imported files are distinct and new to the collection. The qpdf
baseline records 480 structurally clean PDFs and 15 with warnings. The imported
files include 484 papers under CC BY 4.0 and 11 under CC0 1.0. Every file was
validated as a PDF and matches its recorded SHA-256 digest and byte count.

The pinned provenance archive preserves the four raw OAI responses, full
eligible list, deterministic batch 2 selection, OAI format declaration,
harvester, and downloader. Its SHA-256 is
`1E6BE14C29446BC83A02B422FB363A5617CD646DD65CAE9CFEBDD9B5CBE1F635`.

## arXiv explicit Creative Commons batch 3, January 8 through 14

- Metadata source: https://export.arxiv.org/oai2
- Metadata format: arXivRaw
- OAI datestamp window: 2025-01-08 through 2025-01-14
- Licenses: CC BY 4.0 and CC0 1.0
- Included material: 499 versioned research papers across the arXiv subject range

The third deterministic batch selected eligible records 1,001 through 1,500
after ordinal sorting by versioned identifier. Permanent versioned PDF URLs
succeeded for 499 records. One returned HTTP 404 after repeated attempts and
is recorded as an exclusion.

All 499 imported files are distinct and new to the collection. The qpdf
baseline records 480 structurally clean PDFs and 19 with warnings. The imported
files include 479 papers under CC BY 4.0 and 20 under CC0 1.0. Every file was
validated as a PDF and matches its recorded SHA-256 digest and byte count.

The pinned provenance archive preserves the four raw OAI responses, full
eligible list, deterministic batch 3 selection, OAI format declaration,
harvester, and downloader. Its SHA-256 is
`E8F1ECABF10D325A1148F8B28E782658C8949DB513A9EC94513E6D3FDC5D0B28`.

## arXiv explicit Creative Commons final batch, January 8 through 14

- Metadata source: https://export.arxiv.org/oai2
- Metadata format: arXivRaw
- OAI datestamp window: 2025-01-08 through 2025-01-14
- Licenses: CC BY 4.0 and CC0 1.0
- Included material: 510 versioned research papers across the arXiv subject range

The final deterministic batch selected eligible records 1,501 through 2,010
after ordinal sorting by versioned identifier. All 510 permanent versioned PDF
URLs succeeded.

All 510 imported files are distinct and new to the collection. The qpdf
baseline records 480 structurally clean PDFs and 30 with warnings. The imported
files include 497 papers under CC BY 4.0 and 13 under CC0 1.0. Every file was
validated as a PDF and matches its recorded SHA-256 digest and byte count.

The pinned provenance archive preserves the four raw OAI responses, full
eligible list, deterministic final selection, OAI format declaration,
harvester, and downloader. Its SHA-256 is
`B1AF6AD88FB4C7336E5ED40BA3085990C027A6A884BAA44039E3E37014196D11`.


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
