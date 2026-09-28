from pathlib import Path
import re,collections,json
out={}
for path in Path('/tmp/aco-lineup/aco').glob('*.s'):
 records=[];defs={}
 for line,l in enumerate(path.read_text().splitlines(),1):
  parts=l.split(' :: ')
  for p in parts:
   m=re.search(r'= (v_\w+) (.*)',p)
   if not m:continue
   ids=[x for x in re.findall(r'%(\d+)',p[:m.start()]) if x!='0'];args=[x for x in re.findall(r'%(\d+)',m[2]) if x!='0'];r=dict(line=line,op=m[1],args=args,defs=ids,isa=p.strip(),weight=1/len(parts));records.append(r)
   for id in ids:defs[id]=len(records)-1
 # Collect exact activation arithmetic from clamp(-4,4), through FP8 pack, stopping at consumers.
 selected=set();taint=set()
 for i,r in enumerate(records):
  seed=r['op'] in ('v_maxmin_f32','v_med3_f32') and '-4.0' in r['isa'] and '4.0' in r['isa']
  if seed or (any(a in taint for a in r['args']) and not any(x in r['op'] for x in ('wmma','store','load'))):
   selected.add(i)
   if 'cvt_pk_fp8' not in r['op']:taint.update(r['defs'])
 # RCP is specific to probability denominators in this shader (rsq handled separately).
 soft=set();todo=[i for i,r in enumerate(records) if r['op']=='v_rcp_f32' and any(a in defs and records[defs[a]]['op']=='v_cvt_f32_f16' for a in r['args'])]
 # Sum/clamp/cast only: do not traverse exponent bit construction into QK dot product.
 allowed=('v_pk_add_f16','v_add_f16','v_max_f16','v_cvt_f32_f16','v_permlanex16_b32','v_rcp_f32','v_mov_b32')
 while todo:
  i=todo.pop()
  if i in soft:continue
  r=records[i]
  if r['op'] not in allowed:continue
  soft.add(i);todo.extend(defs[a] for a in r['args'] if a in defs)
 taint={d for i in soft if records[i]['op']=='v_rcp_f32' for d in records[i]['defs']}
 for i,r in enumerate(records):
  if any(a in taint for a in r['args']) and not any(x in r['op'] for x in ('wmma','store','load')):
   soft.add(i)
   if 'cvt_pk_fp8' not in r['op']:taint.update(r['defs'])
 def summary(ix):
  c=collections.Counter()
  for i in ix:c[records[i]['op']]+=records[i]['weight']
  return dict(ordinary=sum(c.values()),scalar_ops=len(ix),opcodes=dict(c),rows=[records[i] for i in sorted(ix)])
 out[path.stem]={'activation':summary(selected),'softmax':summary(soft)}
Path('/tmp/aco-lineup/aco-phases.json').write_text(json.dumps(out,indent=2))
for k in ('g_fswin32','g_fswin64','g_fswin128','g_fswin256'):
 print(k,{p:(r['ordinary'],r['scalar_ops']) for p,r in out[k].items()})
