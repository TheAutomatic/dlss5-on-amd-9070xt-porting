"""Isolated Body22 raw-F32 plus independent nonFAST Down epilogue. No host route."""
from pathlib import Path
import argparse,shutil,json,hashlib
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();r=Path(__file__).resolve().parents[4]
for side in ('old','new'):shutil.copytree(r/'hip',a.out/side,dirs_exist_ok=True)
p=a.out/'new/wave_owned_mh.inc';s=p.read_text()
start=s.index('template<uint C,bool ByteIn,bool ByteOut,bool Up=false');end=s.index('#define W2_KERNEL(',start);b=s[start:end]
b=b.replace('bool SkipByteOut=false>','bool SkipByteOut=false,bool DownLocal=false>',1)
b=b.replace(' ,uint supplied_win=0\n#endif\n ){',' ,uint supplied_win=0\n#endif\n ,const float*downw=nullptr,float*downout=nullptr ){',1)
# Default W2_EXPLICIT_WINDOW=0 recipe; keep the exact existing parameter tail.
if 'const float*downw=' not in b:
 b=b.replace('\n#endif\n ){','\n#endif\n ,const float*downw=nullptr,float*downout=nullptr ){',1)
assert 'const float*downw=' in b
needle=' __attribute__((shared)) unsigned char plane0[64*C],plane1[64*C];'
extra=r'''
#ifndef W2_ATTENTION_ONLY
 __attribute__((shared)) _Float16 dpool[DownLocal?16*(C+8):1];
 auto down_capture=[&](f8*result,uint qt){
  if constexpr(DownLocal){
   const uint l=__builtin_amdgcn_workitem_id_x()%32;
   for(uint ci=0;ci<2;ci++)for(uint e=0;e<8;e++){
    float v=Hrtz(result[ci][e]);
    float peer=value(__builtin_amdgcn_ds_bpermute((l^1u)*4,bits(v)));
    float pair=dl_pool_H(v+peer);
    float other=value(__builtin_amdgcn_ds_bpermute((l^8u)*4,bits(pair)));
    float pooled=dl_pool_F(dl_pool_H(dl_pool_H(pair+other)*.25f));
    if(rc<8&&!(rc&1u)){
     uint z=qt*4+rc/2;int px=int((win%(workw/8))*4+z%4)-int(sx/2),py=int((win/(workw/8))*4+z/4)-int(sy/2);
     dpool[z*(C+8)+head*32+ci*16+gr*8+e]=(_Float16)((px>=0&&py>=0&&px<int(width/2)&&py<int(height/2))?pooled:0.f);
    }
   }
  }
 };
#endif
'''
assert b.count(needle)==1;b=b.replace(needle,needle+extra)
# The two mutually exclusive projection spellings (full-window specialized / ordinary).
proj=b.index(' auto finish=')
pre,tail=b[:proj],b[proj:]
needle='#if W2_DIRECT_COORDS\n';assert tail.count(needle)==2
tail=tail.replace(needle,'#ifndef W2_ATTENTION_ONLY\n down_capture(result,qt);\n#endif\n'+needle)
append=r'''
#ifndef W2_ATTENTION_ONLY
 if constexpr(DownLocal){
  WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);
  const _Float16*w16=reinterpret_cast<const _Float16*>(downw);f8 acc[4]{};
  for(uint chunk=0;chunk<C/32;chunk++){f8 sum[4]{};
   for(uint half=0;half<2;half++){uint si=chunk*2+half;h8 av;__builtin_memcpy(&av,dpool+rc*(C+8)+si*16+gr*8,16);
    for(uint j=0;j<4;j++){h8 wv;uint nt=head*4+j;__builtin_memcpy(&wv,w16+(nt*(C/16)+si)*256+(gr*16+rc)*8,16);sum[j]=__builtin_amdgcn_wmma_f32_16x16x16_f16_w32_gfx12(av,wv,sum[j]);}}
   for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)acc[j][e]=dl_pool_H(acc[j][e]+sum[j][e]);
  }
  for(uint j=0;j<4;j++)for(uint e=0;e<8;e++){
   uint z=gr*8+e;int px=int((win%(workw/8))*4+z%4)-int(sx/2),py=int((win/(workw/8))*4+z/4)-int(sy/2);
   if(px>=0&&py>=0&&px<int(width/2)&&py<int(height/2))downout[(uint(py)*(width/2)+uint(px))*(2*C)+head*64+j*16+rc]=dl_pool_F(acc[j][e]);
  }
 }
#endif
'''
# Closing #endif terminates projection alternative; append before original body close.
b=pre+tail;pos=b.rfind('\n}');assert pos>0;b=b[:pos]+append+b[pos:]
helpers=r'''
// Independent normalpacked pool helpers; Body FAST H/Hrtz cannot substitute these.
DEV float dl_pool_H(float x){uint h;float y;asm("v_cvt_f16_f32 %0, %1":"=v"(h):"v"(x));asm("v_cvt_f32_f16 %0, %1":"=v"(y):"v"(h));return y;}
DEV float dl_pool_F(float x){uint a=bits(x)&0x7fffffffu;float c=__builtin_amdgcn_fmed3f(x,-448.f,448.f);float y=__builtin_amdgcn_cvt_f32_fp8(__builtin_amdgcn_cvt_pk_fp8_f32(c,0.f,0,false),0);return a==0?0.f:y;}
'''
s=s[:end]+'\n#ifndef W2_ATTENTION_ONLY\n'+helpers+b.replace('swin_wave2_body(', 'swin_wave2_body_down_local(',1)+'\n#endif\n'+s[end:]
s+=r'''
#ifndef W2_ATTENTION_ONLY
KERNEL __attribute__((amdgpu_flat_work_group_size(256,256))) void c256_wave2_bi_w16_down_local(const float*in,const float*fw,const float*aw,float*raw,uint w,uint h,uint ww,uint hh,uint sx,uint sy,uint post,const float*dw,float*dout){
 if(w!=120||h!=68||ww!=120||hh!=72||sx!=0||sy!=4||post!=3)return;
 swin_wave2_body_down_local<256,true,false,false,true,false,false,false,false,false,true>(in,fw,aw,raw,w,h,ww,hh,sx,sy,post,nullptr,nullptr,dw,dout);
}
#endif
'''
p.write_text(s)
(a.out/'source.json').write_text(json.dumps({'scope':'new optional ordinary Body22 export only; no host route/SP/recovery; raw F32 preserved; independent normal Down H/F; pooledLDS8448 and128DS/wave costs','old_inc_sha':hashlib.sha256((a.out/'old/wave_owned_mh.inc').read_bytes()).hexdigest(),'new_inc_sha':hashlib.sha256(s.encode()).hexdigest(),'shape':[120,68,120,72,0,4],'gold_pending':True},indent=2)+'\n')
