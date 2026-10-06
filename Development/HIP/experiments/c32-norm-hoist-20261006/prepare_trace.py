"""Actual first prefix qt0 Q trace and all-eight norm sums agreement, diagnostic only."""
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);a=p.parse_args();s=a.basis.read_text()
s='extern "C" __attribute__((device)) float c32_prefix_norm_trace[3104]={};\n'+s
needle='   f8 sum{};if(part<2)';assert s.count(needle)==1
s=s.replace(needle,'''   if constexpr(Prefix){if(bid()==0&&qt==0&&part==0)for(uint ci=0;ci<2;ci++)for(uint e=0;e<8;e++){uint pos=r*32+ci*16+g*8+e;c32_prefix_norm_trace[pos]=q[ci][e];c32_prefix_norm_trace[512+pos]=float((_Float16)(q[ci][e]*q[ci][e]));}}
'''+needle)
needle='   for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){float v=q[ci][e];if(part<2)v*='
assert s.count(needle)==1
s=s.replace(needle,'''   if constexpr(Prefix){if(bid()==0&&qt==0&&part==0){uint bad=0;for(uint e=0;e<8;e++)bad+=bits(sum[e])!=bits(sum[0]);reinterpret_cast<uint*>(c32_prefix_norm_trace)[3072+__builtin_amdgcn_workitem_id_x()]=bad;}}
'''+needle)
needle='CW_Q8_END_SITE(a,3);';assert s.count(needle)==1
s=s.replace(needle,'''CW_Q8_END_SITE(a,3);
    if constexpr(Prefix){if(bid()==0&&qt==0&&part==0)for(uint e=0;e<8;e++){uint pos=r*32+ci*16+g*8+e;float ss=sum[e],iv=__builtin_amdgcn_rsqf(maxf(ss,6.198883056640625e-5f))*w[8192];c32_prefix_norm_trace[1024+pos]=ss;c32_prefix_norm_trace[1536+pos]=iv;c32_prefix_norm_trace[2048+pos]=q[ci][e]*iv;reinterpret_cast<uint*>(c32_prefix_norm_trace)[2560+pos]=(uint(a[e/4])>>(8*(e%4)))&255u;}}
''')
a.out.write_text(s)
