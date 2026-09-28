from pathlib import Path
import sys,re,collections,json,importlib.util
R=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(R/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
sys.path.insert(0,str(R/'Development/HIP/experiments/mh-round1'));import cfg
spec=importlib.util.spec_from_file_location('C',R/'Development/HIP/experiments/c32-round2/ledger.py');C=importlib.util.module_from_spec(spec);spec.loader.exec_module(C)
def phase(n,c32):
 if c32:
  if n<928:return 'input_residual'
  if n<=935:return 'expand'
  if n==936:return 'activation'
  if n==937:return 'contract'
  if n<=945:return 'feature'
  if n<=953:return 'qkv_matrix'
  if n<=960:return 'qkv_norm'
  if n<=974:return 'score_exp'
  if n<=978:return 'softmax'
  if n==979:return 'av'
  if n<=995:return 'projection'
  return 'tail'
 if n<1089:return 'input'
 if n<1100:return 'expand'
 if n==1100:return 'activation'
 if n<=1105:return 'contract'
 if n<=1113:return 'contract_quant'
 if n<=1136:return 'mix'
 if n<=1158:return 'qkv_matrix'
 if n<=1168:return 'qkv_norm'
 if n<=1210:return 'score_exp'
 if n<=1218:return 'softmax'
 if n<=1225:return 'av'
 if n<=1276:return 'projection'
 return 'tail'
out={}
for module in ('c32-wave1','c64-wave2'):
 c32=module=='c32-wave1';txt=Path('/tmp/aco-lineup',module+'-debug.hsaco.s').read_text()
 for k,b in S.llvm_kernels(txt):
  if not (k.startswith('c32_wave1') if c32 else re.match(r'c(?:64|128|256)_(?:wave2|attn_wave)',k)):continue
  ls,reach=cfg.analyze(b)
  if c32:
   trips=[4,8,4]+[1]*(len(ls)-3) # tails excluded from selected-segment ranking
  else:trips=[1,4,4,2] if k=='c256_attn_wave' else [1,4,4] if 'attn' in k else [4]*5
  assert len(ls)==len(trips),(k,len(ls),len(trips))
  cur=0;d=collections.defaultdict(collections.Counter);ops=collections.defaultdict(collections.Counter);rows=[]
  for i,l in enumerate(b):
   if i not in reach:continue
   if '.loc' in l:
    ns=[int(x) for x in re.findall(r'probe.hip:(\d+):\d+',l)]
    if 'attn' in k:ns=[n-190 if n>=1359 else 1080 for n in ns if 1313<=n<=1482]
    else:ns=[n for n in ns if (857<=n<=1081 if c32 else 1055<=n<=1292)]
    cur=ns[-1] if ns else 0
   w=1
   for loop,t in zip(ls,trips):
    if i in loop['lines']:w*=t
   ph=phase(cur,c32) if cur else 'unattributed'
   for op,_ in S.ops_of([l]):
    d[ph][S.classify(op)]+=w;ops[ph][op]+=w
    rows.append({'line':i+1,'phase':ph,'weight':w,'source':cur,'op':op,'isa':l.strip()})
  out[k]={'phases':d,'ops':ops,'loops':[{'header':x['header'],'trip':t} for x,t in zip(ls,trips)],'rows':rows}
Path('/tmp/aco-lineup/phases.json').write_text(json.dumps(out,indent=2))
for k in ('c32_wave1_chain','c64_wave2_bi_bo','c128_wave2_bi_bo','c256_attn_wave_bo'):
 print(k,[(p,sum(n for cls,n in c.items() if cls in ('VALU','VOPD'))) for p,c in out[k]['phases'].items()])
