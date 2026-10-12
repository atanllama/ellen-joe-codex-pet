"""Build a portable, offline preview using exact input bytes."""
from __future__ import annotations
import argparse,base64,hashlib,json,os,sys,tempfile
from pathlib import Path
try:
    from .pet_contract import validate_package
    from .playback_profile import load_profile,profile_capabilities
except ImportError:
    from pet_contract import validate_package
    from playback_profile import load_profile,profile_capabilities

ROOT=Path(__file__).resolve().parents[1]
def build_preview(pet_dir: Path, profile_path: Path, output: Path) -> Path:
    errors=validate_package(pet_dir)
    if errors:raise ValueError('; '.join(errors))
    profile=load_profile(profile_path)
    diagnostic=load_profile(ROOT/'qa/playback/v0.1.3/diagnostic-profile.json')
    data=(pet_dir/'spritesheet.webp').read_bytes()
    payload={'profile':profile,'diagnostic':diagnostic,'capabilities':profile_capabilities(profile),'assetSha256':hashlib.sha256(data).hexdigest(),'profileSha256':hashlib.sha256(profile_path.read_bytes()).hexdigest(),'source':str(profile_path.resolve()),'image':'data:image/webp;base64,'+base64.b64encode(data).decode('ascii')}
    encoded=json.dumps(payload,ensure_ascii=True).replace('<','\\u003c').replace('>','\\u003e').replace('&','\\u0026')
    folder=Path(__file__).parent/'preview'
    html=(folder/'template.html').read_text(encoding='utf-8-sig')
    html=html.replace('/*STYLE*/',(folder/'style.css').read_text(encoding='utf-8-sig'))
    html=html.replace('/*ENGINE*/',(folder/'playback.mjs').read_text(encoding='utf-8-sig')).replace('/*UI*/',(folder/'ui.js').read_text(encoding='utf-8-sig')).replace('/*DATA*/',encoded)
    output=output.resolve();output.parent.mkdir(parents=True,exist_ok=True)
    temporary=None
    try:
        with tempfile.NamedTemporaryFile(mode='w',encoding='utf-8',dir=output.parent,suffix='.tmp',delete=False) as f:
            temporary=Path(f.name);f.write(html)
        os.replace(temporary,output)
    finally:
        if temporary is not None and temporary.exists():temporary.unlink()
    return output

def main():
    p=argparse.ArgumentParser();p.add_argument('--pet-dir',type=Path,required=True);p.add_argument('--profile',type=Path,required=True);p.add_argument('--output',type=Path)
    args=p.parse_args()
    try:
        output=args.output
        if output is None:
            base=Path(os.environ.get('RUNNER_TEMP',r'F:\Codex Temp')) if os.name=='nt' else Path(tempfile.gettempdir())
            base.mkdir(parents=True,exist_ok=True)
            output=Path(tempfile.mkdtemp(prefix='ellen-preview-',dir=base))/'preview.html'
        result=build_preview(args.pet_dir,args.profile,output)
    except (ValueError,OSError) as exc:
        print(f'Preview failed: {exc}',file=sys.stderr);return 1
    print(result);return 0

if __name__=='__main__':raise SystemExit(main())
