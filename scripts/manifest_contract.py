"""Standard-library-only package metadata contract shared with installers."""
from __future__ import annotations
import json

EXPECTED_ID = 'ellen-joe-pixel'
EXPECTED_DISPLAY_NAME = 'Ellen Joe Pixel'

class _Pairs(list):
    pass

def _constant(value):
    raise ValueError('non-JSON constant')

def parse_object(text: str) -> dict[str, object]:
    try:
        value = json.loads(text.removeprefix('\ufeff'), object_pairs_hook=_Pairs, parse_constant=_constant)
    except (json.JSONDecodeError, RecursionError) as exc:
        raise ValueError('invalid JSON syntax') from exc
    if not isinstance(value, _Pairs):
        raise ValueError('pet.json must contain a JSON object')
    result = {}
    for key, item in value:
        if key in result:
            raise ValueError('duplicate top-level key')
        result[key] = item
    def materialize(item):
        if isinstance(item, _Pairs):
            return {k: materialize(v) for k,v in item}
        if isinstance(item, list):
            return [materialize(v) for v in item]
        return item
    return {key: materialize(item) for key,item in result.items()}

def parse_manifest(text: str) -> dict[str, object]:
    value = parse_object(text)
    for key, expected in {'id': EXPECTED_ID, 'displayName': EXPECTED_DISPLAY_NAME,
                          'spriteVersionNumber': 2, 'spritesheetPath': 'spritesheet.webp'}.items():
        if type(value.get(key)) is not type(expected) or value[key] != expected:
            raise ValueError(f'{key} must be {expected!r}')
    if not isinstance(value.get('description'), str) or not value['description'].strip():
        raise ValueError('description must be a non-empty string')
    return value

def parse_asset_lock(text: str) -> dict[str, object]:
    import re
    value = parse_object(text)
    if set(value) != {'schemaVersion', 'petId', 'spritesheetSha256'}:
        raise ValueError('invalid asset lock fields')
    if type(value['schemaVersion']) is not int or value['schemaVersion'] != 1:
        raise ValueError('schemaVersion must be integer 1')
    if value['petId'] != EXPECTED_ID:
        raise ValueError('asset lock petId mismatch')
    digest = value['spritesheetSha256']
    if not isinstance(digest, str) or re.fullmatch('[0-9a-f]{64}', digest) is None:
        raise ValueError('spritesheetSha256 must be lowercase SHA-256')
    return value

def main() -> int:
    import argparse
    import sys
    from pathlib import Path
    parser = argparse.ArgumentParser()
    parser.add_argument('--manifest', type=Path, required=True)
    parser.add_argument('--asset-lock', type=Path, required=True)
    args = parser.parse_args()
    try:
        parse_manifest(args.manifest.read_text(encoding='utf-8'))
        lock = parse_asset_lock(args.asset_lock.read_text(encoding='utf-8'))
    except (OSError, UnicodeError, ValueError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print(lock['spritesheetSha256'])
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
