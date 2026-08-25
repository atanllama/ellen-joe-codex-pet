from __future__ import annotations

import hashlib
import os
import re
import tarfile
import time
import zipfile
from pathlib import Path

from scripts.build_release import INCLUDED, build_release


WEBP_BYTES = b"RIFF\x00\r\nWEBP\xff"
TEXT_BYTES = b"first line\nsecond line\n"


def fake_repo(root: Path, *, newline: bytes = b"\n", webp_bytes: bytes = b"webp") -> None:
    for relative in INCLUDED:
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(
            webp_bytes
            if path.suffix == ".webp"
            else b"first line" + newline + b"second line" + newline
        )


def test_release_names_contents_and_checksums(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    fake_repo(repo)
    zip_path, tar_path, sums_path = build_release(repo, "v0.1.0", tmp_path / "dist")
    assert zip_path.name == "ellen-joe-pixel-v0.1.0.zip"
    assert tar_path.name == "ellen-joe-pixel-v0.1.0.tar.gz"
    expected = {f"ellen-joe-pixel-v0.1.0/{item}" for item in INCLUDED}
    with zipfile.ZipFile(zip_path) as archive:
        assert set(archive.namelist()) == expected
    with tarfile.open(tar_path, "r:gz") as archive:
        assert {item.name for item in archive.getmembers() if item.isfile()} == expected
    lines = sums_path.read_text(encoding="ascii").splitlines()
    assert lines == [
        f"{hashlib.sha256(zip_path.read_bytes()).hexdigest()}  {zip_path.name}",
        f"{hashlib.sha256(tar_path.read_bytes()).hexdigest()}  {tar_path.name}",
    ]
    assert all(re.fullmatch(r"[0-9a-f]{64}  .+", line) for line in lines)


def test_release_rejects_invalid_version(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    fake_repo(repo)
    try:
        build_release(repo, "0.1", tmp_path / "dist")
    except ValueError as exc:
        assert str(exc) == "version must match vMAJOR.MINOR.PATCH"
    else:
        raise AssertionError("invalid version was accepted")


def test_release_is_byte_reproducible(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    fake_repo(repo)
    first = build_release(repo, "v0.1.0", tmp_path / "first")
    for index, relative in enumerate(INCLUDED):
        path = repo / relative
        os.utime(path, (1_700_000_000 + index, 1_700_000_000 + index))
    time.sleep(1.1)
    second = build_release(repo, "v0.1.0", tmp_path / "second")
    assert first[0].read_bytes() == second[0].read_bytes()
    assert first[1].read_bytes() == second[1].read_bytes()
    assert first[2].read_text(encoding="ascii") == second[2].read_text(encoding="ascii")


def test_release_normalizes_text_line_endings_but_preserves_webp_bytes(tmp_path: Path) -> None:
    lf_repo = tmp_path / "lf-repo"
    crlf_repo = tmp_path / "crlf-repo"
    lf_repo.mkdir()
    crlf_repo.mkdir()
    fake_repo(lf_repo, newline=b"\n", webp_bytes=WEBP_BYTES)
    fake_repo(crlf_repo, newline=b"\r\n", webp_bytes=WEBP_BYTES)

    lf_release = build_release(lf_repo, "v0.1.0", tmp_path / "lf-dist")
    crlf_release = build_release(crlf_repo, "v0.1.0", tmp_path / "crlf-dist")

    assert hashlib.sha256(lf_release[0].read_bytes()).digest() == hashlib.sha256(
        crlf_release[0].read_bytes()
    ).digest()
    assert hashlib.sha256(lf_release[1].read_bytes()).digest() == hashlib.sha256(
        crlf_release[1].read_bytes()
    ).digest()

    root_name = "ellen-joe-pixel-v0.1.0"
    text_members = [relative for relative in INCLUDED if not relative.endswith(".webp")]
    for release in (lf_release, crlf_release):
        with zipfile.ZipFile(release[0]) as archive:
            for relative in text_members:
                assert archive.read(f"{root_name}/{relative}") == TEXT_BYTES
            assert archive.read(f"{root_name}/pet/ellen-joe-pixel/spritesheet.webp") == WEBP_BYTES
        with tarfile.open(release[1], "r:gz") as archive:
            for relative in text_members:
                member = archive.extractfile(f"{root_name}/{relative}")
                assert member is not None
                assert member.read() == TEXT_BYTES
            member = archive.extractfile(f"{root_name}/pet/ellen-joe-pixel/spritesheet.webp")
            assert member is not None
            assert member.read() == WEBP_BYTES

    assert (lf_repo / "pet/ellen-joe-pixel/spritesheet.webp").read_bytes() == WEBP_BYTES
    assert (crlf_repo / "pet/ellen-joe-pixel/spritesheet.webp").read_bytes() == WEBP_BYTES
