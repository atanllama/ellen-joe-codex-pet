from pathlib import Path
from PIL import Image
from scripts import build_contact_sheet

def test_contact_sheet_uses_final_cells(tmp_path):
    pet=Path(__file__).resolve().parents[1]/'pet/ellen-joe-pixel'
    out=build_contact_sheet.build_contact_sheet(pet,tmp_path/'contact.png')
    with Image.open(pet/'spritesheet.webp') as source, Image.open(out) as result:
        for row,count in enumerate((7,8,8,4,5,8,6,6,6)):
            for col in range(count):
                assert result.crop((col*192, row*240+32,(col+1)*192,row*240+240)).tobytes()==source.convert('RGBA').crop((col*192,row*208,(col+1)*192,(row+1)*208)).tobytes()
