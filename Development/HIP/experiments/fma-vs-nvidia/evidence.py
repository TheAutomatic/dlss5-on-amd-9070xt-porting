#!/usr/bin/env python3
"""Extract small auditable ISA excerpts after re-extracting the original DLL.
cuobjdump --dump-sass --function cc_tinlayout_fused_swin_1h_32_1_fp8 cubins/dlssnr-00.cubin
Other families: fused_swin_2h_64_1, 4h_128_1, 8h_256_1 in cubins 01/02/03.
"""
from pathlib import Path
import re,sys,json,hashlib
src=Path(sys.argv[1]);out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True)
points={'c32.sass':['0aa0','18b0','1900','1a20','4a80','4ef0','6090','6db0','9b10','9c00'],
'c64.sass':['11f0','3920','3d60','5080','5d50'],
'c128.sass':['10b0','3340','3af0','4950','55c0'],
'c256.sass':['1530','3790','3ec0','54a0','6ea0'],
'daniel-c128.s':['17dccc','17dcd8','17dcf0','180768','180814','1808c4','181a44','182080','1820d8','1820e0','182b98'],
'daniel-c256.s':['1ecee4','1ecf14','1ecf48','1ef97c','1ef9a8','1efb10','1f0bc8','1f1204','1f125c','1f1264','1f1d1c'],
'daniel-c64.s':['10cb94','10cba0','10cbb0','10fbb0','10fc30','10fd0c','10ffe4','110fd8','111510','1115f8','11160c','111664','11166c','111674','112438']}
manifest={}
for name,addresses in points.items():
 p=src/name;lines=p.read_text().splitlines();chunks=[]
 for address in addresses:
  hits=[i for i,line in enumerate(lines) if re.search(r'(?:/\*0*'+address+r'\*/|\b0*'+address+r':)',line,re.I)]
  if not hits:raise RuntimeError((name,address))
  for i in hits:chunks.append(f'--- {name} address {address}, full-source line {i+1} ---\n'+'\n'.join(lines[max(0,i-2):i+7]))
 (out/(name+'.txt')).write_text('\n\n'.join(chunks)+'\n');manifest[name]=hashlib.sha256(p.read_bytes()).hexdigest()
(out/'full-isa-hashes.json').write_text(json.dumps(manifest,indent=2)+'\n')
