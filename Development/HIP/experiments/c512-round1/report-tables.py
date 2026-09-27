from pathlib import Path
import json,sys
p=Path(sys.argv[1]);d=json.loads((p/'ledger-summary.json').read_text())
if (p/'tail-summary.json').exists():
 t=json.loads((p/'tail-summary.json').read_text())
 for h in d:d[h].update(t[h])
labels={'mh_pool_project_group_c256':'进入C512的pool/project','mh_shift_pack':'shift/pack','split_mix_blocked_h16w_m32':'mix M32','split_ffn_fused_fp8_t8':'split FFN','split_projection_frag':'FFN projection','mh_qkv_normalize_frag_c512_m32':'QKV M32+norm','mh_attention_fused_fp8_out':'attention','mh_attention_project_frag_c512':'attention projection','mh_pool':'head pool（边界）','mh_pool_project_production_h16w':'head project（边界）'}
print('| 核 | 每帧调用 | 900/1080组数 | wave/组 | VGPR/LDS B | 组/MP上限 | 900/1080边际ms |\n|---|---:|---|---:|---|---:|---|')
for k,n in labels.items():
 if k not in d['900'] or k not in d['1080']:continue
 a,b=d['900'][k],d['1080'][k];r=a['resources'][0];g=lambda x:'/'.join(str(v) for v in sorted({z['groups'] for z in x['resources']}));ms=lambda x:'—' if x['marginal_mean_ms'] is None else f"{x['marginal_mean_ms']:.4f}"
 print(f"| {n} | {a['calls']} | {g(a)} / {g(b)} | {r['threads']//32} | {r['vgpr']} / {r['lds']} | {r['resident_groups_per_mp']} | {ms(a)} / {ms(b)} |")
if (p/'summary.json').exists():
 s=json.loads((p/'summary.json').read_text());print('\n| 候选 | 900两批 Δms（%） | 1080两批 Δms（%） | EXACT/AE候选帧 |\n|---|---|---|---|')
 for k,v in s.items():
  cell=lambda h:' / '.join(f"{x['delta_ms']:+.4f} ({x['delta_percent']:+.2f}%)" for batch in ['r1','r2'] if (x:=v['timing'].get(f'{h}-{batch}')) is not None)
  print(f"| {k} | {cell(900)} | {cell(1080)} | {v['correctness'].get('correct','—')} / {v['correctness'].get('adaptive','—')} |")
