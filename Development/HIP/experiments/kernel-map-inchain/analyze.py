#!/usr/bin/env python3
"""kernel-map-inchain-20261001: our in-chain per-dispatch timing (evprof KEV: begin->end = exec, begin->next begin = step incl. gap)
vs mochizuki --per-layer --dispatch-grid (per-dispatch timestamps in one submit, gaps included), per family, 900/1080.
usage: analyze.py <dir with h{900,1080}-sw{0,1}-p{0,1}.log/.err> <out dir>"""
import sys,re,json,statistics as st,os,importlib.util
src,out=sys.argv[1],sys.argv[2];os.makedirs(out,exist_ok=True)
R='/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results/'
spec=importlib.util.spec_from_file_location('fam',R+'../HIP/experiments/mochizuki-gap/fam.py')
# reuse mz() / mfam() / ofam() without running fam.py's main body
code=open(R+'../HIP/experiments/mochizuki-gap/fam.py').read().split('out={}')[0];ns={};exec(code,ns)
mz,mfam,ofam=ns['mz'],ns['mfam'],ns['ofam']
def ofam2(mod,sym):
    if sym.startswith('sp_'): return 'C256'
    f=ofam(sym,mod)
    if f=='other' and ('pool_project' in sym): return 'C512'
    return f
def kev(path,skip=60):
    fr={}
    for l in open(path,encoding='utf-16' if open(path,'rb').read(2)==b'\xff\xfe' else 'utf-8',errors='ignore'):
        if not l.startswith('KEV,'):continue
        p=l.strip().split(',')
        # KEV,frame,i,module,kernel,groups,threads,exec,step
        f,i=int(p[1]),int(p[2]);fr.setdefault(f,[]).append((i,p[3],p[4],p[5],p[6],float(p[7]),float(p[8])))
    frames=[fr[k] for k in sorted(fr) if k>=skip]
    n=len(frames[0]);assert all(len(x)==n for x in frames),'dispatch count varies'
    rows=[]
    for i in range(n):
        _,m,k,g,t,_,_=frames[0][i]
        rows.append(dict(i=i,module=m,kernel=k,grid=g,threads=t,exec_us=1000*st.median(x[i][5] for x in frames),step_us=1000*st.median(x[i][6] for x in frames)))
    # Known artifact: the last C64 block (c64_wave2_bi, before the C32 up) reads negative (end event ordered before begin).
    # Replace it by the preceding c64_wave2_bi_bo step + 22us (jobbench: bi 104.1 vs bi_bo 82.3 at 900) and flag it.
    for k,r in enumerate(rows):
        if r['step_us']<0:
            r['artifact']=r['step_us'];r['step_us']=rows[k-1]['step_us']+22.0;r['exec_us']=rows[k-1]['exec_us']+22.0
    return rows,len(frames)
def span(path,skip=60):
    v=[]
    for l in open(path,encoding='utf-16' if open(path,'rb').read(2)==b'\xff\xfe' else 'utf-8',errors='ignore'):
        m=re.search(r'hip_span gpu_ms=([0-9.]+)',l)
        if m:v.append(float(m.group(1)))
    return st.median(v[skip:]) if len(v)>skip else None
res={};lines=[]
for h,logs in (('900',['pl1-1600x900.log','pl2-1600x900.log']),('1080',['pl1-1920x1080.log','pl2-1920x1080.log'])):
    runs=[mz(R+'mochizuki-gap-20261001/'+x) for x in logs];mzf={}
    for i in range(len(runs[0])):
        _,k,t,C,_=runs[0][i];mzf[mfam(k,t,C)]=mzf.get(mfam(k,t,C),0)+st.mean(r[i][4] for r in runs)
    rows,nf=kev(f'{src}/h{h}-sw1-p1.log');rows0,_=kev(f'{src}/h{h}-sw0-p1.log')
    json.dump(rows,open(f'{out}/dispatch-{h}.json','w'),indent=0);json.dump(rows0,open(f'{out}/dispatch-{h}-swin-off.json','w'),indent=0)
    of={};oe={};on={}
    for r in rows:
        f=ofam2(r['module'],r['kernel']);of[f]=of.get(f,0)+r['step_us'];oe[f]=oe.get(f,0)+r['exec_us'];on[f]=on.get(f,0)+1
    sp_prof=span(f'{src}/h{h}-sw1-p1.err');sp_plain=span(f'{src}/h{h}-sw1-p0.err');sp_off=span(f'{src}/h{h}-sw0-p0.err')
    tot=sum(r['step_us'] for r in rows)
    lines.append(f'## {h}  frames={nf}  dispatch={len(rows)} (his {len(runs[0])})  sum(step)={tot:.0f}us  span: profiled {sp_prof} / plain {sp_plain} ms (swin-off plain {sp_off}); his total {st.mean(sum(x[4] for x in r) for r in runs):.0f}us')
    lines.append('| fam | ours step (in-chain, gap incl.) | ours exec | disp | his | ours-his |');lines.append('|---|---:|---:|---:|---:|---:|')
    for f in ['C32','C64','C128','C256','C512','ViT','other']:
        lines.append(f'| {f} | {of.get(f,0):.1f} | {oe.get(f,0):.1f} | {on.get(f,0)} | {mzf.get(f,0):.1f} | {of.get(f,0)-mzf.get(f,0):+.1f} |')
    # SP breakdown: production sp rows vs swin-off same blocks
    spr=[r for r in rows if r['module']=='sp']
    lines.append('SP (production): '+'; '.join(f"{r['kernel']} exec {r['exec_us']:.1f} step {r['step_us']:.1f}" for r in spr))
    res[h]=dict(ours_step=of,ours_exec=oe,ours_disp=on,his=mzf,span_profiled=sp_prof,span_plain=sp_plain,span_swin_off=sp_off,sp=spr)
json.dump(res,open(f'{out}/families.json','w'),indent=1);open(f'{out}/table.md','w').write('\n'.join(lines)+'\n');print('\n'.join(lines))
# --- event-overhead correction: every profiled dispatch carries a near-constant event cost f (trivial sp_init/sp_recover
# read ~43us exec). f is solved per tier so that sum(step - f) equals the unprofiled HIP span; corrected fam = step - n*f.
lines2=[]
for h in ('900','1080'):
    rows=json.load(open(f'{out}/dispatch-{h}.json'));d=res[h];n=len(rows)
    f=(sum(r['step_us'] for r in rows)-1000*d['span_plain'])/n
    mn=min(r['exec_us'] for r in rows)
    lines2.append(f'## {h} corrected: f={f:.1f}us/dispatch (min exec {mn:.1f}us, trivial sp_init/recover ~43); plain span {1000*d["span_plain"]:.0f}us vs his {sum(d["his"].values()):.0f}us, diff {1000*d["span_plain"]-sum(d["his"].values()):+.0f}us')
    lines2.append('| fam | ours in-chain (step - f) | disp | his | ours-his |');lines2.append('|---|---:|---:|---:|---:|')
    cf={}
    for r in rows:
        fam=ofam2(r['module'],r['kernel']);cf[fam]=cf.get(fam,0)+r['step_us']-f
    for fam in ['C32','C64','C128','C256','C512','ViT','other']:
        lines2.append(f'| {fam} | {cf.get(fam,0):.1f} | {d["ours_disp"].get(fam,0)} | {d["his"].get(fam,0):.1f} | {cf.get(fam,0)-d["his"].get(fam,0):+.1f} |')
    sp=[r for r in rows if r['module']=='sp'];spo=json.load(open(f'{out}/dispatch-{h}-swin-off.json'))
    lines2.append('SP corrected: '+'; '.join(f"{r['kernel']} {r['step_us']-f:.1f}" for r in sp))
    res[h]['f']=f;res[h]['corrected']=cf
    # swin-off: the same C256 blocks as separate launches; list C256 rows
    c=[r for r in spo if ofam2(r['module'],r['kernel'])=='C256']
    lines2.append('SWIN_RUN=0 C256 dispatches (step - f): '+', '.join(f"{r['kernel'].replace('mh_ffn_fused_c256_frag_project_mapped_g128_qkv_','ffn_')}:{r['step_us']-f:.1f}" for r in c))
json.dump(res,open(f'{out}/families.json','w'),indent=1);open(f'{out}/table.md','a').write('\n'.join(lines2)+'\n');print('\n'.join(lines2))
