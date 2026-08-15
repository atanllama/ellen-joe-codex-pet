from __future__ import annotations

import argparse
import hashlib
import re
import tarfile
import zipfile
from pathlib import Path

INCLUDED = (
    "pet/ellen-joe-pixel/pet.json",
    "pet/ellen-joe-pixel/spritesheet.webp",
    "scripts/install.ps1",
    "scripts/uninstall.ps1",
    "scripts/install.sh",
    "scripts/uninstall.sh",
    "README.md",
    "NOTICE.md",
)


def build_release(repo_root: Path, version: str, output_dir: Path) -> tuple[Path, Path, Path]:
    if re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", version) is None:
        raise ValueError("version must match vMAJOR.MINOR.PATCH")
    repo_root = repo_root.resolve()
    missing = [relative for relative in INCLUDED if not (repo_root / relative).is_file()]
    if missing:
        raise FileNotFoundError("missing release input: " + ", ".join(missing))
    output_dir.mkdir(parents=True, exist_ok=True)
    root_name = f"ellen-joe-pixel-{version}"
    zip_path = output_dir / f"{root_name}.zip"
    tar_path = output_dir / f"{root_name}.tar.gz"
    sums_path = output_dir / "SHA256SUMS.txt"
    with zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for relative in INCLUDED:
            archive.write(repo_root / relative, f"{root_name}/{relative}")
    with tarfile.open(tar_path, "w:gz") as archive:
        for relative in INCLUDED:
            archive.add(repo_root / relative, arcname=f"{root_name}/{relative}", recursive=False)
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
