
KERNEL __attribute__((amdgpu_flat_work_group_size(32,32))) void qkv_store_byte_gold(const unsigned char*in,unsigned char*out){
 uint lane=__builtin_amdgcn_workitem_id_x(),part=0,tokens=16,first=0,row=7*32;
 i2 packed[2]{};for(uint j=0;j<2;j++)for(uint e=0;e<8;e++){uint b=in[(lane/16*8+e)*1024+row+j*16+lane%16];packed[j][e/4]=int(uint(packed[j][e/4])|(b<<(8*(e%4))));}
  for(uint j=0;j<2;j++){
   uint p0=uint(packed[j][0]),p1=uint(packed[j][1]);
   for(uint bit=0;bit<2;bit++){
    uint src=(lane^(1u<<bit))*4;
    uint r0=uint(__builtin_amdgcn_ds_bpermute(src,int(p0))),r1=uint(__builtin_amdgcn_ds_bpermute(src,int(p1)));
    uint x0,x1,mask;
    if(bit==0){x0=((r0&0x00ff00ffu)<<8)|((r0&0xff00ff00u)>>8);x1=((r1&0x00ff00ffu)<<8)|((r1&0xff00ff00u)>>8);mask=(lane&1)?0x00ff00ffu:0xff00ff00u;}
    else{x0=(r0<<16)|(r0>>16);x1=(r1<<16)|(r1>>16);mask=(lane&2)?0x0000ffffu:0xffff0000u;}
    p0=(p0&~mask)|(x0&mask);p1=(p1&~mask)|(x1&mask);
   }
   uint r0=uint(__builtin_amdgcn_ds_bpermute((lane^4u)*4,int(p1))),r1=uint(__builtin_amdgcn_ds_bpermute((lane^4u)*4,int(p0)));
   uint n0=(lane&4)?r0:p0,n1=(lane&4)?p1:r1;
   uint src=((lane&7)|((lane&8)<<1)|((lane&16)>>1))*4;
   i2 words{__builtin_amdgcn_ds_bpermute(src,int(n0)),__builtin_amdgcn_ds_bpermute(src,int(n1))};
   __builtin_memcpy(out+size_t(part*tokens+first+lane%16)*1024+row+j*16+(lane/16)*8,&words,8);
  }
}
