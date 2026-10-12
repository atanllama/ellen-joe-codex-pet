from pathlib import Path
import yaml
ROOT=Path(__file__).parents[1]/'.github/workflows'
def read(name):return yaml.load((ROOT/name).read_text(encoding='utf-8-sig'),Loader=yaml.BaseLoader)

def test_reusable_check_matrix():
    w=read('checks.yml');assert 'workflow_call' in w['on']
    job=w['jobs']['check'];assert set(job['strategy']['matrix']['os'])=={'windows-latest','macos-latest','ubuntu-latest'}
    steps=job['steps'];setup=next(s for s in steps if s.get('uses','').startswith('actions/setup-python@'))
    assert setup['with']['python-version']=='3.12'
    assert set(setup['with']['cache-dependency-path'].split())=={'requirements-dev.txt','requirements-validator.txt'}
    commands='\n'.join(s.get('run','') for s in steps)
    assert 'node --test tests/playback.test.mjs' in commands
    assert '--asset-lock release-assets.json' in commands
    assert 'python -B -m pytest' in commands # full suite includes independent archive tests
    assert '-ShellPath pwsh' in commands and '-ShellPath powershell.exe' in commands
    assert 'sh tests/install-posix.sh' in commands
    assert job['env']['TEMP']=='${{ runner.temp }}' and job['env']['TMP']=='${{ runner.temp }}'

def test_release_requires_same_commit_checks():
    w=read('release.yml');assert w['jobs']['checks']['uses']=='./.github/workflows/checks.yml'
    release=w['jobs']['release'];assert release['needs']=='checks'
    assert w['permissions']['contents']=='read' and release['permissions']['contents']=='write'
    commands='\n'.join(s.get('run','') for s in release['steps'])
    assert '--verify-tag' in commands and '--asset-lock release-assets.json' in commands
    assert '--notes-file' in commands
    assert 'workflow_run' not in w['on']

def test_validate_uses_same_checks():
    assert read('validate.yml')['jobs']['checks']['uses']=='./.github/workflows/checks.yml'
