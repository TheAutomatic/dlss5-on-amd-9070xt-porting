"""Copied diagnostic header hook: snapshot live Body22 input; stock Down is reference."""
from pathlib import Path
import argparse,shutil
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();r=Path(__file__).resolve().parents[4];a.out.mkdir(parents=True,exist_ok=True)
for x in (r/'Development/HIP').glob('*.h'):shutil.copy2(x,a.out/x.name)
for x in (r/'src').glob('native_hip*.h'):shutil.copy2(x,a.out/x.name)
shutil.copy2('/tmp/fresh-mochi1088-20261006/production_options.generated.h',a.out/'production_options.generated.h')
p=a.out/'hip_reference_network.h';s=p.read_text();s=s.replace('class Network {friend class D3D12Bridge;','class Network {friend class D3D12Bridge;\n std::function<void(const char*,void**,unsigned)> dl_gold_hook;',1)
s=s.replace('if(opt.profile)api.Check(api.hipEventRecord(timing.end,stream)', 'if(dl_gold_hook)dl_gold_hook(kernel.c_str(),argv,sizeof...(A));if(opt.profile)api.Check(api.hipEventRecord(timing.end,stream)',1)
s=s.replace(' Handle Stream()const{return stream;}', ' void DiagnosticDownHook(std::function<void(const char*,void**,unsigned)>h){dl_gold_hook=std::move(h);}\n size_t DiagnosticWeightBytes(void*p)const{for(auto&x:weights)if(x.second->ptr==p)return x.second->bytes;throw std::runtime_error("weight pointer absent");}\n Handle Stream()const{return stream;}',1);p.write_text(s)
