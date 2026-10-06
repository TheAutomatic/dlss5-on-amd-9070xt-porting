"""Extend isolated sparse-host C512 start with empty pair/query/CPU-delay controls."""
import argparse,hashlib,json,subprocess,sys
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4]
subprocess.run([sys.executable,str(r/'Development/HIP/experiments/sparse-stage-20261006/prepare.py'),str(a.output)],check=True)
path=a.output/'hip_reference_network.h';s=path.read_text()
s=s.replace(' Handle sparse_begin{},sparse_end{};', ' using SparseQueryFn=int(*)(Handle);SparseQueryFn sparse_query{};double sparse_cpu_us=0,sparse_delay_us=0;int sparse_query_code=-1;\n Handle sparse_begin{},sparse_end{};')
old=' void SparseBegin(unsigned kind){if(sparse_kind!=kind)return;'
new=''' void SparseBegin(unsigned kind){
 if(kind==1&&sparse_kind>=3){
  auto begin=std::chrono::steady_clock::now();
  if(sparse_kind==3){api.Check(api.hipEventRecord(sparse_begin,stream),"empty pair begin");api.Check(api.hipEventRecord(sparse_end,stream),"empty pair end");sparse_started=sparse_complete=true;}
  else if(sparse_kind==4){sparse_query_code=sparse_query(stream);if(sparse_query_code!=0&&sparse_query_code!=600)throw std::runtime_error("nonblocking query error");}
  else if(sparse_kind==5){while(std::chrono::duration<double,std::micro>(std::chrono::steady_clock::now()-begin).count()<sparse_delay_us)std::atomic_signal_fence(std::memory_order_seq_cst);}
  sparse_cpu_us=std::chrono::duration<double,std::micro>(std::chrono::steady_clock::now()-begin).count();return;
 }
 if(sparse_kind!=kind)return;'''
assert s.count(old)==1;s=s.replace(old,new)
s=s.replace('void ConfigureSparseStage(unsigned kind){if(kind>2||opt.graph)', 'void ConfigureSparseStage(unsigned kind,double delay_us){sparse_delay_us=delay_us;if(kind==4){sparse_query=reinterpret_cast<SparseQueryFn>(GetProcAddress(api.dll,"hipStreamQuery"));if(!sparse_query)throw std::runtime_error("query export missing");}if(kind>5||opt.graph)')
s=s.replace('if(kind&&!sparse_begin)', 'if((kind==1||kind==2||kind==3)&&!sparse_begin)')
s=s.replace('if(!sparse_kind)return -1.f;', 'if(!sparse_kind||sparse_kind==4||sparse_kind==5)return -1.f;')
s=s.replace('if(!std::isfinite(ms)||ms<=0)', 'if(!std::isfinite(ms)||ms<0||(sparse_kind!=3&&ms==0))')
s=s.replace(' void PrintMemory(){',' double PacingCpuUs()const{return sparse_cpu_us;}\n int PacingQueryCode()const{return sparse_query_code;}\n void PrintMemory(){',1)
s=s.replace('sparse_started=false;sparse_complete=false;sparse_pdl_delta=0;', 'sparse_started=false;sparse_complete=false;sparse_pdl_delta=0;sparse_cpu_us=0;sparse_query_code=-1;')
path.write_text(s)
bench=(r/'Development/HIP/experiments/sparse-stage-20261006/benchmark.cpp').read_text().replace('argc!=11','argc!=12').replace('SPARSE_KIND','SPARSE_KIND DELAY_US')
bench=bench.replace('net.ConfigureSparseStage(std::stoul(argv[10]));','net.ConfigureSparseStage(std::stoul(argv[10]),std::stod(argv[11]));')
bench=bench.replace('stage_ms,pdl_calls\\n','stage_ms,pdl_calls,pacing_cpu_us,query_code\\n')
bench=bench.replace("<<net.PdlCalls()<<'\\n';", "<<net.PdlCalls()<<','<<net.PacingCpuUs()<<','<<net.PacingQueryCode()<<'\\n';")
(a.output/'benchmark.cpp').write_text(bench)
(a.output/'pacing-source.json').write_text(json.dumps({'host_sha256':hashlib.sha256(s.encode()).hexdigest(),'point':'before C512 Body23..30','modes':{'0':'none','3':'empty pair both recorded at same point','4':'hipStreamQuery one snapshot; no poll loop/sync','5':'CPU busy delay calibrated to pair-call time'},'API_scope':'documented record/query contracts; Windows submit/flush side effects are hypotheses'},indent=2)+'\n')
