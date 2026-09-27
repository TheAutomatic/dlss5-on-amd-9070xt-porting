from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[4];out=Path('/tmp/c512-round1-n')
for d in ('src','Development/HIP'):
 (out/d).mkdir(parents=True,exist_ok=True)
 for p in (root/d).glob('*.h'):shutil.copy2(p,out/d/p.name)
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text();needle='  if(opt.wall_profile)api.Check(api.hipStreamSynchronize(stream),"wall profile drain");';assert s.count(needle)==1
s=s.replace(needle,'  if(kernel=="split_mix_blocked_h16w_m32"&&opt.modules.find("modules-N")!=std::string::npos){kernel+="_n32";groups*=2;}\n'+needle);p.write_text(s)
s=(root/'Development/HIP/benchmark_vit_reuse.cpp').read_text();(out/'Development/HIP/benchmark.cpp').write_text(s)
subprocess.run(['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-municode','-I',str(out/'src'),'-I',str(out/'Development/HIP'),str(out/'Development/HIP/benchmark.cpp'),'-o','/tmp/c512-round1/benchmark-n.exe','-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid'],check=True)
