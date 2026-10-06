"""Minimal LDS restoration prototype; half-square and WMMA order retained."""
import argparse
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);a=p.parse_args();s=a.basis.read_text()
old='q[ci]=part<2?__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,feature[kt],q[ci]):__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(feature[kt],b,q[ci]);'
new='q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(feature[kt],b,q[ci]);'
assert s.count(old)==1;s=s.replace(old,new)
old='sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,squares,sum);'
assert s.count(old)==1;s=s.replace(old,'sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(squares,ones,sum);')
start=s.index('   for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){float v=q[ci][e];if(part<2)v*=')
end=s.index('\n#if CW_QKV_FENCE',start)
oldbody=s[start:end]
newbody='''   __attribute__((shared)) unsigned char transpose_bytes[512];
   float inv=part<2?__builtin_amdgcn_rsqf(maxf(sum[0],6.198883056640625e-5f))*(part==0?w[8192]:1.f):1.f;
   for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){float v=q[ci][e];if(part<2)v*=inv;CW_Q8_SET(a,e,v);}CW_Q8_END_SITE(a,3);
    if(part<2)__builtin_memcpy(transpose_bytes+r*32+ci*16+g*8,&a,8);
    else{values[qt*4+ci*2]=a[0];values[qt*4+ci*2+1]=a[1];}
   }
   if(part<2){__builtin_amdgcn_sched_barrier(0);for(uint ci=0;ci<2;ci++){i2 a{};for(uint e=0;e<8;e++)a[e/4]=int(uint(a[e/4])|(uint(transpose_bytes[(g*8+e)*32+ci*16+r])<<(8*(e%4))));
    if(part==0){queries[qt*4+ci*2]=a[0];queries[qt*4+ci*2+1]=a[1];}else{keys[qt*4+ci*2]=a[0];keys[qt*4+ci*2+1]=a[1];}
   }}'''
s=s[:start]+newbody+s[end:];a.out.parent.mkdir(parents=True,exist_ok=True);a.out.write_text(s)
