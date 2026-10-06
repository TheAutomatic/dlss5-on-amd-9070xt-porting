from pathlib import Path
import argparse,importlib.util,json,hashlib
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);r=Path(__file__).resolve().parents[4];sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);row=next(x for x in m.recipe(r/'hip')if x[0]=='vit-stream');s=row[2]
start=s.index('void vit_stream_qkv_frag_bin_w5f8(');body=s[start:]
needle=' for(uint j=0;j<2;j++)for(uint e=0;e<8;e++){float v=acc[j][e];if(part<2){v*=__builtin_amdgcn_rsqf(maxf(sum[e],6.198883056640625e-5f))*scale;}out[(part*tokens+first+gr()*8+e)*1024+row+j*16+rc()]=byte_F(v);}'
assert body.count(needle)==1
new=''' if(tokens==640){
  i2 packed[2]{};for(uint j=0;j<2;j++)for(uint e=0;e<8;e++){float v=acc[j][e];if(part<2){v*=__builtin_amdgcn_rsqf(maxf(sum[e],6.198883056640625e-5f))*scale;}uint b=byte_F(v)&255u;packed[j][e/4]=int(uint(packed[j][e/4])|(b<<(8*(e%4))));}
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
 }else{'''+needle+'\n }'
changed=s[:start]+body.replace(needle,new,1);(a.output/'old.hip').write_text(s);(a.output/'new.hip').write_text(changed)
(a.output/'source.json').write_text(json.dumps({'compiler':row[1]or'COMGR','row':row[0],'defines':row[3],'opts':row[-1],'oldSHA':hashlib.sha256(s.encode()).hexdigest(),'newSHA':hashlib.sha256(changed.encode()).hexdigest(),'scope':'sole active bin_w5f8 tail, tokens640; originalquant math+producerAoS preserved, non640oldfallback;16DS plus byteperm/mask and dependencies, no new LDS/barrier'},indent=2)+'\n')
