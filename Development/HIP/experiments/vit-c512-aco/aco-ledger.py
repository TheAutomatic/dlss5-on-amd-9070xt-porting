"""ACO single-loop kernels at K=1024 (ViT) or C=512 (split C512).
BB1 header runs trips+1; BB3 body runs trips. Fixed epilogues run once.
Includes all conditional epilogue blocks, so normalized QKV epilogue is an upper bill.
"""
from pathlib import Path
import importlib.util,collections,json,re,sys
ROOT=Path(__file__).resolve().parents[4]
s=importlib.util.spec_from_file_location('S',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(s);s.loader.exec_module(S)
trips={'g_ffwd3':4,'g_ffwd3w':4,'g_gemmproj':2,'g_gemmvact':32,'g_gemmvproj':32,'g_gemmvqkv':32,'g_gemmvqkvnorm':32,'g_gemmvqkvs':4}
out={}
for k,n in trips.items():
 p=Path(sys.argv[1])/(k+'.s');bb='';c=collections.Counter()
 for l in p.read_text().splitlines():
  if re.fullmatch('BB[0-9]+',l):bb=l
  w=n+1 if bb=='BB1' else n if bb=='BB3' else 1
  for op,_ in S.ops_of([l],True):c[S.classify(op)]+=w
 out[k]={'trips':n,'classes':dict(c)}
print(json.dumps(out,indent=2))
