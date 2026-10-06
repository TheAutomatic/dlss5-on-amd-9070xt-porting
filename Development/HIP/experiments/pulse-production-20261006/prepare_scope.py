from pathlib import Path
import argparse
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
b=(r/'Development/HIP/benchmark_vit_reuse.cpp').read_text()
b=b.replace('#include <numeric>','#include <numeric>\n#include <memory>')
b=b.replace('{NativeGameFrame frame;','{std::unique_ptr<NativeGameFrame> frame(new NativeGameFrame);',1)
import re
b=re.sub(r'\bframe\.(?=[A-Za-z_]\w*\()', 'frame->',b)
needle='for(UINT i=0;i<N;i++){'
insert='for(UINT i=0;i<N;i++){\nconst char*resize_env=std::getenv("DLSS5_LAB_PULSE_RESIZE");if(resize_env&&!strcmp(resize_env,"1")&&i){if(N!=3||temporal)throw std::runtime_error("resize gate requires3 plain frames");frame.reset();env("DLSS5_NETWORK_HEIGHT",i==1?"1080":"900");auto resize_noise=NativeReadF32(assets+L"\\noise.f32","noise");frame.reset(new NativeGameFrame);frame->Create(q,target,resize_noise,assets,nullptr,nullptr);printf("PULSE_RESIZE rebuilt frame=%u requested_height=%s\\n",i,i==1?"1080":"900");}\n'
b=b.replace(needle,insert,1);b=b.replace('L\"\\noise.f32\"','L\"/noise.f32\"');(a.output/'benchmark.cpp').write_text(b)
