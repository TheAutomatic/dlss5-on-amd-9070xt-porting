import csv,json,math,statistics,sys
from pathlib import Path
r=Path(sys.argv[1]); data=[]; slots=[]
def st(v):
 s=sorted(v); x=.99*(len(s)-1); lo=int(x); return {'mean':statistics.mean(v),'p99':s[lo]+(s[lo+1]-s[lo])*(x-lo),'n':len(v)}
for i in range(4):
 rows=list(csv.DictReader((r/f'slot-{i}/o.csv').open())); assert len(rows)==160,'invalid totalframecount'
 assert [int(x['frame']) for x in rows]==list(range(160)),'frameindex mismatch'
 assert all(int(x['reset'])==1 for x in rows),'reset contract changed'
 values=[float(x['wall_ms']) for x in rows]; assert all(math.isfinite(x) and x>0 for x in values),'invalid wall timing: reject entire batch'
 assert rows[0]['checked']=='1' and rows[-1]['checked']=='1' and all(x['checked']=='0' for x in rows[1:-1]),'midreadback contract'
 assert int(rows[0]['invalid'])==int(rows[-1]['invalid'])==0,'nonfinite edge'
 v=values[80:]; data.append(v); slots.append({'slot':i,'mode':'replay' if i in (1,2) else 'eager','steady':st(v),'cold_frame0_ms':values[0],'discarded_first80_mean_ms':statistics.mean(values[:80]),'all160_mean_ms':statistics.mean(values)})
a=st(data[0]+data[3]);b=st(data[1]+data[2]);out={'slots':slots,'merged':{'eager':a,'replay':b,'delta_mean_ms':b['mean']-a['mean'],'delta_p99_ms':b['p99']-a['p99']},'control_drift':{k:slots[3]['steady'][k]-slots[0]['steady'][k] for k in ['mean','p99']}}
out['gate']='PASS' if out['merged']['delta_mean_ms']<0 and out['merged']['delta_p99_ms']<0 else 'STOP'
(r/'analysis.json').write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out))
