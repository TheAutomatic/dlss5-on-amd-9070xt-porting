from pathlib import Path
import collections,json,sys,re,importlib.util
root=Path(__file__).resolve().parents[4];sys.path.insert(0,str(root/'Development/HIP/experiments/mh-round1'));import cfg
import dataflow
spec=importlib.util.spec_from_file_location('S',root/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
mods={'mh':'multihead-reference','deep':'deep_reference','c32':'c32_prefix_reference','boundary':'boundary_reference','mh_fast':'multihead-fast-padded-wave-packed','mh_fused':'multihead_fused_attention','deep_fast':'deep_fast-packed','c32_wave1':'c32-wave1','c64_wave2':'c64-wave2','c512_m32_deep':'c512-m32-deep','c512_m32_mh':'c512-m32-mh','vit_stream':'vit-stream','vit_wide_deep':'vit-wide-deep','prefix_fast':'prefix_fast','wave':'wave-pointwise'}
active={}
for h in (900,1080):
 raw=(root/f'Development/results/c512-round1-20260927/{h}/run.log').read_text()
 for l in raw.splitlines():
  if not l.startswith('TOPO,'):continue
  _,stage,m,k,g,t,*rest=l.split(',');key=mods[m]+':'+k
  row=active.setdefault(key,{'module':mods[m],'kernel':k,'tiers':{}})['tiers'].setdefault(str(h),{'calls':0,'waves':0,'groups':[]});row['calls']+=1;row['waves']+=int(g)*int(t)//32;row['groups'].append(int(g))
allkernels={};details={}
for p in Path(sys.argv[1]).glob('*.hsaco.s'):
 module=p.name.removesuffix('.hsaco.s')
 text=p.read_text();exported=set(re.findall(r'\.amdhsa_kernel\s+(\S+)',text))
 for k,b in S.llvm_kernels(text):
  if k not in exported:continue
  key=module+':'+k;cnt=collections.Counter(re.sub(r'_e(?:32|64)$','',op) for op,_ in S.ops_of(b));narrow=cnt['v_cvt_f16_f32'];rtz=cnt['v_cvt_pkrtz_f16_f32'];wide=cnt['v_cvt_f32_f16']
  flow=dataflow.analyze(b)
  allkernels[key]={'same_block_roundtrip_sites':len(flow['same_block_roundtrips']),'half_grid_renarrowing_sites':len(flow['half_grid_renarrowings']),'narrow_to_lds_sites':len(flow['narrow_to_lds']),'narrow_rne_static':narrow,'narrow_rtz_pair_static':rtz,'widen_static':wide,'active':key in active}
  if key not in active:continue
  loops,reachable=cfg.analyze(b)
  details[key]={'dataflow':flow,'baseline':active[key],'static':allkernels[key],'loops':[{'header':x['header'],'ranges':x['ranges'],'counter_ops':[l.strip() for i,l in enumerate(b) if i in x['lines'] and re.search(r'\bs_(?:cmp|add|sub|mov).*',l)]} for x in loops]}
missing=set(active)-set(details);assert not missing,missing
out=Path(sys.argv[2]);out.mkdir(parents=True,exist_ok=True);(out/'conversion-static.json').write_text(json.dumps(allkernels,indent=2)+'\n');(out/'conversion-active.json').write_text(json.dumps(details,indent=2)+'\n')
for key,d in details.items():
 print(key,'cvts',d['static']['narrow_rne_static'],d['static']['narrow_rtz_pair_static'],d['static']['widen_static'],'loops',len(d['loops']))
 for i,l in enumerate(d['loops']):print(' ',i,l['header'],' | '.join(l['counter_ops'][-8:]))

weighted={}
for key,d in details.items():
 weighted[key]={}
 for h,v in d['baseline']['tiers'].items():
  weighted[key][h]={'calls':v['calls'],'waves':v['waves'],**{k:v['waves']*n for k,n in d['static'].items() if isinstance(n,int) and k!='active'}}
(out/'conversion-dispatch-weighted.json').write_text(json.dumps({'metric':'static sites times actual dispatched waves; not loop-expanded, not runtime instruction executions. Same-BB def/use is conservative; LDS sites are separate, not counted as proven redundant.','kernels':weighted},indent=2)+'\n')
