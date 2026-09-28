#!/usr/bin/env python3
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('variant',choices=['P','Q']);p.add_argument('out',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[4];here=Path(__file__).resolve().parent
def get(n):return subprocess.check_output(['git','show','c10a79d1:hip/'+n],cwd=r,text=True)
defs=['HIP_ISA_HALF 1','HIP_PREPACKED_WEIGHTS 1','HIP_BRANCHLESS_F 1','HIP_VIT_STREAM_KERNELS 1','HIP_VIT_PACK_STREAM 1']
if a.variant=='Q':defs.append('HIP_VIT_PACK_REUSE_BYTE 1')
s=''.join('#define '+d+'\n' for d in defs)+get('deep_fast.hip')+'\n'+get('vit_stream.inc')+'\n'+(here/(a.variant+'-vit-pack.inc')).read_text()
a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(s)
