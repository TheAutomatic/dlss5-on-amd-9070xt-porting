"""Loop-weighted instruction upper-path bill; loop trip counts checked against WMMA work."""
from pathlib import Path
import sys,collections,json,importlib.util
root=Path(__file__).resolve().parents[4];sys.path.insert(0,str(root/'Development/HIP/experiments/mh-round1'));from cfg import loops
sp=importlib.util.spec_from_file_location('S',root/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(sp);sp.loader.exec_module(S)
o={}
for v,k,trips,target in [('ZR','split_mix_blocked_h16w_m32',[32],256),('R','split_mix_blocked_h16w_m32',[32],256),('N','split_mix_blocked_h16w_m32_n32',[32],128),('ZQ','mh_qkv_normalize_frag_c512_m32',[8,2],256),('Q','mh_qkv_normalize_frag_c512_m32',[8,2],256),('L-initial','mh_qkv_normalize_frag_c512_m32',[8,2],256),('L','mh_qkv_normalize_frag_c512_m32',[8,2],256)]:
 b=dict(S.llvm_kernels((Path(sys.argv[1])/(v+'.s')).read_text()))[k];ls=loops(b);assert len(ls)==len(trips),(v,len(ls));c=collections.Counter();ops=collections.Counter()
 for i,l in enumerate(b):
  m=1
  for loop,n in zip(ls,trips):
   if i in loop['lines']:m*=n
  for op,_ in S.ops_of([l]):c[S.classify(op)]+=m;ops[op]+=m
 assert c['WMMA']==target,(v,c)
 o[v]={'kernel':k,'classes':dict(c),'ops':dict(ops),'loops':[{'trips':n,'ranges':loop['ranges']} for loop,n in zip(ls,trips)]}
print(json.dumps(o,indent=2))
