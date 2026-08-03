#!/usr/bin/env python3
"""Generate a deterministic X-Plane 737NG Maintenance Toolkit manifest."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import stat
import zipfile
from pathlib import Path, PurePosixPath
from typing import Any


PACKAGE_ID = "olivierbutler.yansh"
REPOSITORY = "https://github.com/olivierbutler/YANSH"
ARCHIVE_ROOT = "YANSH"
TARGET_PATH = "Resources/plugins/YANSH"
VERSION_MARKER = "data/modules/configuration/version.ini"
SUPPORTED_PRODUCTS = ["zibo-737ng", "levelup-737ng"]
PROTECTED_PATHS = [
    "data/modules/configuration/wprefs.ini",
    "data/output/**",
]
SAFE_TAG = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _safe_member_path(info: zipfile.ZipInfo) -> PurePosixPath:
    if "\\" in info.filename or "\0" in info.filename:
        raise ValueError(f"Unsafe ZIP member path: {info.filename!r}")

    path = PurePosixPath(info.filename)
    if path.is_absolute() or not path.parts or any(part in ("", ".", "..") for part in path.parts):
        raise ValueError(f"Unsafe ZIP member path: {info.filename!r}")
    if path.parts[0] != ARCHIVE_ROOT:
        raise ValueError(f"ZIP member is outside the required {ARCHIVE_ROOT}/ root: {info.filename}")

    unix_type = (info.external_attr >> 16) & 0o170000
    if unix_type == stat.S_IFLNK:
        raise ValueError(f"Symbolic links are not allowed in the release ZIP: {info.filename}")
    if info.flag_bits & 0x1:
        raise ValueError(f"Encrypted ZIP members are not supported: {info.filename}")
    return path


def _hash_member(archive: zipfile.ZipFile, info: zipfile.ZipInfo) -> str:
    digest = hashlib.sha256()
    with archive.open(info, "r") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def build_manifest(archive_path: Path, release_tag: str, channel: str) -> dict[str, Any]:
    archive_path = archive_path.resolve(strict=True)
    release_tag = release_tag.strip()
    if not SAFE_TAG.fullmatch(release_tag):
        raise ValueError(f"Unsafe release tag: {release_tag!r}")
    if channel not in ("stable", "beta"):
        raise ValueError("Channel must be 'stable' or 'beta'.")

    package_version = release_tag[1:] if release_tag.startswith("v") else release_tag
    expected_archive_name = f"YANSH_{package_version}.zip"
    if archive_path.name != expected_archive_name:
        raise ValueError(
            f"Release ZIP must be named {expected_archive_name}, found {archive_path.name}."
        )

    files: list[dict[str, Any]] = []
    seen_paths: set[str] = set()
    seen_casefolded_paths: set[str] = set()
    marker_value: str | None = None
    with zipfile.ZipFile(archive_path, "r") as archive:
        for info in archive.infolist():
            member = _safe_member_path(info)
            if info.is_dir():
                continue

            relative = PurePosixPath(*member.parts[1:]).as_posix()
            if not relative:
                raise ValueError("The release ZIP contains a file without a package-relative path.")
            if relative in seen_paths or relative.casefold() in seen_casefolded_paths:
                raise ValueError(f"Duplicate or case-colliding ZIP member: {relative}")
            seen_paths.add(relative)
            seen_casefolded_paths.add(relative.casefold())

            if relative == VERSION_MARKER:
                with archive.open(info, "r") as marker_stream:
                    marker_value = marker_stream.read(128).decode("utf-8-sig").strip()

            files.append(
                {
                    "path": relative,
                    "size": info.file_size,
                    "sha256": _hash_member(archive, info),
                }
            )

    if not files:
        raise ValueError("The release ZIP contains no package files.")
    if marker_value is None:
        raise ValueError(f"The release ZIP does not contain {VERSION_MARKER}.")
    if marker_value != package_version:
        raise ValueError(
            f"Version marker contains {marker_value!r}, expected {package_version!r} from release tag."
        )

    files.sort(key=lambda item: item["path"])
    return {
        "schemaVersion": 1,
        "packageId": PACKAGE_ID,
        "packageVersion": package_version,
        "releaseTag": release_tag,
        "channel": channel,
        "repository": REPOSITORY,
        "installScope": "xPlaneInstallation",
        "targetPath": TARGET_PATH,
        "supportedProducts": SUPPORTED_PRODUCTS,
        "restartRequired": True,
        "archive": {
            "fileName": archive_path.name,
            "rootPath": ARCHIVE_ROOT,
            "size": archive_path.stat().st_size,
            "sha256": sha256_file(archive_path),
        },
        "protectedPaths": PROTECTED_PATHS,
        "files": files,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", required=True, type=Path)
    parser.add_argument("--release-tag", required=True)
    parser.add_argument("--channel", required=True, choices=("stable", "beta"))
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    manifest = build_manifest(args.archive, args.release_tag, args.channel)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Wrote {args.output} with {len(manifest['files'])} verified file entries.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
