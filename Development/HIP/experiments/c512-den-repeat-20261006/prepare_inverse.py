"""Canonical isolated old/new denominator inverse; never change helper math."""
from pathlib import Path
import argparse,importlib.util
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);r=Path(__file__).resolve().parents[4]
sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);rows=[x for x in m.recipe(r/'hip')if x[0]=='c512-m32-mh'];assert len(rows)==1;s=rows[0][2]
needle='float inv=c5c_inv(sums[0][e]+sums[1][e]);';assert s.count(needle)==1
(a.output/'old.hip').write_text(s)
anchor='  i2 prob[4];\n  _Pragma("unroll 4") for(uint key=0;key<4;key++){';prefix,tail=s.rsplit(anchor,1)
new=prefix+'  const float denominator_inverse=c5c_inv(sums[0][0]+sums[1][0]);\n'+anchor+tail
new=new.replace(needle,'float inv=denominator_inverse;');(a.output/'new.hip').write_text(new)
# Keep real helper from canonical source. Gold uses identical operand/layout and
# tests8 old element inverses versus one shared inverse on every lane.
gold='''
KERNEL __attribute__((amdgpu_flat_work_group_size(32,32)))
void c512_den_inverse_gold(uint*out,uint fixture){
 uint lane=__builtin_amdgcn_workitem_id_x();h8 ex[4];
 for(uint key=0;key<4;key++)for(uint e=0;e<8;e++){
  float v=.00006103515625f;
  if(fixture==1)v=float(1+key*257+lane*8+e)/1024.f;
  if(fixture==2)v=9.75f;
  if(fixture==3)v=(lane+e+key)%2?9.75f:.00006103515625f;
  if(fixture==4)v=(lane+e+key)%4==0?8.f:(lane+e+key)%4==1?1.f:(lane+e+key)%4==2?.125f:.015625f;
  if(fixture==5)v=1.f+float(lane+e+key)/1024.f;
  if(fixture==6)v=(lane+e+key)%3? .00006103515625f:-0.f;
  if(fixture==7)v=(lane+e+key)%2?.00390625f:.0078125f;
  ex[key][e]=(_Float16)v;
 }
 h8 ones{};for(uint e=0;e<8;e++)ones[e]=(_Float16)1.f;
 f8 sums[2]{};for(uint side=0;side<2;side++)for(uint h=0;h<2;h++)sums[side]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(ones,ex[side+2*h],sums[side]);
 float shared=c5c_inv(sums[0][0]+sums[1][0]);
 for(uint e=0;e<8;e++){
  float den=sums[0][e]+sums[1][e],old=c5c_inv(den);
  out[lane*8+e]=bits(den);
  out[256+lane*8+e]=bits(old);out[512+lane*8+e]=bits(shared);
  for(uint key=0;key<4;key++){out[768+key*256+lane*8+e]=c5c_fp8(float(ex[key][e])*old);out[1792+key*256+lane*8+e]=c5c_fp8(float(ex[key][e])*shared);}
 }
}
'''
(a.output/'gold.hip').write_text(s+gold)
