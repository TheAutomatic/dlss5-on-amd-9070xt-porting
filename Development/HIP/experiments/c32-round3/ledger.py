"""Reviewed gfx1201 interior routes. Counts issued instructions, not cycles.
F has duplicated tails: never add fast and edge paths together. Archive ISA SHA with the bounds.
"""
from pathlib import Path
import importlib.util,collections,json,hashlib
ROOT=Path(__file__).resolve().parents[4]
sp=importlib.util.spec_from_file_location('L',ROOT/'Development/HIP/experiments/c32-round2/ledger.py');L=importlib.util.module_from_spec(sp);sp.loader.exec_module(L)
def report(path,variant):
 text=Path(path).read_text();out={}
 for k,b in L.old.S.llvm_kernels(text):
  if k not in ('c32_wave1_post','c32_wave1_finish','c32_wave1_finish_dcrop'):continue
  if variant=='F' and k in ('c32_wave1_finish','c32_wave1_finish_dcrop'):
   # Source loops inspected against scalar IVs: qt4, hidden8, attention4, main64/unroll4.
   if k.endswith('dcrop'):
    ranges=[(117,586,4),(207,284,8),(605,1092,4),(1138,1247,16)];omit=[(2166,2409)]
   else:
    ranges=[(119,588,4),(209,286,8),(607,1094,4),(1132,1241,16)];omit=[(1246,2124),(2137,3142),(3148,3156),(3161,3167)]
   for a,z,t in ranges:assert '.LBB' in b[a] and 's_cbranch' in b[z]
  else:
   loops=L.reviewed_loops(b,k);ranges=[(x['start'],x['end'],x['trips']) for x in loops];omit=[]
   if variant=='Q' and k.endswith('post'):omit=[(2526,3165)]
   if k=='c32_wave1_finish':
    # unchanged finish route uses the old null-down accounting
    out[k]=L.count(path)[k];continue
  count=collections.Counter();tail=collections.Counter()
  for i,line in enumerate(b):
   if any(a<=i<=z for a,z in omit):continue
   for op,_ in L.old.S.ops_of([line]):
    mul=1
    for a,z,t in ranges:
     if a<=i<=z:mul*=t
    count[L.old.S.classify(op)]+=mul
    if i>ranges[2][1]:tail[L.old.S.classify(op)]+=mul
  out[k]={'per_window':dict(count),'tail':dict(tail),'reviewed_loops':ranges,'omit':omit}
 return {'isa_sha256':hashlib.sha256(text.encode()).hexdigest(),'kernels':out}
if __name__=='__main__':
 import sys
 print(json.dumps(report(sys.argv[1],sys.argv[2]),indent=2))
