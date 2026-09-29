// Append to production c512-m32-mh sources. Only the final attention projection.
#ifndef C512_PROJECTION_M32
#define C512_PROJECTION_M32 0
#endif
#if C512_PROJECTION_M32
FASTWAVE void mh_attention_project_frag_c512_m32(const unsigned char*av8,const float*feature,const float*w,float*out,uint tokens,uint post,uint cropw,uint croph,uint workw,uint sx,uint sy){
 const uint C=512,l=__builtin_amdgcn_workitem_id_x(),rc=l&15,g=l>>4;
 uint block=__builtin_amdgcn_workgroup_id_x(),first=block/8*32,col=block%8*64;if(first>=tokens)return;
 const unsigned char*wb=reinterpret_cast<const unsigned char*>(w)+size_t(3)*C*C*4;
 const uint skip=4*C*C+(C/32)*4096+C/32;
 f8 acc[2][4];
 // Same per-element Hrtz(feature*scale), before the K reduction. Read each scale once for both tiles.
 _Pragma("unroll") for(uint n=0;n<4;n++){
  uint c=col+n*16+rc;float scale=w[skip+c];
  _Pragma("unroll") for(uint m=0;m<2;m++)for(uint e=0;e<8;e++){
   uint p=first+m*16+g*8+e;acc[m][n][e]=p<tokens?Hrtz(feature[p*C+c]*scale):0.f;
  }
 }
 for(uint k=0;k<C;k+=32){uint gs=k/32;
  for(uint h=0;h<2;h++){
   i2 a[2]{};
   _Pragma("unroll") for(uint m=0;m<2;m++)if(first+m*16+rc<tokens)__builtin_memcpy(&a[m],av8+(first+m*16+rc)*C+g*8+k+h*16,8);
   _Pragma("unroll") for(uint n=0;n<4;n++){
    uint n0=col+n*16+rc;i2 b;__builtin_memcpy(&b,wb+((n0/16)*16+gs)*512+((h*2+g)*16+n0%16)*8,8);
    _Pragma("unroll") for(uint m=0;m<2;m++)acc[m][n]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(a[m],b,acc[m][n]);
   }
  }
 }
 _Pragma("unroll") for(uint m=0;m<2;m++)for(uint n=0;n<4;n++)for(uint e=0;e<8;e++){
  uint p=first+m*16+g*8+e,c=col+n*16+rc;if(p>=tokens)continue;
  float a=acc[m][n][e],v=post==3?Hrtz(a):post==4?F(a):F(Hrtz(a));uint dest=p*C+c;
  if(cropw){uint x=p%workw,y=p/workw;if(x<sx||y<sy||x>=sx+cropw||y>=sy+croph)continue;dest=((y-sy)*cropw+x-sx)*C+c;}
  out[dest]=v;
 }
}
#endif
