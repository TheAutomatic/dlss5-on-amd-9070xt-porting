KERNEL void edge_codec_proof(unsigned short*oldhalf,unsigned char*oldbyte,unsigned char*newbyte,unsigned*decoded){
 uint h=bid()*256+__builtin_amdgcn_workitem_id_x();if(h>=65536)return;
 float x;asm("v_cvt_f32_f16 %0, %1":"=v"(x):"v"(h));
 float f=F(x);_Float16 half=(_Float16)f;unsigned short raw=__builtin_bit_cast(unsigned short,half);
 oldhalf[h]=raw;oldbyte[h]=static_cast<unsigned char>(__builtin_amdgcn_cvt_pk_fp8_f32(float(half),0.f,0,false));
 unsigned char b=vit_contract_F_byte(x);newbyte[h]=b;decoded[h]=bits(__builtin_amdgcn_cvt_f32_fp8(int(b),0));
}
KERNEL void edge_byte_roundtrip(unsigned char*repacked,unsigned*halfdecoded,unsigned*bytedecoded){
 uint b=__builtin_amdgcn_workitem_id_x();float v=__builtin_amdgcn_cvt_f32_fp8(int(b),0);_Float16 h=(_Float16)v;
 repacked[b]=static_cast<unsigned char>(__builtin_amdgcn_cvt_pk_fp8_f32(float(h),0.f,0,false));halfdecoded[b]=bits(float(h));bytedecoded[b]=bits(v);
}
