#!/usr/bin/env python3
"""Conditional geometry/bandwidth equivalents, explicitly NOT measured Daniel family latencies."""
import json,csv
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4];out=ROOT/'Development/results/daniel-kernels-20260928';out.mkdir(exist_ok=True)
d=json.loads(Path('/tmp/daniel-kernels/dispatch/swin-schedule.json').read_text());ledger=json.loads((ROOT/'Development/results/tier900-20260927/summary.json').read_text())
regions=ledger['1080-pdl1']['regions'];cost={f:ledger['1080-pdl1']['families'][f]['mean_ms'] for f in ['C32','C64','C128','C256','C512','ViT']}
rows=[]
for f in ['C32','C64','C128','C256']:
 a=sum(x['waves'] for x in d if x['family']==f and x['resolution']=='1080-matched-ours');b=sum(x['waves'] for x in d if x['family']==f and x['resolution']=='1080-daniel-default');frac=1-b/a
 rows.append(dict(family=f,ours_historical_ms=cost[f],daniel_matched_waves=a,daniel_default_waves=b,geometry_wave_fraction=frac,geometry_equivalent_ms=cost[f]*frac,meaning='if historical own family time scales with Daniel same-family waves; excludes math, layer count and fusion changes'))
rows.sort(key=lambda x:x['geometry_equivalent_ms'],reverse=True)
# Read+write of intermediates avoided if eliminated. n is the known sum over 13 active C512 blocks.
bytes_rows=[]
sched=json.loads(Path('/tmp/daniel-kernels/ours/ours-schedule.json').read_text())
for h,n,t in [(900,26432,400),(1080,33280,640)]:
 c256_n=sum(x['groups']*64 for x in sched[str(h)] if x['kernel'].startswith('c256_attn_wave'))
 for what,byte in [('C256 feature plus QKV intermediate read+write',c256_n*256*4*2),('C512 mixed float intermediate read+write',n*512*4*2),('C512 contract8 intermediate read+write',n*512*2),('ViT 8 input packs: f32 read plus FP8 write',8*t*1024*5)]:
  bytes_rows.append(dict(tier=h,item=what,logical_bytes=byte,decimal_MB=byte/1e6,ms_at_peak_640GBs=byte/640e9*1000,meaning='bandwidth-equivalent only: assumes all these logical bytes hit external memory; cache reuse can make cost near zero, real achieved bandwidth can make cost higher'))
r={'geometry_model':rows,'geometry_total_ms':sum(x['geometry_equivalent_ms'] for x in rows),'intermediate_bandwidth_equivalents':bytes_rows,'unidentified_family_gap_ms':None,'notes':['No per-family Daniel timing trace. Do not apportion the estimated 0.65ms total GPU gap by these numbers.','Deep geometry is identical for Daniel 1088 and1152, C51260x36/ViT640; 900 differs in both geometry and split-K selection.','Daniel full16 C512 blocks vs ours13. Decoder up/down work is fused into Swin boundary variants.','C512 mixed/contract removal is a fusion budget hypothesis, not a proven byte-for-byte comparison of closed-source traffic.']}
(out/'family-budgets.json').write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps(r,indent=2))
