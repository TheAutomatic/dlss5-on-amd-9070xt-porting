from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
root=Path(__file__).resolve().parents[4]
defs=['HIP_ISA_HALF 1','HIP_PREPACKED_WEIGHTS 1','HIP_DEC_WIDE 1','HIP_VIT_ATTN_NATIVE_HALF 1','HIP_VIT_ATTN_PROB_PAIR 1','HIP_VIT_ATTN_TRANSPOSED_AV 1','HIP_VIT_ATTN_TRANSPOSED_SCORE 1','HIP_BRANCHLESS_F 1','C512_F_MASK 1','C512_T8_TAIL_VEC 1','HIP_BYTE_F_ADD0 1','HIP_VIT_ATTN_RCP 1']
original=subprocess.check_output(['git','show','d02b423c:hip/deep_fast.hip'],cwd=root,text=True)
anchor='// ViT projection on the byte stream: attention bytes as the A operand'
assert original.count(anchor)==1
current=original.replace(anchor,Path(__file__).with_name('attention960.inc').read_text()+anchor)
for fast in (0,15):
 head=''.join('#define '+d+'\n' for d in defs)+f'#define VIT_FAST_NUM {fast}\n'
 for name,source in [('baseline',original),('candidate',current)]:
  (a.output/(f'{name}-{fast}.generated.hip')).write_text(head+('#define HIP_VIT_ATTN_960 1\n' if name=='candidate' else '')+source)
