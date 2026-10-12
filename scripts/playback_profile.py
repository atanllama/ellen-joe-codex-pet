"""Versioned diagnostic and source-backed playback data; no machine discovery."""
from __future__ import annotations
import json,math
from datetime import date
from pathlib import Path

STATES=('idle','movingRight','movingLeft','waving','jumping','failed','waiting','running','review')
COUNTS=(6,8,8,4,5,8,6,6,6)
EVENTS=('work','waiting','failed','review','idle')

def _unique(pairs):
    result={}
    for k,v in pairs:
        if k in result:raise ValueError('duplicate profile key')
        result[k]=v
    return result

def _positive(value):return type(value) in (int,float) and math.isfinite(value) and value>0

def _complete(action):
    return bool(action.get('frames')) and all(_positive(f.get('durationMs')) for f in action['frames']) and type(action.get('repeatCount')) is int and action['repeatCount']>0 and action.get('after') in ('hold','idle','loop')

def profile_capabilities(profile: dict[str,object]) -> dict[str,bool]:
    playback=profile['kind']=='codex' and all(_complete(profile['actions'][s]) for s in STATES)
    events=profile['events']
    # All five conditions need a transition for every standard action. Partial
    # tables must not silently inherit a scheduler policy.
    rules={(r['from'],r['event']) for r in events.get('transitions') or []}
    simulation=playback and bool(events.get('priority')) and bool(events.get('lookTrigger')) and all((s,e) in rules for s in STATES for e in EVENTS)
    return {'codexPlayback':playback,'eventSimulation':bool(simulation)}

def load_profile(path: Path) -> dict[str,object]:
    try:
        p=json.loads(path.read_text(encoding='utf-8-sig'),object_pairs_hook=_unique,parse_constant=lambda x: (_ for _ in ()).throw(ValueError('non-JSON constant')))
        _validate(p)
    except (OSError,UnicodeError,KeyError,TypeError,AttributeError,RecursionError) as exc:
        raise ValueError('invalid playback profile structure') from exc
    return p

def _validate(p):
    if type(p['schemaVersion']) is not int or p['schemaVersion']!=1 or p['kind'] not in ('diagnostic','codex'):raise ValueError('profile schema/kind')
    date.fromisoformat(p['capturedAt'])
    codex=p['kind']=='codex'
    if codex and (not isinstance(p['appVersion'],str) or not p['appVersion'].strip()):raise ValueError('Codex appVersion required')
    if not codex and (p['appVersion'] is not None or p['evidence']):raise ValueError('diagnostic cannot claim runtime evidence')
    ids=set()
    for e in p['evidence']:
        if not isinstance(e['id'],str) or not e['id'] or e['id'] in ids:raise ValueError('invalid evidence id')
        if e['level'] not in ('STATIC_VERIFIED','APP_OBSERVED') or not e['source'] or not e['fingerprint']:raise ValueError('invalid evidence')
        ids.add(e['id'])
    def references(refs,required=False):
        if not isinstance(refs,list) or any(x not in ids for x in refs) or (required and not refs):raise ValueError('missing evidence reference')
    actions=p['actions']
    allowed={s:{(row,c) for c in range(COUNTS[row])} for row,s in enumerate(STATES)}
    allowed['neutral']={(0,6)}
    allowed.update({f'look-{i*22.5:05.1f}':{(9+i//8,i%8)} for i in range(16)})
    if not set(STATES)<=set(actions) or not set(actions)<=set(allowed):raise ValueError('missing/unknown action')
    if not codex and set(actions)!=set(allowed):raise ValueError('diagnostic requires 26 choices')
    for name,a in actions.items():
        frames=a['frames'];repeat=a['repeatCount'];after=a['after']
        references(a['evidenceIds'],codex and frames is not None)
        if frames is not None:
            if not isinstance(frames,list) or not frames:raise ValueError('empty frames')
            for f in frames:
                if type(f['row']) is not int or type(f['col']) is not int or (f['row'],f['col']) not in allowed[name]:raise ValueError('frame outside action cells')
                if f['durationMs'] is not None and not _positive(f['durationMs']):raise ValueError('invalid duration')
        if repeat is not None and (type(repeat) is not int or repeat<=0):raise ValueError('invalid repeatCount')
        if after not in (None,'hold','idle','loop'):raise ValueError('invalid after')
        if not codex:
            if not _complete(a) or repeat!=1 or after!='hold' or any(f['durationMs']!=160 for f in frames):raise ValueError('invalid diagnostic parameters')
            if [(f['row'],f['col']) for f in frames] != sorted(allowed[name]):raise ValueError('invalid diagnostic order')
    ev=p['events'];priority=ev['priority'];transitions=ev['transitions'];look=ev['lookTrigger']
    if priority is not None and (not isinstance(priority,list) or len(priority)!=len(set(priority)) or set(priority)!=set(EVENTS)):raise ValueError('invalid priority')
    if look is not None and (not isinstance(look,str) or not look.strip()):raise ValueError('invalid look trigger')
    if not codex and any(v is not None for v in ev.values()):raise ValueError('diagnostic cannot claim event rules')
    seen=set()
    if transitions is not None:
        if not isinstance(transitions,list):raise ValueError('invalid transitions')
        for r in transitions:
            if r['from'] not in STATES or r['to'] not in STATES or r['event'] not in EVENTS or type(r['restart']) is not bool:raise ValueError('invalid transition')
            key=(r['from'],r['event'])
            if key in seen:raise ValueError('duplicate transition')
            seen.add(key);references(r['evidenceIds'],codex)
