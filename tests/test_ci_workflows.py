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
    assert '"-m", "pytest"' in commands # full suite includes independent archive tests
    assert '-ShellPath pwsh' in commands and '-ShellPath powershell.exe' in commands
    assert 'sh tests/install-posix.sh' in commands
    assert job['env']['PYTHONDONTWRITEBYTECODE']=='1'

def test_runner_temp_is_configured_inside_steps_not_job_env():
    for workflow,job_name in [('checks.yml','check'),('release.yml','release')]:
        job=read(workflow)['jobs'][job_name]
        assert not any('runner.' in str(value) for value in job.get('env',{}).values())
        setup=next(step for step in job['steps'] if step.get('name')=='Configure temporary directories')
        assert setup['shell']=='python'
        assert 'RUNNER_TEMP' in setup['run'] and 'GITHUB_ENV' in setup['run']
        assert all(f'"{key}"' in setup['run'] for key in ['TEMP','TMP','TMPDIR'])

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

def test_windows_checks_restore_native_module_path(tmp_path,monkeypatch):
    step=next(s for s in read('checks.yml')['jobs']['check']['steps']
              if s.get('name')=='Restore native Windows PowerShell modules')
    assert step['if']=="runner.os == 'Windows'" and step['shell']=='python'
    output=tmp_path/'github-env'
    monkeypatch.setenv('SystemRoot',str(tmp_path/'Windows'))
    monkeypatch.setenv('GITHUB_ENV',str(output))
    exec(step['run'],{})
    expected=tmp_path/'Windows/System32/WindowsPowerShell/v1.0/Modules'
    assert output.read_text(encoding='utf-8')==f'PSModulePath={expected}\n'

def test_python_checks_do_not_reintroduce_pwsh_module_paths():
    step=next(s for s in read('checks.yml')['jobs']['check']['steps'] if 'pytest' in s.get('run',''))
    assert step.get('shell')=='python'
