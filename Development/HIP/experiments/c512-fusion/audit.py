#!/usr/bin/env python3
"""Offline COMGR assembly audit; default scans ../build-*-gfx1201/*.hsaco.s."""
from pathlib import Path
import argparse,sys,re,json,csv,collections,hashlib
p=argparse.ArgumentParser();p.add_argument('files',nargs='*');p.add_argument('--out',default='/tmp/c512-fusion/isa');a=p.parse_args();out=Path(a.out);out.mkdir(parents=True,exist_ok=True)
R=Path(__file__).resolve().parents[4];sys.path.insert(0,str(R/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
files=[Path(f) for f in a.files] if a.files else sorted(Path('/tmp/c512-fusion').glob('build-*-gfx1201/*.hsaco.s'))
pattern=re.compile(r'c512_qkv_attention_fused|qkv.*c512|c512.*qkv|mh_.*attention|split_ffn_fused_fp8_t8|c(?:64|128|256)_wave(?:2|16)|c256_attn_wave')
def resources(text):
 d={}
 for c in text.split('  - .args:'):
  n=re.search(r'\.name:\s+(\w+)',c)
  if n:d[n[1]]={k:int(v) for k,v in re.findall(r'\.(vgpr_count|sgpr_count|private_segment_fixed_size|group_segment_fixed_size|vgpr_spill_count|sgpr_spill_count|max_flat_workgroup_size):\s+(\d+)',c)}
 return d
rows=[];details={}
for f in files:
 text=f.read_text();meta=resources(text);variant=f.parent.name
 for name,ls in S.llvm_kernels(text):
  if not pattern.search(name) or name not in meta:continue
  c=collections.Counter();hist=collections.Counter();normalized=[]
  for op,l in S.ops_of(ls):
   cat=S.classify(op);c[cat]+=1;hist[op]+=1;c['vector_slots']+=2 if cat=='VOPD' else int(cat=='VALU');normalized.append(re.sub(r'\.LBB\w+','LABEL',re.sub(r'\s+',' ',l.strip())))
   if op.startswith('scratch_'):c['scratch_sites']+=1
   if op.startswith('ds_load'):c['LDS_load_sites']+=1
   if op.startswith('ds_store'):c['LDS_store_sites']+=1
   if op.startswith('s_barrier'):c['barrier_sites']+=1
   if cat=='VMEM':
    rw='read' if 'load' in op else 'write' if 'store' in op else 'other';c['VMEM_'+rw+'_requests']+=1
    m=re.search(r'_b(8|16|32|64|96|128)(?:_|$)',op)
    if m:c['VMEM_'+rw+'_bytes_per_lane_static']+=int(m[1])//8
  c['issued_static']=sum(c[k] for k in ['VALU','VOPD','WMMA','VMEM','DS','SMEM','SALU','WAIT'])
  key=f'{variant}/{f.name}/{name}';row={'variant':variant,'module':f.name,'kernel':name,**meta[name],**c};rows.append(row)
  details[key]={'resources':meta[name],'static':dict(c),'opcodes':dict(hist),'operand_text_hash':hashlib.sha256('\n'.join(normalized).encode()).hexdigest(),'counter_tail':[l.strip() for l in ls if re.search(r'\bs_(?:cmp|add|cbranch)',l)][-25:]}
report={'method':'Static all-path instruction sites, not loop-expanded runtime. VMEM bytes per active lane request width, not DRAM bytes. VOPD issued1/slots2. Operand hash normalizes branch labels; screening only, not binary equivalence proof.','files':[str(f) for f in files],'kernels':details}
(out/'audit.json').write_text(json.dumps(report,indent=2))
if rows:
 with (out/'resources.csv').open('w') as f:w=csv.DictWriter(f,list(dict.fromkeys(k for r in rows for k in r)));w.writeheader();w.writerows(rows)
print(f'{len(files)} files, {len(rows)} selected kernels; outputs {out}/audit.json and resources.csv')
for row in rows:
 if 'fused' in row['kernel']:print(row['variant'],row['kernel'],'VGPR',row.get('vgpr_count'),'LDS',row.get('group_segment_fixed_size'),'private',row.get('private_segment_fixed_size'),'WMMA static',row.get('WMMA',0))
