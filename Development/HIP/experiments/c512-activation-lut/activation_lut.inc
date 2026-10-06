// Experimental: lookup the fixed activation only after the required RTZ half boundary.
#ifndef C512_ACTIVATION_LUT
#define C512_ACTIVATION_LUT 0
#endif
DEV unsigned char c512_activation_reference(float accum){
 float v=Hrtz(accum),gate=clampf(v,-4.f,4.f),poly=__builtin_fmaf(gate,__builtin_fmaf(absf(gate),-.055908203125f,.447265625f),.89453125f);
 return byte_F(v*poly);
}
#if C512_ACTIVATION_LUT
extern "C" __attribute__((device)) unsigned char c512_activation_table[65536]{};
KERNEL void c512_activation_prepare(){
 uint h=bid()*256+__builtin_amdgcn_workitem_id_x();if(h>=65536)return;
 float v;asm("v_cvt_f32_f16 %0, %1":"=v"(v):"v"(h));
 c512_activation_table[h]=c512_activation_reference(v);
}
DEV unsigned char c512_activation_byte(float accum){
 uint h;asm("v_cvt_pkrtz_f16_f32 %0, %1, %1":"=v"(h):"v"(accum));
 return c512_activation_table[h&65535u];
}
#else
DEV unsigned char c512_activation_byte(float accum){return c512_activation_reference(accum);}
#endif
