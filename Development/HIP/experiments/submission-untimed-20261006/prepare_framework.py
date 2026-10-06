#!/usr/bin/env python3
"""Prepare the same full NativeGameFrame pulse with timing-disabled event creation."""
import argparse,hashlib,json,pathlib,subprocess,sys
sys.dont_write_bytecode=True
HERE=pathlib.Path(__file__).resolve().parent;ROOT=HERE.parents[3]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=pathlib.Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(ROOT/'Development/HIP/experiments/framework-submit-pair-20261006/prepare.py'),str(a.output)],check=True)
path=a.output/'hip_reference_network.h';s=path.read_text()
old='''{const char*v=std::getenv("DLSS5_LAB_SUBMIT_PAIR");if(v&&!std::strcmp(v,"1")){if(opt.graph)throw std::runtime_error("submit pair trial requires graph0");api.Check(api.hipEventCreate(&submit_pair_begin),"submit pair begin");api.Check(api.hipEventCreate(&submit_pair_end),"submit pair end");submit_pair_active=true;std::fprintf(stderr,"submit_pair_trial active=1 point=C512-encoder-start timed=1 preallocated=1\\n");}}'''
assert s.count(old)==1
new='''{const char*t=std::getenv("DLSS5_LAB_SUBMIT_PAIR"),*u=std::getenv("DLSS5_LAB_SUBMIT_UNTIMED_PAIR");const bool timed=t&&!std::strcmp(t,"1"),untimed=u&&!std::strcmp(u,"1");
 if(timed&&untimed)throw std::runtime_error("choose one same-position pulse control");
 if(timed||untimed){if(opt.graph)throw std::runtime_error("submit pair trial requires graph0");
  if(untimed){using CreateFlagsFn=int(*)(Handle*,unsigned);auto create=reinterpret_cast<CreateFlagsFn>(GetProcAddress(api.dll,"hipEventCreateWithFlags"));if(!create)throw std::runtime_error("untimed event unsupported: missing hipEventCreateWithFlags");api.Check(create(&submit_pair_begin,2u),"untimed begin create");int e=create(&submit_pair_end,2u);if(e){api.hipEventDestroy(submit_pair_begin);submit_pair_begin=nullptr;api.Check(e,"untimed end create");}}
  else{api.Check(api.hipEventCreate(&submit_pair_begin),"timed begin create");int e=api.hipEventCreate(&submit_pair_end);if(e){api.hipEventDestroy(submit_pair_begin);submit_pair_begin=nullptr;api.Check(e,"timed end create");}}
  submit_pair_active=true;std::fprintf(stderr,"submit_pair_trial active=1 point=C512-encoder-start api_timing_disabled=%u flags=%u preallocated=1 hw_timestamp_removal_unverified=1\\n",unsigned(untimed),untimed?2u:0u);
 }}'''
s=s.replace(old,new);path.write_text(s)
cmd=['x86_64-w64-mingw32-g++','-w','-std=c++17','-O2','-static','-municode','-DDLSS5_USE_HIP=1','-I'+str(a.output),'-I'+str(ROOT/'src'),'-I'+str(ROOT/'Development/HIP'),str(a.output/'benchmark.cpp'),'-o',str(a.output/'benchmark-framework-untimed.exe'),'-ld3d12','-ldxgi','-ld3dcompiler','-ldxguid']
subprocess.run(cmd,check=True)
(a.output/'framework-untimed-source.json').write_text(json.dumps({'scope':'same current complete NativeGameFrame, same one C512 start point','flags':'none / DLSS5_LAB_SUBMIT_PAIR=1 / DLSS5_LAB_SUBMIT_UNTIMED_PAIR=1; both1 reject','API_disabled_timing':2,'source_sha256':hashlib.sha256(s.encode()).hexdigest(),'host_sha256':hashlib.sha256((a.output/'benchmark-framework-untimed.exe').read_bytes()).hexdigest(),'no_advance':'no GPU/runtime flag-acceptance/speed claim; prepare/build only','command':cmd},indent=2)+'\n')
print('CPU_FRAMEWORK_UNTIMED_BUILD_PASS',a.output)
