from pathlib import Path
import csv,json,sys,collections
root=Path(sys.argv[1])
def rows(name):
 b=(root/name).read_bytes();s=b.decode('utf-16') if b[:2] in (b'\xff\xfe',b'\xfe\xff') else b.decode('utf-8-sig');return list(csv.DictReader(s.splitlines()))
m=rows('measurements.csv');h=rows('frame-hashes.csv');a=rows('adaptive-decisions.csv');summary={}
# The N probe uses a freshly built host: also prove its controls match the installed-host controls.
baseline={}
for r in h:
 if not r['tag'].endswith('-False'):continue
 mode=r['set_batch'].rsplit('-',1)[1]
 if mode not in ('correct','adaptive'):continue
 key=(mode,r['tag'],r['frame'])
 if key in baseline:assert baseline[key]==r['sha256'],('baseline changed across sets',key,r['set_batch'])
 baseline[key]=r['sha256']
sets=sorted({r['set_batch'].removeprefix('runtime-regression-').rsplit('-',1)[0] for r in m})
for name in sets:
 o={'timing':{},'correctness':{},'adaptive':{}}
 for mode in ('correct','adaptive'):
  key='runtime-regression-'+name+'-'+mode;hs=[r for r in h if r['set_batch']==key]
  if not hs:continue
  lookup={(r['tag'],r['frame']):r['sha256'] for r in hs};checks=0
  for (tag,frame),sha in lookup.items():
   if tag.endswith('-True'):
    assert lookup[(tag.removesuffix('-True')+'-False',frame)]==sha,(name,tag,frame);checks+=1
  assert checks==84,(name,mode,checks)
  o['correctness'][mode]=checks
 for batch in ('r1','r2'):
  key='runtime-regression-'+name+'-'+batch
  for height in (900,1080):
   rs={r['tag']:float(r['mean_ms']) for r in m if r['set_batch']==key}
   tags=[f'time-{height}-{i}' for i in range(4)]
   if not all(t in rs for t in tags):continue
   x=[rs[t] for t in tags];base=(x[0]+x[3])/2;candidate=(x[1]+x[2])/2;o['timing'][f'{height}-{batch}']={'baseline_ms':base,'candidate_ms':candidate,'delta_ms':candidate-base,'delta_percent':100*(candidate/base-1)}
 ar=[r for r in a if r['set']=='runtime-regression-'+name+'-adaptive']
 if ar:
  look={(r['case'],r['frame']):r for r in ar};counts=collections.Counter();checks=0
  for (case,frame),r in look.items():
   if case.endswith('-True'):
    other=look[(case.removesuffix('-True')+'-False',frame)]
    assert all(other[k]==r[k] for k in ['reuse','age','reason','relative','local','image']),(name,case,frame,r,other)
    counts[r['reuse']]+=1;checks+=1
  assert checks==84,(name,checks)
  o['adaptive']={'matched_decisions':checks,'reuse_counts':dict(counts)}
 summary[name]=o
print(json.dumps(summary,indent=2))
