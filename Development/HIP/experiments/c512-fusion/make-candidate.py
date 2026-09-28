#!/usr/bin/env python3
"""Generate isolated c512-m32-mh source; no writes to the repository."""
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,default=Path(__file__).resolve().parents[4]);p.add_argument('--output',type=Path,default=Path('/tmp/c512-fusion/code/c512-m32-mh.generated.hip'));p.add_argument('--waves',type=int,choices=[2,4],default=2);p.add_argument('--debug',action='store_true');a=p.parse_args()
defines=['HIP_ISA_HALF 1','HIP_PREPACKED_WEIGHTS 1','HIP_FFN_HOIST_RES 2','HIP_PDL_KERNELS 0','HIP_FMED3_CLAMP 1','C512_FUSED_QKV_ATTN 1',f'C512_FUSED_WAVES {a.waves}',f'C512_FUSED_DEBUG {int(a.debug)}']
s=''.join('#define '+d+'\n' for d in defines)
for f in ['multihead_fast_padded.hip','c512_m32_mh.inc']:s+=subprocess.check_output(['git','show','8c9a61db:hip/'+f],cwd=a.repo,text=True)+'\n'
s+=Path(__file__).with_name('c512_qkv_attention_fused.inc').read_text()+'\n'
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(s);print(a.output)
