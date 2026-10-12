import json
import subprocess
import sys
from pathlib import Path
import pytest
from scripts import manifest_contract
from scripts.pet_contract import validate_package
from test_pet_contract import write_package

ROOT = Path(__file__).resolve().parents[1]
LOCK = {'schemaVersion':1, 'petId':'ellen-joe-pixel','spritesheetSha256':'a'*64}


def test_structure_valid_but_unapproved_bytes(tmp_path):
    pet = write_package(tmp_path)
    lock = tmp_path/'lock.json'
    lock.write_text(json.dumps(LOCK))
    assert validate_package(pet) == []
    assert any('hash mismatch' in x for x in validate_package(pet,asset_lock=lock))

@pytest.mark.parametrize('raw', ['{',json.dumps(dict(LOCK,petId='other')),json.dumps(dict(LOCK,schemaVersion=1.0)),json.dumps(dict(LOCK,spritesheetSha256='A'*64)),json.dumps(dict(LOCK,spritesheetSha256='a'*63)),json.dumps(LOCK)[:-1]+',"schemaVersion":1}',json.dumps(dict(LOCK,extra=1))])
def test_invalid_lock(raw):
    with pytest.raises(ValueError):
        manifest_contract.parse_asset_lock(raw)


def test_invalid_lock_cli(tmp_path):
    pet = write_package(tmp_path)
    result = subprocess.run([sys.executable,'-B',str(ROOT/'scripts/validate_pet.py'),str(pet),'--asset-lock',str(tmp_path/'missing')],capture_output=True,text=True)
    assert result.returncode == 1
    assert 'Traceback' not in result.stdout + result.stderr
