from __future__ import annotations

import hashlib
import stat
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

from generate_toolkit_manifest import build_manifest  # noqa: E402


class GenerateToolkitManifestTests(unittest.TestCase):
    def test_build_manifest_describes_exact_release_zip(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = Path(temporary) / "YANSH_3.19.zip"
            files = {
                "YANSH/data/modules/configuration/version.ini": b"3.19\n",
                "YANSH/data/modules/main.lua": b"return true\n",
                "YANSH/data/output/readme.txt": b"Runtime output\n",
            }
            self._write_zip(archive_path, files)

            manifest = build_manifest(archive_path, "3.19", "stable")

            self.assertEqual("olivierbutler.yansh", manifest["packageId"])
            self.assertEqual("3.19", manifest["packageVersion"])
            self.assertEqual("Resources/plugins/YANSH", manifest["targetPath"])
            self.assertEqual("YANSH", manifest["archive"]["rootPath"])
            self.assertEqual(self._sha256(archive_path.read_bytes()), manifest["archive"]["sha256"])
            self.assertEqual(
                sorted(path.removeprefix("YANSH/") for path in files),
                [entry["path"] for entry in manifest["files"]],
            )
            main = next(entry for entry in manifest["files"] if entry["path"] == "data/modules/main.lua")
            self.assertEqual(self._sha256(files["YANSH/data/modules/main.lua"]), main["sha256"])

    def test_version_marker_must_match_release_tag(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = Path(temporary) / "YANSH_3.19.zip"
            self._write_zip(
                archive_path,
                {"YANSH/data/modules/configuration/version.ini": b"3.18\n"},
            )

            with self.assertRaisesRegex(ValueError, "Version marker"):
                build_manifest(archive_path, "3.19", "stable")

    def test_member_outside_package_root_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = Path(temporary) / "YANSH_3.19.zip"
            self._write_zip(
                archive_path,
                {
                    "YANSH/data/modules/configuration/version.ini": b"3.19\n",
                    "other/file.txt": b"unexpected\n",
                },
            )

            with self.assertRaisesRegex(ValueError, "outside"):
                build_manifest(archive_path, "3.19", "stable")

    def test_case_colliding_members_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = Path(temporary) / "YANSH_3.19.zip"
            self._write_zip(
                archive_path,
                {
                    "YANSH/data/modules/configuration/version.ini": b"3.19\n",
                    "YANSH/data/File.txt": b"first\n",
                    "YANSH/data/file.txt": b"second\n",
                },
            )

            with self.assertRaisesRegex(ValueError, "case-colliding"):
                build_manifest(archive_path, "3.19", "stable")

    def test_symbolic_link_member_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            archive_path = Path(temporary) / "YANSH_3.19.zip"
            with zipfile.ZipFile(archive_path, "w") as archive:
                archive.writestr("YANSH/data/modules/configuration/version.ini", b"3.19\n")
                link = zipfile.ZipInfo("YANSH/data/link")
                link.create_system = 3
                link.external_attr = (stat.S_IFLNK | 0o777) << 16
                archive.writestr(link, b"target")

            with self.assertRaisesRegex(ValueError, "Symbolic links"):
                build_manifest(archive_path, "3.19", "stable")

    @staticmethod
    def _write_zip(path: Path, files: dict[str, bytes]) -> None:
        with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for name, content in files.items():
                archive.writestr(name, content)

    @staticmethod
    def _sha256(value: bytes) -> str:
        return hashlib.sha256(value).hexdigest()


if __name__ == "__main__":
    unittest.main()
