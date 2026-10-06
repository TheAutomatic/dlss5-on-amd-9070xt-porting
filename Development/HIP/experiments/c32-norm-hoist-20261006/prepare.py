"""Original layout and half-square two-WMMA norm, only reuse lane inverse."""
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);p.add_argument('--enable',action='store_true');a=p.parse_args();s=a.basis.read_text()
old='   for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){float v=q[ci][e];if(part<2)v*=__builtin_amdgcn_rsqf(maxf(sum[e],6.198883056640625e-5f))*(part==0?w[8192]:1.f);'
new='   float lane_rsq=part<2?__builtin_amdgcn_rsqf(maxf(sum[0],6.198883056640625e-5f)):0.f;\n   for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){float v=q[ci][e];if(part<2)v*=lane_rsq*(part==0?w[8192]:1.f);'
assert s.count(old)==1
# Macro0 preserves the exact old preprocessed statement; macro1 matches testedH.
guarded='#if CW_NORM_HOIST\n'+new+'\n#else\n'+old+'\n#endif\n'
a.out.parent.mkdir(exist_ok=True,parents=True)
a.out.write_text(('#define CW_NORM_HOIST 1\n' if a.enable else '')+'#ifndef CW_NORM_HOIST\n#define CW_NORM_HOIST 0\n#endif\n'+s.replace(old,guarded))
