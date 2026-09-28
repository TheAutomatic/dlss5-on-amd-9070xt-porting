#!/usr/bin/env python3
import sys,re,json,collections,importlib.util,yaml
from pathlib import Path
root=Path(__file__).resolve().parents[4]
sys.path.insert(0,str(root/'Development/HIP/experiments/mh-round1'));import cfg
sys.path.insert(0,str(root/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
mods={'mh':'multihead-reference','deep':'deep_reference','c32':'c32_prefix_reference','boundary':'boundary_reference','mh_fast':'multihead-fast-padded-wave-packed','mh_fused':'multihead_fused_attention','deep_fast':'deep_fast-packed','c32_wave1':'c32-wave1','c64_wave2':'c64-wave2','c512_m32_deep':'c512-m32-deep','c512_m32_mh':'c512-m32-mh','vit_stream':'vit-stream','vit_wide_deep':'vit-wide-deep','prefix_fast':'prefix_fast','wave':'wave-pointwise'}
active={};schedule={}
for h in (900,1080):
 schedule[h]=[]
 for l in (root/f'Development/results/c512-round1-20260927/{h}/run.log').read_text().splitlines():
  if not l.startswith('TOPO,'):continue
  _,stage,m,k,g,t,*rest=l.split(',');key=mods[m]+':'+k
  row=dict(stage_before=stage,module=mods[m],kernel=k,groups=int(g),threads=int(t),waves=int(g)*int(t)//32);schedule[h].append(row)
  v=active.setdefault(key,dict(module=mods[m],kernel=k,tiers={})).setdefault('tiers',{}).setdefault(str(h),dict(calls=0,waves=0,groups=[]));v['calls']+=1;v['waves']+=row['waves'];v['groups'].append(int(g))
def stats(lines):
 c=collections.Counter()
 for op,l in S.ops_of(lines):
  k=S.classify(op);c[k]+=1
  if k=='VOPD':c['VOPD_slots']+=len(l.split('::'))
  if 'mov' in op:c['mov']+=1
  if op.startswith('scratch_'):c['scratch_requests']+=1
 c['vector_slots']=c['VALU']+c['VOPD_slots'];c['issued']=sum(c[k] for k in ['VALU','VOPD','WMMA','VMEM','DS','SMEM','SALU','WAIT'])
 return dict(c)
out={};dump=[]
for path in Path(sys.argv[1]).glob('*.hsaco.s'):
 text=path.read_text();m=re.search(r'\.amdgpu_metadata\s*\n(.*?)\.end_amdgpu_metadata',text,re.S);md={k['.name']:k for k in yaml.safe_load(m[1].strip())['amdhsa.kernels']} if m else {}
 for k,b in S.llvm_kernels(text):
  key=path.name.removesuffix('.hsaco.s')+':'+k
  if key not in active:continue
  ls,reachable=cfg.analyze(b);loops=[]
  for i,q in enumerate(ls):
   c=[l.strip() for j,l in enumerate(b) if j in q['lines'] and re.match(r'\s*s_(?:cmp|add|sub|mov|cbranch)',l)]
   pre=[l.strip() for l in b[max(0,q['header']-12):q['header']]]
   loops.append(dict(index=i,header=b[q['header']],counter=c,preheader=pre,body=stats([b[j] for j in q['lines']]),ranges=q['ranges']))
   dump.append(f'{key} LOOP {i} {b[q["header"]]}\nPRE '+' | '.join(pre)+'\nBODY '+' | '.join(c[-18:]))
  out[key]={**active[key],'resources':{a.removeprefix('.'):v for a,v in md[k].items() if a in ['.vgpr_count','.sgpr_count','.group_segment_fixed_size','.private_segment_fixed_size','.vgpr_spill_count']},'static':stats(b),'loops':loops}
assert set(out)==set(active),set(active)-set(out)
p=Path(sys.argv[2]);p.mkdir(parents=True,exist_ok=True);(p/'ours-census.json').write_text(json.dumps(out,indent=2)+'\n');(p/'ours-schedule.json').write_text(json.dumps(schedule,indent=2)+'\n');(p/'ours-loops.txt').write_text('\n\n'.join(dump)+'\n')
print(len(out),'active kernels',[len(v) for v in schedule.values()],'dispatches',sum(len(v['loops']) for v in out.values()),'natural loops')
