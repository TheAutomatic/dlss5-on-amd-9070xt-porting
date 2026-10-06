KERNEL void direct_pack_proof(unsigned char*old,unsigned char*next){
 uint h=bid()*256+__builtin_amdgcn_workitem_id_x();if(h>=65536)return;
 float raw;asm("v_cvt_f32_f16 %0, %1":"=v"(raw):"v"(h));float v=c512_hq(raw);
 old[h]=static_cast<unsigned char>(__builtin_amdgcn_cvt_pk_fp8_f32(F(v),0.f,0,false));next[h]=byte_F(v);
}
KERNEL void direct_pack_pair_proof(unsigned*old,unsigned*next){
 uint h=bid()*256+__builtin_amdgcn_workitem_id_x();if(h>=65536)return;
 float ov[8],nv[8];for(uint e=0;e<8;e++){uint b=(h+e*8191u)&65535u;float raw;asm("v_cvt_f32_f16 %0, %1":"=v"(raw):"v"(b));float v=c512_hq(raw);ov[e]=F(v);nv[e]=fp8_add0(v);}
 i2 a=c5d_pack8f(ov),b=c5d_pack8f(nv);old[h*2]=a[0];old[h*2+1]=a[1];next[h*2]=b[0];next[h*2+1]=b[1];
}
KERNEL void pack_real_weights(const float*in,unsigned char*out){
 uint i=bid()*256+__builtin_amdgcn_workitem_id_x();
 if(i<262144)out[i]=byte_F(in[i]);else if(i<393216)out[262144*4+i-262144]=byte_F(in[i]);else if(i<524288)out[393216*4+i-393216]=byte_F(in[i]);
}
