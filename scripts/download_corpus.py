#!/usr/bin/env python3
"""Download and verify a versioned KillerPDF Corpus release."""

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


def extract(archive: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        bundle.extractall(destination)
    print(f"Extracted {archive.name} to {destination}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", help="Release tag, such as v0.1.0")
    parser.add_argument("--include-fuzz", action="store_true")
    parser.add_argument("--destination", type=Path, default=Path("corpus"))
    args = parser.parse_args()

    try:
        data = release(args.version)
        version = data["tag_name"]
        assets = asset_map(data)
        downloads = args.destination / "downloads"

        names = [f"killerpdf-corpus-regression-{version}.zip"]
        if args.include_fuzz:
            names.append(f"killerpdf-corpus-fuzz-{version}.zip")

        for name in names:
            archive = fetch_asset(assets, name, downloads)
            digest = fetch_asset(assets, f"{name}.sha256", downloads)
            verify(archive, digest)
            category = "fuzz" if "-fuzz-" in name else "regression"
            extract(archive, args.destination / category)
    except (OSError, RuntimeError, urllib.error.URLError, zipfile.BadZipFile) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

