"""Loop-weighted upper-path bill, gfx1201; full 32-token tile and Q/K normalization path.
Branches not pruned except loops; tail predicates make this a conservative instruction-work estimate.
"""
from pathlib import Path
import importlib.util,collections,json,hashlib
ROOT=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('S',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
configs={
 'split_mix_blocked_h16w_m32':('c512-m32-deep',[(77,156,32)],256),
 'mh_qkv_normalize_frag_c512_m32':('c512-m32-mh',[(97,267,8),(327,888,2)],256),
 'split_projection_frag':('deep_fast-packed',[(343,410,8)],128),
 'split_ffn_fused_fp8_t8':('deep_fast-packed',[],32),
}
if __name__=='__main__':
 import sys
 out={}
 for k,(module,ranges,wmma) in configs.items():
  p=Path(sys.argv[1])/(module+'.hsaco.s');text=p.read_text();b=dict(S.llvm_kernels(text))[k];c=collections.Counter();ops=collections.Counter()
  for i,l in enumerate(b):
   mul=1
   for a,z,t in ranges:
    if a<=i<=z:mul*=t
   for op,_ in S.ops_of([l]):c[S.classify(op)]+=mul;ops[op]+=mul
  assert c['WMMA']==wmma,(k,c)
  out[k]={'classes':dict(c),'opcodes':dict(ops),'ranges':ranges,'isa_sha256':hashlib.sha256(text.encode()).hexdigest()}
 print(json.dumps(out,indent=2))
