import os,re,shutil,subprocess,sys,tarfile,zipfile
from pathlib import Path
import pytest
from scripts.build_release import build_release
ROOT=Path(__file__).resolve().parents[1]

@pytest.fixture(params=['zip','tar'])
def extracted(request,tmp_path):
    paths=build_release(ROOT,'v0.1.3',tmp_path/'dist')
    out=tmp_path/'解压 独立目录';out.mkdir()
    if request.param=='zip':
        with zipfile.ZipFile(paths[0]) as z:z.extractall(out)
    else:
        with tarfile.open(paths[1]) as t:t.extractall(out,filter='data')
    return out/'ellen-joe-pixel-v0.1.3'

def test_archive_can_validate_without_checkout(extracted):
    env=dict(os.environ);env.pop('PYTHONPATH',None)
    r=subprocess.run([sys.executable,'-B','scripts/validate_pet.py','pet/ellen-joe-pixel','--asset-lock','release-assets.json'],cwd=extracted,env=env,capture_output=True,text=True)
    assert r.returncode==0,r.stdout+r.stderr
    assert (extracted/'requirements-validator.txt').exists()
    assert not (extracted/'tests').exists()
    assert not (extracted/'requirements-dev.txt').exists()
    assert not (extracted/'scripts/preview').exists()

def test_archive_install_lifecycle(extracted,tmp_path):
    from test_installer_contract import command,run
    shell='pwsh' if os.name=='nt' else 'sh'
    home=tmp_path/'isolated home'
    sentinel=home/'pets/sentinel/pet.json';sentinel.parent.mkdir(parents=True);sentinel.write_bytes(b'sentinel')
    for force,expected in [(False,0),(False,2),(True,0)]:
        r=run(command(shell,extracted,home,force));assert r.returncode==expected,r.stdout+r.stderr
    assert len(list((home/'pet-backups').iterdir()))==1
    args=command(shell,extracted,home);args=[s.replace('install.ps1','uninstall.ps1').replace('install.sh','uninstall.sh') for s in args]
    assert run(args).returncode==0
    assert sentinel.read_bytes()==b'sentinel'
    assert not (home/'pets/ellen-joe-pixel').exists()

def test_readme_user_links_resolve(extracted):
    for name in ['README.md','README.zh-CN.md']:
        for target in re.findall(r'\]\(([^)]+)\)',(extracted/name).read_text(encoding='utf-8')):
            if not target.startswith(('https:','http:','#')):
                assert (extracted/target.split('#')[0]).exists(),target

def test_invalid_source_preserves_existing_archives(tmp_path):
    repo=tmp_path/'repo';shutil.copytree(ROOT/'pet',repo/'pet');shutil.copytree(ROOT/'scripts',repo/'scripts')
    for name in ['release-assets.json','README.md','README.zh-CN.md','LICENSE','NOTICE.md','THIRD_PARTY_NOTICES.md','requirements-validator.txt']:
        shutil.copyfile(ROOT/name,repo/name)
    shutil.copytree(ROOT/'docs/releases',repo/'docs/releases');shutil.copytree(ROOT/'qa',repo/'qa')
    out=tmp_path/'dist';out.mkdir()
    for name in ['ellen-joe-pixel-v0.1.3.zip','ellen-joe-pixel-v0.1.3.tar.gz','SHA256SUMS.txt']:(out/name).write_bytes(b'prior')
    (repo/'pet/ellen-joe-pixel/pet.json').write_text('{}')
    with pytest.raises(ValueError):build_release(repo,'v0.1.3',out)
    assert all(p.read_bytes()==b'prior' for p in out.iterdir())
