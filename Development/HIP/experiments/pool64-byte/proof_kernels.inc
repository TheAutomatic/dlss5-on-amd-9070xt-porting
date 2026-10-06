// Compare old f32 pool output with decoding the proposed stored byte.
KERNEL void pool64_half_proof(unsigned*old,unsigned*next){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i>=65536)return;
 float raw;asm("v_cvt_f32_f16 %0, %1":"=v"(raw):"v"(i));float v=F(Hrtz(raw));
 old[i]=bits(v);next[i]=bits(__builtin_amdgcn_cvt_f32_fp8(int(q8(v)),0));
}
