"""Canonical active LLVM23 route; no remote calls, no GPU loading."""
import argparse,json,subprocess,hashlib,struct
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('names',nargs='+');p.add_argument('--arch',default='gfx1201',choices=['gfx1201','gfx1200']);a=p.parse_args();c=Path('/home/lmxxf/work/llvm-build-23/bin');records={}
for n in a.names:
 s=a.root/(n+'.hip');bc=a.root/(n+'-canonical.bc');obj=a.root/(n+'-canonical.o');h=a.root/(n+'-canonical.hsaco');cuid=hashlib.sha256(struct.pack('<Q',s.stat().st_size)+s.read_bytes()).hexdigest().upper()
 front=[str(c/'clang'),'--target=x86_64-pc-windows-msvc','--offload-arch='+a.arch,'-O3','-x','hip','--offload-device-only','-cuid='+cuid,'-c','-emit-llvm','-fshort-wchar','-std=c++14','-fms-compatibility-version=19.44.35229','-nogpuinc','-nogpulib','-Xclang','-target-feature','-Xclang','-real-true16',str(s),'-o',str(bc)]
 back=[str(c/'clang'),'-target','amdgcn-amd-amdhsa','-mcpu='+a.arch,'-O3','-nogpulib','-Xclang','-target-feature','-Xclang','-real-true16','-mllvm','-enable-post-misched=0','-mllvm','-amdgpu-sched-strategy=max-ilp','-c','-mllvm','-amdgpu-internalize-symbols',str(bc),'-o',str(obj)]
 link=[str(c/'ld.lld'),'--no-undefined','-shared','-plugin-opt=mcpu='+a.arch,str(obj),'-o',str(h)]
 with (a.root/(n+'-canonical.build.log')).open('w') as log:
  for cmd in [front,back,link]:subprocess.run(cmd,stdout=log,stderr=log,check=True)
 for tool,args,ext in [('llvm-objdump',['-d','--mcpu='+a.arch],'isa'),('llvm-readobj',['--notes'],'notes')]:
  with (a.root/(n+'-canonical.'+ext)).open('w') as f:subprocess.run([str(c/tool),*args,str(h)],stdout=f,check=True)
 records[n]={'commands':[front,back,link],'sha256':hashlib.sha256(h.read_bytes()).hexdigest()}
(a.root/'latest-build.json').write_text(json.dumps(records,indent=2)+'\n')
