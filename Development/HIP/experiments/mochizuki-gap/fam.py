# per-family table: mochizuki --per-layer --dispatch-grid logs vs our kernel-map-v3 dispatch csv
import csv,re,sys,json,statistics as st
R='/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results/'
def mz(path):
    rows=[];f=0
    for l in open(path,encoding='ascii',errors='ignore'):
        if l.startswith('i ') and 'kernel' in l: f=1;continue
        if f:
            p=l.split()
            if len(p)<12 or not p[0].isdigit(): 
                if rows: break
                continue
            rows.append((int(p[0]),p[1],p[2],int(p[3]),float(p[8])))
    return rows
def mfam(k,t,C):
    if t.startswith('CCVit'): return 'ViT'
    if 'DecInput' in t or 'FinalHead' in t or 'ProjPool' in t: return 'C512' if 'Pool' in t else 'other'
    if C in (3,32): return 'C32'
    return 'C%d'%C
def ofam(sym,mod):
    s=sym
    if s.startswith('vit_'): return 'ViT'
    if 'c32' in s: return 'C32'
    if s.startswith('c64') or s.endswith('c64'): return 'C64'
    if s.startswith('c128') or s.endswith('c128'): return 'C128'
    if 'c256' in s or 'sp_run256' in s: return 'C256'
    if 'c512' in s or s.startswith('split_'): return 'C512'
    if 'decoder' in s: return 'other'
    return 'other'
out={}
for geo,logs,csvf in [('900',['pl1-1600x900.log','pl2-1600x900.log'],'ours-900-dispatch.csv'),('1080',['pl1-1920x1080.log','pl2-1920x1080.log'],'ours-1080-dispatch.csv')]:
    runs=[mz(R+'mochizuki-gap-20261001/'+x) for x in logs]
    m={}
    for i in range(len(runs[0])):
        _,k,t,C,_=runs[0][i]; us=st.mean(r[i][4] for r in runs)
        fam=mfam(k,t,C); m[fam]=m.get(fam,0)+us
    o={};n={}
    for r in csv.DictReader(open(R+'kernel-map-v3-20260930/'+csvf)):
        fam=ofam(r['symbol'],r['module']); o[fam]=o.get(fam,0)+float(r['median_us']); n[fam]=n.get(fam,0)+1
    out[geo]={'mochizuki_inchain_us':m,'ours_isolated_us':o,'ours_dispatches':n,'mochizuki_dispatches':len(runs[0]),'mochizuki_total_ms':[sum(x[4] for x in r)/1000 for r in runs]}
    print(geo,'mz total',out[geo]['mochizuki_total_ms'])
    for f in ['C32','C64','C128','C256','C512','ViT','other']:
        print('  %-5s ours %7.1f (%3d disp)  mz %7.1f  diff %+7.1f'%(f,o.get(f,0),n.get(f,0),m.get(f,0),o.get(f,0)-m.get(f,0)))
    print('  sum ours %.1f mz %.1f'%(sum(o.values()),sum(m.values())))
json.dump(out,open(R+'mochizuki-gap-20261001/families.json','w'),indent=1)
