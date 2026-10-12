from __future__ import annotations

import argparse
import gzip
import hashlib
import io
import re
import tarfile
import zipfile
from pathlib import Path

try:
    from .pet_contract import validate_package
except ImportError:
    from pet_contract import validate_package

INCLUDED = (
    "pet/ellen-joe-pixel/pet.json",
    "pet/ellen-joe-pixel/spritesheet.webp",
    "scripts/install.ps1",
    "scripts/uninstall.ps1",
    "scripts/install.sh",
    "scripts/uninstall.sh",
    "README.md",
    "README.zh-CN.md",
    "LICENSE",
    "NOTICE.md",
    "THIRD_PARTY_NOTICES.md",
)
EXTRA_INPUTS = (
    "scripts/validate_pet.py", "scripts/pet_contract.py", "scripts/manifest_contract.py",
    "scripts/manifest-contract.ps1", "requirements-validator.txt", "release-assets.json",
    "qa/contact-sheet-standard.png",
)

def release_inputs(version: str) -> tuple[str, ...]:
    return INCLUDED + EXTRA_INPUTS + (f"docs/releases/{version}.md",)


def _release_bytes(relative: str, path: Path) -> bytes:
    data = path.read_bytes()
    if path.suffix not in {".webp", ".png"}:
        return data.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    return data


def build_release(repo_root: Path, version: str, output_dir: Path) -> tuple[Path, Path, Path]:
    if re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", version) is None:
        raise ValueError("version must match vMAJOR.MINOR.PATCH")
    repo_root = repo_root.resolve()
    included = release_inputs(version)
    missing = [relative for relative in included if not (repo_root / relative).is_file()]
    if missing:
        raise FileNotFoundError("missing release input: " + ", ".join(missing))
    errors = validate_package(repo_root / "pet/ellen-joe-pixel", asset_lock=repo_root / "release-assets.json")
    if errors:
        raise ValueError("invalid release source: " + "; ".join(errors))
    output_dir.mkdir(parents=True, exist_ok=True)
    root_name = f"ellen-joe-pixel-{version}"
    zip_path = output_dir / f"{root_name}.zip"
    tar_path = output_dir / f"{root_name}.tar.gz"
    sums_path = output_dir / "SHA256SUMS.txt"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative in included:
            data = _release_bytes(relative, repo_root / relative)
            info = zipfile.ZipInfo(f"{root_name}/{relative}", (1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    with tar_path.open("wb") as raw_file:
        with gzip.GzipFile(fileobj=raw_file, mode="wb", mtime=0) as compressed:
            with tarfile.open(fileobj=compressed, mode="w", format=tarfile.USTAR_FORMAT) as archive:
                for relative in included:
                    path = repo_root / relative
                    data = _release_bytes(relative, path)
                    info = tarfile.TarInfo(f"{root_name}/{relative}")
                    info.size = len(data)
                    info.mode = 0o644
                    info.mtime = 0
                    info.uid = 0
                    info.gid = 0
                    info.uname = ""
                    info.gname = ""
                    archive.addfile(info, io.BytesIO(data))
    lines = [
        f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.name}"
        for path in (zip_path, tar_path)
    ]
    sums_path.write_text("\n".join(lines) + "\n", encoding="ascii")
    return zip_path, tar_path, sums_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", type=Path, required=True)
    parser.add_argument("--version", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    for result in build_release(**vars(parser.parse_args())):
        print(result.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
