#!/usr/bin/env python3
"""C32 ISA accounting. Counts issue instructions (a VOPD pair counts once).
Loops traced against 0.34 source: qt=4, hidden=8, attention qt=4;
main finish t=64 in pairs (32 iterations), downsample k=16, post t=2. Full interior window,
main/down enabled and prefix history enabled; boundary-skip paths cost less.
Debug line tables are used only after .text identity was checked.
"""
import collections, hashlib, importlib.util, json, re, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('stats',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py')
S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
CLASSES=('VALU','VOPD','WMMA','DS','VMEM','SALU','SMEM','WAIT')
def loops(body,k):
 labels={m[1]:i for i,l in enumerate(body) if (m:=re.match(r'(\.LBB\w+):',l))}
 backs={}
 for i,l in enumerate(body):
  m=re.search(r's_(?:cbranch_\w+|branch) (\.LBB\w+)',l)
  if m and labels.get(m[1],10**9)<i:backs[m[1]]=max(i,backs.get(m[1],0))
 pairs=sorted((labels[l],e,l) for l,e in backs.items())
 trips=[4,8,4]+({'c32_wave1_finish':[32],'c32_wave1_finish_dcrop':[32,16], 'c32_wave1_post':[2],'c32_wave1_prefix':[32]}.get(k,[]))
 if len(pairs)!=len(trips):raise ValueError((k,'unreviewed loop structure',pairs,trips))
 # Validate the unroll-by-two tail against the actual induction variable, not the C++ trip count.
 if k in ('c32_wave1_finish','c32_wave1_finish_dcrop','c32_wave1_prefix'):
  a,b,_=pairs[3];guard='\n'.join(body[a:a+18]);assert re.search(r's_add_co_i32 s\d+, s\d+, 2',guard) and ', 64' in guard
 return [dict(start=a,end=b,label=l,trips=t) for (a,b,l),t in zip(pairs,trips)]
def phase(line):
 if 773<=line<=825:return 'input'
 if 826<=line<=829:return 'ffn_residual'
 if line in (833,834):return 'ffn_expand'
 if line==835:return 'ffn_activation'
 if line==836:return 'ffn_contract'
 if line==838:return 'ffn_pack_residual_store'
 if 839<=line<=848:return 'qkv_norm' if line in (846,847) else 'qkv_matrix'
 if 862<=line<=867:return 'scores_exp'
 if 868<=line<=870:return 'softmax'
 if line==871:return 'av'
 if 872<=line<=874:return 'projection_quant'
 if line==875 or 880<=line<=909:return 'tail'
 return 'control_unattributed'
def llvm(path,source=None):
 text=Path(path).read_text()
 if '\t.loc\t' in text:
  source=Path(source) if source else Path(path).with_name('base.generated.hip')
  assert hashlib.sha256(source.read_bytes()).hexdigest()=='3c600d6ef6ba4183eddb4d068dfd070160855891486219e8cf8e1bb1ddc8841c', 'Source-line phase map is only reviewed for the archived 0.34 source'
 result={}
 for k,body in S.llvm_kernels(text):
  if not k.startswith('c32_wave1'):continue
  lp=loops(body,k);total=collections.Counter();ph=collections.defaultdict(collections.Counter);ops=collections.Counter();current=0
  for i,l in enumerate(body):
   if '.loc' in l:
    src=[int(x) for x in re.findall(r'probe.hip:(\d+):\d+',l)]
    src=[x for x in src if 757<=x<=910]
    current=src[-1] if src else 0
   for op,instr in S.ops_of([l]):
    w=1
    for loop in lp:
     if loop['start']<=i<=loop['end']:w*=loop['trips']
    cls=S.classify(op);total[cls]+=w;ops[op]+=w;ph[phase(current)][cls]+=w
  result[k]={'total':dict(total),'loops':lp,'phases':{k:dict(v) for k,v in ph.items()},'opcodes':dict(ops.most_common())}
 return result

def regs(text):
 out=[]
 for a,b,half in re.findall(r'(?<!\w)v\[(\d+)(?:-(\d+))?\](?:\[(0|16):(?:16|32)\])?',text):
  for r in range(int(a),int(b or a)+1):out.extend([(r,int(half)//16)] if half else [(r,0),(r,1)])
 return out

def aco(path):
 # Track physical half-register versions through the straight-line program. Each
 # WMMA increments the depth of A/B; its C operand continues the same sum. Depths
 # 1..6 = expand, contract, QKV, scores, AV, projection. C32 WMMA histogram must
 # be 64/64/48/32/32/16. Mixed phases in VOPD are explicitly separate.
 stage={};ph=collections.defaultdict(collections.Counter);total=collections.Counter();wmma=collections.Counter();ops=collections.Counter()
 for line in Path(path).read_text().splitlines():
  issued=list(S.ops_of([line],True))
  if not issued:continue
  op,_=issued[0];cls=S.classify(op);total[cls]+=1;ops[op]+=1
  depths=[]
  for part in line.split('::'):
   if ' = ' not in part:depths.append(0);continue
   lhs,rhs=part.split(' = ',1);subop=rhs.strip().split()[0];ds=regs(lhs);rs=regs(rhs);st=max((stage.get(r,0) for r in rs),default=0)
   if subop.startswith(('global_load','buffer_load','s_load')):st=0
   if 'wmma' in subop:
    spans=re.findall(r'%\d+:v\[\d+(?:-\d+)?\]',rhs)
    st=max((stage.get(r,0) for span in spans[:2] for r in regs(span)),default=0)+1;wmma[st]+=1
   for r in ds:stage[r]=st
   depths.append(st)
  phasekey='/'.join(map(str,sorted(set(depths))))
  ph[phasekey][cls]+=1
 return {'total':dict(total),'phases_by_data_depth':{k:dict(v) for k,v in ph.items()},'wmma_depth':dict(wmma),'opcodes':dict(ops.most_common())}
if __name__=='__main__':
 mode,path=sys.argv[1:3];print(json.dumps(llvm(path,sys.argv[3] if len(sys.argv)>3 else None) if mode=='llvm' else aco(path),indent=2))
