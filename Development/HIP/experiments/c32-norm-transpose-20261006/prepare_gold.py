"""Actual QKV/norm expressions, isolated single16token wave; no performance proxy."""
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);a=p.parse_args()
body=r'''
template<bool Transpose>
DEV void c32_norm_unit(const unsigned char*in,const float*w,const float*raw,float*out,uint use_raw){
 constexpr uint cw_kind=5;
 uint l=__builtin_amdgcn_workitem_id_x(),r=l&15u,g=l>>4;
 i2 feature[2];for(uint kt=0;kt<2;kt++)__builtin_memcpy(&feature[kt],in+r*32+kt*16+g*8,8);
 f8 q[2]{};for(uint ci=0;ci<2;ci++)for(uint kt=0;kt<2;kt++){i2 b=matrix8(w,(ci*16+r)*32+kt*16+g*8);
 if constexpr(Transpose)q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(feature[kt],b,q[ci]);
 else q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,feature[kt],q[ci]);}
 for(uint ci=0;ci<2;ci++)for(uint e=0;e<8;e++){uint token=Transpose?g*8+e:r,ch=ci*16+(Transpose?r:g*8+e),pos=token*32+ch;if(use_raw)q[ci][e]=raw[pos];out[pos]=q[ci][e];out[512+pos]=float((_Float16)(q[ci][e]*q[ci][e]));}
 f8 sum{};for(uint ci=0;ci<2;ci++){h8 squares{},ones{};for(uint e=0;e<8;e++){squares[e]=(_Float16)(q[ci][e]*q[ci][e]);ones[e]=(_Float16)1.f;}
 if constexpr(Transpose)sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(squares,ones,sum);else sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,squares,sum);}
 float lane_inv=__builtin_amdgcn_rsqf(maxf(sum[0],6.198883056640625e-5f));
 for(uint ci=0;ci<2;ci++){CW_Q8_DECL(a);for(uint e=0;e<8;e++){uint token=Transpose?g*8+e:r,ch=ci*16+(Transpose?r:g*8+e),pos=token*32+ch;float ss=Transpose?sum[0]:sum[e],inv=Transpose?lane_inv:__builtin_amdgcn_rsqf(maxf(ss,6.198883056640625e-5f));out[1024+pos]=ss;out[1536+pos]=inv;float value=q[ci][e]*inv;out[2048+pos]=value;CW_Q8_SET(a,e,value);}CW_Q8_END_SITE(a,3);
 for(uint e=0;e<8;e++){uint token=Transpose?g*8+e:r,ch=ci*16+(Transpose?r:g*8+e);reinterpret_cast<uint*>(out)[2560+token*32+ch]=(uint(a[e/4])>>(8*(e%4)))&255u;}}
}
extern "C" __attribute__((global)) __attribute__((amdgpu_flat_work_group_size(32,32))) void c32_norm_gold_A(const unsigned char*in,const float*w,const float*raw,float*out,uint use_raw){c32_norm_unit<false>(in,w,raw,out,use_raw);}
extern "C" __attribute__((global)) __attribute__((amdgpu_flat_work_group_size(32,32))) void c32_norm_gold_T(const unsigned char*in,const float*w,const float*raw,float*out,uint use_raw){c32_norm_unit<true>(in,w,raw,out,use_raw);}
'''
a.out.write_text(a.basis.read_text()+body)
