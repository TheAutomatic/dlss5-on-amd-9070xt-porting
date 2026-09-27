# Isolated build tree; no production changes until the lifetime probe justifies them.
from pathlib import Path
import shutil
root=Path(__file__).resolve().parents[4]
out=Path('/tmp/yami-runtime-stream')
for part in ('src','Development/HIP','include'):
 d=out/part;d.mkdir(parents=True,exist_ok=True)
 for p in (root/part).glob('*.h'):shutil.copy2(p,d/p.name)
shutil.copy2(root/'src/LmxxfNrRuntime.cpp',out/'src/LmxxfNrRuntime.cpp')
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text()
s=s.replace('class Network {','''class Network {
 struct CachedStream {unsigned runtime,device;Handle stream;};
 static std::vector<CachedStream>& StreamCache(){static std::vector<CachedStream> p;return p;}
 static std::mutex& StreamMutex(){static std::mutex m;return m;}
 void AcquireStream(){std::lock_guard<std::mutex> lock(StreamMutex());auto&p=StreamCache();for(auto it=p.begin();it!=p.end();++it)if(it->runtime==opt.runtime&&it->device==opt.device){stream=it->stream;p.erase(it);return;}api.Check(api.hipStreamCreate(&stream),"stream");}
 void ReturnStream(){if(api.hipStreamSynchronize(stream)){api.hipStreamDestroy(stream);return;}std::lock_guard<std::mutex> lock(StreamMutex());StreamCache().push_back({opt.runtime,opt.device,stream});}
''')
s=s.replace('api.Check(api.hipStreamCreate(&stream),"stream");try{','AcquireStream();try{')
# Only successful destruction returns the stream. Construction failures destroy theirs.
s=s.replace('for(auto&m:modules)api.hipModuleUnload(m.second);api.hipStreamDestroy(stream);}', 'for(auto&m:modules)api.hipModuleUnload(m.second);ReturnStream();}')
s=s.replace('#include <atomic>','#include <atomic>\n#include <mutex>')
p.write_text(s)
print(out)
