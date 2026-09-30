#!/usr/bin/env python3
# C512 split mix: production m32 (base, writes golden) vs 4-wave LDS weight-sharing candidates (output f32 compared byte-for-byte).
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
jobs=[]
for n in [1504,2160]:
 tiles=(n+31)//32
 for label in ['base','u4','u2','u1','g2u2','g2u1']:
  lds=label!='base';g=1 if not lds else (2 if label.startswith('g2') else 4)
  jobs.append(dict(id=f'ours-{n}-{label}',module='c512_m32_deep',module_file=f'build-{"g0" if not lds else label}/gfx1201/c512-m32-deep.hsaco',
   symbol='split_mix_blocked_h16w_m32_lds' if lds else 'split_mix_blocked_h16w_m32',grid=[8*((tiles+g-1)//g),1,1],block=[32*g,1,1],arg_bytes=28,
   buffers=[dict(id='in',bytes=n*2048,init='f32',amplitude=.25,check='none'),dict(id='w',bytes=2097152,init='half',amplitude=.25,check='none'),dict(id='out',bytes=n*2048,init='zero',check='f32')],
   args=[dict(offset=0,type='ptr',buffer='in'),dict(offset=8,type='ptr',buffer='w'),dict(offset=16,type='ptr',buffer='out'),dict(offset=24,type='u32',value=n)]))
(a.out/'jobs.json').write_text(json.dumps(jobs,indent=1)+'\n')
