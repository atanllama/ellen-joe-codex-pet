import json
from pathlib import Path
import pytest
from scripts import manifest_contract

CASES = json.loads((Path(__file__).parent / 'fixtures/manifest-cases.json').read_text(encoding='utf-8'))

@pytest.mark.parametrize('case', CASES, ids=lambda c: c['name'])
def test_manifest_cases(case):
    if case['valid']:
        assert isinstance(manifest_contract.parse_manifest(case['text']), dict)
    else:
        with pytest.raises(ValueError):
            manifest_contract.parse_manifest(case['text'])
