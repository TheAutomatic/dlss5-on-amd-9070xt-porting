# per-dispatch C64/C128 ledger from kernel-map-inchain dispatch-*.json (step - f) vs mochizuki fswinp{ds,up}{64,128}
import json,statistics as st,sys
F={'900':41.7,'1080':42.6}
HIS={'900':{'ds64':352.5,'ds128':359.7,'up128':343.9,'up64':340.7},'1080':{'ds64':476.5,'ds128':484.1,'up128':464.5,'up64':461.7}}
SEG={'ds64':range(6,11),'ds128':range(11,18)}
out=[]
for g in ['900','1080']:
  d=json.load(open(f'results/kernel-map-inchain-20261001/dispatch-{g}.json'));f=F[g]
  ks=[x['kernel'] for x in d]
  up128=ks.index('c128_wave2_up_lb_sh');up64=ks.index('c64_wave2_up_lb_sh')
  segs={'ds64':list(range(6,11)),'ds128':list(range(11,18)),'up128':list(range(up128,up64)),'up64':list(range(up64,up64+4))}
  out.append(f'\n### {g}（µs，我们 = step − {f}）\n')
  out.append('| 段 | 派发 | 核 | 我们 | 链中间块中位 | 超出中位 |\n|---|---:|---|---:|---:|---:|')
  summ=[]
  for s,idx in segs.items():
    rows=[(i,d[i]['kernel'],d[i]['step_us']-f) for i in idx]
    mid=st.median([v for i,k,v in rows if k.endswith('_bi_bo')])
    tot=sum(v for *_,v in rows);ends=0
    for i,k,v in rows:
      ex=(v if 'pool' in k else v-mid) if not k.endswith('_bi_bo') else 0
      ends+=ex
      out.append(f'| {s} | {i} | `{k}` | {v:.1f} | {mid:.1f} | {"%+.1f"%ex if not k.endswith("_bi_bo") else ""} |')
    nb=sum(1 for i,k,v in rows if 'pool' not in k)
    his=HIS[g][s];summ.append((s,tot,his,ends,nb,mid))
  out.append('\n| 段 | 我们合计 | 他（1 派发） | 差 | 其中两端超出中位（含池化） | 块数 × 中位 | 他每层均摊 | 中间体差 = 差 − 两端 |\n|---|---:|---:|---:|---:|---:|---:|---:|')
  for s,tot,his,ends,nb,mid in summ:
    out.append(f'| {s} | {tot:.1f} | {his} | **{tot-his:+.1f}** | {ends:+.1f} | {nb}×{mid:.1f} | {his/nb:.1f} | {tot-his-ends:+.1f} |')
  T=sum(x[1] for x in summ);H=sum(x[2] for x in summ);EN=sum(x[3] for x in summ)
  out.append(f'| 合计 | {T:.1f} | {H:.1f} | **{T-H:+.1f}** | {EN:+.1f} | | | {T-H-EN:+.1f} |')
print('\n'.join(out))
