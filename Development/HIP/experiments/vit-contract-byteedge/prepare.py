from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[4]
get=lambda name:subprocess.check_output(['git','show','ed5295fe:hip/'+name],cwd=root,text=True)
defs=['HIP_ISA_HALF 1','HIP_PREPACKED_WEIGHTS 1','HIP_BRANCHLESS_F 1','HIP_VIT_STREAM_KERNELS 1','HIP_VIT_QKV_W5 1','VIT_CONTRACT_OCC_LDS 4096','VIT_QKV_F8W 1']
for fast in (0,4):
 head=''.join('#define '+s+'\n' for s in defs)+f'#define VIT_FAST_NUM {fast}\n'
 for name in ('baseline','candidate'):
  parts=[get(n) if name=='baseline' else (root/'hip'/n).read_text() for n in ('deep_fast.hip','vit_stream.inc')]
  proof=Path(__file__).with_name('proof_kernels.inc').read_text() if name=='candidate' else ''
  (a.output/f'{name}-{fast}.generated.hip').write_text(head+('#define VIT_CONTRACT_BYTE_EDGE 1\n' if name=='candidate' else '')+'\n'.join(parts)+'\n'+proof)
