#!/usr/bin/env python3
"""Round-2 C32 instruction work estimate. Full interior-window path; actual dispatch counts.
The block69 finish has down=null: skip its guarded downsample block rather than billing dead code.
WAIT counts instructions, not cycles. Window-weighted counts are not measured time shares.
"""
from pathlib import Path
import collections,importlib.util,json,re,sys
ROOT=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('old',ROOT/'Development/HIP/experiments/c32-aco/ledger.py');old=importlib.util.module_from_spec(spec);spec.loader.exec_module(old)
def reviewed_loops(body,k):
 labels={m[1]:i for i,l in enumerate(body) if (m:=re.match(r'(\.LBB\w+):',l))};backs={}
 for i,l in enumerate(body):
  m=re.search(r's_(?:cbranch_\w+|branch) (\.LBB\w+)',l)
  if m and labels.get(m[1],10**9)<i:backs[m[1]]=max(i,backs.get(m[1],0))
 pairs=sorted((labels[l],e,l) for l,e in backs.items());assert len(pairs)>=3
 answer=[]
 for j,(a,b,label) in enumerate(pairs):
  if j<3:trip=(4,8,4)[j]
  elif k=='c32_wave1_post':trip=2
  else:
   region='\n'.join(body[a:b+1]);opts=[]
   for reg,bound in re.findall(r's_cmp_\w+_u32 (s\d+), (64|16|0x40|0x10)\b',region):
    inc=re.findall(r's_add_co_i32 '+reg+', '+reg+r', (\d+)\b',region)
    if inc:opts.append((int(bound,0),int(inc[-1])))
   assert opts,(k,label,'review new loop');bound,step=opts[-1];assert bound%step==0;trip=bound//step
  answer.append(dict(start=a,end=b,label=label,trips=trip))
 return answer

def count(path):
 result={}
 for k,b in old.S.llvm_kernels(Path(path).read_text()):
  if not k.startswith('c32_wave1'):continue
  loops=reviewed_loops(b,k);omit=set()
  if k=='c32_wave1_finish':
   # Last null-pointer test after the main-output loop is down==nullptr. The
   # branch targets the function exit and dominates the entire unrolled down body.
   labels={m[1]:i for i,l in enumerate(b) if (m:=re.match(r'(\.LBB\w+):',l))}
   candidates=[]
   for i,l in enumerate(b):
    if i>loops[-1]['end'] and 's_cmp_eq_u64' in l and ', 0' in l:
     j=i+1
     while j<len(b) and not re.search(r's_cbranch_scc1 (\.LBB\w+)',b[j]):j+=1
     m=re.search(r's_cbranch_scc1 (\.LBB\w+)',b[j]);candidates.append((j,labels[m[1]]))
   assert len(candidates)==1,(k,candidates)
   a,z=candidates[0];omit.update(range(a+1,z))
  total=collections.Counter();tail=collections.Counter();ops=collections.Counter()
  for i,l in enumerate(b):
   if i in omit:continue
   for op,_ in old.S.ops_of([l]):
    w=1
    for x in loops:
     if x['start']<=i<=x['end']:w*=x['trips']
    cls=old.S.classify(op);total[cls]+=w;ops[op]+=w
    if i>loops[2]['end']:tail[cls]+=w
  result[k]={'per_window':dict(total),'tail':dict(tail),'loops':loops,'omitted_null_down_lines':len(omit),'opcodes':dict(ops.most_common())}
 return result

def schedule(W,H):
 def win(w,h,shift):return ((w+8*(shift&1))*(h+8*((shift>>1)&1)))//64
 out=[('prefix',0,win(W,H,0))]
 for block in (1,2,3,4,66,67,68,69):
  shift=({1:0,2:3,3:1,4:2,66:0,67:3,68:1,69:2})[block]
  kind='mapped' if block in (1,66) else 'finish_dcrop' if block==4 else 'finish' if block==69 else 'chain'
  out.append((kind,block,win(W//2,H//2,shift)))
 out.append(('post',70,win(W,H,3)));return out
if __name__=='__main__':
 base=count(sys.argv[1]);answer={'kernels':base,'frames':{}}
 for h,W,H in [(900,1600,960),(1080,1920,1152)]:
  dispatch=schedule(W,H);rows=[]
  for kind in ('prefix','post','chain','mapped','finish_dcrop','finish'):
   chosen=[x for x in dispatch if x[0]==kind];nw=sum(x[2] for x in chosen);c=base['c32_wave1_'+kind]['per_window'];rows.append(dict(kind=kind,blocks=[x[1] for x in chosen],calls=len(chosen),windows=nw,weighted={key:val*nw for key,val in c.items()},valu_vopd=(c.get('VALU',0)+c.get('VOPD',0))*nw))
  denom=sum(x['valu_vopd'] for x in rows)
  for x in rows:x['fraction_of_vector_instructions']=x['valu_vopd']/denom
  answer['frames'][str(h)]=rows
 print(json.dumps(answer,indent=2))
