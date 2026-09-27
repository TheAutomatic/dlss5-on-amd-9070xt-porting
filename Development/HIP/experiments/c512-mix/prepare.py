from pathlib import Path
import shutil,subprocess
root=Path(__file__).resolve().parents[4];out=Path('/tmp/c512-mix-20260927')
shutil.copytree(root/'hip',out/'hip',dirs_exist_ok=True)
s=(root/'hip/c512_m32_deep.inc').read_text();s=s[s.index('WAVE void'):].replace('split_mix_blocked_h16w_m32','split_mix_m32_hout')
s=s.replace('out[','reinterpret_cast<_Float16*>(out)[')
d=(root/'hip/deep_fast.hip').read_text();a=d.index('KERNEL __attribute__((amdgpu_flat_work_group_size(128,128)))\nvoid split_ffn_fused_fp8_t8');b=d.index('// split_projection_blocked',a)
d=d[a:b].replace('split_ffn_fused_fp8_t8','split_ffn_t8_hin').replace('a[e]=(_Float16)in[(first+rc())*512+g*64+k+gr()*8+e]','a[e]=reinterpret_cast<const _Float16*>(in)[(first+rc())*512+g*64+k+gr()*8+e]')
(out/'hip/c512_half.inc').write_text('#ifndef HIP_C512_HALF_EDGE\n#define HIP_C512_HALF_EDGE 0\n#endif\n#if HIP_C512_HALF_EDGE\n'+s+d+'\n#endif\n')
p=out/'hip/build-modules.ps1';s=p.read_text();i=s.index("    @{ name = 'vit-stream';");s=s[:i]+"    @{ name = 'c512-half'; defines = @('HIP_PREPACKED_WEIGHTS 1','HIP_BRANCHLESS_F 1','HIP_C512_HALF_EDGE 1'); sources = @('deep_fast.hip','c512_half.inc') },\n"+s[i:];p.write_text(s)
for folder in ('src','Development/HIP'):
 dest=out/folder;dest.mkdir(parents=True,exist_ok=True)
 for p in (root/folder).glob('*.h'):shutil.copy2(p,dest/p.name)
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text().replace('bool c512_m32_active=false;','bool c512_m32_active=false;bool c512_half_active=false;')
s=s.replace('c512_m32_active=C512M32Compatible(opt);','c512_m32_active=C512M32Compatible(opt);c512_half_active=c512_m32_active&&std::getenv("DLSS5_HIP_C512_HALF")&&std::string(std::getenv("DLSS5_HIP_C512_HALF"))=="1";')
s=s.replace('if(c512_m32_active){\n const char*extra','if(c512_half_active){Handle m{};api.Check(api.LoadModule(&m,(opt.modules+"/c512-half.hsaco").c_str()),"c512-half.hsaco");modules["c512_half"]=m;}\nif(c512_m32_active){\n const char*extra')
s=s.replace('auto mixed=New(size_t(n)*512),','auto mixed=New(size_t(n)*(c512_half_active?256:512)),')
needle='  if(module=="mh_window")';i=s.index(needle);s=s[:i]+'''  if(c512_half_active&&kernel=="split_mix_blocked_h16w_m32"){module="c512_half";kernel="split_mix_m32_hout";}
  if(c512_half_active&&kernel=="split_ffn_fused_fp8_t8"){module="c512_half";kernel="split_ffn_t8_hin";}
'''+s[i:];p.write_text(s)
subprocess.run(['x86_64-w64-mingw32-g++','-std=c++17','-O2','-static','-municode','-I',str(out/'src'),'-I',str(out/'Development/HIP'),str(root/'Development/HIP/benchmark_vit_reuse.cpp'),'-o',str(out/'benchmark.exe'),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid'],check=True)
