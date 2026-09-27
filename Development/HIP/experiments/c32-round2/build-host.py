from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[4];out=Path('/tmp/c32-round2-20260927/host')
for part in ('src','Development/HIP'):
 d=out/part;d.mkdir(parents=True,exist_ok=True)
 for p in (root/part).glob('*.h'):shutil.copy2(p,d/p.name)
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text().replace('class Network {','class Network {\n unsigned c32_trace_calls=0;')
s=s.replace('  if(opt.wall_profile)api.Check(api.hipStreamSynchronize(stream),"wall profile drain");','''  if(module=="c32_wave1"&&c32_trace_calls++<10)std::printf("C32_CALL W=%u H=%u kernel=%s windows=%u\\n",W,H,kernel.c_str(),groups);
  if(opt.wall_profile)api.Check(api.hipStreamSynchronize(stream),"wall profile drain");''')
s=s.replace('~Network(){api.hipStreamSynchronize(stream);','''~Network(){api.hipStreamSynchronize(stream);
 {auto it=modules.find("c32_wave1");if(it!=modules.end()){
 int(*getglobal)(void**,size_t*,Handle,const char*)=nullptr;api.Load(getglobal,"hipModuleGetGlobal");void*ptr=nullptr;size_t bytes=0;
 if(!getglobal(&ptr,&bytes,it->second,"cw_pack_census")){
  if(bytes!=6*7*5*4)throw std::runtime_error("census size");std::vector<unsigned> v(6*7*5);api.Check(api.hipMemcpy(v.data(),ptr,bytes,2),"census read");
  for(unsigned k=0;k<6;k++)for(unsigned site=0;site<7;site++){unsigned*q=v.data()+(k*7+site)*5;float maxabs;std::memcpy(&maxabs,q+4,4);std::printf("C32_CENSUS kind=%u site=%u packs=%u nonfinite_waves=%u over448_waves=%u over1_waves=%u maxabs=%.9g\\n",k,site,q[0],q[1],q[2],q[3],maxabs);}
 }}}
''')
p.write_text(s)
cmd=['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-municode','-I',str(out/'src'),'-I',str(out/'Development/HIP'),str(root/'Development/HIP/benchmark_vit_reuse.cpp'),'-o',str(out/'benchmark-census.exe'),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid']
subprocess.run(cmd,check=True)
