#!/usr/bin/env python3
"""CPU prepare untimed same-position HIP record-pair. No production/GPU change."""
import argparse, hashlib, json, pathlib, subprocess, sys
sys.dont_write_bytecode=True
HERE=pathlib.Path(__file__).resolve().parent;ROOT=HERE.parents[3]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=pathlib.Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
subprocess.run([sys.executable,str(ROOT/'Development/HIP/experiments/submission-pacing-20261006/prepare.py'),str(a.output)],check=True)
path=a.output/'hip_reference_network.h';s=path.read_text()
s=s.replace('using SparseQueryFn=int(*)(Handle);','using CreateFlagsFn=int(*)(Handle*,unsigned);CreateFlagsFn sparse_create_flags{};unsigned long long untimed_records=0;using SparseQueryFn=int(*)(Handle);')
needle='  else if(sparse_kind==4){';assert s.count(needle)==1
s=s.replace(needle,'  else if(sparse_kind==6){api.Check(api.hipEventRecord(sparse_begin,stream),"untimed same-position begin");api.Check(api.hipEventRecord(sparse_end,stream),"untimed same-position end");untimed_records+=2;}\n'+needle)
s=s.replace('if(kind>5||opt.graph)','if(kind>6||opt.graph)')
needle='sparse_kind=kind;if((kind==1||kind==2||kind==3)&&!sparse_begin)'
assert needle in s
s=s.replace(needle,'''sparse_kind=kind;
 if(kind==6&&!sparse_begin){sparse_create_flags=reinterpret_cast<CreateFlagsFn>(GetProcAddress(api.dll,"hipEventCreateWithFlags"));if(!sparse_create_flags)throw std::runtime_error("untimed marker unsupported: missing hipEventCreateWithFlags export");api.Check(sparse_create_flags(&sparse_begin,2u),"untimed create begin");api.Check(sparse_create_flags(&sparse_end,2u),"untimed create end");}
 if((kind==1||kind==2||kind==3)&&!sparse_begin)''')
s=s.replace('if(!sparse_kind||sparse_kind==4||sparse_kind==5)return -1.f;', 'if(!sparse_kind||sparse_kind==3||sparse_kind==4||sparse_kind==5||sparse_kind==6)return -1.f;')
# The pair positive control must not call inner ElapsedTime either: outer endpoints
# remain the sole timed GPU boundaries for both pair variants.
s=s.replace(' double PacingCpuUs()const{', ' unsigned long long UntimedRecordCount()const{return untimed_records;}\n double PacingCpuUs()const{',1)
path.write_text(s)
bench=(a.output/'benchmark.cpp').read_text();bench=bench.replace('api.hipEventDestroy(begin);api.hipEventDestroy(end);', 'printf("UNTIMED_MARKER_RECORDS %llu flags=0x2 position=C512-encoder-start query_sync_inner_elapsed=0\\n",net.UntimedRecordCount());api.hipEventDestroy(begin);api.hipEventDestroy(end);')
(a.output/'benchmark.cpp').write_text(bench)
(a.output/'production_options.generated.h').write_bytes(pathlib.Path('/tmp/sync-network-gap-20261006/production_options.generated.h').read_bytes())
cmd=['x86_64-w64-mingw32-g++','-w','-std=c++17','-O2','-static','-I'+str(a.output),'-I'+str(ROOT/'Development/HIP'),'-I'+str(ROOT/'src'),str(a.output/'benchmark.cpp'),'-o',str(a.output/'benchmark-untimed.exe')]
subprocess.run(cmd,check=True)
(a.output/'untimed-source.json').write_text(json.dumps({'base_kind3':'same-position timed pair, inner elapsed disabled in this control','kind6':'same-position two events created with hipEventDisableTiming0x2','point':'before C512 encoder Body23..30 ONLY','create':'once before warmup, optional export mandatory if selected','destroy':'after existing owned-stream synchronize, before stream destruction','no_added':'query/sync/DisableSystemFence/any location grid','outer_GPU_timed_events':'unchanged','scope':'candidate may still generate timestamps/markers; no flush or speed guarantee','host_sha256':hashlib.sha256((a.output/'benchmark-untimed.exe').read_bytes()).hexdigest(),'core_source_sha256':hashlib.sha256(s.encode()).hexdigest(),'compile':cmd},indent=2)+'\n')
print('CPU_UNTIMED_MARKER_BUILD_PASS',a.output)
