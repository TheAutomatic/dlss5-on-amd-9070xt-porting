"""Reviewable 900 FAST1 optional module constructor routing; no production edit."""
from pathlib import Path
import argparse,difflib
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();repo=Path(__file__).resolve().parents[4];s=(repo/'Development/HIP/hip_reference_network.h').read_text()
old=' for(auto&entry:extra){entry[1]+=".hsaco";Handle m{};api.Check(api.LoadModule(&m,(opt.modules+"/"+entry[1]).c_str()),entry[1].c_str());modules[entry[0]]=m;}}'
new=r''' for(auto&entry:extra){entry[1]+=".hsaco";Handle m{};
  api.Check(api.LoadModule(&m,(opt.modules+"/"+entry[1]).c_str()),entry[1].c_str());modules[entry[0]]=m;
  if(entry[0]=="c32_wave1"){
   const bool geometry=fast_numeric&&W==1600&&H==960&&!opt.graph&&!opt.experimental_temporal;
   const char*norm900="c32-wave1-fast-norm900.hsaco";Handle candidate{};
   if(geometry&&std::ifstream(std::filesystem::u8path(opt.modules+"/"+norm900),std::ios::binary).good()){
    int ec=api.LoadModule(&candidate,(opt.modules+"/"+norm900).c_str());bool complete=!ec;const char*missing=nullptr;
    // Locked fast-numeric baseline/hoist ABI contains26 exports, including postfeatures.
    // Whole fallback on any missing legacy export; never partially select an old callee.
    const char*required[]={"c32_fast_ffn_attention_fused","c32_fast_ffn_attention_fused_half","c32_fast_ffn_attention_fused_half_mapped","c32_fast_ffn_attention_fused_half_chain","c32_fast_ffn_attention_fused_half_finish_main8","c32_fast_ffn_attention_fused_half_chain_finish","c32_fast_ffn_attention_fused_half_prefix_finish_main8","c32_fast_ffn_attention_fused_half_chain_finish_dcrop","c32_post_merge_head_half","c32_post_merge_fused_half","c32_wave1_chain","c32_wave1_mapped","c32_wave1_finish","c32_wave1_finish_dcrop","c32_wave1_post","c32_wave1_prefix","c32_wave1_finish_dcrop_b8","c32_wave1_finish_dcrop_b8d","c32_wave1_prefix_b8d","c32_wave1_mapped_b8","c32_wave1_finish_b8","c32_wave1_post_b8","c32_wave1_post_b8_rgba","c32_wave1_post_b8_features","c32_wave1_up_b8","c32_wave1_up"};
    if(complete)for(const char*name:required){Handle f{};if(api.hipModuleGetFunction(&f,candidate,name)){complete=false;missing=name;break;}}
    if(complete){modules["c32_norm900"]=candidate;c32_norm900_loaded=true;}
    else{if(candidate)api.hipModuleUnload(candidate);std::fprintf(stderr,"c32_norm900 active=0 reason=optional-load-or-full26-export-fallback load_status=%d missing_export=%s\n",ec,missing?missing:"none");}
   }
   std::fprintf(stderr,"c32_norm900 scope=%u loaded=%u selected=%s processing=%ux%u fast_numeric=%u mp=%u graph=%u experimental=%u\n",unsigned(geometry&&multi_pass==1),unsigned(c32_norm900_loaded),C32Norm900Active()?norm900:entry[1].c_str(),W,H,unsigned(fast_numeric),multi_pass,unsigned(opt.graph),unsigned(opt.experimental_temporal));
  }
 }}'''
assert s.count(old)==1;newsource=s.replace(old,new)
newsource=newsource.replace('bool fast_numeric=false;', 'bool c32_norm900_loaded=false;bool fast_numeric=false;',1)
fnold=' Handle Fn(const std::string&m,const std::string&name){std::string key=m+":"+name;auto it=functions.find(key);if(it!=functions.end())return it->second;Handle f{};api.Check(api.hipModuleGetFunction(&f,modules.at(m),name.c_str()),name.c_str());functions.emplace(key,f);return f;}'
fnnew=' bool C32Norm900Active()const{return c32_norm900_loaded&&fast_numeric&&W==1600&&H==960&&multi_pass==1&&!opt.graph&&!opt.experimental_temporal;}\n Handle Fn(const std::string&m,const std::string&name){static const std::string normkey="c32_norm900";const std::string&actual=m=="c32_wave1"&&C32Norm900Active()?normkey:m;std::string key=actual+":"+name;auto it=functions.find(key);if(it!=functions.end())return it->second;Handle f{};api.Check(api.hipModuleGetFunction(&f,modules.at(actual),name.c_str()),name.c_str());functions.emplace(key,f);return f;}'
assert newsource.count(fnold)==1;newsource=newsource.replace(fnold,fnnew)
a.out.mkdir(parents=True,exist_ok=True);(a.out/'hip_reference_network.h').write_text(newsource)
(a.out/'route.patch').write_text(''.join(difflib.unified_diff(s.splitlines(True),newsource.splitlines(True),fromfile='a/Development/HIP/hip_reference_network.h',tofile='b/Development/HIP/hip_reference_network.h')))
