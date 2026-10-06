"""Build isolated counter-only headers; no production mutation or GPU work."""
from pathlib import Path
import shutil,sys
root=Path(__file__).resolve().parents[3]
out=Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
for p in (root/'HIP').glob('*.h'):shutil.copy2(p,out/p.name)
p=out/'hip_reference_network.h';s=p.read_text()
a='public: unsigned PdlCalls()const{return pdl_calls;} private:'
assert s.count(a)==1
s=s.replace(a,'public: unsigned long long DiagnosticDispatchCount()const{return diagnostic_dispatch_count;} unsigned PdlCalls()const{return pdl_calls;} private: unsigned long long diagnostic_dispatch_count=0;')
a='unsigned gg=unsigned(groups?groups:(count+255ull)/256);';assert s.count(a)==1
p.write_text(s.replace(a,'++diagnostic_dispatch_count;'+a))
p=out/'swin_persistent_network.h';s=p.read_text();a='api.Check(api.hipModuleLaunchKernel(';assert s.count(a)==4;p.write_text(s.replace(a,'++diagnostic_dispatch_count;'+a))
for p in out.glob('*.h'):p.write_text(p.read_text().replace('"../../src/','"'+str(root.parent/'src')+'/'))
shutil.copy2(root.parent/'src/native_hip_env_options.h',out/'native_hip_env_options.h')
p=out/'native_hip_env_options.h';p.write_text(p.read_text().replace('../Development/HIP/hip_reference_network.h','hip_reference_network.h'))
shutil.copy2(Path(__file__).with_name('benchmark.cpp'),out/'benchmark.cpp')
print('Supply frozen production_options.generated.h from fresh-mochi1088; compile C++17 O2 static with src include.')
