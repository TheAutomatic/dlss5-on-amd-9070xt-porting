"""One timed event at the same C512 start; other behavior and caller stay fixed."""
import argparse,subprocess,sys,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
subprocess.run([sys.executable,str(r/'Development/HIP/experiments/framework-submit-pair-20261006/prepare.py'),str(a.output)],check=True)
path=a.output/'hip_reference_network.h';s=path.read_text()
s=s.replace('bool submit_pair_active=false;', 'bool submit_pair_active=false,submit_single=false;')
old='''{const char*v=std::getenv("DLSS5_LAB_SUBMIT_PAIR");if(v&&!std::strcmp(v,"1")){if(opt.graph)throw std::runtime_error("submit pair trial requires graph0");api.Check(api.hipEventCreate(&submit_pair_begin),"submit pair begin");api.Check(api.hipEventCreate(&submit_pair_end),"submit pair end");submit_pair_active=true;std::fprintf(stderr,"submit_pair_trial active=1 point=C512-encoder-start timed=1 preallocated=1\\n");}}'''
new='''{const char*v=std::getenv("DLSS5_LAB_SUBMIT_SINGLE");if(v&&!std::strcmp(v,"1")){if(opt.graph)throw std::runtime_error("submit single trial requires graph0");api.Check(api.hipEventCreate(&submit_pair_begin),"submit single create");submit_pair_active=submit_single=true;std::fprintf(stderr,"submit_single_trial active=1 point=C512-encoder-start timed=1 owned_events=1\\n");}}'''
assert s.count(old)==1;s=s.replace(old,new)
s=s.replace('api.Check(api.hipEventRecord(submit_pair_end,stream),"submit pulse end");','if(!submit_single)api.Check(api.hipEventRecord(submit_pair_end,stream),"submit pulse end");')
path.write_text(s)
native=a.output/'native_hip_network.h';n=native.read_text();assert n.count(' hip_reference::D3D12Bridge::NetworkTiming PollNetworkTiming()')==1;n=n.replace(' hip_reference::D3D12Bridge::NetworkTiming PollNetworkTiming()', ' void PacingTimingTag(unsigned long long tag){bridge.SetTimingTag(tag);}\n hip_reference::D3D12Bridge::NetworkTiming PollNetworkTiming()',1);native.write_text(n)
frame=a.output/'native_game_frame.h';f=frame.read_text();assert f.count(' auto PacingNetworkTiming()')==1;f=f.replace(' auto PacingNetworkTiming()', ' void PacingTimingTag(unsigned long long tag){resources->network.PacingTimingTag(tag);}\n auto PacingNetworkTiming()',1);frame.write_text(f)
benchpath=a.output/'benchmark.cpp';bench=benchpath.read_text();needle='if(timing.valid)printf("FRAME_NET_GPU frame=%u gpu_ms=%.9g\\n",i,double(timing.ms));'
assert bench.count(needle)==1;bench=bench.replace(needle,'printf("FRAME_NET_GPU frame=%u gpu_ms=%.9g tag=%llu ready=%u\\n",i,double(timing.ms),static_cast<unsigned long long>(timing.tag),unsigned(timing.valid));')
needle='auto begin=std::chrono::steady_clock::now();frame.ProcessSubmittedFrame';assert bench.count(needle)==1;bench=bench.replace(needle,'frame.PacingTimingTag(i+1);'+needle,1)
bench=bench.replace('unsigned(timing.valid));','unsigned(timing.valid&&timing.tag==i+1));',1)
benchpath.write_text(bench)
(a.output/'single-source.json').write_text(json.dumps({'host_sha256':hashlib.sha256(s.encode()).hexdigest(),'scope':'one same-position timed Record, one owned event; new logger reuses existing snapshot, adds no query','default':0,'files':{name:hashlib.sha256((a.output/name).read_bytes()).hexdigest() for name in ['benchmark.cpp','native_hip_network.h','native_game_frame.h','hip_reference_network.h','hip_d3d12_bridge.h','native_hip_env_options.h']},'production_helper':'isolated throw-on-error still experimental; actual optional error fallback helper being reviewed separately'},indent=2)+'\n')
