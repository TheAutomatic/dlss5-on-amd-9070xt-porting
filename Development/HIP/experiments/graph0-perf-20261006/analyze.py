import csv,json,statistics,math,sys
from pathlib import Path
r=Path(sys.argv[1]);slots=[];data=[]
def stats(v):
 s=sorted(v);i=.99*(len(s)-1);lo=int(i);return {'mean':statistics.mean(v),'p99':s[lo]+(s[min(lo+1,len(s)-1)]-s[lo])*(i-lo),'n':len(v)}
for i in range(4):
 rows=list(csv.DictReader((r/f'slot-{i}/timing.csv').open()));assert len(rows)==160
 for x in rows:assert all(math.isfinite(float(x[k])) and float(x[k])>0 for k in ['gpu_ms','wall_ms'])
 d={k:[float(x[k]) for x in rows] for k in ['gpu_ms','wall_ms']};data.append(d);slots.append({'slot':i,'mode':'replay' if i in (1,2) else 'eager',**{k:stats(v) for k,v in d.items()}})
result={'slots':slots,'merged':{},'control_drift':{}}
for k in ['gpu_ms','wall_ms']:
 a=stats(data[0][k]+data[3][k]);b=stats(data[1][k]+data[2][k]);result['merged'][k]={'eager':a,'replay':b,'delta_mean_ms':b['mean']-a['mean'],'delta_p99_ms':b['p99']-a['p99']};result['control_drift'][k]={q:slots[3][k][q]-slots[0][k][q] for q in ['mean','p99']}
result['gate']='PASS' if all(x['delta_mean_ms']<0 and x['delta_p99_ms']<0 for x in result['merged'].values()) else 'STOP'
(r/'analysis.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
