#!/usr/bin/env python3
# HIP-segment ledger: span (hipEvent around network Enqueue) vs kernel sum (kernel-map-v3 jobbench, the two changed modules re-timed).
import csv,re,json,statistics as st,sys
from pathlib import Path
R=Path(sys.argv[1]);K=R.parent/'kernel-map-v3-20260930'
re_t={}
for l in open(R/'rejobs.log',encoding='utf-8',errors='ignore'):
    m=re.match(r'(o\d+-\d+) RESULT,[^,]+,([0-9.]+)',l.strip())
    if m:re_t[m.group(1)]=float(m.group(2))
roof=json.load(open(Path(__file__).with_name('roofline.json')))
bw={'900':0.0345,'1080':0.0452}  # hipMemcpyAsync D2D of the rgb output (17.6/25.3 MB) measured in bw.log
out={}
for h in ('900','1080'):
    rows=list(csv.DictReader(open(K/f'ours-{h}-dispatch.csv')))
    old=sum(float(r['median_us']) for r in rows);new=0;chg_old=chg_new=0
    per={}
    for r in rows:
        t=float(r['median_us'])
        if r['id'] in re_t:chg_old+=t;t=re_t[r['id']];chg_new+=t
        new+=t;per[r['symbol']]=per.get(r['symbol'],0)+t
    # 1080: 5 intermittently slow dispatches -> same-kernel median (as kernel-map-v3)
    fix=0
    if h=='1080':
        for sym in ('c512_qkv_attention_compact','vit_attention_fused_640_bytein_bout'):
            ts=[re_t.get(r['id'],float(r['median_us'])) for r in rows if r['symbol']==sym]
            fix+=sum(ts)-st.median(ts)*len(ts)
    kern=(new-fix)/1000
    sp=lambda tag:[float(m.group(1)) for m in re.finditer(r'hip_span gpu_ms=([0-9.]+)',open(R/f'{tag}-{h}.err',encoding='utf-16' if open(R/f'{tag}-{h}.err','rb').read(2)==b'\xff\xfe' else 'utf-8',errors='ignore').read())][200:]
    spans=sp('span')+sp('span2')
    walls={t:[float(r['wall_ms']) for r in csv.DictReader(open(R/f'{t}-{h}.csv')) if int(r['frame'])>=200] for t in ('wall','wall2','span','span2')}
    span=st.median(spans);cp=bw[h];gap=span-cp-kern
    rf=roof[h]
    out[h]=dict(dispatches=len(rows)+ (0),span_median_ms=span,span_mean_ms=st.mean(spans),span_p99_ms=sorted(spans)[int(.99*len(spans))],
      wall_plain_mean_ms=[st.mean(walls['wall']),st.mean(walls['wall2'])],wall_with_probe_mean_ms=[st.mean(walls['span']),st.mean(walls['span2'])],
      kernel_sum_ms=kern,kernel_sum_v3_ms=old/1000,changed_modules_old_new_us=[chg_old,chg_new],slow_fix_us=fix,output_copy_ms=cp,gap_ms=gap,gap_per_dispatch_us=gap*1000/len(rows),
      top=sorted(((k,round(v,1)) for k,v in per.items()),key=lambda x:-x[1])[:12])
print(json.dumps(out,indent=1));(R/'ledger.json').write_text(json.dumps(out,indent=1)+'\n')
# ---- per-family: measured kernel sum vs analytic floors (WMMA at peak, minimal VALU, DRAM bytes at 620 GB/s read-equivalent)
BW=620e9
def fam(s):
    s=s.lower()
    if s.startswith('vit') :return 'ViT'
    if 'c512' in s or s.startswith('split_'):return 'C512'
    if 'c256' in s or s.startswith('sp_'):return 'C256'
    if 'c128' in s:return 'C128'
    if 'c64' in s:return 'C64'
    if 'c32' in s:return 'C32'
    return 'other'
fam_out={}
for h in ('900','1080'):
    rows=list(csv.DictReader(open(K/f'ours-{h}-dispatch.csv')));meas={}
    for r in rows:
        t=re_t.get(r['id'],float(r['median_us']));meas[fam(r['symbol'])]=meas.get(fam(r['symbol']),0)+t
    rf=roof[h];g=rf['GFLOP'];clk=rf['clock_GHz']
    tab={}
    for f in ('C32','C64','C128','C256','C512','ViT','other'):
        f8=sum(v for k,v in g.items() if k.split('/')[0] in ({f} if f!='ViT' else {'ViT','ViT-attn'}) and k.endswith('fp8'))
        f16=sum(v for k,v in g.items() if k.split('/')[0] in ({f} if f!='ViT' else {'ViT','ViT-attn'}) and k.endswith('fp16'))
        if f=='other':f16=sum(v for k,v in g.items() if k.split('/')[0] in ('down','up','input-head'))
        wm=(f8/rf['fp8_peak_TFLOPS']+f16/rf['f16_peak_TFLOPS'])*1e3   # us
        va=rf['valu_by_family_ms'].get(f,0)*1e3
        mb=rf['weight_MB_by_family'].get(f,0)+rf['act_MB_by_family'].get(f,0)+(rf['act_MB_by_family'].get('io',0) if f=='C32' else 0)
        me=mb*1e6/BW*1e6
        m=meas.get(f,0)
        tab[f]=dict(measured_us=round(m,1),wmma_us=round(wm,1),valu_us=round(va,1),mem_us=round(me,1),ideal_us=round(max(wm,me),1),real_ideal_us=round(max(wm+va,me),1),x_real=round(m/max(wm+va,me,1e-9),2))
    fam_out[h]=tab
print(json.dumps(fam_out,indent=1));(R/'families.json').write_text(json.dumps(fam_out,indent=1)+'\n')
