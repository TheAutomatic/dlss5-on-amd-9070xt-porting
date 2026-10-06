"""Attach actual timed-event lease/ABI adapter to the isolated framework."""
import argparse,subprocess,sys,shutil,json,hashlib
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[4]
subprocess.run([sys.executable,str(Path(__file__).with_name('prepare.py')),str(a.output)],check=True)
for name in ('submit_pulse.h','submit_pulse_hip.h'):shutil.copy2(r/'Development/HIP'/name,a.output/name)
p=a.output/'hip_reference_network.h';s=p.read_text();s='#include "submit_pulse_hip.h"\n'+s
s=s.replace('class Network {','class Network {friend class D3D12Bridge;',1)
s=s.replace(' Handle submit_pair_begin{},submit_pair_end{};bool submit_pair_active=false,submit_single=false;','')
# Original prepare places the pulse fields beside Api (spacing is deliberate).
if 'submit_pair_begin' in s:
 s=s.replace('Handle submit_pair_begin{},submit_pair_end{};bool submit_pair_active=false,submit_single=false;','')
s=s.replace('Api api;Handle stream{};', 'Api api;Handle stream{};HipSubmitPulseOps pulse_ops;SubmitPulseLease<HipSubmitPulseOps> pulse_lease;bool pulse_fallback_logged=false,pulse_frame_history=false;')
s=s.replace(':api(o.runtime),opt(std::move(o))', ':api(o.runtime),pulse_ops{int(o.device),&stream,api.hipSetDevice,api.hipEventCreate,api.hipEventRecord,api.hipStreamSynchronize,api.hipEventDestroy},pulse_lease(pulse_ops),opt(std::move(o))')
old='''{const char*v=std::getenv("DLSS5_LAB_SUBMIT_SINGLE");if(v&&!std::strcmp(v,"1")){if(opt.graph)throw std::runtime_error("submit single trial requires graph0");api.Check(api.hipEventCreate(&submit_pair_begin),"submit single create");submit_pair_active=submit_single=true;std::fprintf(stderr,"submit_single_trial active=1 point=C512-encoder-start timed=1 owned_events=1\\n");}}'''
assert s.count(old)==1;s=s.replace(old,'')
needle='if(multi_skin)PrepareSkin();}catch(...)';assert s.count(needle)==1
s=s.replace(needle,'''if(multi_skin)PrepareSkin();}catch(...)''')
needle='if(submit_pair_active){api.Check(api.hipEventRecord(submit_pair_begin,stream),"submit pulse begin");if(!submit_single)api.Check(api.hipEventRecord(submit_pair_end,stream),"submit pulse end");}'
assert s.count(needle)==1;s=s.replace(needle,'''if(pulse_lease.Active()){if(PulseEligible())pulse_lease.Record();else if(!pulse_fallback_logged){pulse_fallback_logged=true;std::fprintf(stderr,"submit_pulse active=0 reason=frame-scope-fallback\\n");}}''')
s=s.replace('if(submit_pair_begin)api.hipEventDestroy(submit_pair_begin);if(submit_pair_end)api.hipEventDestroy(submit_pair_end);','')
s=s.replace('}catch(...){if(pdl_flags)', '}catch(...){if(!pulse_lease.Close()){std::fprintf(stderr,"submit_pulse ctor cleanup retained owner stream\\n");throw;}if(pdl_flags)',1)
s=s.replace('~Network(){api.hipStreamSynchronize(stream);', '~Network(){if(!pulse_lease.Close()){std::fprintf(stderr,"submit_pulse direct destructor retained owner stream; bridge must preclose\\n");return;}api.hipSetDevice(int(opt.device));api.hipStreamSynchronize(stream);',1)
s=s.replace('void Enqueue(void*rgba,void*history,void*rgb_output,U seed){', 'void Enqueue(void*rgba,void*history,void*rgb_output,U seed){pulse_frame_history=history!=nullptr;',1)
needle=' bool GraphEnabled()const';assert s.count(needle)==1
s=s.replace(needle,''' private: void ConfigureSubmitPulse()noexcept{const char*v=std::getenv("DLSS5_LAB_SUBMIT_SINGLE");bool requested=v&&!std::strcmp(v,"1");bool active=pulse_lease.Configure(requested,PulseEligible(),1,0);if(requested)std::fprintf(stderr,"submit_single_trial requested=1 active=%u point=C512-encoder-start safe_lease=1\\n",unsigned(active));}
 public: bool CloseSubmitPulse()noexcept{return pulse_lease.Close();}
 bool PulseEligible()const{const char*ae=std::getenv("DLSS5_VIT_ADAPTIVE");return !pulse_frame_history&&!opt.graph&&!opt.profile&&!opt.wall_profile&&!opt.experimental_temporal&&!opt.temporal_feature_tap&&opt.skip_blocks.empty()&&multi_pass==1&&!multi_predict&&!multi_skin&&(!ae||!*ae||!std::strcmp(ae,"0"))&&!pdl_anyorder&&pdl_calls==0&&fast_numeric==1&&((W==1600&&H==960)||(W==1920&&(H==1088||H==1152)));}
 bool GraphEnabled()const''')
assert 'submit_pair_begin' not in s
p.write_text(s)
p=a.output/'hip_d3d12_bridge.h';s=p.read_text()
s=s.replace('if(network&&network->Runtime().hipStreamSynchronize(network->Stream()))return false;', 'if(network&&(network->Runtime().hipSetDevice(hip_device)||network->Runtime().hipStreamSynchronize(network->Stream())))return false;',1)
s=s.replace('if(!WaitForSubmittedWork())return;', 'if(!WaitForSubmittedWork()||(network&&!network->CloseSubmitPulse()))return;',1)
s=s.replace('try{api.Check(api.hipMemsetAsync(input.mapped', 'try{api.Check(api.hipSetDevice(hip_device),"select HIP owner for preparation");api.Check(api.hipMemsetAsync(input.mapped',1)
needle=' }\n ID3D12Resource*Output()const';assert s.count(needle)==1;s=s.replace(needle,'  network->ConfigureSubmitPulse();\n'+needle,1)
p.write_text(s)
(a.output/'safe-source.json').write_text(json.dumps({'scope':'isolated regular bridge only; DLL retained; pulse preclose before bridge resource release/delete; bridge configure last/noexcept; private friend-only, direct Network creates no pulse','files':{name:hashlib.sha256((a.output/name).read_bytes()).hexdigest() for name in ['hip_reference_network.h','hip_d3d12_bridge.h','submit_pulse.h','submit_pulse_hip.h','benchmark.cpp']}},indent=2)+'\n')
