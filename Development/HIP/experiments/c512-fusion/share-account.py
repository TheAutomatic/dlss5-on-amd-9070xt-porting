from pathlib import Path
import json
root=Path(__file__).resolve().parents[4];helper=root/'Development/HIP/experiments/c256-fusion/weighted.py';s={'__file__':str(helper)};exec(helper.read_text().split("for v in ['Z'")[0],s);S=s['S'];cfg=s['cfg'];count=s['count'];out={}
for label,path in [('base','/tmp/daniel-kernels/ours-current/c64-wave2.hsaco.s'),('Sboth','/tmp/c512-fusion/build-Sboth-gfx1201/c64-wave2.hsaco.s')]:
 ks=dict(S.llvm_kernels(Path(path).read_text()));out[label]={}
 for n in ['c64_wave2_bi_bo','c128_wave2_bi_bo']:
  b=ks[n];loops,reach=cfg.analyze(b);assert len(loops)==5;trips=[4]*5 if label=='base' else [2,4,4,4,4];w=[int(i in reach) for i in range(len(b))]
  for q,t in zip(loops,trips):
   for i in q['lines']:w[i]*=t
  inner=[v if i in loops[1]['lines'] else 0 for i,v in enumerate(w)];out[label][n]={'trips':trips,'whole_path_upper':count(b,w),'ffn_ht_loop':count(b,inner)}
Path('/tmp/c512-fusion/isa/share-account.json').write_text(json.dumps(out,indent=2))
for n in out['base']:
 print(n,[(v,out[v][n]['whole_path_upper']['WMMA'],out[v][n]['ffn_ht_loop'].get('VMEM'),out[v][n]['ffn_ht_loop'].get('VMEM_read_bytes_per_lane')) for v in out])
