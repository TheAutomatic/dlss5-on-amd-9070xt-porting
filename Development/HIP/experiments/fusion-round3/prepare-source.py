#!/usr/bin/env python3
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('out',type=Path);p.add_argument('--revision',default='c10a79d1');p.add_argument('--variant',choices=['P','Q','U','U2','T','D']);a=p.parse_args()
r=Path(__file__).resolve().parents[4];here=Path(__file__).resolve().parent;o=a.out.resolve()
for name in subprocess.check_output(['git','ls-tree','-r','--name-only',a.revision,'src','hip','Development/HIP'],cwd=r,text=True).splitlines():
 if not(name.startswith(('src/','hip/')) or (name.count('/')==2 and (name.endswith('.h') or name.endswith('/benchmark_vit_reuse.cpp')))):continue
 q=o/name;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(subprocess.check_output(['git','show',a.revision+':'+name],cwd=r))
# Identical probe for old/new source; only adds the no-temporal-context measurement option to the 0.35 harness.
(o/'Development/HIP/benchmark_vit_reuse.cpp').write_bytes(subprocess.check_output(['git','show','c10a79d1:Development/HIP/benchmark_vit_reuse.cpp'],cwd=r))
if a.variant:
 for suffix in ['host']+([] if a.variant in ['P','Q'] else ['kernel']):
  subprocess.run(['patch','-s','-p1','-d',str(o)],input=(here/(a.variant+'-'+suffix+'.patch')).read_bytes(),check=True)
 if a.variant in ['P','Q']:
  q=o/'hip/vit_stream.inc';q.write_text(q.read_text()+'\n'+(here/(a.variant+'-vit-pack.inc')).read_text())
