#!/usr/bin/env python3
"""Recreate rejected R/RF, V and accepted prototype C from task base 50dc5cd5."""
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('out',type=Path);p.add_argument('--variant',required=True,choices=['R','V','C']);a=p.parse_args()
here=Path(__file__).resolve().parent;r=here.parents[3];o=a.out.resolve()
for name in subprocess.check_output(['git','ls-tree','-r','--name-only','50dc5cd5','src','hip','Development/HIP'],cwd=r,text=True).splitlines():
 if not(name.startswith(('src/','hip/')) or (name.count('/')==2 and (name.endswith('.h') or name.endswith('/benchmark_vit_reuse.cpp')))):continue
 q=o/name;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(subprocess.check_output(['git','show','50dc5cd5:'+name],cwd=r))
for suffix in ['host']+(['kernel'] if a.variant=='V' else []):
 subprocess.run(['patch','-s','-p1','-d',str(o)],input=(here/(a.variant+'-'+suffix+'.patch')).read_bytes(),check=True)
if a.variant=='C':
 q=o/'hip/c512_m32_mh.inc';q.write_text(q.read_text()+'\n'+(here/'C-attention.inc').read_text())
if a.variant=='R':
 q=o/'hip/deep_fast.hip';q.write_text(q.read_text()+'\n'+(here/'R-ffn.inc').read_text())
print(o)
