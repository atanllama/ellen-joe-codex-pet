import base64,json,re,subprocess,sys
from pathlib import Path
import pytest
from scripts import build_preview as api
ROOT=Path(__file__).resolve().parents[1];PET=ROOT/'pet/ellen-joe-pixel';PROFILE=ROOT/'qa/playback/v0.1.3/diagnostic-profile.json'

def test_preview_embeds_exact_webp(tmp_path):
    out=api.build_preview(PET,PROFILE,tmp_path/'preview.html');text=out.read_text(encoding='utf-8')
    encoded=re.search(r'data:image/webp;base64,([A-Za-z0-9+/=]+)',text).group(1)
    assert base64.b64decode(encoded)==(PET/'spritesheet.webp').read_bytes()

def test_preview_is_self_contained(tmp_path):
    text=api.build_preview(PET,PROFILE,tmp_path/'p.html').read_text(encoding='utf-8')
    assert '<style>' in text and 'function reducePlayback' in text and 'requestAnimationFrame' in text
    assert not re.search(r'(?:src|href)=["\']https?://|\bimport\s',text)

def test_bad_input_preserves_previous_output(tmp_path):
    out=tmp_path/'old.html';out.write_text('old');bad=tmp_path/'bad.json';bad.write_text('{}')
    r=subprocess.run([sys.executable,'-B',str(ROOT/'scripts/build_preview.py'),'--pet-dir',str(PET),'--profile',str(bad),'--output',str(out)],capture_output=True,text=True)
    assert r.returncode==1 and out.read_text()=='old' and str(out) not in r.stdout and 'Traceback' not in r.stderr

def test_untrusted_profile_text_stays_data(tmp_path):
    p=json.loads(PROFILE.read_text());p['scope']='</script><script>alert(1)</script>'
    path=tmp_path/'profile.json';path.write_text(json.dumps(p))
    text=api.build_preview(PET,path,tmp_path/'p.html').read_text(encoding='utf-8')
    assert p['scope'] not in text
    raw=re.search(r'<script id="preview-data" type="application/json">(.*?)</script>',text,re.S).group(1)
    assert json.loads(raw)['profile']['scope']==p['scope']
