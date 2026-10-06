"""Original operand/layout unit, both branches differ only inverse reuse; all sum lanes checked."""
from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('basis',type=Path);p.add_argument('out',type=Path);a=p.parse_args()
# Reuse typed unit skeleton; strip both transpose branches explicitly.
s=(Path(__file__).parent.parent/'c32-norm-transpose-20261006/prepare_gold.py').read_text();body=s.split("body=r'''",1)[1].split("'''",1)[0]
body=body.replace('Transpose','Hoist')
old=' if constexpr(Hoist)q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(feature[kt],b,q[ci]);\n else q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,feature[kt],q[ci]);'
assert old in body;body=body.replace(old,' q[ci]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(b,feature[kt],q[ci]);')
old=' if constexpr(Hoist)sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(squares,ones,sum);else sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,squares,sum);'
assert old in body;body=body.replace(old,' sum=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,squares,sum);')
body=body.replace('token=Hoist?g*8+e:r,ch=ci*16+(Hoist?r:g*8+e)','token=r,ch=ci*16+g*8+e').replace('float ss=Hoist?sum[0]:sum[e]','float ss=sum[e]')
body=body.replace('float value=q[ci][e]*inv;','float value=q[ci][e]*(inv*1.25f);')
body=body.replace(' float lane_inv=', ' uint sumdiff=0;for(uint e=0;e<8;e++)sumdiff+=bits(sum[e])!=bits(sum[0]);reinterpret_cast<uint*>(out)[3072+l]=sumdiff;\n float lane_inv=')
body=body.replace('c32_norm_gold_T','c32_norm_gold_H')
a.out.write_text(a.basis.read_text()+body)
