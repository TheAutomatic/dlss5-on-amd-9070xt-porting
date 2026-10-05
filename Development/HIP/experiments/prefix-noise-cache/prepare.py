#!/usr/bin/env python3
"""Generate isolated current C32 variants and host. Never edit production files."""
import argparse, hashlib, importlib.util, json, pathlib, sys
sys.dont_write_bytecode=True
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[3]

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def main(out):
 out.mkdir(parents=True,exist_ok=True)
 inc=(ROOT/'hip/wave_owned_c32.inc').read_text()
 begin=inc.index('    uint h=production_pcg(',inc.index('#if CW_PREFIX_SPLIT'))
 end=inc.index('    cw_pv_t g0=cw_prefix_shuffle',begin)
 original=inc[begin:end]
 cache=r'''    cw_pv_t gc,gs;
    if constexpr(CachedNoise){uint packed=noise_cache[rgbp*2+g];
#if CW_PREFIX_HALF_SOURCE
     gc=__builtin_bit_cast(_Float16,(unsigned short)packed);gs=__builtin_bit_cast(_Float16,(unsigned short)(packed>>16));
#else
     gc=float(__builtin_bit_cast(_Float16,(unsigned short)packed));gs=float(__builtin_bit_cast(_Float16,(unsigned short)(packed>>16)));
#endif
    }else{
'''+original.replace('cw_pv_t gc=','gc=')+'''    }
'''
 inc=inc[:begin]+cache+inc[end:]
 inc=inc.replace('bool PostTap=false>','bool PostTap=false,bool CachedNoise=false>')
 inc=inc.replace('_Float16*post_features=nullptr){fp8_sat_mode();','_Float16*post_features=nullptr,const uint*noise_cache=nullptr){fp8_sat_mode();')
 entry=r'''
#if CW_PREPOST_BYTE && CW_PREFIX_SPLIT
// Layout at raster p: half4(g1,g2,g0,+0), packed as uint2. Producer arithmetic
// copied byte-for-byte from CURRENT CW_PREFIX_SPLIT, not a CPU/mochi substitute.
CW_ENTRY void cw_prefix_noise_build(uint*out,uint width,uint height,uint seed){
 uint lane=__builtin_amdgcn_workitem_id_x(),r=lane&15u,g=lane>>4;
 uint p=bid()*16+r;if(p>=width*height)return;
 uint tile=p/64,x=(tile%(width/8))*8+p%8,y=(tile/(width/8))*8+(p%64)/8,rgbp=y*width+x;
'''+original+r'''
 uint packed=uint(__builtin_bit_cast(unsigned short,(_Float16)gc));
 if(!g)packed|=uint(__builtin_bit_cast(unsigned short,(_Float16)gs))<<16;
 out[rgbp*2+g]=packed;
}
CW_ENTRY void c32_wave1_prefix_b8d_noise(const unsigned char*rgba,const float*history,const float*fw,const float*w,unsigned char*main,unsigned char*down,uint windows,uint mode,uint raw,uint width,uint height,uint seed,uint temporal,const uint*cache){
 cw_body<false,true,false,false,true,false,false,true,false,false,false,false,true>(rgba,fw,w,nullptr,windows,mode,raw,width,height,0,0,0,0,0,reinterpret_cast<float*>(main),reinterpret_cast<float*>(down),nullptr,nullptr,nullptr,nullptr,nullptr,0.f,history,seed,temporal,nullptr,nullptr,cache);
}
// Same producer half-domain diagnostic entry. Not used as a performance claim.
CW_ENTRY void cw_prefix_noise_gold(uint*out,uint width,uint height,uint seed){
 uint lane=__builtin_amdgcn_workitem_id_x(),r=lane&15u,g=lane>>4;
 uint p=bid()*16+r;if(p>=width*height)return;
 uint tile=p/64,x=(tile%(width/8))*8+p%8,y=(tile/(width/8))*8+(p%64)/8,rgbp=y*width+x;
'''+original+r'''
 uint packed=uint(__builtin_bit_cast(unsigned short,(_Float16)gc));
 if(!g)packed|=uint(__builtin_bit_cast(unsigned short,(_Float16)gs))<<16;
 out[rgbp*2+g]=packed;
}
#endif
'''
 inc+=entry
 path=ROOT/'Development/tools/llvm-fork/compile-modules.py'
 spec=importlib.util.spec_from_file_location('canonical',path);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
 records=[]
 for name,compiler,source,defs,parts,opts in m.recipe(ROOT/'hip'):
  if name not in ('c32-wave1','c32-wave1-fast'):continue
  old=(ROOT/'hip/wave_owned_c32.inc').read_text()+'\n'
  assert source.count(old)==1
  patched=source.replace(old,inc+'\n')
  dest=out/(name+'.hip');dest.write_text(patched)
  records.append(dict(name=name,compiler=compiler,defines=defs,backend_opts=opts,source_sha256=sha(dest),current_source_sha256=hashlib.sha256(source.encode()).hexdigest()))
 core=(ROOT/'Development/HIP/hip_reference_network.h').read_text()
 core=core.replace(' Tensor inline_rgba,inline_hist;', (HERE/'host_cache.inc').read_text()+'\n Tensor inline_rgba,inline_hist;',1)
 call='Run("c32_wave1","c32_wave1_prefix_b8d",windows,P(inline_rgba),P(inline_hist?inline_hist:inline_rgba),PackedC32Weight(fw,false),PackedC32Weight(aw,true),P(main),P(down),windows,U(diagonal?3:0),U(1),w,h,inline_seed,inline_temporal);'
 assert core.count(call)==1
 cached='auto cache=PrefixNoiseCache(inline_seed);if(cache)Run("c32_wave1","c32_wave1_prefix_b8d_noise",windows,P(inline_rgba),P(inline_hist?inline_hist:inline_rgba),PackedC32Weight(fw,false),PackedC32Weight(aw,true),P(main),P(down),windows,U(diagonal?3:0),U(1),w,h,inline_seed,inline_temporal,P(cache));else '+call
 core=core.replace(call,cached)
 core=core.replace('  if(module=="c512_m32_mh"||module=="c512_m32_deep")', '  if(module=="c32_wave1"&&(kernel=="c32_wave1_prefix_b8d_noise"||kernel=="cw_prefix_noise_build"||kernel=="cw_prefix_noise_gold")){groups=count;threads=32;}\n  if(module=="c512_m32_mh"||module=="c512_m32_deep")',1)
 core=core.replace(' ~Network(){api.hipStreamSynchronize(stream);',' ~Network(){api.hipStreamSynchronize(stream);prefix_noise_cache.reset();')
 # Methods inserted after public marker with unique constructor anchor.
 core=core.replace(' Network(const Network&)=delete;', (HERE/'host_public.inc').read_text()+'\n Network(const Network&)=delete;',1)
 (out/'hip_reference_network.h').write_text(core)
 (out/'source.json').write_text(json.dumps({'base_source':sha(ROOT/'hip/wave_owned_c32.inc'),'host_base_source':sha(ROOT/'Development/HIP/hip_reference_network.h'),'rows':records,'noise_arithmetic_original':original,'cache_layout':'raster uint2 / half4(g1,g2,g0,+0)','cache_bytes_per_pixel':8,'noise_depends_on':'x,y,seed plus fixed compiler/helper; RGB/history/style/exposure are never cached','host_extra_conservative_keys':'geometry, seed0, style float bits, explicit preExposure float bits, explicit reset epoch; unprovided context is baseline fallback'},indent=2)+'\n')
 print(out)

if __name__=='__main__':
 p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=pathlib.Path);a=p.parse_args();main(a.output)
