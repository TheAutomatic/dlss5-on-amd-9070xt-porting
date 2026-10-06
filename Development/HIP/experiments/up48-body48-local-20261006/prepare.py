"""Single new Up48+Body48 export; independent decoder-half math, existing body byte/residual path."""
from pathlib import Path
import argparse,shutil,json,hashlib
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();r=Path(__file__).resolve().parents[4];shutil.copytree(r/'hip',a.out/'hip',dirs_exist_ok=True)
p=a.out/'hip/wave_owned_mh.inc';s=p.read_text();start=s.index('template<uint C,bool ByteIn,bool ByteOut,bool Up=false');end=s.index('#define W2_KERNEL(',start);b=s[start:end];b=b.replace('swin_wave2_body(', 'swin_up48_body48_local(',1)
u=b.index(' // For fused Up');v=b.index(' }else{\n // Stage original input',u);up=b[u:v]
up=up.replace('H(', 'ub_up_H(').replace('w2_skipF<SkipByte>(', 'ub_up_F(').replace('w2_up_F(', 'ub_up_F(')
up=up.replace('W2_UP_ADD0?w2_add0(merged):ub_up_F(merged)', 'ub_up_add0(merged)')
b=b[:u]+up+b[v:]
b=b.replace('bool SkipByteOut=false>','bool SkipByteOut=false,bool TraceUp=false>',1)
b=b.replace('\n#endif\n ){','\n#endif\n ,unsigned char*up_tap=nullptr ){',1)
needle=' }else{\n // Stage original input'
tap=r'''
 if constexpr(TraceUp){
  w2_sync();
  for(uint qt=0;qt<4;qt++)for(uint ci=0;ci<2;ci++){
   uint tok=qt*16+rc,x=(win%(workw/8))*8+tok%8,y=(win/(workw/8))*8+tok/8;
   if(x>=sx&&y>=sy&&x<sx+width&&y<sy+height){i2 a=w2_load<C>(plane0,qt,head*2+ci);__builtin_memcpy(up_tap+((y-sy)*width+x-sx)*C+head*32+ci*16+gr*8,&a,8);}
  }
  w2_sync();
 }
'''
assert b.count(needle)==1;b=b.replace(needle,tap+needle,1)

helpers=r'''
DEV float ub_up_H(float x){uint h;float y;asm("v_cvt_f16_f32 %0, %1":"=v"(h):"v"(x));asm("v_cvt_f32_f16 %0, %1":"=v"(y):"v"(h));return y;}
DEV float ub_up_F(float x){uint a=bits(x)&0x7fffffffu;float c=__builtin_fminf(__builtin_fmaxf(x,-448.f),448.f);float y=__builtin_amdgcn_cvt_f32_fp8(__builtin_amdgcn_cvt_pk_fp8_f32(c,0.f,0,false),0);return a==0?0.f:y;}
DEV float ub_up_add0(float x){return __builtin_amdgcn_fmed3f(x+0.f,-448.f,448.f);}
'''
s=s[:end]+'\n#ifndef W2_ATTENTION_ONLY\n'+helpers+b+'\n#endif\n'+s[end:]
s+=r'''
#ifndef W2_ATTENTION_ONLY
KERNEL __attribute__((amdgpu_flat_work_group_size(256,256))) void c256_up48_body48_bi_bo_w16_local(const float*low,const float*fw,const float*aw,void*out,uint w,uint h,uint ww,uint hh,uint sx,uint sy,uint post,const float*uw,const float*skip){
 if(w!=120||h!=68||ww!=120||hh!=72||sx||sy||post!=0)return;
 swin_up48_body48_local<256,true,true,true,true>(low,fw,aw,out,w,h,ww,hh,sx,sy,post,uw,skip);
}
#endif
''';s+=r'''
#ifndef W2_ATTENTION_ONLY
KERNEL __attribute__((amdgpu_flat_work_group_size(256,256))) void c256_up48_body48_bi_bo_w16_local_trace(const float*low,const float*fw,const float*aw,void*out,uint w,uint h,uint ww,uint hh,uint sx,uint sy,uint post,const float*uw,const float*skip,unsigned char*tap){
 if(w!=120||h!=68||ww!=120||hh!=72||sx||sy||post!=0)return;
 swin_up48_body48_local<256,true,true,true,true,false,false,false,false,false,true>(low,fw,aw,out,w,h,ww,hh,sx,sy,post,uw,skip,tap);
}
#endif
''';p.write_text(s)
(a.out/'source.json').write_text(json.dumps({'new_inc_sha':hashlib.sha256(s.encode()).hexdigest(),'scope':'only new C256/W16 Up48Body48 export,UpH/F/add0 cloned actual deep decoder not FASTH,originalbody byte residual/norm unchanged,SP not changed','shape':[120,68,120,72,0,0],'wg':256,'matrix_padding':{'new_low_tiles':135,'old_low_tiles':128},'gold_pending':True},indent=2)+'\n')
