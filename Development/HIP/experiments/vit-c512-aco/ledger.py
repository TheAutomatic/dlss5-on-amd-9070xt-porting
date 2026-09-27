from pathlib import Path
import importlib.util,collections,json,sys,re,hashlib
ROOT=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('S',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
def projection(path,variant):
 text=Path(path).read_text();b=dict(S.llvm_kernels(text))['vit_project_frag_n64']
 # Reviewed fixed 1024-channel kernel: four p quarters, 16 K16 steps each.
 # A unrolls all 16 K16; V unrolls four and loops four times. Residual loads occur only p=0.
 ranges=([(91,1404,4)] if variant=='A' else [(82,515,4),(408,464,4)])
 residual=(1115,1404) if variant=='A' else (112,400)
 c=collections.Counter();ops=collections.Counter();read_bytes=0;write_bytes=0
 for i,l in enumerate(b):
  m=1
  for a,z,n in ranges:
   if a<=i<=z:m*=n
  if residual[0]<=i<=residual[1]:m=1
  for op,_ in S.ops_of([l]):
   c[S.classify(op)]+=m;ops[op]+=m
   if op.startswith('global_'):
    q=re.search(r'_b(8|16|32|64|128)$',op)
    if q:
     if 'load' in op:read_bytes+=m*int(q[1])//8
     if 'store' in op:write_bytes+=m*int(q[1])//8
 assert c['WMMA']==256
 return {'classes':dict(c),'opcodes':dict(ops),'global_read_bytes_per_lane':read_bytes,'global_write_bytes_per_lane':write_bytes,'isa_sha256':hashlib.sha256(text.encode()).hexdigest(),'reviewed_loop_ranges':ranges,'p0_only':residual}
if __name__=='__main__':print(json.dumps(projection(sys.argv[1],sys.argv[2]),indent=2))
