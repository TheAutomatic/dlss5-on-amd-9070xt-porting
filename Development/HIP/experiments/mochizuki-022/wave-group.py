from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[4];out=Path('/tmp/mochizuki-022');host=Path('/tmp/mochizuki-022-group4')
s=(root/'hip/c512_m32_deep.inc').read_text();a=s.index('WAVE void split_mix_blocked_h16w_m32(');k=s[a:]
k=k.replace('WAVE void split_mix_blocked_h16w_m32(', 'KERNEL __attribute__((amdgpu_flat_work_group_size(128,128))) void split_mix_blocked_h16w_m32_wg4(')
k=k.replace('uint first=bid()/8*32,row=bid()%8*64;', 'uint wave=__builtin_amdgcn_readfirstlane(__builtin_amdgcn_workitem_id_x()/32);uint first=(bid()/8*4+wave)*32,row=bid()%8*64;')
a=k.index('#if C512_ZERO_PAD_900');b=k.index('#endif',a)+len('#endif');k=k[:a]+k[b:]
p=out/'hip/c512_m32_deep.inc';existing=p.read_text().split('\n#ifndef C512_WG4')[0];p.write_text(existing+'\n#ifndef C512_WG4\n#define C512_WG4 0\n#endif\n#if C512_WG4\n'+k+'\n#endif\n')
for d in ('src','Development/HIP'):
 (host/d).mkdir(parents=True,exist_ok=True)
 for p in (root/d).glob('*.h'):shutil.copy2(p,host/d/p.name)
p=host/'Development/HIP/hip_reference_network.h';s=p.read_text();s=s.replace('class Network {','class Network {\n unsigned wg4_calls=0;\n',1)
needle='  if(opt.wall_profile)api.Check(api.hipStreamSynchronize(stream),"wall profile drain");';assert s.count(needle)==1
s=s.replace(needle,'  if(kernel=="split_mix_blocked_h16w_m32"&&opt.modules.find("modules-H")!=std::string::npos){kernel+="_wg4";unsigned tiles=count/8192;groups=((tiles+3)/4)*8;threads=128;++wg4_calls;}\n'+needle,1)
s=s.replace('~Network(){api.hipStreamSynchronize(stream);','~Network(){api.hipStreamSynchronize(stream);printf("WG4 calls=%u\\n",wg4_calls);',1);p.write_text(s)
shutil.copy2(root/'Development/HIP/benchmark_vit_reuse.cpp',host/'Development/HIP/benchmark.cpp')
subprocess.run(['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-municode','-I',str(host/'src'),'-I',str(host/'Development/HIP'),str(host/'Development/HIP/benchmark.cpp'),'-o',str(out/'benchmark-group.exe'),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid'],check=True)
