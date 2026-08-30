#!/usr/bin/env python3
"""Download and verify a versioned release of The KillerPDF Corpus."""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
import urllib.error
import urllib.request
import zipfile
from pathlib import Path


REPOSITORY = "SteveTheKiller/KillerPDF-Corpus"
USER_AGENT = "KillerPDF-Corpus downloader"


def api_json(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request) as response:
        return json.load(response)


def download(url: str, destination: Path) -> None:
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request) as response, destination.open("wb") as out:
        shutil.copyfileobj(response, out)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def release(version: str | None) -> dict:
    if version:
        endpoint = f"https://api.github.com/repos/{REPOSITORY}/releases/tags/{version}"
    else:
        endpoint = f"https://api.github.com/repos/{REPOSITORY}/releases/latest"
    return api_json(endpoint)


def asset_map(data: dict) -> dict[str, str]:
    return {
        asset["name"]: asset["browser_download_url"]
        for asset in data.get("assets", [])
    }


def fetch_asset(assets: dict[str, str], name: str, destination: Path) -> Path:
    try:
        url = assets[name]
    except KeyError as error:
        raise RuntimeError(f"Release asset not found: {name}") from error
    destination.mkdir(parents=True, exist_ok=True)
    path = destination / name
    print(f"Downloading {name}")
    download(url, path)
    return path


def verify(archive: Path, digest_file: Path) -> None:
    expected = digest_file.read_text(encoding="utf-8").split()[0].lower()
    actual = sha256(archive)
    if actual != expected:
        raise RuntimeError(
            f"SHA-256 mismatch for {archive.name}: expected {expected}, got {actual}"
        )
    print(f"Verified {archive.name}: {actual}")


def verify_index_digest(path: Path, expected: str) -> None:
    actual = sha256(path)
    if actual.lower() != expected.lower():
        raise RuntimeError(
            f"SHA-256 mismatch for {path.name}: expected {expected}, got {actual}"
        )


def extract(archive: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        bundle.extractall(destination)
    print(f"Extracted {archive.name} to {destination}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", help="Release tag, such as v1.8.1")
    parser.add_argument("--include-standards", action="store_true")
    parser.add_argument("--include-fuzz", action="store_true")
    parser.add_argument("--destination", type=Path, default=Path("corpus"))
    args = parser.parse_args()

    try:
        data = release(args.version)
        version = data["tag_name"]
        assets = asset_map(data)
        downloads = args.destination / "downloads"

        index_name = f"killerpdf-corpus-{version}-assets.json"
        if index_name in assets:
            index_path = fetch_asset(assets, index_name, downloads)
            index = json.loads(index_path.read_text(encoding="utf-8"))
            if index.get("version") != version:
                raise RuntimeError(
                    f"Release index version is {index.get('version')}, expected {version}"
                )
            selected = ["regression"]
            if args.include_standards:
                selected.append("standards")
            if args.include_fuzz:
                selected.append("fuzz")
            destinations = {
                "regression": args.destination / "regression",
                "standards": args.destination / "conformance",
                "fuzz": args.destination / "fuzz",
            }
            collections = index.get("collections", {})
            for category in selected:
                try:
                    collection = collections[category]
                except KeyError as error:
                    raise RuntimeError(
                        f"Release collection not found: {category}"
                    ) from error
                for asset in collection.get("assets", []):
                    name = asset["name"]
                    archive = fetch_asset(assets, name, downloads)
                    digest_file = fetch_asset(assets, f"{name}.sha256", downloads)
                    verify(archive, digest_file)
                    verify_index_digest(archive, asset["sha256"])
                    extract(archive, destinations[category])
        else:
            names = [f"killerpdf-corpus-regression-{version}.zip"]
            if args.include_fuzz:
                names.append(f"killerpdf-corpus-fuzz-{version}.zip")
            for name in names:
                archive = fetch_asset(assets, name, downloads)
                digest_file = fetch_asset(assets, f"{name}.sha256", downloads)
                verify(archive, digest_file)
                category = "fuzz" if "-fuzz-" in name else "regression"
                extract(archive, args.destination / category)
    except (OSError, RuntimeError, urllib.error.URLError, zipfile.BadZipFile) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
