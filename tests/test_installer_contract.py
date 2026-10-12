import json, os, shutil, subprocess, sys
from pathlib import Path
import pytest
ROOT=Path(__file__).resolve().parents[1]
CASES=json.loads((ROOT/'tests/fixtures/manifest-cases.json').read_text())
SHELLS=['pwsh','powershell.exe'] if os.name=='nt' else ['sh']
if os.name=='nt' and Path('C:/Program Files/Git/bin/sh.exe').exists():
    SHELLS.append('C:/Program Files/Git/bin/sh.exe')

def fixture(tmp_path):
    repo=tmp_path/'fixture repo'
    shutil.copytree(ROOT/'scripts',repo/'scripts')
    shutil.copytree(ROOT/'pet',repo/'pet')
    shutil.copyfile(ROOT/'release-assets.json',repo/'release-assets.json')
    return repo

def command(shell,repo,home,force=False):
    if shell == 'sh' or shell.endswith('/sh.exe'):
        return [shell,str(repo/'scripts/install.sh'),'--codex-home',str(home),*(['--force'] if force else [])]
    return [shell,'-NoProfile','-File',str(repo/'scripts/install.ps1'),'-CodexHome',str(home),*(['-Force'] if force else [])]

def run(args):
    return subprocess.run(args,capture_output=True,text=True,encoding='utf-8',errors='replace')

@pytest.mark.parametrize('case',CASES,ids=lambda c:c['name'])
def test_python_helper(case,tmp_path):
    repo=fixture(tmp_path)
    manifest=repo/'pet/ellen-joe-pixel/pet.json'
    manifest.write_text(case['text'],encoding='utf-8')
    result=run([sys.executable,'-B',str(repo/'scripts/manifest_contract.py'),'--manifest',str(manifest),'--asset-lock',str(repo/'release-assets.json')])
    assert result.returncode==(0 if case['valid'] else 1),result.stderr
    if case['valid']:
        assert result.stdout.strip()==json.loads((repo/'release-assets.json').read_text())['spritesheetSha256']

@pytest.mark.parametrize('shell',SHELLS)
@pytest.mark.parametrize('case',CASES,ids=lambda c:c['name'])
def test_installer_manifest(shell,case,tmp_path):
    assert shutil.which(shell),f'required shell unavailable: {shell}'
    repo=fixture(tmp_path)
    (repo/'pet/ellen-joe-pixel/pet.json').write_text(case['text'],encoding='utf-8')
    home=tmp_path/'home'
    sentinel=home/'pets/sentinel/pet.json'
    sentinel.parent.mkdir(parents=True)
    sentinel.write_bytes(b'sentinel')
    result=run(command(shell,repo,home))
    assert result.returncode==(0 if case['valid'] else 3),result.stdout+result.stderr
    assert sentinel.read_bytes()==b'sentinel'
    target=home/'pets/ellen-joe-pixel'
    if case['valid']:
        assert {p.name for p in target.iterdir()}=={'pet.json','spritesheet.webp'}
    else:
        assert not target.exists()
        assert sorted(p.name for p in (home/'pets').iterdir())==['sentinel']

@pytest.mark.parametrize('shell',SHELLS)
@pytest.mark.parametrize('bad',['missing','malformed','hash'])
@pytest.mark.parametrize('force',[False,True])
def test_bad_lock_preserves_target(shell,bad,force,tmp_path):
    repo=fixture(tmp_path)
    home=tmp_path/'home'
    target=home/'pets/ellen-joe-pixel'
    if force:
        target.mkdir(parents=True)
        (target/'pet.json').write_bytes(b'old manifest')
        (target/'spritesheet.webp').write_bytes(b'old sheet')
    lock=repo/'release-assets.json'
    if bad=='missing': lock.unlink()
    elif bad=='malformed': lock.write_text('{')
    else:
        value=json.loads(lock.read_text());value['spritesheetSha256']='0'*64;lock.write_text(json.dumps(value))
    result=run(command(shell,repo,home,force))
    assert result.returncode==3,result.stdout+result.stderr
    if force:
        assert (target/'pet.json').read_bytes()==b'old manifest'
        assert (target/'spritesheet.webp').read_bytes()==b'old sheet'
    else: assert not home.exists()
