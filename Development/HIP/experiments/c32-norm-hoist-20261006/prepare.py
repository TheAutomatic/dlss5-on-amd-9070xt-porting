"""Original layout and half-square two-WMMA norm, only reuse lane inverse."""
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);a=p.parse_args();s=a.basis.read_text()
old='   for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){float v=q[ci][e];if(part<2)v*=__builtin_amdgcn_rsqf(maxf(sum[e],6.198883056640625e-5f))*(part==0?w[8192]:1.f);'
new='   float lane_rsq=part<2?__builtin_amdgcn_rsqf(maxf(sum[0],6.198883056640625e-5f)):0.f;\n   for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){float v=q[ci][e];if(part<2)v*=lane_rsq*(part==0?w[8192]:1.f);'
assert s.count(old)==1;a.out.parent.mkdir(exist_ok=True,parents=True);a.out.write_text(s.replace(old,new))
