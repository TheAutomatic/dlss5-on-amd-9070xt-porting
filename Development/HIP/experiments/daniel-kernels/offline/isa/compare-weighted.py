#!/usr/bin/env python3
from pathlib import Path
import json,collections,csv,re
# Reuse exact census categorization, without rerunning entire Daniel census.
exec((Path(__file__).parent/'census.py').read_text().split('new=parse')[0])
base=Path('/tmp/daniel-kernels');ours=json.loads((base/'ours/ours-census.json').read_text());dan=json.loads((OUT/'census.json').read_text())['kernels'];results={};flat=[]
def unified(lines):
 st=stats(lines)[0];st['vector_slots']=st.get('VALU',0)+st.get('VOPD_slots',0);return st
def measure(lines,weights):
 total=collections.Counter()
 for i,l in enumerate(lines):
  for k,v in unified([l]).items():total[k]+=v*weights[i]
 return dict(total)
for key,d in ours.items():
 if d['module'] not in ['c32-wave1','c64-wave2']:continue
 blocks=dict(S.llvm_kernels((base/'ours-current'/f"{d['module']}.hsaco.s").read_text()));lines=blocks[d['kernel']];loops,_=cfg.analyze(lines)
 assert len(loops)==len(d['loops'])
 k=d['kernel'];trips=None;status='unknown';variants={}
 if k in ['c32_wave1_chain','c32_wave1_mapped']:trips=[4,8,4];status='loop-expanded path-sum upper; boundary paths summed'
 elif k.startswith(('c64_wave2_','c128_wave2_')) and len(loops)==5:trips=[4]*5;status='loop-expanded path-sum upper; mutually exclusive boundary loads summed'
 elif k=='c32_wave1_prefix':trips=[4,8,4,16];status='loop-expanded path-sum upper; prefix tail included'
 elif k=='c32_wave1_post':trips=[4,8,4,2];status='loop-expanded path-sum upper; t=lane,+32,<64 implies two tail iterations'
 elif k=='c32_wave1_finish_dcrop':
  variants={'full':[4,8,4,16,0,0],'edge':[4,8,4,0,32,16]};status='exclusive full vs edge; downcrop edge loop16, full downcrop unrolled; nonloop alternatives remain summed'
 elif k=='c256_attn_wave':trips=[1,4,4,2];status='conditional path-sum upper with PDL once; output ci=0,1 nested in qt4; actual spin unbounded'
 elif k=='c32_wave1_finish':
  # Tail loops are mutually exclusive; neither full-body sum nor their sum is actual execution.
  variants={'tail16':[4,8,4,16,0],'tail32':[4,8,4,0,32]};status='two mutually exclusive tail loop scenarios; nonloop alternative blocks still upper'
 elif k=='c256_attn_wave_bo':trips=[1,4,4];status='conditional upper with PDL spin exactly once; actual spin unbounded'
 if trips is not None:variants={'upper':trips}
 st=unified(lines);r={'kernel':key,'static':st,'status':status,'variants':{},'tiers':d['tiers']}
 for tag,tt in variants.items():
  weights=[1]*len(lines)
  for q,t in zip(loops,tt):
   for i in q['lines']:weights[i]*=t
  measured=measure(lines,weights)
  r['variants'][tag]={'trips':tt,'counts':measured,'weighted_by_tier':{h:{metric:value*v['waves'] for metric,value in measured.items()} for h,v in d['tiers'].items()}}
  flat.append({'kernel':key,'scenario':tag,'status':status,**measured})
 if not variants:flat.append({'kernel':key,'scenario':'static-only','status':status,**st})
 results[key]=r
# Ordinary body comparisons per dispatched wave, before grid/window normalization.
pairs=[('c32-wave1:c32_wave1_chain','_Z12k_reg_swin32ILi0ELb0EEv9VarParams'),('c64-wave2:c64_wave2_bi_bo','_Z13k_reg_swin_mhILi64ELi0ELb0EEv9VarParams'),('c64-wave2:c128_wave2_bi_bo','_Z13k_reg_swin_mhILi128ELi0ELb0EEv9VarParams')]
comparison=[]
for a,b in pairs:
 x=results[a]['variants']['upper']['counts'];y=dan[b]['loop_expanded_path_sum_upper']
 if y is None:continue
 y={**y,'vector_slots':y.get('VALU',0)+y.get('VOPD_slots',0)}
 comparison.append({'ours':a,'daniel':b,'scope':'per dispatched wave path-sum upper; grids and work coverage may differ','ours_counts':x,'daniel_counts':y,'ours_minus_daniel':{k:x.get(k,0)-y.get(k,0) for k in set(x)|set(y)}})
(OUT/'ours-loop-weighted.json').write_text(json.dumps({'kernels':results,'ordinary_pairs':comparison},indent=2))
keys=list(dict.fromkeys(k for row in flat for k in row))
with (OUT/'ours-loop-weighted.csv').open('w') as f:w=csv.DictWriter(f,keys);w.writeheader();w.writerows(flat)
for row in comparison:print(row['ours'],{k:(row['ours_counts'].get(k,0),row['daniel_counts'].get(k,0)) for k in ['issued_static','vector_slots','WMMA','VMEM','DS','WAIT']})
