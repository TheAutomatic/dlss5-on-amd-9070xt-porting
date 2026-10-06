"""Prepare one-window/head actual-model trace; no production source mutation."""
from pathlib import Path
import argparse,importlib.util,json,hashlib
p=argparse.ArgumentParser();p.add_argument('output',type=Path);p.add_argument('--first',action='store_true');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);repo=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('recipe',repo/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
rows=[r for r in m.recipe(repo/'hip') if r[0]=='c512-m32-mh'];assert len(rows)==1
s=rows[0][2];needle='  i2 prob[4];\n  _Pragma("unroll 4") for(uint key=0;key<4;key++){';assert s.count(needle)==2
s='extern "C" __attribute__((device)) unsigned c512_den_trace[1024]={};\nextern "C" __attribute__((device)) unsigned c512_den_trace_calls=0;\n'+s
prefix,tail=s.rsplit(needle,1)
s=prefix+'''  if(win==0&&head==0){
   if(tid==0&&t==0)c512_den_trace_calls++;
   for(uint e=0;e<8;e++)c512_den_trace[((wave*QT+t)*32+tid%32)*8+e]=bits(sums[0][e]+sums[1][e]);
  }
'''+needle+tail
if a.first:
 compact_start=s.index('DEV void c5c_body')
 prefix,body=s[:compact_start],s[compact_start:]
 barrier=' WG_FENCE(3);__builtin_amdgcn_s_barrier();WG_FENCE(2);'
 assert body.count(barrier)==1
 body=body.replace(barrier,' __attribute__((shared)) uint capture_first;\n if(tid==0){capture_first=0;if(win==0&&head==0){capture_first=c512_den_trace_calls==0;c512_den_trace_calls++;}}\n'+barrier,1)
 body=body.replace('if(win==0&&head==0){\n   if(tid==0&&t==0)c512_den_trace_calls++;','if(win==0&&head==0&&capture_first){')
 s=prefix+body
(a.output/'actual.hip').write_text(s)
# Clone only headers; retain production option helper from existing locked CPU fixture.
h=(repo/'Development/HIP/hip_reference_network.h').read_text().replace('#include "../../src/native_experimental_history.h"','#include "'+str(repo/'src/native_experimental_history.h')+'"')
h=h.replace(' Api& Runtime(){return api;}', ' Handle C512DiagnosticModule(){return modules.at("c512_m32_mh");}\n Api& Runtime(){return api;}');assert 'C512DiagnosticModule' in h
(a.output/'hip_reference_network.h').write_text(h)
b=(repo/'Development/HIP/experiments/c32-norm-hoist-20261006/prefix_capture.cpp').read_text()
start=b.index(' api.Load(api.hipModuleGetGlobal');end=b.index('\n api.hipEventDestroy',start)
b=b[:start]+''' if(const char*cap=std::getenv("DLSS5_DEN_CAPTURE");cap&&!std::strcmp(cap,"1")){api.Load(api.hipModuleGetGlobal,"hipModuleGetGlobal");void*trace{};size_t bytes{};api.Check(api.hipModuleGetGlobal(&trace,&bytes,net.C512DiagnosticModule(),"c512_den_trace"),"den trace");if(bytes!=4096)throw std::runtime_error("den trace footprint");std::vector<unsigned>words(1024);api.Check(api.hipMemcpy(words.data(),trace,bytes,2),"den trace read");unsigned ediff=0,cold=0;for(unsigned p=0;p<128;p++)for(unsigned e=0;e<8;e++){ediff+=words[p*8+e]!=words[p*8];cold+=words[p*8+e]==0;}std::ofstream(std::string(argv[5])+"/den.u32",std::ios::binary).write((char*)words.data(),bytes);api.Check(api.hipModuleGetGlobal(&trace,&bytes,net.C512DiagnosticModule(),"c512_den_trace_calls"),"trace calls");unsigned calls=0;api.Check(api.hipMemcpy(&calls,trace,4,2),"trace calls read");unsigned columns_different=0;for(unsigned p=1;p<128;p++)columns_different+=words[p*8]!=words[0];printf("ACTUAL_DEN calls=%u within_lane_e_diff=%u zero_words=%u asymmetric_columns=%u\\n",calls,ediff,cold,columns_different);if(calls!=16||cold||!columns_different||ediff)throw std::runtime_error("actual denominator identity/asymmetry gate failed");}
'''+b[end:]
b=b.replace(' Handle begin{},end{};api.Check(api.hipEventCreate(&begin),\"create begin\");api.Check(api.hipEventCreate(&end),\"create end\");','').replace(' api.hipEventDestroy(begin);api.hipEventDestroy(end);','')
(a.output/'actual_probe.cpp').write_text(b)
env=(repo/'src/native_hip_env_options.h').read_text().replace('#include \"../Development/HIP/hip_reference_network.h\"','#include \"hip_reference_network.h\"').replace('#include \"native_frame_stats.h\"','#include \"'+str(repo/'src/native_frame_stats.h')+'\"')
(a.output/'native_hip_env_options.h').write_text(env)
(a.output/'trace-source.json').write_text(json.dumps({'scope':'full current model, window0/head0, global overwritten by last C512 invocation, expected16 calls; no output/kernel math change; trace overhead not benchmark','first_call_only':a.first,'source_sha':hashlib.sha256(s.encode()).hexdigest(),'original_recipe_compiler':rows[0][1]},indent=2)+'\n')
