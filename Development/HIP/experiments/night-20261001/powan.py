# powan.py <dir with r*-h*-*.tel/.err> <gap-map dispatch dir> [count]: per-family clock/power ledger from powerfam.ps1.
# Model (power cap): 1/f = sum_k w_k*eps_k (eps = energy per cycle / P_cap, w = time fraction). Two runs (base, family dup xN) give eps_family
# and eps_rest; E_f = family share of the base frame's energy. X% less energy per cycle in the family -> clock x 1/(1-X*E_f), time -T0*X*E_f (upper bound).
import re,sys,json,statistics as st
from pathlib import Path
from collections import defaultdict
d=Path(sys.argv[1]);gm=Path(sys.argv[2]);N=int(sys.argv[3]) if len(sys.argv)>3 else 8
def rd(p):
    b=p.read_bytes();return b.decode('utf-16') if b[:2] in (b'\xff\xfe',b'\xfe\xff') else b.decode('utf-8','replace')
def tel(p):
    L=[l for l in rd(p).splitlines() if 'adapter=0 ' in l and 'status=0' in l]
    L=[l for l in L if (m:=re.search(r'sensor19=(\d+)',l)) and int(m.group(1))>=90];L=L[len(L)//4:]
    g=lambda s:[int(re.search(rf'sensor{s}=(\d+)',l).group(1)) for l in L]
    return (st.median(g(1)) if L else None, st.median(g(73)) if L else None, len(L))
def span(p):
    v=[float(x) for x in re.findall(r'hip_span gpu_ms=([0-9.]+)',rd(p))][60:]
    return st.median(v)
R=defaultdict(list)
for t in sorted(d.glob('r*-h*-*.tel')):
    m=re.match(r'r(\d+)-h(\d+)-(.+)\.tel',t.name);rnd,h,c=m.groups()
    e=t.with_suffix('.err')
    if not e.exists():continue
    f,w,n=tel(t);R[(h,c)].append((span(e),f,w,n))
disp={'900':json.loads((gm/'dispatch-900.json').read_text()),'1080':json.loads((gm/'dispatch-1152.json').read_text())}
pref={'c32_wave1':'c32_wave1_','c64_wave2':'c64_wave2_','c128_wave2':'c128_wave2_','vit_stream':'vit_stream_'}
print('| tier | family (DUP prefix) | base share s | span base→dup ms | clock MHz base→dup | W | family eps/base eps | energy share E_f | -10% energy: clock / ms |')
print('|---|---|---:|---|---|---:|---:|---:|---|')
for h in ('900','1080'):
    if (h,'base') not in R:continue
    b=R[(h,'base')];T0=st.mean(x[0] for x in b);f0=st.mean(x[1] for x in b)
    ev=disp[h];tot=sum(x['step_us'] for x in ev)
    for (hh,c),v in sorted(R.items()):
        if hh!=h or c=='base':continue
        p=pref.get(c,c);tf=sum(x['step_us'] for x in ev if x['kernel'].startswith(p))/tot*T0;s=tf/T0
        Td=st.mean(x[0] for x in v);fd=st.mean(x[1] for x in v);W=st.mean(x[2] for x in v)
        wf=(tf+(Td-T0))/Td
        # solve 1/f0=s*a+(1-s)*b, 1/fd=wf*a+(1-wf)*b
        det=s*(1-wf)-wf*(1-s)
        a=((1/f0)*(1-wf)-(1/fd)*(1-s))/det;bb=(s*(1/fd)-wf*(1/f0))/det
        Ef=s*a*f0;rel=a/(1/f0)
        up=1/(1-0.1*Ef)
        print(f'| {h} | {c} | {s:.3f} | {T0:.2f}→{Td:.2f} | {f0:.0f}→{fd:.0f} | {W:.0f} | {rel:.3f} | {Ef:.3f} | +{(up-1)*100:.2f}% / −{T0*0.1*Ef:.3f} |')
