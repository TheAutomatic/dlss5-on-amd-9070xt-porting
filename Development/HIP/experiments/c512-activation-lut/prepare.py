"""Generate isolated original/macro0/LUT modules from pinned production source; no GPU."""
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args()
root=Path(__file__).resolve().parents[4];a.output.mkdir(parents=True,exist_ok=True)
get=lambda path:subprocess.check_output(['git','show','170f7b3c:'+path],cwd=root,text=True)
defs=''.join('#define '+s+'\n' for s in ['HIP_ISA_HALF 1','HIP_PREPACKED_WEIGHTS 1','HIP_BRANCHLESS_F 1','C512_MIX_OCC_LDS 4096','C512_F_MASK 1','HIP_BYTE_F_ADD0 1','C512_FFN_ONE 2','C512_FFN_F8W 1'])
deep=get('hip/deep_fast.hip');base=get('hip/c512_m32_deep.inc')
current=Path(__file__).with_name('activation_lut.inc').read_text()+base
old='float v=Hrtz(ex[e]),gate=clampf(v,-4.f,4.f),poly=__builtin_fmaf(gate,__builtin_fmaf(absf(gate),-.055908203125f,.447265625f),.89453125f);a[e/4]=int(uint(a[e/4])|(uint(byte_F(v*poly))<<(8*(e%4))));'
assert current.count(old)==3
current=current.replace(old,'a[e/4]=int(uint(a[e/4])|(uint(c512_activation_byte(ex[e]))<<(8*(e%4))));')
old2='float v=Hrtz(ex[t][e]),gate=clampf(v,-4.f,4.f),poly=__builtin_fmaf(gate,__builtin_fmaf(absf(gate),-.055908203125f,.447265625f),.89453125f);a[t][e/4]=int(uint(a[t][e/4])|(uint(byte_F(v*poly))<<(8*(e%4))));'
assert current.count(old2)==1
current=current.replace(old2,'a[t][e/4]=int(uint(a[t][e/4])|(uint(c512_activation_byte(ex[t][e]))<<(8*(e%4))));')
texts={'baseline':defs+deep+'\n'+get('hip/c512_m32_deep.inc'),'macro0':defs+deep+'\n'+current,'candidate':defs+'#define C512_ACTIVATION_LUT 1\n'+deep+'\n'+current+'\n'+Path(__file__).with_name('probe_kernels.inc').read_text()}
for name,s in texts.items():(a.output/(name+'.generated.hip')).write_text(s)
print(a.output)
