#!/usr/bin/env python3
"""Offline audit. python3 audit.py /tmp/c256-fusion/build-*-gfx1201/c64-wave2.hsaco
Prefers sibling .hsaco.s COMGR listing; otherwise --objdump PATH (LLVM21+ gfx1201).
No GPU calls. Writes only output directory, never production.
"""
from pathlib import Path
import argparse,sys,re,json,collections,subprocess,hashlib,csv
p=argparse.ArgumentParser();p.add_argument('inputs',nargs='+');p.add_argument('--objdump',default='llvm-objdump');p.add_argument('--baseline',default='/tmp/daniel-kernels/ours-current/c64-wave2.hsaco.s');p.add_argument('--out',default='/tmp/c256-fusion/isa');a=p.parse_args();out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
R=Path(__file__).resolve().parents[4];sys.path.insert(0,str(R/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
sys.path.insert(0,str(R/'Development/HIP/experiments/mh-round1'));import cfg
wanted=['c256_wave2'+s for s in ['', '_bi','_bo','_bi_bo']];unchanged=['c'+str(c)+'_wave2'+s for c in [64,128] for s in ['', '_bi','_bo','_bi_bo']]+['c256_attn_wave','c256_attn_wave_bo']
def parse(text):
 if 'Disassembly of section' not in text:return dict(S.llvm_kernels(text))
 funcs={};name=None
 for l in text.splitlines():
  m=re.match(r'^([0-9a-f]+) <([^>]+)>:',l)
  if m:name=m[2];funcs[name]=[]
  elif name and (m:=re.search(r'// ([0-9A-Fa-f]+):',l)) and 's_code_end' not in l:funcs[name].append((int(m[1],16),l.split('//')[0].strip()))
 result={}
 for n,seq in funcs.items():
  addr={pc for pc,l in seq};targets=set();normalized=[]
  for pc,l in seq:
   m=re.match(r'(s_(?:branch|cbranch_\w+)) (\d+)',l)
   if m:
    offset=int(m[2]);offset=offset-65536 if offset>=32768 else offset;t=pc+4+4*offset
    if t in addr:targets.add(t);l=m[1]+f' .LBB_{t:x}'
   normalized.append((pc,l))
  result[n]=sum(([f'.LBB_{pc:x}:',l] if pc in targets else [l] for pc,l in normalized),[])
 return result
def meta(text):
 result={}
 for chunk in text.split('  - .args:'):
  m=re.search(r'\.name:\s+(\w+)',chunk)
  if m:result[m[1]]={f:int(v) for f,v in re.findall(r'\.(vgpr_count|sgpr_count|group_segment_fixed_size|private_segment_fixed_size|vgpr_spill_count|sgpr_spill_count):\s+(\d+)',chunk)}
 return result
def canonical(lines):
 # Register/opcode/operand equality; labels and comments normalized. Not binary equivalence proof.
 labelnames=[m[1] for l in lines if (m:=re.match(r'(\.LBB\w+):',l))];labels={name:f'L{idx}' for idx,name in enumerate(labelnames)}
 result=[]
 for op,line in S.ops_of(lines):
  for old,new in labels.items():line=re.sub(re.escape(old)+r'\b',new,line)
  result.append(re.sub(r'\s+',' ',line.strip()))
 return result
def counts(lines):
 c=collections.Counter()
 for op,l in S.ops_of(lines):
  cat=S.classify(op);c[cat]+=1;c['vector_slots']+=2 if cat=='VOPD' else int(cat=='VALU')
  if op.startswith('scratch_'):c['scratch_requests']+=1
  if 'movrel' in op:c['movrel']+=1
  if op.startswith('ds_load'):c['LDS_load_sites']+=1
  if op.startswith('ds_store'):c['LDS_store_sites']+=1
  if op.startswith('s_barrier'):c['barrier_instruction_sites']+=1
 c['issued']=sum(c[k] for k in ['VALU','VOPD','WMMA','VMEM','DS','SMEM','SALU','WAIT']);return dict(c)
base_text=Path(a.baseline).read_text();base=parse(base_text);base_meta=meta(base_text);report={};rows=[]
for filename in a.inputs:
 f=Path(filename);tag=f.parent.name
 if not f.exists():report[tag]={'error':'input not present','path':str(f)};continue
 asm=f if f.suffix=='.s' else Path(str(f)+'.s')
 if asm.exists():text=asm.read_text();resources=meta(text);fmt='COMGR assembly'
 else:
  version=subprocess.check_output([a.objdump,'--version'],text=True)
  major=re.search(r'version\s+(\d+)',version)
  if not major or int(major[1])<21:raise SystemExit('Need LLVM21+ gfx1201 objdump, or provide sibling c64-wave2.hsaco.s COMGR assembly; system LLVM18 cannot decode gfx12 reliably.')
  text=subprocess.check_output([a.objdump,'-d','--mcpu=gfx1201',str(f)],text=True)
  if '<unknown>' in text:raise SystemExit('Unknown ISA in disassembly; refusing incomplete census')
  notes=subprocess.check_output(['llvm-readelf','--notes',str(f)],text=True);resources=meta(notes);fmt='objdump';(out/(tag+'.dis.s')).write_text(text)
 kernels=parse(text);result={'format':fmt,'path':str(f),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'kernels':{},'unchanged':{}}
 for n in unchanged:
  result['unchanged'][n]={'present':n in kernels,'canonical_isa_equal':canonical(kernels[n])==canonical(base[n]) if n in kernels and n in base else None,'resources_equal':resources.get(n)==base_meta.get(n)}
 for n in wanted:
  if n not in kernels:result['kernels'][n]={'error':'missing export'};continue
  b=kernels[n];loops,reach=cfg.analyze(b);st=counts([l for i,l in enumerate(b) if i in reach]);rec={'resources':resources.get(n,{}),'static_reachable':st,'loops':[],'lds_sites':[]}
  for q in loops:
   body=[b[i] for i in sorted(q['lines'])];rec['loops'].append({'header':b[q['header']],'body_static':counts(body),'counter_ops':[l.strip() for l in body if re.search(r'\bs_(?:cmp|add|sub|mov|cbranch)',l)][-35:],'trip_count':None,'note':'Do not assume old loop count/order after reorganization; counters and source must prove trip.'})
  rec['lds_sites']=[{'line':i+1,'isa':l.strip()} for i,l in enumerate(b) if re.search(r'\b(?:ds_(?:load|store)|s_barrier|v_movrel)',l)]
  rec['static_delta_vs_production']={k:st.get(k,0)-counts(base.get(n,[])).get(k,0) for k in set(st)|set(counts(base.get(n,[])))}
  result['kernels'][n]=rec;rows.append({'variant':tag,'kernel':n,**rec['resources'],**st,'loops':len(loops)})
 report[tag]=result
(out/'candidate-audit.json').write_text(json.dumps(report,indent=2))
if rows:
 with (out/'candidate-resources.csv').open('w') as f:w=csv.DictWriter(f,list(dict.fromkeys(k for r in rows for k in r)));w.writeheader();w.writerows(rows)
print(json.dumps({v:{'kernels':{n:d.get('resources',{}) for n,d in r.get('kernels',{}).items()},'changed_unrelated':[n for n,d in r.get('unchanged',{}).items() if d['canonical_isa_equal'] is False or not d['resources_equal']],'error':r.get('error')} for v,r in report.items()},indent=2))
