#!/usr/bin/env python3
from pathlib import Path
import argparse,json,copy,numpy as np
p=argparse.ArgumentParser();p.add_argument('--root',type=Path,default=Path('/tmp/kernel-map'));a=p.parse_args();r=a.root
jobs=json.loads((r/'ours-jobs.json').read_text());assert jobs[67]['symbol']=='mh_pool' and jobs[68]['symbol']=='mh_pool_project_production_h16w'
weight=jobs[68]['buffers'][1];raw=(r/weight['file']).read_bytes();w=np.frombuffer(raw,dtype='<u2',count=1024*512).reshape(64,16,32,2,8);(r/'synthetic/head-frag-half.bin').write_bytes(w.transpose(0,2,3,1,4).copy().tobytes())
out=[]
for j in jobs:
 if j['symbol']=='vit_attention_fused_640_bytein_bout':
  q=copy.deepcopy(j);q['baseline_id']=q['id'];q['id']='after-'+q['id'];q['module_file']='flat-C/deep_fast-packed.hsaco';out.append(q)
b0=copy.deepcopy(jobs[67]['buffers'][0]);bw=copy.deepcopy(weight);bw.update(bytes=1048576,check_bytes=1048576,file='synthetic/head-frag-half.bin');bo=copy.deepcopy(jobs[68]['buffers'][2])
out.append(dict(id='ours-head-group',module='mh_fast',module_file='flat-C/multihead-fast-padded-wave-packed.hsaco',symbol='mh_pool_project_group_c512',grid=[40,1,1],block=[512,1,1],arg_bytes=44,buffers=[b0,bw,bo],args=[dict(offset=0,type='ptr',buffer='b0'),dict(offset=8,type='ptr',buffer='b1'),dict(offset=16,type='ptr',buffer='b2')]+[dict(offset=24+i*4,type='u32',value=v) for i,v in enumerate([32,20,60,30,18])]))
(r/'after-jobs.json').write_text(json.dumps(out,indent=2)+'\n');(r/'after-list.txt').write_text('\n'.join(x['id'] for x in out)+'\n')
