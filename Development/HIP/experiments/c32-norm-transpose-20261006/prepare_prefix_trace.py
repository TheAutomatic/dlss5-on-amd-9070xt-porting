"""Capture actual first prefix Q norm, qt0/window0; never timing modules."""
import argparse
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);p.add_argument('--transpose',action='store_true');a=p.parse_args();s=a.basis.read_text();needle='   f8 sum{};if(part<2)';assert s.count(needle)==1
s='extern "C" __attribute__((device)) float c32_prefix_norm_trace[3072]={};\n'+s
pos='(g*8+e)*32+ci*16+r' if a.transpose else 'r*32+ci*16+g*8+e'
cap='''   if constexpr(Prefix){if(bid()==0&&qt==0&&part==0)for(uint ci=0;ci<2;ci++)for(uint e=0;e<8;e++){uint pos=POS;c32_prefix_norm_trace[pos]=q[ci][e];c32_prefix_norm_trace[512+pos]=float((_Float16)(q[ci][e]*q[ci][e]));}}
'''.replace('POS',pos)
s=s.replace(needle,cap+needle)
needle='CW_Q8_END_SITE(a,3);';assert s.count(needle)==1
ss='sum[0]' if a.transpose else 'sum[e]'
cap='''CW_Q8_END_SITE(a,3);
    if constexpr(Prefix){if(bid()==0&&qt==0&&part==0)for(uint e=0;e<8;e++){uint pos=POS;float ss=SUM,iv=__builtin_amdgcn_rsqf(maxf(ss,6.198883056640625e-5f))*w[8192];c32_prefix_norm_trace[1024+pos]=ss;c32_prefix_norm_trace[1536+pos]=iv;c32_prefix_norm_trace[2048+pos]=q[ci][e]*iv;reinterpret_cast<uint*>(c32_prefix_norm_trace)[2560+pos]=(uint(a[e/4])>>(8*(e%4)))&255u;}}'''.replace('POS',pos).replace('SUM',ss)
s=s.replace(needle,cap);a.out.write_text(s)
