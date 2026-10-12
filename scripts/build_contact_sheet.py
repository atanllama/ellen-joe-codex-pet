from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image,ImageDraw
try:
    from .pet_contract import validate_package
except ImportError:
    from pet_contract import validate_package

STATES=('idle','movingRight','movingLeft','waving','jumping','failed','waiting','running','review')
def build_contact_sheet(pet_dir: Path, output: Path) -> Path:
    errors=validate_package(pet_dir)
    if errors: raise ValueError('; '.join(errors))
    with Image.open(pet_dir/'spritesheet.webp') as source:
        atlas=source.convert('RGBA')
    sheet=Image.new('RGBA',(1536,2160))
    draw=ImageDraw.Draw(sheet)
    for row,state in enumerate(STATES):
        draw.rectangle((0,row*240,1535,row*240+31), fill='#222638')
        draw.text((8,row*240+8),state + (' | col 6: neutral (reserved)' if row==0 else ''),fill='white')
        sheet.paste(atlas.crop((0,row*208,1536,(row+1)*208)),(0,row*240+32))
    output.parent.mkdir(parents=True,exist_ok=True)
    sheet.save(output,format='PNG')
    return output

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--pet-dir',type=Path,required=True);p.add_argument('--output',type=Path,required=True)
    print(build_contact_sheet(**vars(p.parse_args())).resolve())
