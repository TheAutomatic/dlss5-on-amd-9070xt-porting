from pathlib import Path
import sys,json,re,collections
R=Path(__file__).resolve().parents[4];sys.path.insert(0,str(R/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
sys.path.insert(0,str(R/'Development/HIP/experiments/mh-round1'));import cfg
out={}
def count(lines,weights):
 c=collections.Counter()
 for i,l in enumerate(lines):
  w=weights[i]
  for op,line in S.ops_of([l]):
   cat=S.classify(op);c[cat]+=w;c['vector_slots']+=w*(2 if cat=='VOPD' else int(cat=='VALU'))
   if cat in ['VMEM','DS'] and ('load' in op or 'store' in op):
    rw='read' if 'load' in op else 'write';m=re.search(r'_b(8|16|32|64|96|128)(?:_|$)',op)
    if m:c[f'{cat}_{rw}_bytes_per_lane']+=w*int(m[1])//8*(2 if '2addr' in op else 1)
 c['issued']=sum(c[k] for k in ['VALU','VOPD','WMMA','VMEM','DS','SMEM','SALU','WAIT']);return dict(c)
for v in ['Z','B','BL','L']:
 p=Path(f'/tmp/c256-fusion/build-{v}-gfx1201/c64-wave2.hsaco.s');ks=dict(S.llvm_kernels(p.read_text()));out[v]={}
 for n in ['c256_wave2','c256_wave2_bi','c256_wave2_bo','c256_wave2_bi_bo']:
  b=ks[n];ls,reach=cfg.analyze(b);tt=[2,4,4,4,4,4] if v in ['B','BL'] else [4]*5;assert len(ls)==len(tt)
  weights=[int(i in reach) for i in range(len(b))]
  for q,t in zip(ls,tt):
   for i in q['lines']:weights[i]*=t
  inner=ls[1]['lines'];ffnweights=[weights[i] if i in inner else 0 for i in range(len(b))]
  out[v][n]={'trips':tt,'loop_path_sum_upper':count(b,weights),'ffn_ht_loop_executed':count(b,ffnweights),'loop_headers':[b[q['header']] for q in ls],'note':'FFN ht body is straight nested math; whole kernel sums mutually exclusive boundary paths, hence upper, not measured runtime.'}
for n in out['Z']:
 vals=[out[v][n]['loop_path_sum_upper']['WMMA'] for v in out];assert len(set(vals))==1,(n,vals)
p=Path('/tmp/c256-fusion/isa');(p/'weighted.json').write_text(json.dumps(out,indent=2))
lines=['# C256循环加权','', 'Z/L: qt4 × ht4；B/BL: qtbatch2 × ht4 × Ksub4，后面三个qt循环各4。ISA与源码共同确认。嵌套逐行乘积，不能拿静态WMMA 510→498说少计算。', '', '|bi_bo 每wave|Z|B|BL|L|','|---|---:|---:|---:|---:|']
for scope,metrics in [('loop_path_sum_upper',['issued','vector_slots','WMMA','VMEM','DS','DS_read_bytes_per_lane','DS_write_bytes_per_lane']),('ffn_ht_loop_executed',['WMMA','VMEM','VMEM_read_bytes_per_lane'])]:
 for metric in metrics:lines.append('|'+scope+'/'+metric+'|'+'|'.join(str(out[v]['c256_wave2_bi_bo'][scope].get(metric,0)) for v in ['Z','B','BL','L'])+'|')
lines+=['','FFN ht loop没有特征输入/最终输出global操作，其VMEM是权重读请求。per-lane字节乘32可得全活跃wave逻辑请求量；缓存复用未知，不能当DRAM流量。全核边界路径仍累加为上界。','', 'Q LDS相对差异应比较L-Z、BL-B的DS read/write；这些量不含bank conflict或真实延迟。']
(p/'WEIGHTED.md').write_text('\n'.join(lines)+'\n');print('\n'.join(lines))
