#!/usr/bin/env python3
"""Isolated small-stage selector; production C256 and modules remain unchanged."""
import argparse,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--out',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[4];rev='d7b29df2'
def original(n):return subprocess.check_output(['git','show',rev+':'+n],cwd=root)
names=subprocess.check_output(['git','ls-tree','-r','--name-only',rev,'src','Development/HIP'],cwd=root,text=True).splitlines()
for n in names:
 if n.startswith('src/') or (n.count('/')==2 and (n.endswith('.h') or n.endswith('/benchmark_vit_reuse.cpp'))):
  f=a.out/'runner'/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(original(n))
f=a.out/'runner/Development/HIP/swin_persistent_network.h';s=f.read_text()
s=s.replace('U sides=SpEnv("SP_SIDES",3);','U sides=c==256?3:SpEnv("SP_SMALL_SIDES",3);')
s=s.replace('(SpEnv("SP_CHANNELS",SwinRunCompatible(opt)?4u:0u)&bit)','((SwinRunCompatible(opt)?(4u|SpEnv("SP_SMALL_CHANNELS")):0u)&bit)')
s=s.replace('p.fault=SpEnv("SP_FORCE_TIMEOUT");','p.fault=c==256?0:SpEnv("SP_FORCE_TIMEOUT");')
f.write_text(s)
s=original('Development/HIP/experiments/kernel-map/regression.ps1').decode()
s=s.replace("Count -ne 30)","Count -ne 31)")
s=s.replace('^microbench|^runtime-smoke','^microbench|^runtime-smoke|^jobbench|^recorder|^Magpie')
s=s.replace(' [IO.File]::WriteAllLines("$dir\\flags.txt",$flags)',' $flags += "DLSS5_HIP_SWIN_RUN=1"\n [IO.File]::WriteAllLines("$dir\\flags.txt",$flags)')
(a.out/'regression.ps1').write_text(s)

s=s.replace(' $runner=if($candidate', ' $env:SP_SMALL_CHANNELS=if($candidate){$env:SP_REQUEST_CHANNELS}else{"0"}\n $runner=if($candidate')
(a.out/'regression-matched.ps1').write_text(s)
