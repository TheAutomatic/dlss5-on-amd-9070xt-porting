"""Generate an isolated current-host two-boundary stage probe; no production changes."""
import argparse,hashlib,json
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];source=(r/'Development/HIP/hip_reference_network.h').read_text();s=source
s=s.replace('#include "../../src/native_experimental_history.h"','#include "'+str(r/'src/native_experimental_history.h')+'"')
fields='''
 Handle sparse_begin{},sparse_end{};unsigned sparse_kind=0;bool sparse_started=false,sparse_complete=false;unsigned sparse_pdl_before=0,sparse_pdl_delta=0;
 void SparseBegin(unsigned kind){if(sparse_kind!=kind)return;if(sparse_started)throw std::runtime_error("duplicate sparse begin");sparse_pdl_before=pdl_calls;api.Check(api.hipEventRecord(sparse_begin,stream),"sparse begin");sparse_started=true;}
 void SparseEnd(unsigned kind){if(sparse_kind!=kind)return;if(!sparse_started||sparse_complete)throw std::runtime_error("sparse stage order");api.Check(api.hipEventRecord(sparse_end,stream),"sparse end");sparse_pdl_delta=pdl_calls-sparse_pdl_before;sparse_complete=true;}
'''
s=s.replace(' Tensor temporal_features;',fields+' Tensor temporal_features;',1)
methods='''
 void ConfigureSparseStage(unsigned kind){if(kind>2||opt.graph)throw std::runtime_error("sparse requires graph0 and kind0..2");sparse_kind=kind;if(kind&&!sparse_begin){api.Check(api.hipEventCreate(&sparse_begin),"sparse event");api.Check(api.hipEventCreate(&sparse_end),"sparse event");}}
 float ReadSparseStage(){if(!sparse_kind)return -1.f;if(!sparse_complete||sparse_pdl_delta||pdl_calls)throw std::runtime_error("sparse stage incomplete or anyorder present");float ms=-1;api.Check(api.hipEventElapsedTime(&ms,sparse_begin,sparse_end),"sparse elapsed");if(!std::isfinite(ms)||ms<=0)throw std::runtime_error("bad sparse event batch");return ms;}
'''
s=s.replace(' void PrintMemory(){',methods+' void PrintMemory(){',1)
s=s.replace('void Enqueue(void*rgba,void*history,void*rgb_output,U seed){','void Enqueue(void*rgba,void*history,void*rgb_output,U seed){sparse_started=false;sparse_complete=false;sparse_pdl_delta=0;')
needle='for(U j=0;j<8;j++){source=Body(source,W/32,H/32,512,shifts[j],23+j,j==7);}skips[4]=source;';assert s.count(needle)==1
s=s.replace(needle,'SparseBegin(1);'+needle.replace('}skips','}SparseEnd(1);skips'),1)
needle='source=AdaptiveVitGroup(source,n);';assert s.count(needle)==1;s=s.replace(needle,'SparseBegin(2);'+needle+'SparseEnd(2);',1)
s=s.replace('SpReport();pdl_keep.clear();','if(sparse_begin)api.hipEventDestroy(sparse_begin);if(sparse_end)api.hipEventDestroy(sparse_end);SpReport();pdl_keep.clear();',1)
(a.output/'hip_reference_network.h').write_text(s)
(a.output/'source.json').write_text(json.dumps({'base_sha256':hashlib.sha256(source.encode()).hexdigest(),'instrumented_sha256':hashlib.sha256(s.encode()).hexdigest(),'new_pairs_per_frame':1,'existing_total_pair_per_frame':1,'kinds':{'1':'C512 encoder Body23..30','2':'ViT Adaptive31..38 AE0 only'},'ordering':'Read requires stage pdl_delta0 AND full-frame pdl_calls0; otherwise rejects'},indent=2)+'\n')

env=(r/'src/native_hip_env_options.h').read_text().replace('#include "../Development/HIP/hip_reference_network.h"','#include "hip_reference_network.h"')
(a.output/'native_hip_env_options.h').write_text(env)
