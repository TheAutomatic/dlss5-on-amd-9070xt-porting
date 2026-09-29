#!/usr/bin/env python3
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();here=Path(__file__).resolve().parent;repo=here.parents[3];o=a.out.resolve()
for name in subprocess.check_output(['git','ls-tree','-r','--name-only','b99e9ef6','src','Development/HIP'],cwd=repo,text=True).splitlines():
 if not(name.startswith('src/') or (name.count('/')==2 and (name.endswith('.h') or name.endswith('/benchmark_vit_reuse.cpp')))):continue
 q=o/name;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(subprocess.check_output(['git','show','b99e9ef6:'+name],cwd=repo))
subprocess.run(['patch','-s','-p1','-d',str(o)],input=(here/'recorder-host.patch').read_bytes(),check=True)
print(o)
