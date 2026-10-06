from pathlib import Path
import json,collections,sys,re
R=Path(__file__).resolve().parents[4];sys.path.insert(0,str(R/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
ours=json.load(open('/tmp/aco-lineup/phases.json'));ffn=json.load(open('/tmp/aco-lineup/c256-ffn-phases.json'));aco=json.load(open('/tmp/aco-lineup/aco-phases.json'));out={}
# C32 full interior body BB19. Four alternative half-window edge bodies are mutually exclusive.
def ai(c,p,k=""):
 if c==32:
  variant="g_fswinimagepreds32" if k.endswith("prefix") else "g_fswinimagepost32" if k.endswith("post") else "g_fswinds32" if k.endswith("finish_dcrop") else None
  if variant:return aco[variant][p]["ordinary"]
 a=aco['g_fswin'+str(c)][p]
 if c!=32:return a['ordinary']
 lines=Path('/tmp/aco-lineup/aco/g_fswin32.s').read_text().splitlines();bb='';labels={}
 for i,l in enumerate(lines,1):
  if re.fullmatch(r'BB\d+',l):bb=l
  labels[i]=bb
 return sum(r['weight'] for r in a['rows'] if labels[r['line']]=='BB19')
for tier in ('900','1080'):
 weights=collections.Counter();detail=[]
 for line in (R/f'Development/results/c512-round1-20260927/{tier}/run.log').read_text().splitlines():
  if not line.startswith('TOPO,'):continue
  _,stage,module,k,g,t,*_=line.split(',');weights[k]+=int(g)*int(t)//32
 grouped=collections.defaultdict(lambda:dict(ours=0,aco=0,waves=0))
 for k,w in weights.items():
  if k in ours:
   c=int(re.match(r'c(\d+)',k)[1]);fam='C32' if c==32 else 'C64-C128' if c<256 else 'C256'
   for phase in ('activation','softmax'):
    if phase not in ours[k]['phases']:continue
    n=sum(v for cls,v in ours[k]['phases'][phase].items() if cls in ('VALU','VOPD'));v=grouped[fam+'/'+phase];v['ours']+=n*w;v['aco']+=ai(c,phase,k)*w;v['waves']+=w
  elif k in ffn:
   n=sum(v for op,v in ffn[k]['ops']['activation'].items() if S.classify(op) in ('VALU','VOPD'));v=grouped['C256/activation'];v['ours']+=n*w;v['aco']+=ai(256,'activation')*w/8;v['waves']+=w
 for k,v in grouped.items():v['gap']=v['ours']-v['aco']
 out[tier]=dict(sorted(grouped.items(),key=lambda a:-a[1]['gap']))
print(json.dumps(out,indent=2));Path('/tmp/aco-lineup/ranking.json').write_text(json.dumps(out,indent=2))
