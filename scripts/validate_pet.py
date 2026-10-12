from __future__ import annotations

import argparse
from pathlib import Path

from pet_contract import validate_package


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("pet_dir", type=Path)
    parser.add_argument("--asset-lock", type=Path)
    args = parser.parse_args()
    errors = validate_package(args.pet_dir.resolve(), asset_lock=args.asset_lock)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print("OK: valid Ellen Joe Codex Pet v2 package")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
