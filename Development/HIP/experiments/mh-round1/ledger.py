from pathlib import Path
import importlib.util,collections,json,re,sys,hashlib
import cfg
ROOT=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('S',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
# Source callsites from immutable build-A generated HIP. The 144-line shared attention body occurs twice.
def phase(n,attn):
 if attn:
  if 1212<=n<=1255:return 'input_qkv',1
  if 1256<=n<=1339:n-=144
 if 1027<=n<=1044:return 'input',1
 if 1046<=n<=1065:
  if 1050<=n<=1055:return 'ffn_expand',16
  if n in (1058,1059):return 'activation',16
  if 1060<=n<=1063:return 'ffn_contract',16
  return 'ffn_loop',16 if n>=1048 else 4
 if n==1066:return 'contract_rtz_pack',4
 if n==1072:return 'residual_input_rtz',4
 if 1070<=n<=1076:return 'ffn_mix',4
 if n==1077:return 'feature_pack',4
 if 1080<=n<=1111:return ('qkv_norm_pack' if 1101<=n<=1107 else 'qkv_matrix'),1
 if 1112<=n<=1154:return 'score_exp',4
 if 1155<=n<=1161:return 'softmax',4
 if 1162<=n<=1167:return 'av',4
 if 1170<=n<=1181:return 'projection',4
 if 1182<=n<=1190:return 'tail',4
 return 'control_unattributed',1
source=Path(sys.argv[2]);assert hashlib.sha256(source.read_bytes()).hexdigest()=='5765f396d95443ad3cab834f2b7a952bf0f7d20221d5356031852849bc5fbb69', 'Review the phase map for this generated source'
text=Path(sys.argv[1]).read_text();out={}
for k,b in S.llvm_kernels(text):
 if not re.match(r'c(?:64|128|256)_(?:wave2|attn_wave)',k):continue
 ls,reachable=cfg.analyze(b);trips=([1,4,4,2] if k=='c256_attn_wave' else [1,4,4] if 'attn' in k else [4]*5);assert len(ls)==len(trips),(k,len(ls));
 cur=0;d=collections.defaultdict(collections.Counter)
 for index,l in enumerate(b):
  if index not in reachable:continue
  if '.loc' in l:
   ns=[int(x) for x in re.findall(r'probe.hip:(\d+):\d+',l)];ns=[x for x in ns if (1212<=x<=1334 if 'attn' in k else 1027<=x<=1190)];cur=ns[-1] if ns else cur
  name,_=phase(cur,'attn' in k);mul=1
  for loop,t in zip(ls,trips):
   if index in loop['lines']:mul*=t
  for op,_ in S.ops_of([l]):
   dest='projection' if S.classify(op)=='WMMA' and index in ls[2 if 'attn' in k else 4]['lines'] else name
   d[dest][S.classify(op)]+=mul
 total=collections.Counter()
 for c in d.values():total.update(c)
 expected=232 if 'attn' in k else 168+int(re.match(r'c(\d+)',k)[1])*9//2
 assert total['WMMA']==expected,(k,total['WMMA'],expected)
 out[k]={'per_wave_upper':dict(total),'phases':{a:dict(c) for a,c in d.items()}}
print(json.dumps({'isa_sha256':hashlib.sha256(text.encode()).hexdigest(),'kernels':out},indent=2))
