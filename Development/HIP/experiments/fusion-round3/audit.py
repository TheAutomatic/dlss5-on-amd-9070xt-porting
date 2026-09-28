from pathlib import Path
import sys,re,json,csv,collections,hashlib
R=Path(__file__).resolve().parents[4];sys.path.insert(0,str(R/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
root=Path('/tmp/fusion-round3');out=root/'isa';out.mkdir(exist_ok=True)
def meta(t):
 d={}
 for c in t.split('  - .args:'):
  n=re.search(r'\.name:\s+(\w+)',c)
  if n:d[n[1]]={k:int(v) for k,v in re.findall(r'\.(vgpr_count|sgpr_count|private_segment_fixed_size|group_segment_fixed_size|vgpr_spill_count|max_flat_workgroup_size):\s+(\d+)',c)}
 return d
def canonical(ls):
 labels={m[1]:str(i) for i,l in enumerate(ls) if (m:=re.match(r'(\.LBB\w+):',l))};result=[]
 for op,l in S.ops_of(ls):
  l=re.sub(r'\.LBB\w+',lambda m:'LABEL'+labels.get(m[0],m[0]),l);result.append(re.sub(r'\s+',' ',l.strip()))
 return result
report={};rows=[]
for p in sorted(root.glob('build-*-gfx1201/*.hsaco.s')):
 mod=p.name;baseline=Path('/tmp/c512-fusion/production/gfx1201')/mod
 if not baseline.exists():baseline=Path('/tmp/daniel-kernels/ours-current')/mod
 if not baseline.exists():continue
 t=p.read_text();bt=baseline.read_text();new=dict(S.llvm_kernels(t));old=dict(S.llvm_kernels(bt));nm=meta(t);bm=meta(bt);checks={}
 for n in bm:
  checks[n]={'present':n in nm,'isa_same':n in new and canonical(new[n])==canonical(old[n]),'resources_same':nm.get(n)==bm[n]}
 added={}
 for n in nm.keys()-bm.keys():
  c=collections.Counter(S.classify(op) for op,l in S.ops_of(new[n]));c['vector_slots']=c['VALU']+c['VOPD']*2
  added[n]={'resources':nm[n],'static':dict(c)};rows.append({'variant':p.parent.name,'kernel':n,**nm[n],**c})
 report[p.parent.name+'/'+mod]={'baseline':str(baseline),'existing_count':len(checks),'changed_existing':{n:d for n,d in checks.items() if not all(d.values())},'all_existing_equal':all(all(d.values()) for d in checks.values()),'new':added}
(out/'audit.json').write_text(json.dumps(report,indent=2))
if rows:
 with (out/'resources.csv').open('w') as f:w=csv.DictWriter(f,list(dict.fromkeys(k for r in rows for k in r)));w.writeheader();w.writerows(rows)
print(json.dumps(report,indent=2))
