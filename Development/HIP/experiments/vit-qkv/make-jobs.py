#!/usr/bin/env python3
# ViT QKV micro jobs: our production kernel vs candidates (output compared byte-for-byte with base golden) + Daniel reference.
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
jobs=[]
mods={'base':'flat-A/vit-stream.hsaco','hoist':'build-hoist/gfx1201/vit-stream.hsaco','w5':'build-w5/gfx1201/vit-stream.hsaco','w5a':'build-w5a/gfx1201/vit-stream.hsaco','o1':'build-o1/gfx1201/vit-stream.hsaco','o2':'build-o2/gfx1201/vit-stream.hsaco','o3':'build-o3/gfx1201/vit-stream.hsaco'}
for n in [400,640]:
 for label,mf in mods.items():
  w5=label.startswith('w5')
  jobs.append(dict(id=f'ours-{n}-{label}',module='vit_stream',module_file=mf,symbol='vit_stream_qkv_frag_hin_w5' if w5 else 'vit_stream_qkv_frag_hin',
   grid=[96*((n//16+4)//5) if w5 else n//16*96,1,1],block=[160 if w5 else 32,1,1],arg_bytes=40,
   buffers=[dict(id='in',bytes=n*2048,init='half',amplitude=.25,check='none'),
            dict(id='w',bytes=6291584,init='half',amplitude=.25,check='none',segments=[dict(offset=6291456,bytes=128,init='f32',amplitude=1.0)]),
            dict(id='out',bytes=n*3072,init='zero',check='fp8')],
   args=[dict(offset=0,type='ptr',buffer='in'),dict(offset=8,type='ptr',buffer='w'),dict(offset=16,type='ptr',buffer='out'),dict(offset=24,type='u32',value=n),dict(offset=32,type='u64',value=0)]))
jobs.append(dict(id='daniel-050-640',module='daniel',module_file='daniel-050.hsaco',symbol='_Z11k_reg1d_qkvILb0ELb0EEv14Reg1dQkvParams',grid=[10,12,1],block=[256,1,1],arg_bytes=72,
 buffers=[dict(id='input',bytes=655360,init='fp8',amplitude=.25,check='none')]+[dict(id=x,bytes=655360,init='zero',check='fp8') for x in 'QKV']+[dict(id='weights',bytes=3145856,init='fp8',amplitude=.015625,check='none',segments=[dict(offset=0,bytes=128,init='f32',amplitude=.015625)])],
 args=[dict(offset=i*8,type='ptr',buffer=x) for i,x in enumerate(['input','Q','K','V','weights'])]+[dict(offset=40,type='i32',value=640),dict(offset=48,type='u64',value=0),dict(offset=56,type='u64',value=0),dict(offset=64,type='u64',value=0)],
 notes='Daniel 0.5.0 reference QKV (FP8 in/weights, different math); timing reference only.'))
(a.out/'jobs.json').write_text(json.dumps(jobs,indent=1)+'\n')
