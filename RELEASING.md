# Releasing KillerPDF Corpus

Corpus PDFs are published as GitHub release assets. They are never committed to the repository.

## Build the assets

Run the deterministic packager from the repository root:

```powershell
python scripts/package_release.py v0.2.0
```

The packager:

1. Hashes every accepted regression, standards, and fuzz file.
2. Requires a matching provenance record for every file.
3. Writes versioned manifests under `manifests/`.
4. Splits large collections below the GitHub per-asset limit.
5. Uses fixed ZIP metadata and ordinal path ordering.
6. Reopens every archive and verifies every file against its source hash and size.
7. Writes an asset index and a SHA-256 file for every publishable file.

The finished assets are written to `downloads/releases/<version>/`, which is excluded from repository history.

## Review before publishing

Confirm that the asset index reports the expected collection totals. Every ZIP must have a matching `.sha256` file. The regression, standards, and fuzz manifests and their checksum files must also be present.

Do not publish the local stressful-corpus overlay or the Altona and Ghent color collection. Their source terms do not grant corpus-wide redistribution permission.

## Publish

1. Commit the repository documentation, scripts, baselines, licenses, and versioned manifests.
2. Create a GitHub release with a matching version tag from that commit.
3. Upload every file from `downloads/releases/<version>/` as a release asset.
4. Publish the release only after every asset finishes uploading.
5. Run the downloader into an empty directory using the published tag.
6. Compare the downloaded file counts and hashes with the release manifests.

Release archives are immutable. Correct a bad release with a new version instead of silently replacing a published asset.
