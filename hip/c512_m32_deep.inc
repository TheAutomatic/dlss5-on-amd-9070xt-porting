#ifndef C512_MIX_OCC_LDS
#define C512_MIX_OCC_LDS 0 /* bytes of dummy LDS on split_mix_blocked_h16w_m32 (occupancy cap) */
#endif
// C512 split mix (half weights), 32 tokens per wave (opt-in DLSS5_HIP_C512_M32, module c512-m32-deep): each half B
// fragment feeds two WMMAs; per-output K order and F(Hrtz()) epilogue as split_mix_blocked_h16w. results/c512-ffn-20260926.
#ifndef C512_ZERO_PAD_900
#define C512_ZERO_PAD_900 0
#endif
#if C512_ZERO_PAD_900
using c512_u4=uint __attribute__((ext_vector_type(4)));
DEV uint c512_wave_or(uint x){uint lane=__builtin_amdgcn_workitem_id_x();for(uint d=16;d;d>>=1)x|=uint(__builtin_amdgcn_ds_bpermute((lane^d)*4,int(x)));
#if C512_ZERO_PAD_900 == 2
 return __builtin_amdgcn_readfirstlane(x);
#else
 return x;
#endif
}
DEV bool c512_zero_tile(const float*in,const _Float16*w,uint first,uint row){
 uint lane=__builtin_amdgcn_workitem_id_x(),bits_or=0;c512_u4 v;
 // Cheap rejection, then prove every scalar is +/-zero; no assumption about real image pixels.
 __builtin_memcpy(&v,in+first*512+lane*4,16);bits_or=v[0]|v[1]|v[2]|v[3];
 if(c512_wave_or(bits_or&0x7fffffffu))return false;
 _Pragma("clang loop unroll(disable)") for(uint q=32+lane;q<4096;q+=32){__builtin_memcpy(&v,in+first*512+q*4,16);bits_or|=v[0]|v[1]|v[2]|v[3];}
 if(c512_wave_or(bits_or&0x7fffffffu))return false;
 // Zero*Inf/NaN is not zero. Check the actual 64x512 half-weight tile before bypassing the WMMA.
 uint bad=0;
 _Pragma("clang loop unroll(disable)") for(uint q=lane;q<4096;q+=32){__builtin_memcpy(&v,w+row*512+q*8,16);for(uint j=0;j<4;j++)bad|=((v[j]&0x7c007c00u)+0x04000400u)&0x80008000u;}
 return c512_wave_or(bad)==0;
}
#endif
WAVE void split_mix_blocked_h16w_m32(const float*in,const float*w,float*out,uint tokens){
#if C512_MIX_OCC_LDS
 __attribute__((shared)) volatile uint occ_pad[C512_MIX_OCC_LDS/4]; /* occupancy cap only (small-wins O); branch never taken for a real token count */
 if(tokens==0xffffffffu){uint lane=__builtin_amdgcn_workitem_id_x();uint i=(bid()*131u+lane)%(C512_MIX_OCC_LDS/4);occ_pad[i]=i;__builtin_amdgcn_s_barrier();if(occ_pad[(i+1)%(C512_MIX_OCC_LDS/4)]==5u)out[0]=0.f;}
#endif

 uint first=bid()/8*32,row=bid()%8*64;if(first>=tokens)return;const bool two=first+16<tokens;f8 acc0[4]{},acc1[4]{};const _Float16*w16=reinterpret_cast<const _Float16*>(w);
#if C512_ZERO_PAD_900
 const bool suspect=(tokens==1792&&first>=1680)||(tokens==2240&&(first+32<=224||first>=1904));
 if(two&&suspect&&c512_zero_tile(in,w16,first,row)){
  for(uint t=0;t<2;t++)for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)out[(first+t*16+gr()*8+e)*512+row+j*16+rc()]=0.f;
  return;
 }
#endif
 for(uint k=0;k<512;k+=16){h8 a0{},a1{};for(uint e=0;e<8;e++)a0[e]=(_Float16)in[(first+rc())*512+k+gr()*8+e];if(two)for(uint e=0;e<8;e++)a1[e]=(_Float16)in[(first+16+rc())*512+k+gr()*8+e];
  for(uint j=0;j<4;j++){h8 b;__builtin_memcpy(&b,w16+(row+j*16+rc())*512+k+gr()*8,16);acc0[j]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(a0,b,acc0[j]);acc1[j]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(a1,b,acc1[j]);}}
 for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)out[(first+gr()*8+e)*512+row+j*16+rc()]=F(c512_hq(acc0[j][e]));
 if(two)for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)out[(first+16+gr()*8+e)*512+row+j*16+rc()]=F(c512_hq(acc1[j][e]));
}
#ifndef C512_MIX_LDS_G
#define C512_MIX_LDS_G 0 /* >0: add export split_mix_blocked_h16w_m32_lds (32*G threads = G waves on one 64-column row block, each wave the same 32-token tile work as split_mix_blocked_h16w_m32; half-weight 64x64 chunks staged once per group through LDS, double buffered). Same per-wave WMMA chains/K order/epilogue. grid = 8*ceil(ceil(tokens/32)/G). results/c512-ffn-lds-20260930. */
#endif
#ifndef C512_MIX_LDS_U
#define C512_MIX_LDS_U 4 /* unroll of the 4 k16 steps inside a staged chunk */
#endif
#if C512_MIX_LDS_G
static_assert(C512_MIX_LDS_G==4||C512_MIX_LDS_G==2,"4 waves x 4 pieces or 2 waves x 8 pieces = one 8KB chunk");
KERNEL __attribute__((amdgpu_flat_work_group_size(32*C512_MIX_LDS_G,32*C512_MIX_LDS_G))) void split_mix_blocked_h16w_m32_lds(const float*in,const float*w,float*out,uint tokens){
 constexpr uint CH=4;/* chunk = 4 k16 steps x 4 column tiles x 32 lanes x 16B = 8KB = 512 pieces; thread t moves pieces t+i*128 (column tile i) */
 __attribute__((shared)) _Float16 lds[2*4*CH*256];
 const uint t=__builtin_amdgcn_workitem_id_x(),wv=t>>5,lane=t&31,first=(bid()/8*C512_MIX_LDS_G+wv)*32,row=bid()%8*64;
 const bool live=first<tokens,two=first+16<tokens;const _Float16*w16=reinterpret_cast<const _Float16*>(w);
 h8 s0,s1,s2,s3,s4,s5,s6,s7;constexpr uint TS=32*C512_MIX_LDS_G;f8 acc0[4]{},acc1[4]{};
 const _Float16*src=w16+(row+(t&15))*512+((t>>5)&3)*16+((t>>4)&1)*8;/* p=t+i*TS: j=p>>7, kk=(p>>5)&3; for TS=128 + i*16 columns, TS=64 + (i>>1)*16 columns + (i&1)*2 k16 steps */
#define MIXL_OFF(i) (TS==128?(i)*16*512:((i)>>1)*16*512+((i)&1)*32)
#define MIXL_FETCH(kc_) {const _Float16*q=src+(kc_)*CH*16;__builtin_memcpy(&s0,q+MIXL_OFF(0),16);__builtin_memcpy(&s1,q+MIXL_OFF(1),16);__builtin_memcpy(&s2,q+MIXL_OFF(2),16);__builtin_memcpy(&s3,q+MIXL_OFF(3),16);if(TS==64){__builtin_memcpy(&s4,q+MIXL_OFF(4),16);__builtin_memcpy(&s5,q+MIXL_OFF(5),16);__builtin_memcpy(&s6,q+MIXL_OFF(6),16);__builtin_memcpy(&s7,q+MIXL_OFF(7),16);}}
#define MIXL_STASH(sb_) {_Float16*d=lds+(sb_)*(4*CH*256)+t*8;__builtin_memcpy(d,&s0,16);__builtin_memcpy(d+TS*8,&s1,16);__builtin_memcpy(d+2*TS*8,&s2,16);__builtin_memcpy(d+3*TS*8,&s3,16);if(TS==64){__builtin_memcpy(d+4*TS*8,&s4,16);__builtin_memcpy(d+5*TS*8,&s5,16);__builtin_memcpy(d+6*TS*8,&s6,16);__builtin_memcpy(d+7*TS*8,&s7,16);}}
 MIXL_FETCH(0)
#pragma unroll 1
 for(uint kc=0;kc<512/(16*CH);kc++){MIXL_STASH(kc&1)__builtin_amdgcn_s_barrier();if(kc+1<512/(16*CH)){MIXL_FETCH(kc+1)}
  if(live)
#pragma unroll C512_MIX_LDS_U
  for(uint kk=0;kk<CH;kk++){const uint k=(kc*CH+kk)*16;h8 a0{},a1{};for(uint e=0;e<8;e++)a0[e]=(_Float16)in[(first+rc())*512+k+gr()*8+e];if(two)for(uint e=0;e<8;e++)a1[e]=(_Float16)in[(first+16+rc())*512+k+gr()*8+e];
#pragma unroll
   for(uint j=0;j<4;j++){h8 b;__builtin_memcpy(&b,lds+(kc&1)*(4*CH*256)+(j*128+kk*32+lane)*8,16);acc0[j]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(a0,b,acc0[j]);acc1[j]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(a1,b,acc1[j]);}}}
#undef MIXL_FETCH
#undef MIXL_STASH
#undef MIXL_OFF
 if(!live)return;
 for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)out[(first+gr()*8+e)*512+row+j*16+rc()]=F(c512_hq(acc0[j][e]));
 if(two)for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)out[(first+16+gr()*8+e)*512+row+j*16+rc()]=F(c512_hq(acc1[j][e]));
}
#endif
