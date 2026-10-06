#!/usr/bin/env python3
# kernel-map v3 (2026-09-30 afternoon): installed modules (add-on 6d059845 recipe), 900 + 1080.
# jobbench 7-round median per dispatch; sp (persistent C256) from in-network events minus the event bias
# (median of event-jobbench over all matched dispatches). Static ISA class mix per kernel (gfx1201 objdump).
# Memory floor = sum of job buffer bytes (activations + weights, allocation size) / 640 GB/s.
# usage: analyze-v3.py WORK OUT OLD(results/kernel-map-900-20260930)
import sys,json,csv,re,subprocess,statistics as st,collections
from pathlib import Path
W,O,OLD=map(Path,sys.argv[1:4]);O.mkdir(parents=True,exist_ok=True)
_a=sys.argv;sys.argv=[_a[0]];sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'prefix-post-arith'));from cls import fam;sys.argv=_a
def parse(p,sym):
    b=p.read_bytes();s=b.decode('utf-16') if b[:2] in (b'\xff\xfe',b'\xfe\xff') else b.decode('utf-8','replace')
    t={};start=[];chk=[];res=0
    for l in s.splitlines():
        r=l.strip().split(',')
        if r[0]=='START':start.append(r[2])
        elif r[0]=='TIME':t[int(r[2])]=float(r[3])
        elif r[0]=='CHECK':chk.append({k:int(v) for k,v in (z.split('=',1) for z in r[2:] if '=' in z)})
        elif r[0]=='RESULT':res+=1
    err=[]
    if start!=[sym]:err.append('start')
    if sorted(t)!=list(range(7)):err.append('rounds')
    if len(chk)<2 or any(c.get('guards')!=0 or c.get('invalid')!=0 or c.get('nonzero',0)<=0 for c in chk):err.append('check')
    return (st.median(t.values()) if t else float('nan')),';'.join(err)
def kev(p):
    d=collections.defaultdict(list);names={}
    for l in open(p,errors='replace'):
        if not l.startswith('KEV,'):continue
        _,f,i,mod,k,g,t,ms=l.strip().split(',')
        if int(f)<30:continue
        d[int(i)].append(float(ms)*1000);names[int(i)]=(mod,k,int(g),int(t))
    return [(names[i],st.median(d[i])) for i in sorted(d)]
# static ISA mix
isa={}
def mix(module,sym):
    key=(module,sym)
    if key in isa:return isa[key]
    if module not in isa:
        txt=subprocess.run(['llvm-objdump','-d','--mcpu=gfx1201',str(W/'flat-P'/(module+'.hsaco'))],capture_output=True,text=True).stdout
        cur=None;per=collections.defaultdict(collections.Counter)
        for l in txt.splitlines():
            m=re.match(r'^[0-9a-f]+ <(.+)>:$',l)
            if m:cur=m.group(1);continue
            s=l.strip()
            if cur and s and not s.startswith(('/',';','.')) and not s.endswith(':'):
                o=s.split()[0];f=fam(o);per[cur][f]+=1;per[cur]['_n']+=1
        isa[module]=per
    isa[key]=isa[module].get(sym,collections.Counter());return isa[key]
def cls(c):
    n=c['_n'] or 1;v=sum(x for k,x in c.items() if k.startswith('V:'))
    return dict(n=c['_n'],wmma=c['WMMA'],valu=v,valu_pct=100*v/n,wait=c['wait'],mem=c['MEM'],lds=c['LDS'],salu=c['SALU'],cvt=c['V:cvt'],bitpack=c['V:bit/pack'])
out={}
for h in (900,1080):
    jobs=json.load(open(W/f'ours{h}-jobs.json'));rows=[]
    for j in jobs:
        us,err=parse(W/f'logs-o{h}'/(j['id']+'.log'),j['symbol'])
        mb=sum(b['bytes'] for b in j['buffers'])/1e6
        rows.append(dict(id=j['id'],module=Path(j['module_file']).stem,symbol=j['symbol'],us=us,err=err,mb=mb,grid=j['grid'][0]*j['grid'][1]*j['grid'][2],threads=j['block'][0]))
    ev=kev(W/f'prof-{h}.log')
    # match non-sp events in order to jobbench rows
    evn=[(n,u) for n,u in ev if n[0]!='sp']
    assert [n[1] for n,u in evn]==[r['symbol'] for r in rows],(h,len(evn),len(rows))
    bias=st.median(u-r['us'] for (n,u),r in zip(evn,rows))
    for (n,u) in ev:
        if n[0]=='sp':rows.append(dict(id=f'sp{h}-{n[1]}',module='swin-persistent',symbol='sp_run256_w16(est)',us=u-bias,err='',mb=float('nan'),grid=n[2],threads=n[3],est=1))
    bad=[r for r in rows if r['err']];print(h,'rows',len(rows),'bad',len(bad),'bias',round(bias,1))
    tot=sum(r['us'] for r in rows)
    with open(O/f'ours-{h}-dispatch.csv','w',newline='') as f:
        w=csv.writer(f);w.writerow(['id','module','symbol','grid','threads','median_us','buffer_MB','status'])
        for r in rows:w.writerow([r['id'],r['module'],r['symbol'],r['grid'],r['threads'],f"{r['us']:.3f}",f"{r['mb']:.2f}",'estimate_event_minus_bias' if r.get('est') else (r['err'] or 'ok')])
    agg=collections.OrderedDict()
    for r in rows:
        a=agg.setdefault(r['symbol'],dict(module=r['module'],calls=0,us=0.0,mb=0.0));a['calls']+=1;a['us']+=r['us'];a['mb']+=0 if r.get('est') else r['mb']
    rank=sorted(agg.items(),key=lambda x:-x[1]['us'])
    with open(O/f'ours-{h}-kernels.csv','w',newline='') as f:
        w=csv.writer(f);w.writerow(['rank','kernel','module','calls','total_us','per_call_us','share_pct','buffer_MB','mem_floor_us_640','x_floor','isa_n','wmma','valu','valu_pct','wait','mem','lds','salu','cvt','bitpack'])
        for i,(k,a) in enumerate(rank,1):
            sym=k.replace('(est)','').replace('sp_run256_w16','sp_run256_w16')
            c=cls(mix(a['module'],sym));fl=a['mb']/640e3*1e6 if a['mb'] else float('nan')
            w.writerow([i,k,a['module'],a['calls'],f"{a['us']:.1f}",f"{a['us']/a['calls']:.2f}",f"{100*a['us']/tot:.2f}",f"{a['mb']:.1f}",f"{fl:.1f}",f"{a['us']/fl:.2f}" if fl==fl and fl else '',c['n'],c['wmma'],c['valu'],f"{c['valu_pct']:.0f}",c['wait'],c['mem'],c['lds'],c['salu'],c['cvt'],c['bitpack']])
    out[h]=dict(total=tot,rows=len(rows),agg=agg)
    print(h,'total_us',round(tot,1))
# compare with morning 900 map
old={}
for r in csv.DictReader(open(OLD/'ours-900-kernels.csv')):old[r['kernel']]=(int(r['calls']),float(r['total_us']))
def base(k):return re.sub(r'_(b8d|b8|w16)$','',k.replace('(est)',''))
with open(O/'compare-900-morning.csv','w',newline='') as f:
    w=csv.writer(f);w.writerow(['kernel_now','kernel_morning','calls_now','us_now','calls_morning','us_morning','delta_us'])
    seen=set()
    for k,a in sorted(out[900]['agg'].items(),key=lambda x:-x[1]['us']):
        b=base(k);m=k if k in old else (b if b in old else ('sp_run256' if k.startswith('sp_') else None))
        if m=='sp_run256':m=[x for x in old if x.startswith('sp_run256')][0]
        o=old.get(m,(0,0.0));seen.add(m)
        w.writerow([k,m or '',a['calls'],f"{a['us']:.1f}",o[0],f"{o[1]:.1f}",f"{a['us']-o[1]:+.1f}"])
    for m,(c,u) in old.items():
        if m not in seen:w.writerow(['',m,0,'0.0',c,f'{u:.1f}',f'{-u:+.1f}'])
with open(O/'compare-900-1080.csv','w',newline='') as f:
    w=csv.writer(f);w.writerow(['kernel','calls900','us900','calls1080','us1080','ratio'])
    ks=list(dict.fromkeys(list(out[1080]['agg'])+list(out[900]['agg'])))
    for k in sorted(ks,key=lambda k:-out[1080]['agg'].get(k,{'us':0})['us']):
        a=out[900]['agg'].get(k,dict(calls=0,us=0.0));b=out[1080]['agg'].get(k,dict(calls=0,us=0.0))
        w.writerow([k,a['calls'],f"{a['us']:.1f}",b['calls'],f"{b['us']:.1f}",f"{a['us']/b['us']:.2f}" if b['us'] else ''])
json.dump({h:dict(total_us=out[h]['total'],dispatch_rows=out[h]['rows']) for h in out},open(O/'totals.json','w'),indent=1)
