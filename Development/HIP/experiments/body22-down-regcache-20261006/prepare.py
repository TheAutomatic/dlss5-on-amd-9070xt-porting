"""One uniform8word/lane cache variant; two barriers, dead plane0 reuse, unchanged ABI/math."""
from pathlib import Path
import argparse,shutil,json,hashlib
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();base=Path('/tmp/body22-down-local-20261006/new');shutil.copytree(base,a.out/'hip',dirs_exist_ok=True)
p=a.out/'hip/wave_owned_mh.inc';s=p.read_text();start=s.index('DEV void swin_wave2_body_down_local(');end=s.index('\n#endif\n#define W2_KERNEL',start);b=s[start:end]
b=b.replace(' __attribute__((shared)) _Float16 dpool[DownLocal?16*(C+8):1];',''' uint dc0a=0,dc0b=0,dc1a=0,dc1b=0,dc2a=0,dc2b=0,dc3a=0,dc3b=0;
 _Float16*dpool=reinterpret_cast<_Float16*>(plane0);''',1)
old=b[b.index('   for(uint ci=0;ci<2;ci++)for(uint e=0;e<8;e++){'):b.index('\n  }\n };',b.index(' auto down_capture='))]
new='''   uint words[8]{};
   for(uint ci=0;ci<2;ci++)for(uint e=0;e<8;e++){
    float v=Hrtz(result[ci][e]);float peer=value(__builtin_amdgcn_ds_bpermute((l^1u)*4,bits(v)));
    float pair=dl_pool_H(v+peer);float other=value(__builtin_amdgcn_ds_bpermute((l^8u)*4,bits(pair)));
    float pooled=dl_pool_F(dl_pool_H(dl_pool_H(pair+other)*.25f));
    uint q=rc/2,z=qt*4+q;int px=int((win%(workw/8))*4+z%4)-int(sx/2),py=int((win/(workw/8))*4+z/4)-int(sy/2);
    _Float16 ph=(_Float16)((px>=0&&py>=0&&px<int(width/2)&&py<int(height/2))?pooled:0.f);
    uint hb=__builtin_bit_cast(unsigned short,ph);words[ci*4+e/2]|=hb<<(16*(e&1));
   }
   uint owner=2*(l&3)+16*((l>>3)&1),w0=4*(l>>4)+2*((l>>2)&1);
   // Gather fixed registers at source; destination selects its two words.
   uint v0=__builtin_amdgcn_ds_bpermute(owner*4,words[0]),v1=__builtin_amdgcn_ds_bpermute(owner*4,words[1]);
   uint v2=__builtin_amdgcn_ds_bpermute(owner*4,words[2]),v3=__builtin_amdgcn_ds_bpermute(owner*4,words[3]);
   uint v4=__builtin_amdgcn_ds_bpermute(owner*4,words[4]),v5=__builtin_amdgcn_ds_bpermute(owner*4,words[5]);
   uint v6=__builtin_amdgcn_ds_bpermute(owner*4,words[6]),v7=__builtin_amdgcn_ds_bpermute(owner*4,words[7]);
   uint ca=w0==0?v0:w0==2?v2:w0==4?v4:v6,cb=w0==0?v1:w0==2?v3:w0==4?v5:v7;
   if(qt==0){dc0a=ca;dc0b=cb;}else if(qt==1){dc1a=ca;dc1b=cb;}else if(qt==2){dc2a=ca;dc2b=cb;}else{dc3a=ca;dc3b=cb;}
'''
b=b.replace(old,new,1)
needle=' if constexpr(DownLocal){\n  WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);'
# Last use of original planes is complete only after all headwaves pass reuse barrier.
repl=''' if constexpr(DownLocal){
  WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);
  uint l=__builtin_amdgcn_workitem_id_x()%32,q=l&3,ch=head*32+(l>>4)*16+((l>>3)&1)*8+((l>>2)&1)*4;
  uint*dp=reinterpret_cast<uint*>(dpool);
  dp[((0*4+q)*(C+8)+ch)/2]=dc0a;dp[((0*4+q)*(C+8)+ch)/2+1]=dc0b;
  dp[((1*4+q)*(C+8)+ch)/2]=dc1a;dp[((1*4+q)*(C+8)+ch)/2+1]=dc1b;
  dp[((2*4+q)*(C+8)+ch)/2]=dc2a;dp[((2*4+q)*(C+8)+ch)/2+1]=dc2b;
  dp[((3*4+q)*(C+8)+ch)/2]=dc3a;dp[((3*4+q)*(C+8)+ch)/2+1]=dc3b;
  WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);'''
assert b.count(needle)==1;b=b.replace(needle,repl);b=b.replace('__attribute__((shared)) unsigned char plane0[64*C],plane1[64*C];','__attribute__((shared,aligned(16))) unsigned char plane0[64*C],plane1[64*C];',1)
s=s[:start]+b+s[end:];p.write_text(s)
(a.out/'source.json').write_text(json.dumps({'base':'/tmp/body22-down-local-20261006/new','new_inc_sha':hashlib.sha256(s.encode()).hexdigest(),'scope':'sole new fusion export body clone;8explicitu32/lane cache;old plane0 reused after added WGbarrier;extra8fixedwordgather/qt;noqtunrollchange;math/raw/ABI unchanged','gold_pending':True},indent=2)+'\n')
