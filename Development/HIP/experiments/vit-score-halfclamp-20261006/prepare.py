"""Regenerate B2 from stair B; only exact score helper replacement."""
import argparse
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);a=p.parse_args()
here=Path(__file__).parent;old=(here.parent/'vit-math-stair-20261006/score_half.inc').read_text();new=(here/'score_half.inc').read_text();s=a.basis.read_text()
assert s.count(old)==1
a.out.mkdir(parents=True,exist_ok=True);(a.out/'B2.hip').write_text(s.replace(old,new))
(a.out/'score-probe.hip').write_text('#define DEV __attribute__((device)) __attribute__((always_inline)) inline\n'+new+'\nextern "C" __attribute__((global)) void score_half_probe(const float* in,unsigned short* out,int n){int i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i<n)out[i]=vit_trial_score_half(in[i]);}\n')
