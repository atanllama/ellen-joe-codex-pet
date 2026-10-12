from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from scripts.pet_contract import EXPECTED_SIZE, USED_COUNTS, validate_package


def write_package(root: Path, *, size: tuple[int, int] = EXPECTED_SIZE) -> Path:
    pet_dir = root / "ellen-joe-pixel"
    pet_dir.mkdir()
    (pet_dir / "pet.json").write_text(
        json.dumps(
            {
                "id": "ellen-joe-pixel",
                "displayName": "Ellen Joe Pixel",
                "description": "A sleepy full-body Ellen Joe fan-art Codex Pet.",
                "spriteVersionNumber": 2,
                "spritesheetPath": "spritesheet.webp",
            }
        ),
        encoding="utf-8",
    )
    atlas = Image.new("RGBA", size, (0, 0, 0, 0))
    if size == EXPECTED_SIZE:
        for row, used in enumerate(USED_COUNTS):
            for col in range(used):
                atlas.putpixel((col * 192 + 96, row * 208 + 104), (1, 1, 1, 255))
    atlas.save(pet_dir / "spritesheet.webp", format="WEBP", lossless=True)
    return pet_dir


def test_valid_package_has_no_errors(tmp_path: Path) -> None:
    assert validate_package(write_package(tmp_path)) == []


def test_v2_idle_row_reserves_neutral_look_frame(tmp_path: Path) -> None:
    pet_dir = write_package(tmp_path)
    with Image.open(pet_dir / "spritesheet.webp") as loaded:
        alpha = loaded.convert("RGBA").getchannel("A")
    neutral = alpha.crop((6 * 192, 0, 7 * 192, 208))
    unused = alpha.crop((7 * 192, 0, 8 * 192, 208))
    assert neutral.getbbox() is not None
    assert unused.getbbox() is None


def test_wrong_atlas_size_is_rejected(tmp_path: Path) -> None:
    errors = validate_package(write_package(tmp_path, size=(192, 208)))
    assert "spritesheet must be 1536x2288, got 192x208" in errors


def test_opaque_unused_cell_is_rejected(tmp_path: Path) -> None:
    pet_dir = write_package(tmp_path)
    with Image.open(pet_dir / "spritesheet.webp") as loaded:
        atlas = loaded.convert("RGBA")
    atlas.putpixel((7 * 192 + 96, 104), (255, 0, 0, 255))
    atlas.save(pet_dir / "spritesheet.webp", format="WEBP", lossless=True)
    errors = validate_package(pet_dir)
    assert "row 0 unused cell 7 is not transparent" in errors


def test_wrong_manifest_version_is_rejected(tmp_path: Path) -> None:
    pet_dir = write_package(tmp_path)
    manifest_path = pet_dir / "pet.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    manifest["spriteVersionNumber"] = 1
    manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
    assert "spriteVersionNumber must be 2" in validate_package(pet_dir)


def test_non_object_manifest_is_rejected(tmp_path: Path) -> None:
    pet_dir = write_package(tmp_path)
    (pet_dir / "pet.json").write_text("[]", encoding="utf-8")
    assert "pet.json must contain a JSON object" in validate_package(pet_dir)


def test_disguised_png_rejected(tmp_path):
    pet = write_package(tmp_path)
    path = pet / 'spritesheet.webp'
    with Image.open(path) as image:
        image.save(path, format='PNG')
    assert any('WebP' in error for error in validate_package(pet))


def test_animated_webp_rejected(tmp_path):
    pet = write_package(tmp_path)
    path = pet / 'spritesheet.webp'
    with Image.open(path) as image:
        first = image.convert('RGBA')
    second = first.copy()
    second.putpixel((96,104), (255,0,0,255))
    first.save(path, format='WEBP', lossless=True, save_all=True, append_images=[second], duration=160)
    assert any('static' in error for error in validate_package(pet))


def test_missing_alpha_rejected(tmp_path):
    pet = write_package(tmp_path)
    path = pet / 'spritesheet.webp'
    Image.new('RGB', EXPECTED_SIZE, 'white').save(path, format='WEBP', lossless=True)
    assert any('alpha' in error for error in validate_package(pet))
