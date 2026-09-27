from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[4];base=Path('/tmp/c512-round1');out=Path('/tmp/c512-round1-tail')
for d in ('src','Development/HIP'):
 (out/d).mkdir(parents=True,exist_ok=True)
 for p in (base/d).glob('*.h'):shutil.copy2(p,out/d/p.name)
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text().replace('std::string c5_stage;','std::string c5_stage,c5_only_stage;')
s=s.replace('void C5Dup(const std::string& s,unsigned n){','void C5OnlyStage(const std::string&s){c5_only_stage=s;} void C5Dup(const std::string& s,unsigned n){');s=s.replace('!opt.dup_prefix.empty()&&','!opt.dup_prefix.empty()&&(c5_only_stage.empty()||c5_stage==c5_only_stage)&&');p.write_text(s)
s=(base/'ledger.cpp').read_text();a=s.index(' const char* kernels[]=');b=s.index('\n FILE*csv',a);s=s[:a]+''' const char* kernels[]={"mh_shift_pack$","mh_pool_project_group_c256$","mh_pool$","mh_pool_project_production_h16w$"};'''+s[b:];s=s.replace('for(auto k:kernels){for(int round','for(auto k:kernels){net.C5OnlyStage(std::string(k)=="mh_pool_project_production_h16w$"?"block30":"");for(int round');s=s.replace('round<3','round<2');(out/'tail.cpp').write_text(s)
subprocess.run(['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-I',str(out/'src'),'-I',str(out/'Development/HIP'),str(out/'tail.cpp'),'-o',str(base/'ledger-tail.exe'),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid'],check=True)
here=Path(__file__).resolve().parent;s=(here/'ledger.ps1').read_text().replace('$height-pdl1','$height-tail').replace('ledger.exe','ledger-tail.exe');(here/'tail.ps1').write_text(s)
