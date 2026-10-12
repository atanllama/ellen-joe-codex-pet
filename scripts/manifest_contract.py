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
