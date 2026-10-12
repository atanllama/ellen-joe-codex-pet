import copy,json
from pathlib import Path
import pytest
from scripts import playback_profile as api
QA=Path(__file__).resolve().parents[1]/'qa/playback/v0.1.3'

def profile(kind='diagnostic'):return json.loads((QA/f'{kind}-profile.json').read_text(encoding='utf-8-sig'))
def load(tmp_path,value):
    p=tmp_path/'profile.json';p.write_text(json.dumps(value),encoding='utf-8');return api.load_profile(p)

def test_diagnostic_maps_26_choices():
    p=api.load_profile(QA/'diagnostic-profile.json');a=p['actions']
    assert len(a)==26
    assert [(f['row'],f['col']) for f in a['idle']['frames']]==[(0,c) for c in range(6)]
    assert [(f['row'],f['col']) for f in a['neutral']['frames']]==[(0,6)]
    for i in range(16):
        f=a[f'look-{i*22.5:05.1f}']['frames'][0];assert (f['row'],f['col'])==(9+i//8,i%8)

def test_diagnostic_timing():
    p=api.load_profile(QA/'diagnostic-profile.json')
    assert all(f['durationMs']==160 for a in p['actions'].values() for f in a['frames'])

def test_incomplete_codex_disables_mode(tmp_path):
    p=profile('codex');p['actions']['waving']['frames']=None
    assert api.profile_capabilities(load(tmp_path,p))=={'codexPlayback':False,'eventSimulation':False}

def test_unknown_events_disable_only_simulation():
    assert api.profile_capabilities(api.load_profile(QA/'codex-profile.json'))=={'codexPlayback':True,'eventSimulation':False}

@pytest.mark.parametrize('field,value',[('row',11),('col',7),('durationMs',0),('durationMs',-1),('durationMs',float('inf')),('durationMs',True)])
def test_invalid_frame(tmp_path,field,value):
    p=profile();p['actions']['idle']['frames'][0][field]=value
    with pytest.raises(ValueError):load(tmp_path,p)

@pytest.mark.parametrize('change',['repeat','missing','evidence','version','diagnostic-evidence'])
def test_invalid_profile(tmp_path,change):
    p=profile('codex')
    if change=='repeat':p['actions']['idle']['repeatCount']=True
    if change=='missing':del p['actions']['idle']
    if change=='evidence':p['actions']['idle']['evidenceIds']=['absent']
    if change=='version':p['appVersion']=None
    if change=='diagnostic-evidence':p['kind']='diagnostic'
    with pytest.raises(ValueError):load(tmp_path,p)

def test_duplicate_actions_rejected(tmp_path):
    raw=json.dumps(profile());raw=raw.replace('"actions": {','"actions": {"idle":null,',1)
    path=tmp_path/'p.json';path.write_text(raw)
    with pytest.raises(ValueError):api.load_profile(path)
