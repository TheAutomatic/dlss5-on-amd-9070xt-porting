from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[4];out=Path('/tmp/tier900-20260927');old=root/'Development/HIP/experiments/family-ledger'
for d in ('src','Development/HIP'):
 (out/d).mkdir(parents=True,exist_ok=True)
 for p in (root/d).glob('*.h'):shutil.copy2(p,out/d/p.name)
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text().replace('class Network {','class Network {\n'+(old/'members.inc').read_text(),1)
needle='if(opt.profile)api.Check(api.hipEventRecord(timing.end,stream),"event end");';assert s.count(needle)==1
s=s.replace(needle,'if(topo_active){topo_kernels.push_back(module+":"+kernel+"|groups="+std::to_string(groups?groups:(count+255ull)/256)+"|threads="+std::to_string(threads));++prefix_cursor;}else if(prefix_active){++prefix_cursor;if(prefix_cursor==prefix_total)api.Check(api.hipEventRecord(prefix_end,stream),"compute end marker");else if(prefix_cursor==prefix_cut)api.Check(api.hipEventRecord(prefix_mid,stream),"cut marker");}'+needle)
s=s.replace('void Stage(const std::string&name,const Tensor&t){','void Stage(const std::string&name,const Tensor&t){if(topo_active)topo_stages.emplace_back(name,prefix_cursor);')
s=s.replace(' Handle Stream()const{return stream;}',(old/'public.inc').read_text()+' Handle Stream()const{return stream;}');p.write_text(s)
s=(old/'runner.cpp.in').read_text().replace('/* OPTIONS */','auto o=LmxxfProductionOptions(W,H,argv[2],argv[1]);').replace('#include "Development/HIP/hip_reference_network.h"','#include "Development/HIP/hip_reference_network.h"\n#include "src/LmxxfProductionOptions.h"')
(out/'ledger.cpp').write_text(s)
subprocess.run(['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-I',str(out/'src'),'-I',str(out/'Development/HIP'),str(out/'ledger.cpp'),'-o',str(out/'ledger.exe'),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid'],check=True)
