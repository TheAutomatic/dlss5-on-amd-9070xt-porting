# Annotate the immutable round-1 baseline using debug locations, after checking .text identity.
from pathlib import Path
import hashlib,importlib.util,collections,re,json,sys
here=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('ledger',here/'ledger.py');L=importlib.util.module_from_spec(spec);spec.loader.exec_module(L)
source=Path(sys.argv[2]);text=source.read_text().splitlines()
assert 'DEV void cw_body' in text[791] and 'if(!CW_TAIL_QUAD&&down)' in text[955], 'Review the phase ranges for changed source'
def phase(n):
 if 808<=n<=860:return 'input'
 if 861<=n<=864:return 'ffn_residual'
 if n in (868,869):return 'ffn_expand'
 if n==870:return 'activation_pack'
 if n==871:return 'ffn_contract'
 if 873<=n<=880:return 'feature_rtz_pack'
 if 881<=n<=890:return 'qkv_norm' if n in (888,889) else 'qkv_matrix'
 if 904<=n<=908:return 'scores_exp'
 if 910<=n<=912:return 'softmax'
 if n==913:return 'av'
 if 914<=n<=925:return 'projection_quant'
 if n==926 or 931<=n<=960:return 'tail'
 return 'control_unattributed'
out={}
for k,b in L.old.S.llvm_kernels(Path(sys.argv[1]).read_text()):
 if not k.startswith('c32_wave1'):continue
 lp=L.reviewed_loops(b,k);p=collections.defaultdict(collections.Counter);cur=0
 for i,l in enumerate(b):
  if '.loc' in l:
   ns=[int(x) for x in re.findall(r'probe.hip:(\d+):\d+',l)];ns=[x for x in ns if 792<=x<=961];cur=ns[-1] if ns else 0
  for op,_ in L.old.S.ops_of([l]):
   w=1
   for loop in lp:
    if loop['start']<=i<=loop['end']:w*=loop['trips']
   p[phase(cur)][L.old.S.classify(op)]+=w
 out[k]={a:dict(v) for a,v in p.items()}
print(json.dumps(out,indent=2))
