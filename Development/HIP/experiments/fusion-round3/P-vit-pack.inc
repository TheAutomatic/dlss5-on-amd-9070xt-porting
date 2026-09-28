// Optional byte edge on the existing n64 projection. Keep float outputs for residuals,
// AE statistics and the final gather; the byte copy feeds only the next expand.
#ifndef HIP_VIT_PACK_STREAM
#define HIP_VIT_PACK_STREAM 0
#endif
#if HIP_VIT_PACK_STREAM
template<uint TM,uint TN,bool ByteAv,bool HalfSkip>
DEV void vit_stream_project_tiles_pack(const float*in,const float*w,const float*skip,float*out,unsigned char*out8,uint tokens,const uint*reuse_gate){if(reuse_gate&&reuse_gate[0])return;
 constexpr uint IN=1024,OUT=1024;
 uint first=bid()/(OUT/(16*TN))*(16*TM),row=bid()%(OUT/(16*TN))*(16*TN);if(first>=tokens)return;
 uint live=0;
#pragma unroll
 for(uint t=0;t<TM;t++)live+=first+t*16<tokens;
 const unsigned char*wf=reinterpret_cast<const unsigned char*>(w);
 f8 total[TM][TN]{};
 for(uint p=0;p<4;p++){f8 a[TM][TN]{};
  if(!p)
#pragma unroll
  for(uint t=0;t<TM;t++)for(uint j=0;j<TN;j++)if(t<live)for(uint e=0;e<8;e++)a[t][j][e]=H((HalfSkip?float(reinterpret_cast<const _Float16*>(skip)[(first+t*16+gr()*8+e)*OUT+row+j*16+rc()]):skip[(first+t*16+gr()*8+e)*OUT+row+j*16+rc()])*w[IN*OUT+row+j*16+rc()]);
  for(uint k=p*(IN/4);k<(p+1)*(IN/4);k+=16){i2 x[TM];
#pragma unroll
   for(uint t=0;t<TM;t++){x[t]=i2{};if(t<live){if constexpr(ByteAv)__builtin_memcpy(&x[t],reinterpret_cast<const unsigned char*>(in)+(first+t*16+rc())*IN+k+gr()*8,8);else {DF_PACK8_LOOP(x[t],in[(first+t*16+rc())*IN+k+gr()*8+e]);}}}
#pragma unroll
   for(uint j=0;j<TN;j++){uint r0=row+j*16;i2 y;__builtin_memcpy(&y,wf+((r0/16)*(IN/32)+k/32)*512+((((k%32)/16)*2+gr())*16+rc())*8,8);
#pragma unroll
    for(uint t=0;t<TM;t++)a[t][j]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(x[t],y,a[t][j]);}}
#pragma unroll
  for(uint t=0;t<TM;t++)
#pragma unroll
  for(uint j=0;j<TN;j++)for(uint e=0;e<8;e++)total[t][j][e]=p?total[t][j][e]+a[t][j][e]:a[t][j][e];}
#pragma unroll
 for(uint t=0;t<TM;t++){if(t>=live)continue;for(uint j=0;j<TN;j++)for(uint e=0;e<8;e++){uint i=(first+t*16+gr()*8+e)*OUT+row+j*16+rc();float v=F(H(total[t][j][e]));out[i]=v;out8[i]=static_cast<unsigned char>(__builtin_amdgcn_cvt_pk_fp8_f32(v,0.f,0,false));}}
}

WAVE void vit_stream_project_n64_bh_pack(const float*in,const float*w,const float*skip,float*out,unsigned char*out8,uint tokens,uint inputs,uint outputs,const uint*reuse_gate){vit_stream_project_tiles_pack<1,4,true,true>(in,w,skip,out,out8,tokens,reuse_gate);}
// Gather still emits the unchanged float boundary used by AE. Packing here is
// before AE's decision, so no gate may suppress the float boundary.
KERNEL __attribute__((amdgpu_flat_work_group_size(256,256)))
void vit_stream_gather_pack(const float*in,const uint*map,float*out,uint*out8,uint count,const uint*reuse_gate){
 uint word=bid()*256+__builtin_amdgcn_workitem_id_x(),i=word*4;if(i>=count)return;
 float x0=in[map[i]],x1=in[map[i+1]],x2=in[map[i+2]],x3=in[map[i+3]];
 out[i]=x0;out[i+1]=x1;out[i+2]=x2;out[i+3]=x3;
 uint p0=uint(__builtin_amdgcn_cvt_pk_fp8_f32(clampf(x0,-448.f,448.f),clampf(x1,-448.f,448.f),0,false));
 uint p1=uint(__builtin_amdgcn_cvt_pk_fp8_f32(clampf(x2,-448.f,448.f),clampf(x3,-448.f,448.f),0,false));
 out8[word]=(p0&65535u)|((p1&65535u)<<16);
}
#endif
