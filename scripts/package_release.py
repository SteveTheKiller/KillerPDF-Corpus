#!/usr/bin/env python3
"""Build and verify deterministic release assets for The KillerPDF Corpus."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import shutil
import zipfile
from dataclasses import dataclass
from pathlib import Path


DEFAULT_SHARD_BYTES = 1_500_000_000
MANIFEST_FIELDS = [
    "Path", "SHA256", "Bytes", "Category", "Source", "SourceRevision", "SourcePath"
]


@dataclass(frozen=True)
class CorpusFile:
    path: Path
    archive_path: str
    sha256: str
    size: int
    category: str
    source: str
    source_revision: str
    source_path: str


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest().upper()


def load_provenance(repo: Path) -> dict[str, dict[str, str]]:
    paths = sorted((repo / "sources").glob("*/import-manifest.csv"))
    paths.extend(sorted((repo / "manifests").glob("development-import-*.csv")))
    paths.extend(sorted((repo / "manifests").glob("v*.csv")))
    records: dict[str, dict[str, str]] = {}
    for path in paths:
        with path.open("r", encoding="utf-8-sig", newline="") as stream:
            for row in csv.DictReader(stream):
                sha256 = row.get("SHA256", "").upper()
                status = row.get("Status", "").lower()
                if not sha256 or status.startswith("excluded") or status == "skipped":
                    continue
                candidate = {
                    "Source": row.get("Source", ""),
                    "SourceRevision": row.get("SourceRevision", ""),
                    "SourcePath": row.get("SourcePath", row.get("Path", "")),
                }
                current = records.get(sha256)
                if current is None or (not current["SourceRevision"] and candidate["SourceRevision"]):
                    records[sha256] = candidate
    return records


def collect(repo: Path, category: str, provenance: dict[str, dict[str, str]]) -> list[CorpusFile]:
    corpus = repo / "corpus"
    if category == "regression":
        root = corpus / "regression"
        paths = sorted(root.rglob("*.pdf"))
    elif category == "standards":
        root = corpus / "conformance"
        paths = sorted(path for path in root.rglob("*.pdf") if root / "color" not in path.parents)
    elif category == "fuzz":
        root = corpus / "fuzz"
        paths = sorted(path for path in root.rglob("*") if path.is_file())
    else:
        raise ValueError(f"Unknown category: {category}")

    files: list[CorpusFile] = []
    missing: list[str] = []
    for index, path in enumerate(paths, 1):
        sha256 = digest(path)
        record = provenance.get(sha256)
        if record is None:
            missing.append(str(path.relative_to(repo)).replace("\\", "/"))
            continue
        files.append(CorpusFile(
            path=path,
            archive_path=str(path.relative_to(root)).replace("\\", "/"),
            sha256=sha256,
            size=path.stat().st_size,
            category=category,
            source=record["Source"],
            source_revision=record["SourceRevision"],
            source_path=record["SourcePath"],
        ))
        if index % 1000 == 0:
            print(f"{category}: hashed {index}/{len(paths)}", flush=True)
    if missing:
        preview = "\n".join(missing[:20])
        raise RuntimeError(f"{len(missing)} {category} files have no provenance record:\n{preview}")
    return files


def shard(files: list[CorpusFile], maximum: int) -> list[list[CorpusFile]]:
    result: list[list[CorpusFile]] = []
    current: list[CorpusFile] = []
    current_size = 0
    for item in files:
        if item.size > maximum:
            raise RuntimeError(f"A single file exceeds the shard limit: {item.path}")
        if current and current_size + item.size > maximum:
            result.append(current)
            current = []
            current_size = 0
        current.append(item)
        current_size += item.size
    if current:
        result.append(current)
    return result


def zip_file_info(name: str) -> zipfile.ZipInfo:
    info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    info.create_system = 3
    return info


def write_archive(path: Path, files: list[CorpusFile]) -> None:
    temporary = path.with_suffix(path.suffix + ".tmp")
    with temporary.open("xb") as raw:
        with zipfile.ZipFile(raw, "w", allowZip64=True, compresslevel=6) as archive:
            for item in files:
                with item.path.open("rb") as source, archive.open(
                    zip_file_info(item.archive_path), "w", force_zip64=True
                ) as target:
                    shutil.copyfileobj(source, target, length=1024 * 1024)
        raw.flush()
        os.fsync(raw.fileno())
    temporary.replace(path)


def verify_archive(path: Path, files: list[CorpusFile]) -> None:
    expected = {item.archive_path: item for item in files}
    with zipfile.ZipFile(path, "r") as archive:
        names = archive.namelist()
        if names != list(expected):
            raise RuntimeError(f"Archive entry order or names differ: {path.name}")
        for index, name in enumerate(names, 1):
            value = hashlib.sha256()
            size = 0
            with archive.open(name) as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b""):
                    value.update(block)
                    size += len(block)
            item = expected[name]
            if value.hexdigest().upper() != item.sha256 or size != item.size:
                raise RuntimeError(f"Archive verification failed: {path.name}!/{name}")
            if index % 1000 == 0:
                print(f"{path.name}: verified {index}/{len(names)}", flush=True)


def write_manifest(path: Path, files: list[CorpusFile]) -> None:
    with path.open("x", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=MANIFEST_FIELDS, quoting=csv.QUOTE_ALL)
        writer.writeheader()
        for item in files:
            writer.writerow({
                "Path": item.archive_path,
                "SHA256": item.sha256,
                "Bytes": item.size,
                "Category": item.category,
                "Source": item.source,
                "SourceRevision": item.source_revision,
                "SourcePath": item.source_path,
            })


def checksum_file(path: Path, sha256: str) -> Path:
    result = path.with_suffix(path.suffix + ".sha256")
    result.write_text(f"{sha256.lower()}  {path.name}\n", encoding="ascii", newline="\n")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("version", help="Release tag, such as v1.8.1")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path)
    parser.add_argument("--shard-bytes", type=int, default=DEFAULT_SHARD_BYTES)
    args = parser.parse_args()
    if not args.version.startswith("v") or not args.version[1:]:
        parser.error("version must start with v")

    repo = args.repo.resolve()
    output = (args.output or repo / "downloads" / "releases" / args.version).resolve()
    if output.exists():
        raise RuntimeError(f"Output already exists: {output}")
    output.mkdir(parents=True)

    provenance = load_provenance(repo)
    collections: dict[str, list[CorpusFile]] = {}
    for category in ("regression", "standards", "fuzz"):
        collections[category] = collect(repo, category, provenance)

    index: dict[str, object] = {
        "schemaVersion": 1,
        "version": args.version,
        "collections": {},
    }
    manifest_dir = repo / "manifests"
    for category, files in collections.items():
        manifest = manifest_dir / f"{args.version}-{category}.csv"
        if manifest.exists():
            raise RuntimeError(f"Manifest already exists: {manifest}")
        write_manifest(manifest, files)
        manifest_copy = output / manifest.name
        shutil.copyfile(manifest, manifest_copy)
        manifest_sha = digest(manifest_copy)
        checksum_file(manifest_copy, manifest_sha)

        parts = shard(files, args.shard_bytes)
        assets = []
        for part_number, part in enumerate(parts, 1):
            suffix = f"-part{part_number:02d}" if len(parts) > 1 else ""
            name = f"killerpdf-corpus-{category}-{args.version}{suffix}.zip"
            archive = output / name
            print(f"Writing {name}: {len(part)} files, {sum(item.size for item in part)} bytes", flush=True)
            write_archive(archive, part)
            verify_archive(archive, part)
            sha256 = digest(archive)
            checksum_file(archive, sha256)
            assets.append({
                "name": name,
                "sha256": sha256,
                "bytes": archive.stat().st_size,
                "files": len(part),
                "uncompressedBytes": sum(item.size for item in part),
            })
        index["collections"][category] = {
            "files": len(files),
            "bytes": sum(item.size for item in files),
            "manifest": manifest_copy.name,
            "manifestSha256": manifest_sha,
            "assets": assets,
        }

    index_path = output / f"killerpdf-corpus-{args.version}-assets.json"
    index_path.write_text(json.dumps(index, indent=2) + "\n", encoding="utf-8", newline="\n")
    checksum_file(index_path, digest(index_path))
    print(f"Release assets written to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
