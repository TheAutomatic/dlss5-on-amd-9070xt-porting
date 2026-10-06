"""Generate default-off timed pulse in a complete isolated NativeGameFrame host."""
import argparse,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
s=(r/'Development/HIP/hip_reference_network.h').read_text().replace('#include "../../src/native_experimental_history.h"','#include "'+str(r/'src/native_experimental_history.h')+'"')
s=s.replace(' Tensor temporal_features;', ' Handle submit_pair_begin{},submit_pair_end{};bool submit_pair_active=false;\n Tensor temporal_features;',1)
anchor='if(wave_owned_active)HasFn("c32_wave1","c32_wave1_post_b8_rgba");'
assert s.count(anchor)==1
setup='''{const char*v=std::getenv("DLSS5_LAB_SUBMIT_PAIR");if(v&&!std::strcmp(v,"1")){if(opt.graph)throw std::runtime_error("submit pair trial requires graph0");api.Check(api.hipEventCreate(&submit_pair_begin),"submit pair begin");api.Check(api.hipEventCreate(&submit_pair_end),"submit pair end");submit_pair_active=true;std::fprintf(stderr,"submit_pair_trial active=1 point=C512-encoder-start timed=1 preallocated=1\\n");}}'''
s=s.replace(anchor,setup+anchor,1)
needle='for(U j=0;j<8;j++){source=Body(source,W/32,H/32,512,shifts[j],23+j,j==7);}'
assert s.count(needle)==1
s=s.replace(needle,'if(submit_pair_active){api.Check(api.hipEventRecord(submit_pair_begin,stream),"submit pulse begin");api.Check(api.hipEventRecord(submit_pair_end,stream),"submit pulse end");}'+needle,1)
s=s.replace('SpReport();pdl_keep.clear();', 'if(submit_pair_begin)api.hipEventDestroy(submit_pair_begin);if(submit_pair_end)api.hipEventDestroy(submit_pair_end);SpReport();pdl_keep.clear();',1)
(a.output/'hip_reference_network.h').write_text(s)
for name in ('native_hip_network.h','native_hip_env_options.h','native_game_frame.h'):
 text=(r/'src'/name).read_text().replace('#include "../Development/HIP/hip_d3d12_bridge.h"','#include "hip_d3d12_bridge.h"').replace('#include "../Development/HIP/hip_reference_network.h"','#include "hip_reference_network.h"')
 if name=='native_game_frame.h':
  text=text.replace(' void ExperimentalFrameMetadata(', ' auto PacingNetworkTiming(){return resources->network.PollNetworkTiming();}\n void ExperimentalFrameMetadata(',1)
 (a.output/name).write_text(text)
(a.output/'hip_d3d12_bridge.h').write_text((r/'Development/HIP/hip_d3d12_bridge.h').read_text())
bench=(r/'Development/HIP/benchmark_vit_reuse.cpp').read_text()
# GPU whole-network duration is queried only after the frame's normal completion; no added sync.
needle='walltotal+=elapsed;'
assert bench.count(needle)==1
bench=bench.replace(needle,needle+'auto timing=frame.PacingNetworkTiming();if(timing.valid)printf("FRAME_NET_GPU frame=%u gpu_ms=%.9g\\n",i,double(timing.ms));',1)
(a.output/'benchmark.cpp').write_text(bench)
(a.output/'source.json').write_text(json.dumps({'scope':'complete unchanged codec/bridge/NN/decode caller; candidate only timedempty event pair before C512','flag':'DLSS5_LAB_SUBMIT_PAIR default0','graph':'rejected when on','resource':'2 preallocated per-Network handles, destructor after stream completion','files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in a.output.iterdir() if p.is_file()}},indent=2)+'\n')
