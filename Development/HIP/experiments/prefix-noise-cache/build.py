#!/usr/bin/env python3
"""Local CPU-only standalone LLVM23+MinGW build of isolated prefix cache probes."""
import argparse, hashlib, json, pathlib, subprocess, sys, struct
sys.dont_write_bytecode=True
HERE=pathlib.Path(__file__).resolve().parent
ROOT=HERE.parents[3]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=pathlib.Path);p.add_argument('--llvm',type=pathlib.Path,default=pathlib.Path('/home/lmxxf/work/llvm-build-23/bin'));p.add_argument('--production-options',type=pathlib.Path,default=pathlib.Path('/tmp/sync-network-gap-20261006/production_options.generated.h'));a=p.parse_args()
subprocess.run([sys.executable,str(HERE/'prepare.py'),str(a.output)],check=True)
(a.output/'production_options.generated.h').write_bytes(a.production_options.read_bytes())
(a.output/'native_hip_env_options.h').write_text((ROOT/'src/native_hip_env_options.h').read_text().replace('"../Development/HIP/hip_reference_network.h"','"hip_reference_network.h"'))
rows=json.loads((a.output/'source.json').read_text())['rows'];out=a.output/'gfx1201';out.mkdir(exist_ok=True);receipt=[]
for row in rows:
 name=row['name'];source=a.output/(name+'.hip');bc=out/(name+'.bc');obj=out/(name+'.o');asm=out/(name+'.s');elf=out/(name+'.hsaco')
 cuid=hashlib.sha256(struct.pack('<Q',source.stat().st_size)+source.read_bytes()).hexdigest().upper()
 front=[str(a.llvm/'clang'),'--target=x86_64-pc-windows-msvc','--offload-arch=gfx1201','-O3','-x','hip','--offload-device-only','-cuid='+cuid,'-c','-emit-llvm','-fshort-wchar','-std=c++14','-fms-compatibility-version=19.44.35229','-nogpuinc','-nogpulib','-Xclang','-target-feature','-Xclang','-real-true16',str(source),'-o',str(bc)]
 back=[str(a.llvm/'clang'),'-target','amdgcn-amd-amdhsa','-mcpu=gfx1201','-O3','-nogpulib','-Xclang','-target-feature','-Xclang','-real-true16']
 for flag in row['backend_opts']:back+=['-mllvm',flag]
 commands=[front,back+['-S',str(bc),'-o',str(asm)],back+['-c',str(bc),'-o',str(obj)],[str(a.llvm/'ld.lld'),'-shared',str(obj),'-o',str(elf)]]
 with (out/(name+'.build.log')).open('w') as log:
  for command in commands:subprocess.run(command,stdout=log,stderr=log,check=True)
 receipt.append(dict(name=name,commands=commands,sha256=hashlib.sha256(elf.read_bytes()).hexdigest(),bytes=elf.stat().st_size))
cmd=['x86_64-w64-mingw32-g++','-w','-std=c++17','-O2','-static','-I'+str(a.output),'-I'+str(ROOT/'Development/HIP'),'-I'+str(ROOT/'src'),str(HERE/'probe.cpp'),'-o',str(a.output/'probe.exe')]
subprocess.run(cmd,check=True)
(a.output/'build.json').write_text(json.dumps({'module_builds':receipt,'host_command':cmd,'host_sha256':hashlib.sha256((a.output/'probe.exe').read_bytes()).hexdigest(),'llvm_version':subprocess.check_output([str(a.llvm/'clang'),'--version'],text=True)},indent=2)+'\n')
print('CPU_PREFIX_CACHE_BUILD_PASS',a.output)
