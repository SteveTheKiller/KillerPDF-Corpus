# Contributing

Contributions that add meaningful PDF coverage are welcome.

## Before submitting files

Open an issue describing:

- The public source URL
- The source license
- The PDF feature or failure mode covered
- The approximate file count and total size
- Whether the files are normal regression inputs or malformed fuzz inputs
- Known overlap with existing corpus sources

Do not submit private customer documents, personal records, confidential files,
malware, or documents whose redistribution rights are unclear.

## Acceptance criteria

An imported file must be useful for at least one of these areas:

- Parsing and cross-reference recovery
- Rendering and image decoding
- Text extraction, fonts, encodings, and writing systems
- Forms, XFA, annotations, outlines, attachments, and optional content
- Encryption, permissions, signatures, and timestamps
- PDF/A, PDF/UA, and ISO 32000 conformance
- Editing, saving, incremental updates, and round-trip preservation
- Accessibility and logical structure
- Performance, memory use, or unusually large document structures
- Security and malformed-input resilience

All accepted files are hashed and checked for duplication. Fuzz inputs remain
separate from the normal regression corpus.

