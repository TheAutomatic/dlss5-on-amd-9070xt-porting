from pathlib import Path
import argparse, hashlib, json
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
defines=['MH_POOL_HALF_IN 1','C512_HEAD_GROUP 1','HIP_C512_HOIST_RES 1','HIP_FFN_HOIST_RES 2','HIP_FFN_LINE_STORES 1','HIP_FMED3_CLAMP 1','HIP_POOL32_B8 1']
s=''.join('#define '+x+'\n' for x in defines)+(r/'hip/multihead_fast_padded.hip').read_text()+'\n'+(r/'hip/c512_head_group.inc').read_text()+'\n'+Path(__file__).with_name('proof_kernels.inc').read_text()
out=a.output/'pool64.generated.hip';out.write_text(s)
(a.output/'source.json').write_text(json.dumps({'sha256':hashlib.sha256(s.encode()).hexdigest(),'defines':defines,'proof':'GPU pending; CPU representation only complete'},indent=2)+'\n')
