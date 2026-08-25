from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

CELL_SIZE = (192, 208)
EXPECTED_SIZE = (1536, 2288)
# The v2 atlas reserves the seventh idle slot for the neutral look frame.
USED_COUNTS = (7, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8)
EXPECTED_ID = "ellen-joe-pixel"
EXPECTED_DISPLAY_NAME = "Ellen Joe Pixel"


def _cell_alpha_bbox(
    alpha: Image.Image, row: int, col: int
) -> tuple[int, int, int, int] | None:
    width, height = CELL_SIZE
    return alpha.crop(
        (col * width, row * height, (col + 1) * width, (row + 1) * height)
    ).getbbox()


def validate_package(pet_dir: Path) -> list[str]:
    errors: list[str] = []
    manifest_path = pet_dir / "pet.json"
    if not manifest_path.is_file():
        return ["missing pet.json"]
    try:
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        return [f"invalid pet.json: {exc}"]
    if not isinstance(manifest, dict):
        return ["pet.json must contain a JSON object"]

    expected = {
        "id": EXPECTED_ID,
        "displayName": EXPECTED_DISPLAY_NAME,
        "spriteVersionNumber": 2,
        "spritesheetPath": "spritesheet.webp",
    }
    for key, value in expected.items():
        if manifest.get(key) != value:
            errors.append(
                f"{key} must be {value!r}"
                if isinstance(value, str)
                else f"{key} must be {value}"
            )
    if not isinstance(manifest.get("description"), str) or not manifest[
        "description"
    ].strip():
        errors.append("description must be a non-empty string")

    sheet_path = pet_dir / "spritesheet.webp"
    if not sheet_path.is_file():
        errors.append("missing spritesheet.webp")
        return errors
    try:
        with Image.open(sheet_path) as loaded:
            atlas = loaded.convert("RGBA")
    except (OSError, ValueError) as exc:
        errors.append(f"invalid spritesheet.webp: {exc}")
        return errors
    if atlas.size != EXPECTED_SIZE:
        errors.append(
            f"spritesheet must be 1536x2288, got {atlas.width}x{atlas.height}"
        )
        return errors

    alpha = atlas.getchannel("A")
    for row, used in enumerate(USED_COUNTS):
        for col in range(8):
            populated = _cell_alpha_bbox(alpha, row, col) is not None
            if col < used and not populated:
                errors.append(f"row {row} used cell {col} is empty")
            if col >= used and populated:
                errors.append(f"row {row} unused cell {col} is not transparent")
    return errors
