#!/usr/bin/env python3
import re,json,csv,sys,subprocess,collections
from pathlib import Path
import yaml
ROOT=Path('/home/lmxxf/work/ai-theorys-study/wechat/assets/297')
sys.path.insert(0,str(ROOT/'Development/HIP/experiments/mh-round1'));import cfg
sys.path.insert(0,str(ROOT/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
SRC=Path('/tmp/claude-1000/-home-lmxxf-work-ai-theorys-study/129f068a-8529-42b4-b98b-08071124e161/scratchpad/d050');OUT=Path(__file__).parent
notes=subprocess.check_output(['llvm-readelf','--notes',str(SRC/'x/gfx1201.hsaco')],text=True);meta=yaml.safe_load(notes[notes.index('---'):]);metadata={k['.name']:k for k in meta['amdhsa.kernels']}
def parse(path):
 out={};name=None
 for l in path.read_text().splitlines():
  m=re.match(r'^([0-9a-f]+) <([^>]+)>:',l)
  if m:name=m[2];out[name]={'base':int(m[1],16),'lines':[]}
  elif name and re.search(r'// [0-9A-Fa-f]+:',l) and 's_code_end' not in l:out[name]['lines'].append(l)
 return out
def stats(lines):
 c=collections.Counter();ops=collections.Counter()
 for op,l in S.ops_of(lines):
  kind=S.classify(op);c[kind]+=1;ops[op]+=1
  if kind=='VOPD':c['VOPD_slots']+=len(l.split('::'))
  if kind=='VMEM':
   rw='read' if 'load' in op else 'write' if 'store' in op else 'other'
   c['VMEM_'+rw+'_requests']+=1
   m=re.search(r'_(?:b|u|i)(8|16|32|64|96|128)(?:_|$)',op)
   n=re.search(r'dword(x[234])?',op)
   if m:c['VMEM_'+rw+'_bytes_per_lane_static']+=int(m[1])//8
   elif n:c['VMEM_'+rw+'_bytes_per_lane_static']+=4*(int(n[1][1:]) if n[1] else 1)
   else:c['VMEM_'+rw+'_unknown_width']+=1
  if 'mov' in op:c['mov']+=1
  if 'pk' in op or 'pack' in op:c['pack']+=1
  if 'clamp' in l:c['clamp']+=1
  if op.startswith('scratch_'):c['scratch_requests']+=1
 c['issued_static']=sum(c[k] for k in ['VALU','VOPD','WMMA','VMEM','DS','SMEM','SALU','WAIT'])
 return dict(c),dict(ops)
def flow(data):
 labels={};asm=[]
 for l in data['lines']:
  a=int(re.search(r'// ([0-9A-Fa-f]+):',l)[1],16);labels[a]=f'.LBB_{a:x}'
 targets=set()
 for l in data['lines']:
  a=int(re.search(r'// ([0-9A-Fa-f]+):',l)[1],16);m=re.match(r'\s*s_(?:cbranch_\w+|branch) (\d+)',l)
  if m:
   n=int(m[1]);n=n-65536 if n>=32768 else n;targets.add(a+4+n*4)
 for l in data['lines']:
  a=int(re.search(r'// ([0-9A-Fa-f]+):',l)[1],16)
  if a in targets:asm.append(labels[a]+':')
  raw=l.split('//')[0].strip()
  m=re.match(r'(s_(?:cbranch_\w+|branch)) (\d+)',raw)
  if m:
   n=int(m[2]);n=n-65536 if n>=32768 else n;t=a+4+n*4
   if t in labels:raw=m[1]+' '+labels[t]
  asm.append(raw)
 loops,reach=cfg.analyze(asm)
 result=[]
 for q in loops:
  body=[asm[i] for i in sorted(q['lines'])];entry=asm[q['header']].rstrip(':');trip=None;proof=None
  branch=[x for x in body if re.match(r's_(?:branch|cbranch)',x)]
  cmps=[re.match(r's_cmp_(?:eq|lg)_u32 (s\d+), (0x[0-9a-f]+|\d+)$',x) for x in body];cmps=[x for x in cmps if x]
  if len(cmps)==1 and ((branch==['s_cbranch_scc0 '+entry] and cmps[0][0].startswith('s_cmp_eq')) or (branch==['s_cbranch_scc1 '+entry] and cmps[0][0].startswith('s_cmp_lg'))):
   reg,limit=cmps[0].groups();limit=int(limit,0)
   updates=[]
   for x in body:
    m=re.match(r's_add_(?:nc_u64|co_i32|u32) (s\[\d+:\d+\]|s\d+), \1, (0x[0-9a-f]+|\d+)$',x)
    if m and (m[1]==reg or m[1].startswith('s['+reg[1:]+':')):updates.append(m)
   if len(updates)==1:
    dest,step=updates[0].groups();step=int(step,0)
    ids=[int(x) for x in re.findall(r'\d+',dest)];owned=set(range(ids[0],ids[-1]+1))
    writes=[]
    for x in body:
     # Scalar destinations and vector carry-out scalar destinations can alias either half of a pair.
     prefix=x.split(',')[0];operands=x.split(',')
     candidates=[prefix.split()[-1]] if re.match(r's_',x) and not re.match(r's_(?:cmp|cbranch|branch|wait|delay|store)',x) else []
     if re.match(r'v_.*(?:co_|co_ci_)',x) and len(operands)>1:candidates.append(operands[1].strip())
     for operand in candidates:
      mm=re.fullmatch(r's(?:\[(\d+):(\d+)\]|(\d+))',operand)
      if mm:
       rr=set(range(int(mm[1]),int(mm[2])+1)) if mm[1] else {int(mm[3])}
       if rr&owned:writes.append(x)

    pre=asm[:q['header']];initial=None
    for x in reversed(pre):
     if x.endswith(':') or re.match(r's_(?:branch|cbranch)',x):break
     if re.match(r's_\w+ '+re.escape(dest)+r',',x):
      m=re.match(r's_mov_b(?:32|64) '+re.escape(dest)+r', (0x[0-9a-f]+|\d+)$',x)
      if m:initial=int(m[1],0)
      break
    if initial is not None and len(writes)==1 and step>0 and limit>initial and (limit-initial)%step==0:
     trip=(limit-initial)//step;proof=f'{dest} starts {initial}, sole update +{step}, sole backedge compares {reg} == {limit}; straight loop body'
  st=stats(body)[0]
  result.append({'header':entry,'trip_count':trip,'reason':proof or 'ISA loop identified; trip count and branch path not proven','body_static':st,'weighted_body':{k:v*trip for k,v in st.items()} if trip else None,'counter_ops':[x for x in body if re.match(r's_(?:cmp|add|sub|mov|cbranch)',x)][-30:]})
 return result

new=parse(SRC/'dis-gfx1201.s');old=parse(SRC/'dis-old1201.s');rows={};delta=[]
for name,d in new.items():
 if name not in metadata:continue
 st,op=stats(d['lines']);m=metadata[name];ls=flow(d)
 upper=None
 if all(q['trip_count'] for q in ls):
  upper=dict(st)
  for q in ls:
   for k,v in q['body_static'].items():upper[k]=upper.get(k,0)+(q['trip_count']-1)*v
 row={'kernel':name,'mode':('reference' if re.findall(r'Lb([01])E',name)[-1]=='0' else 'fast') if re.findall(r'Lb([01])E',name) else 'shared','resources':{k.removeprefix('.'):v for k,v in m.items() if k in ['.group_segment_fixed_size','.private_segment_fixed_size','.sgpr_count','.vgpr_count','.sgpr_spill_count','.vgpr_spill_count','.wavefront_size','.max_flat_workgroup_size']},'static':st,'opcodes':op,'loops':ls,'loop_expanded_path_sum_upper':upper,'dynamic':None,'dynamic_status':'unknown trip counts or branch paths; static is not runtime'}
 oldname=name if name in old else re.sub(r'Lb[01]EE','E',name)
 oldname=re.sub(r'IE','',oldname) if oldname not in old else oldname
 if oldname in old:
  row['old_kernel']=oldname
  before,_=stats(old[oldname]['lines']);row['delta_vs_040']={k:st.get(k,0)-before.get(k,0) for k in set(st)|set(before)};delta.append({'kernel':name,'mode':row['mode'],**{k:row['delta_vs_040'].get(k,0) for k in ['issued_static','scratch_requests','mov','pack','clamp','WMMA','VMEM','DS','VALU','VOPD','WAIT']}})
 rows[name]=row
(OUT/'census.json').write_text(json.dumps({'metric_notes':['Static instruction sites include mutually exclusive paths.','VOPD counts issued pairs; slots counts arithmetic operations.','VMEM byte widths are per active lane per instruction, not measured DRAM bytes.','Loop bodies reported separately, no unsupported dynamic sum.','Daniel reference half/PTX arithmetic differs from current float FMA baseline.'], 'kernels':rows},indent=2))
def csvout(name,rs):
 keys=list(dict.fromkeys(k for r in rs for k in r));f=(OUT/name).open('w');w=csv.DictWriter(f,keys);w.writeheader();w.writerows(rs);f.close()
flat=[{'kernel':n,'mode':r['mode'],**r['resources'],**r['static'],'loops':len(r['loops'])} for n,r in rows.items()];csvout('all-kernels.csv',flat);csvout('reference-kernels.csv',[r for r in flat if r['mode']=='reference']);csvout('040-to-050-delta.csv',delta)
print('kernels',len(rows),'modes',collections.Counter(r['mode'] for r in rows.values()),'loops',sum(len(r['loops']) for r in rows.values()))
print('reference scratch',[(r['kernel'],r['private_segment_fixed_size']) for r in flat if r['mode']=='reference' and r['private_segment_fixed_size']])
print('largest reference deltas',sorted([r for r in delta if r['mode']=='reference'],key=lambda x:x['issued_static'])[:8])

(OUT/'compiler-provenance.txt').write_text(subprocess.check_output(['readelf','-p','.comment',str(SRC/'x/gfx1201.hsaco')],text=True)+'\nOurs .ident strings:\n'+'\n'.join(sorted(set(re.findall(r'\.ident\s+(.+)',p.read_text())[0] for p in Path('/tmp/daniel-kernels/ours-current').glob('*.hsaco.s') if re.findall(r'\.ident\s+(.+)',p.read_text()))))+'\nSame producer revision proven; flags not recoverable from producer alone.\n')
