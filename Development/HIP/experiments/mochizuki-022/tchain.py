from pathlib import Path
import shutil,subprocess,sys
root=Path(__file__).resolve().parents[4];out=Path('/tmp/mochizuki-022');hip=out/'hip';host=Path('/tmp/mochizuki-022-tchain')
(hip/'c512_m32_deep.inc').write_text((root/'hip/c512_m32_deep.inc').read_text())
helper='''
#ifndef HIP_TILE_CHAIN
#define HIP_TILE_CHAIN 0
#endif
#ifndef HIP_TILE_CHAIN_RELAXED
#define HIP_TILE_CHAIN_RELAXED 0
#endif
#if HIP_TILE_CHAIN
#if HIP_TILE_CHAIN_RELAXED
#define TC_FLAG_LOAD __ATOMIC_RELAXED
#define TC_FLAG_PUB __ATOMIC_RELAXED
#else
#define TC_FLAG_LOAD __ATOMIC_ACQUIRE
#define TC_FLAG_PUB __ATOMIC_RELEASE
#endif
DEV void tc_signal(uint*f,uint tile){__builtin_amdgcn_fence(__ATOMIC_RELEASE,"agent");__builtin_amdgcn_s_barrier();if(__builtin_amdgcn_workitem_id_x()==0)__hip_atomic_fetch_add(f+tile,1u,TC_FLAG_PUB,__HIP_MEMORY_SCOPE_AGENT);}
DEV void tc_wait(const uint*f,uint target,uint first,uint count){if(__builtin_amdgcn_workitem_id_x()==0){for(uint i=0;i<count;i++)while(__hip_atomic_load(f+first+i,TC_FLAG_LOAD,__HIP_MEMORY_SCOPE_AGENT)<target)__builtin_amdgcn_s_sleep(1);}__builtin_amdgcn_s_barrier();
#if HIP_TILE_CHAIN_RELAXED
 asm volatile("":::"memory"); // same relaxed polling model as existing PDL; prevent compiler load hoisting
#else
 __builtin_amdgcn_fence(__ATOMIC_ACQUIRE,"agent");
#endif
}
#endif
'''

def kernel(s,name):
 a=s.index('void '+name+'(');a=s.rfind('\n',0,a)+1;b=s.index('{',a);depth=1;i=b+1
 while depth:
  depth+=(s[i]=='{')-(s[i]=='}');i+=1
 return s[a:i]
# Twins preserve original signatures and defaults. Only new exports use the protocol.
s=(root/'hip/deep_fast.hip').read_text();k=kernel(s,'split_projection_frag').replace('split_projection_frag(','split_projection_frag_tc(').replace('uint tokens){','uint tokens,uint*tc_out){');k=k[:-1]+'tc_signal(tc_out,first/16);\n}'
(hip/'deep_fast.hip').write_text(s+helper+'\n#if HIP_TILE_CHAIN\n'+k+'\n#endif\n')
s=(root/'hip/c512_m32_mh.inc').read_text();k=kernel(s,'mh_qkv_normalize_frag_c512_m32').replace('mh_qkv_normalize_frag_c512_m32(','mh_qkv_normalize_frag_c512_m32_tc(').replace('uint tokens){','uint tokens,const uint*tc_flags,uint tc_target){');k=k.replace('const bool two=first+16<tokens;','const bool two=first+16<tokens;tc_wait(tc_flags,tc_target,first/16,two?2:1);');(hip/'c512_m32_mh.inc').write_text(s+helper+'\n#if HIP_TILE_CHAIN\n'+k+'\n#endif\n')
s=(root/'hip/vit_stream.inc').read_text();producer='''WAVE void vit_stream_contract_frag_hout_tc(const float*in,const float*w,const float*skip,float*out,uint tokens,uint inputs,uint outputs,uint*tc_out,const uint*reuse_gate){uint first=bid()/16*16;if(first>=tokens)return;if(!(reuse_gate&&reuse_gate[0])){if(inputs==4096&&outputs==1024)vit_contract_blocked_body<false,false,false,true,true>(in,w,skip,out,tokens);}tc_signal(tc_out,first/16);}'''
k=kernel(s,'vit_stream_qkv_frag_hin').replace('vit_stream_qkv_frag_hin(','vit_stream_qkv_frag_hin_tc(').replace('uint tokens,const uint*reuse_gate','uint tokens,const uint*tc_flags,uint tc_target,const uint*reuse_gate');k=k.replace('if(part>=3)return;','if(part>=3)return;tc_wait(tc_flags,tc_target,first/16,1);')
# Helper comes from the concatenated deep_fast.hip in this module.
(hip/'vit_stream.inc').write_text(s+'\n#if HIP_TILE_CHAIN && HIP_VIT_STREAM_KERNELS\n'+producer+'\n'+k+'\n#endif\n')
for d in ('src','Development/HIP'):
 (host/d).mkdir(parents=True,exist_ok=True)
 for p in (root/d).glob('*.h'):shutil.copy2(p,host/d/p.name)
p=host/'Development/HIP/hip_reference_network.h';s=p.read_text();s=s.replace('class Network {','class Network {\n bool tc_c512=false,tc_vit=false;unsigned tc512_calls=0,tcvit_calls=0,tc_wraps=0;\n',1)
s=s.replace('wave_owned_active=WaveOwnedCompatible(opt);','tc_c512=opt.pdl&&(opt.modules.find("modules-S")!=std::string::npos||opt.modules.find("modules-T")!=std::string::npos);tc_vit=opt.pdl&&(opt.modules.find("modules-V")!=std::string::npos||opt.modules.find("modules-T")!=std::string::npos||opt.modules.find("modules-F")!=std::string::npos);wave_owned_active=WaveOwnedCompatible(opt);',1)
s=s.replace('~Network(){api.hipStreamSynchronize(stream);','~Network(){api.hipStreamSynchronize(stream);printf("TCHAIN c512=%u vit=%u wraps=%u\\n",tc512_calls,tcvit_calls,tc_wraps);',1)
s=s.replace('if(pdl_total[s]>std::numeric_limits<unsigned>::max()-waves){','''#ifndef TC_WRAP_LIMIT
#define TC_WRAP_LIMIT 4294967295u
#endif
  const unsigned limit=kind>=2?TC_WRAP_LIMIT:std::numeric_limits<unsigned>::max();
  if(pdl_total[s]>limit-waves){if(kind>=2)++tc_wraps;''',1)
needle='if(opt.c512_proj_tiles)Run("deep","split_projection_frag",size_t(n)*512,P(contract8),PackedSplitProjectionFrag(Block(block,"ffwd-projection")),P(packed),P(ffn),P(ffn8),n);';assert s.count(needle)==1
s=s.replace(needle,'''unsigned*tc_flags=nullptr;unsigned tc_target=0;
if(tc_c512&&c512_m32_active&&opt.c512_proj_tiles){tc_flags=PdlSlot(2,512,ww,hh,8);tc_target=pdl_last_target;Run("deep","split_projection_frag_tc",size_t(n)*512,P(contract8),PackedSplitProjectionFrag(Block(block,"ffwd-projection")),P(packed),P(ffn),P(ffn8),n,tc_flags);++tc512_calls;}else '''+needle,1)
needle='if(c512_m32_active)Run("c512_m32_mh","mh_qkv_normalize_frag_c512_m32",size_t((n+31)/32*32)*768,P(ffn8),PackedMhWeightQkvFrag(Block(block,"attention"),512),P(producer_norm),n);';assert s.count(needle)==1
s=s.replace(needle,'''if(tc_flags){pdl_anyorder=true;Run("c512_m32_mh","mh_qkv_normalize_frag_c512_m32_tc",size_t((n+31)/32*32)*768,P(ffn8),PackedMhWeightQkvFrag(Block(block,"attention"),512),P(producer_norm),n,(const unsigned*)tc_flags,tc_target);pdl_anyorder=false;}else '''+needle,1)
# Thread/grid rules for the new projection preserve the original shape.
s=s.replace('if(module=="mh_window"){groups=count;threads=256;}','if(kernel=="split_projection_frag_tc"){groups=count/1024;threads=32;}\n  if(module=="mh_window"){groups=count;threads=256;}',1)
needle='if(opt.vit_contract_frag&&opt.vit_contract_blocked)Run("deep",(vit_stream_active&2)?"vit_stream_contract_frag_hout":"vit_contract_blocked_fp8_frag",size_t(n)*1024,P(hidden),PackedVitWeight(Block(block,"contract"),1024,4096,true,true),P(input),P(contract),n,U(4096),U(1024));';assert s.count(needle)==1
# These local fields only span contract -> QKV in this ViT call, with the next attention as an ordinary barrier.
s=s.replace('std::string expand_name="vit_expand_blocked_fp8";','Tensor vtc_keep;unsigned*vtc_flags=nullptr;unsigned vtc_target=0;std::string expand_name="vit_expand_blocked_fp8";',1)
s=s.replace(needle,'''if(tc_vit&&(vit_stream_active&2)&&opt.vit_contract_frag&&opt.vit_contract_blocked){vtc_flags=PdlSlot(3,1024,n,1,16);vtc_target=pdl_last_target;vtc_keep=hidden;Run("vit_stream","vit_stream_contract_frag_hout_tc",size_t(n)*1024,P(hidden),PackedVitWeight(Block(block,"contract"),1024,4096,true,true),P(input),P(contract),n,U(4096),U(1024),vtc_flags);++tcvit_calls;}else '''+needle,1)
needle='if(opt.vit_qkv_fused)Run("deep",opt.vit_qkv_fp8?';assert s.count(needle)==1
s=s.replace(needle,'''if(vtc_flags){pdl_anyorder=true;Run("vit_stream","vit_stream_qkv_frag_hin_tc",size_t(n)*3072,P(contract),qw,P(norm),n,(const unsigned*)vtc_flags,vtc_target);pdl_anyorder=false;}else '''+needle,1)
s=s.replace('if(kernel=="vit_stream_contract_frag_hout")','if(kernel=="vit_stream_contract_frag_hout"||kernel=="vit_stream_contract_frag_hout_tc")').replace('if(kernel=="vit_stream_qkv_frag_hin")','if(kernel=="vit_stream_qkv_frag_hin"||kernel=="vit_stream_qkv_frag_hin_tc")')
needle='auto qw=(opt.vit_qkv_fused&&opt.packed_weights)?'
assert s.count(needle)==1
s=s.replace(needle,'if(vtc_flags&&P(vtc_keep)==P(norm))throw std::runtime_error("TC hidden/norm alias");'+needle,1)
if '--unsafe-no-keep' in sys.argv:
 s=s.replace('vtc_keep=hidden;','').replace('if(vtc_flags&&P(vtc_keep)==P(norm))','if(vtc_flags&&vtc_keep&&P(vtc_keep)==P(norm))')
p.write_text(s)
shutil.copy2(root/'Development/HIP/benchmark_vit_reuse.cpp',host/'Development/HIP/benchmark.cpp')
if '--sources-only' in sys.argv:sys.exit(0)
names=[('benchmark-fast.exe',[]),('benchmark-fast-wrap.exe',['-DTC_WRAP_LIMIT=64'])] if '--fast' in sys.argv else [('benchmark-tc.exe',[]),('benchmark-wrap.exe',['-DTC_WRAP_LIMIT=64'])]
for name,defs in names:
 subprocess.run(['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-municode',*defs,'-I',str(host/'src'),'-I',str(host/'Development/HIP'),str(host/'Development/HIP/benchmark.cpp'),'-o',str(out/name),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid'],check=True)
