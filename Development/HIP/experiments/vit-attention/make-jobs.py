#!/usr/bin/env python3
import argparse,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
jobs=[]
for n in [400,448,640]:
 for label,g in [('base',1),('native',1),('pair',1),('transpose',1),('pair_transpose',1),('native_g1_u1_h0',1),('native_g1_u4_h0',1),('native_g4_u4_h1',4),('g1_u1_h0',1),('g1_u1_h1',1),('g4_u1_h1',4),('g1_u4_h0',1),('g4_u4_h1',4)]:
  jobs.append(dict(id=f'ours-{n}-{label}',module='deep',module_file='flat-A/deep_fast-packed.hsaco' if label=='base' else 'probe/gfx1201/probe.hsaco',symbol=f'vit_attention_fused_{400 if n==400 else 640}_bytein_bout' if label=='base' else 'vit_probe_'+label,grid=[((n//16+g-1)//g)*32,1,1],block=[g*32,1,1],arg_bytes=32,buffers=[dict(id='input',bytes=n*3072,init='fp8',amplitude=.25,check='none'),dict(id='output',bytes=n*1024,init='zero',check='fp8')],args=[dict(offset=0,type='ptr',buffer='input'),dict(offset=8,type='ptr',buffer='output'),dict(offset=16,type='u32',value=n),dict(offset=24,type='u64',value=0)]))
for ver in ['050','051']:
 for n in [448,640]:
  jobs.append(dict(id=f'daniel-{ver}-{n}',module='daniel',module_file=f'daniel-{ver}.hsaco',symbol='_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams',grid=[n//64,32,1],block=[128,1,1],arg_bytes=48,buffers=[dict(id=name,bytes=n*1024,init='zero' if name=='output' else 'fp8',amplitude=.25,check='fp8' if name=='output' else 'none') for name in ['Q','K','V','output']],args=[dict(offset=i*8,type='ptr',buffer=name) for i,name in enumerate(['Q','K','V','output'])]+[dict(offset=32,type='i32',value=n),dict(offset=36,type='i32',value=n),dict(offset=40,type='u64',value=0)]))
(a.out/'jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
import copy
for n in [400,448,640]:
 for label,symbol in [('base',f'vit_attention_fused_{400 if n==400 else 640}_bytein_bout'),('native','vit_probe_native'),('nov','vit_probe_native_constv')]:
  j=copy.deepcopy(next(j for j in jobs if j['id']==f'ours-{n}-base'))
  j['id']=f'constv-{n}-{label}';j['symbol']=symbol
  if label!='base':j['module_file']='probe/gfx1201/probe.hsaco'
  j['buffers'][0]['segments']=[dict(offset=2*n*1024,bytes=n*1024,init='byte',value=0x38)]
  j['notes']='Restricted all-V=+1 fixture; no-V kernel is diagnostic only, not a general candidate.'
  jobs.append(j)
(a.out/'jobs.json').write_text(json.dumps(jobs,indent=2)+'\n')
