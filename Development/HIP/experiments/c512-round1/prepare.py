from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[4];here=Path(__file__).resolve().parent;out=Path('/tmp/c512-round1');out.mkdir(exist_ok=True)
for d in ('src','Development/HIP','hip'):
 (out/d).mkdir(parents=True,exist_ok=True)
 for p in (root/d).glob('*'):
  if p.is_file():shutil.copy2(p,out/d/p.name)
for n in ('regression.ps1','collect.ps1','collect-adaptive.ps1'):
 s=(here/n).read_text() if (here/n).exists() else (here.parent/'mh-round1'/n).read_text().replace('mh-round1','c512-round1');(here/n).write_text(s);(out/n).write_text(s)
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text().replace('class Network {','class Network {\n bool c5_trace=false; std::string c5_stage;\n',1)
s=s.replace(' Handle Stream()const{return stream;}',' void C5Trace(bool v){c5_trace=v;} void C5Dup(const std::string& s,unsigned n){opt.dup_prefix=s;opt.dup_count=n;} Handle Stream()const{return stream;}',1)
s=s.replace(' void Stage(const std::string&name,const Tensor&t){',' void Stage(const std::string&name,const Tensor&t){c5_stage=name;',1)
needle='  if(opt.wall_profile)api.Check(api.hipStreamSynchronize(stream),"wall profile drain");'
s=s.replace(needle,'''  if(c5_trace){using Occ=int(*)(int*,Handle,int,size_t);using Attr=int(*)(int*,int,Handle);Occ occ{};Attr attr{};api.Load(occ,"hipModuleOccupancyMaxActiveBlocksPerMultiprocessor");api.Load(attr,"hipFuncGetAttribute");int blocks=0,regs=0,lds=0,scratch=0;auto f=Fn(module,kernel);api.Check(occ(&blocks,f,threads,0),"occ");api.Check(attr(&regs,4,f),"regs");api.Check(attr(&lds,1,f),"lds");api.Check(attr(&scratch,3,f),"scratch");printf("TOPO,%s,%s,%s,%u,%u,%d,%d,%d,%d\\n",c5_stage.c_str(),module.c_str(),kernel.c_str(),groups?groups:(count+255u)/256,threads,regs,lds,scratch,blocks);}
'''+needle,1);p.write_text(s)
base=(here.parent/'family-ledger/runner.cpp.in').read_text();base=base.replace('#include "Development/HIP/hip_reference_network.h"','#include "Development/HIP/hip_reference_network.h"\n#include "src/LmxxfProductionOptions.h"').replace('/* OPTIONS */','auto o=LmxxfProductionOptions(W,H,argv[2],argv[1]);')
base=base.replace('#include <windows.h>','#include <windows.h>\n#include <tlhelp32.h>')
base=base.replace('int main(int argc,char**argv)','''void idle(){HANDLE snap=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);if(snap==INVALID_HANDLE_VALUE)throw std::runtime_error("process snapshot");PROCESSENTRY32 pe{};pe.dwSize=sizeof(pe);bool busy=false;if(Process32First(snap,&pe))do{std::string n=pe.szExeFile;std::transform(n.begin(),n.end(),n.begin(),[](unsigned char c){return char(std::tolower(c));});if(n.find("shipping")!=std::string::npos||n=="re9.exe"||n.find("onimusha")!=std::string::npos)busy=true;}while(Process32Next(snap,&pe));CloseHandle(snap);if(busy)throw std::runtime_error("game running: stop ledger");}
int main(int argc,char**argv)''')
a=base.index(' /* topology:');b=base.index('}catch',a)
base=base[:a]+''' auto props=api.Properties(0);printf("DEVICE,%s,MP=%d,warp=%d,threads=%d,LDS=%zu\\n",props.name,props.multiProcessorCount,props.warpSize,props.maxThreadsPerMultiProcessor,props.sharedMemPerMultiprocessor);
 net.C5Trace(true);run();net.C5Trace(false);verify("topology");
 const char* kernels[]={"split_mix_blocked_h16w_m32$","split_ffn_fused_fp8_t8$","split_projection_frag$","mh_qkv_normalize_frag_c512_m32$","mh_attention_fused_fp8_out$","mh_attention_project_frag_c512$"};
 FILE*csv=fopen("marginal.csv","wb");fprintf(csv,"kernel,round,slot,extra,ms\\n");
 for(auto k:kernels){for(int round=0;round<3;round++){for(int slot=0;slot<4;slot++){idle();unsigned extra=(slot==1||slot==2)?2:0;net.C5Dup(k,1+extra);for(int i=0;i<20;i++)run();auto t=std::chrono::steady_clock::now();for(int i=0;i<160;i++)run();double ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-t).count()/160;fprintf(csv,"%s,%d,%d,%u,%.9f\\n",k,round,slot,extra,ms);fflush(csv);idle();verify(k);}}}
 fclose(csv);net.C5Dup("",1);verify("final");api.hipFree(x);api.hipFree(y);printf("PASS c512 ledger checks=%u\\n",checks);return 0;
'''+base[b:];(out/'ledger.cpp').write_text(base)
subprocess.run(['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-I',str(out/'src'),'-I',str(out/'Development/HIP'),str(out/'ledger.cpp'),'-o',str(out/'ledger.exe'),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid'],check=True)
s=(here/'ledger.ps1').read_text();(out/'ledger.ps1').write_text(s)
s=(here/'stage.ps1').read_text();(out/'stage.ps1').write_text(s)
print(out)
