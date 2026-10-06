KERNEL void act_compare(unsigned char*reference,unsigned char*lookup){
 uint h=bid()*256+__builtin_amdgcn_workitem_id_x();if(h>=65536)return;
 float v;asm("v_cvt_f32_f16 %0, %1":"=v"(v):"v"(h));
 reference[h]=c512_activation_reference(v);lookup[h]=c512_activation_byte(v);
}
KERNEL void fp8_pack_weights(const float*in,unsigned char*out){
 uint i=bid()*256+__builtin_amdgcn_workitem_id_x();
 if(i<262144)out[i]=byte_F(in[i]);
 else if(i<393216)out[262144*4+i-262144]=byte_F(in[i]);
 else if(i<524288)out[393216*4+i-393216]=byte_F(in[i]);
}
