from __future__ import annotations

try:
    from .manifest_contract import parse_manifest
except ImportError:
    from manifest_contract import parse_manifest
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
        parse_manifest(manifest_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, ValueError) as exc:
        return [str(exc)]

    sheet_path = pet_dir / "spritesheet.webp"
    if not sheet_path.is_file():
        errors.append("missing spritesheet.webp")
        return errors
    try:
        with Image.open(sheet_path) as loaded:
            if loaded.format != "WEBP":
                return ["spritesheet must be WebP"]
            if getattr(loaded, "is_animated", False):
                return ["spritesheet must be static WebP"]
            if "A" not in loaded.getbands():
                return ["spritesheet must have an alpha channel"]
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
