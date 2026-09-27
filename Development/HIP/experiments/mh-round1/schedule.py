from pathlib import Path
import json,csv,re,collections,sys
root=Path(sys.argv[1]);base=json.loads((root/'baseline-ledger.json').read_text());out={}
for tier in ('900','1080'):
 calls=collections.defaultdict(list)
 for row in csv.DictReader(open(root.parent/f'tier900-20260927/{tier}-pdl1/topology.csv')):
  name,*meta=row['kernel'].split('|');module,k=name.split(':');attrs=dict(x.split('=') for x in meta)
  if module!='c64_wave2':continue
  block=int(row['stage'].replace('block',''));post=3 if block in (8,14,22) else 0 if block in (48,55,61,65) else 4
  calls[k].append({'block':block,'windows':int(attrs['groups']),'waves_per_window':int(attrs['threads'])//32,'post':post})
 rows={};denom=0
 for k,record in base['kernels'].items():
  n=sum(c['windows']*c['waves_per_window'] for c in calls[k]);heads=int(re.match(r'c(\d+)',k)[1])//32;v=record['per_wave_upper'];bill={a:b*n for a,b in v.items()};denom+=bill.get('VALU',0)+bill.get('VOPD',0)
  rows[k]={'calls':calls[k],'dispatches':len(calls[k]),'windows':sum(c['windows'] for c in calls[k]),'wave_windows':n,'per_window_upper':{a:b*heads for a,b in v.items()},'weighted_upper':bill,'weighted_phases':{p:{a:b*n for a,b in d.items()} for p,d in record['phases'].items()}}
 for k,v in rows.items():v['ordinary_work_share']=(v['weighted_upper'].get('VALU',0)+v['weighted_upper'].get('VOPD',0))/denom
 out[tier]=rows
print(json.dumps(out,indent=2))
