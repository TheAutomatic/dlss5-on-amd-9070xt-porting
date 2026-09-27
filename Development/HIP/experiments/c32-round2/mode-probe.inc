// Appended to the generated M source: exercises the actual cw_pack8 helper.
CW_ENTRY void mode_probe(uint*out){
 uint i=__builtin_amdgcn_workgroup_id_x()*32+__builtin_amdgcn_workitem_id_x();if(i>=8192)return;
 float t[8];for(uint e=0;e<8;e++)t[e]=float(__builtin_bit_cast(_Float16,(ushort)(i*8+e)));
 int lo=__builtin_amdgcn_cvt_pk_fp8_f32(cw_z(t[0]),cw_z(t[1]),0,false);lo=__builtin_amdgcn_cvt_pk_fp8_f32(cw_z(t[2]),cw_z(t[3]),lo,true);
 int hi=__builtin_amdgcn_cvt_pk_fp8_f32(cw_z(t[4]),cw_z(t[5]),0,false);hi=__builtin_amdgcn_cvt_pk_fp8_f32(cw_z(t[6]),cw_z(t[7]),hi,true);
 i2 v=cw_pack8<0,0>(t);uint mode,guard;float large=70000.f+float(i&1);
 asm volatile("s_getreg_b32 %0, hwreg(HW_REG_MODE, 23, 1)":"=s"(mode)::"memory");
 asm volatile("v_cvt_f16_f32 %0, %1":"=v"(guard):"v"(large):"memory");
 out[i*6]=uint(lo);out[i*6+1]=uint(hi);out[i*6+2]=uint(v[0]);out[i*6+3]=uint(v[1]);out[i*6+4]=mode;out[i*6+5]=guard&65535;
}
