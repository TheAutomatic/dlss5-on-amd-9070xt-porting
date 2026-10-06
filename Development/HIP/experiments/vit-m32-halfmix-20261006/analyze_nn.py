import argparse,csv,json,statistics,math
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args()
def pct(xs,p):
 x=sorted(xs);pos=(len(x)-1)*p;k=int(pos);return x[k]*(1-pos+k)+x[min(k+1,len(x)-1)]*(pos-k)
s=[];merged={'old':{'gpu_ms':[],'cpu_ms':[]},'new':{'gpu_ms':[],'cpu_ms':[]}}
for i in range(4):
 rows=list(csv.DictReader((a.root/f'nn1088-slot-{i}'/'timing.csv').open()));assert len(rows)==160
 side='new'if i in(1,2)else'old';r={'slot':i,'side':side}
 for k in('gpu_ms','cpu_ms'):
  x=[float(q[k])for q in rows];assert all(math.isfinite(v)and v>0 for v in x);merged[side][k]+=x;r[k]={'mean':statistics.mean(x),'p99':pct(x,.99)}
 s.append(r)
out={'scope':'single firstscreen ABBA1088 ViT640 QB32 halfscoreFMA/64keyhalfden numerical combination, common encoded synthetic input, canonicalCOMGR old/new, completeNN outerGPU event vs CPUwall separate','slots':s,'merged':{}}
for k in('gpu_ms','cpu_ms'):
 old,new=merged['old'][k],merged['new'][k];out['merged'][k]={'old_mean':statistics.mean(old),'new_mean':statistics.mean(new),'mean_delta':statistics.mean(new)-statistics.mean(old),'old_p99':pct(old,.99),'new_p99':pct(new,.99),'p99_delta':pct(new,.99)-pct(old,.99)}
(a.root/'analysis.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
