
#ifndef VIT_CONTRACT_T32_W2
#define VIT_CONTRACT_T32_W2 0
#endif
#if HIP_VIT_STREAM_KERNELS && VIT_CONTRACT_BYTE_EDGE && VIT_QKV_F8W && VIT_CONTRACT_T32_W2
// Two independent token waves share each K512 weight segment. Each output's
// original four K1024 partials, ascending K16 chain, skip and F/H remain intact.
KERNEL __attribute__((amdgpu_flat_work_group_size(64,64)))
void vit_stream_contract_frag_bout_t32w2(const float*in,const float*w,const float*skip,float*out,uint tokens,uint inputs,uint outputs,const uint*reuse_gate){
 if(reuse_gate&&reuse_gate[0])return;if(tokens!=960||inputs!=4096||outputs!=1024)return;
 uint tid=__builtin_amdgcn_workitem_id_x(),wave=tid/32,r=tid&15u,g=(tid>>4)&1u;
 uint first=bid()/16*32+wave*16,col=bid()%16*64;
 __attribute__((shared)) uint wt[8192];const uint*ip=reinterpret_cast<const uint*>(in),*wp=reinterpret_cast<const uint*>(w);
 f8 total[4]{};for(uint j=0;j<4;j++)for(uint e=0;e<8;e++){uint c=col+j*16+r;total[j][e]=VIT_FAST_H(skip[(first+g*8+e)*1024+c]*w[4194304+c]);}
 for(uint part=0;part<4;part++){f8 acc[4]{};
  for(uint segment=0;segment<2;segment++){
   uint base=part*1024+segment*512;
   // Every wave has finished reading the previous segment before any lane overwrites it.
   if(part||segment){WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);}
   _Pragma("clang loop unroll(disable)") for(uint i=tid;i<8192;i+=64){uint j=i/2048,within=i%2048;wt[i]=wp[(col/16+j)*16384+(base/32)*128+within];}
   WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);
   for(uint kk=0;kk<512;kk+=16){uint k=base+kk,off=((first+r)*4096+k+g*8)/4;i2 a={int(ip[off]),int(ip[off+1])};
    for(uint j=0;j<4;j++){uint wo=((j*16+kk/32)*512+((((kk%32)/16)*2+g)*16+r)*8)/4;i2 b={int(wt[wo]),int(wt[wo+1])};acc[j]=__builtin_amdgcn_wmma_f32_16x16x16_fp8_fp8_w32_gfx12(a,b,acc[j]);}
   }
  }
  for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)total[j][e]+=acc[j][e];
 }
 for(uint j=0;j<4;j++)for(uint e=0;e<8;e++){uint i=(first+g*8+e)*1024+col+j*16+r;reinterpret_cast<unsigned char*>(out)[i]=vit_contract_F_byte(VIT_FAST_H(total[j][e]));}
}
#endif
