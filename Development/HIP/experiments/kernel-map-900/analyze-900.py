#!/usr/bin/env python3
# 900-tier kernel map (2026-09-30). Reads jobbench logs (same harness/rules as kernel-map-20260929):
# 7 TIME rounds, median; START symbol; pre/post CHECK guards=0 invalid=0 nonzero>0.
# usage: analyze-900.py WORK OUT   (WORK has ours-jobs.json daniel-*.json logs-ours900 logs-daniel900 [logs-ours1080 ours1080-jobs.json])
import sys,json,csv,math,statistics as st,collections
from pathlib import Path
W=Path(sys.argv[1]);O=Path(sys.argv[2]);O.mkdir(parents=True,exist_ok=True)
def parse(log,symbol):
    t={};start=[];checks=[];res=[];err=[]
    b=log.read_bytes();s=b.decode('utf-16') if b[:2] in (b'\xff\xfe',b'\xfe\xff') else b.decode('utf-8','replace')
    for line in s.splitlines():
        r=line.strip().split(',')
        if r[0]=='START':start.append(r[2])
        elif r[0]=='TIME':t[int(r[2])]=float(r[3])
        elif r[0]=='CHECK':checks.append({k:int(v) for k,v in (z.split('=',1) for z in r[2:] if '=' in z)})
        elif r[0]=='RESULT':res.append(r)
    if start!=[symbol]:err.append('start')
    if sorted(t)!=list(range(7)):err.append('rounds')
    if len(checks)<2 or any(c.get('guards')!=0 or c.get('invalid')!=0 or c.get('nonzero',0)<=0 for c in checks):err.append('check')
    if len(res)!=1:err.append('result')
    return (st.median(t.values()) if t else float('nan')),err
def fam_ours(k):
    if k.startswith('c32_') or k=='mh_pool_project_production_h16w':return 'C32'
    if k.startswith('c64_') or k=='mh_pool_project_group_c64':return 'C64'
    if k.startswith('c128_') or k=='mh_pool_project_group_c128':return 'C128'
    if k.startswith('c256_') or k.startswith('sp_') or k.startswith('mh_ffn_fused_c256') or k=='mh_pool_project_group_c256' or k=='decoder_project2x_h16w_byteout':return 'C256'
    if k=='mh_pool_project_group_c512':return 'head'
    if k=='decoder_project2x_h16w':return 'decoder'
    if k.startswith('vit_'):return 'ViT'
    return 'C512'
def load(jobs,logdir):
    rows=[]
    for j in json.load(open(jobs)):
        us,err=parse(logdir/(j['id']+'.log'),j['symbol']);rows.append(dict(id=j['id'],symbol=j['symbol'],grid=j['grid'][0]*j['grid'][1]*j['grid'][2],threads=j['block'][0],us=us,err=';'.join(err),family=j.get('family'),position=j.get('position')))
    return rows
ours=load(W/'ours-jobs.json',W/'logs-ours900')
dan=load(W/'daniel-deep-900.json',W/'logs-daniel900')+load(W/'daniel-shallow-900.json',W/'logs-daniel900')
for r in ours:r['family']=fam_ours(r['symbol'])
for r in dan:
    f=r['family'];r['family']={'ViT-repack':'ViT'}.get(f,f)
sp=json.load(open(W/'sp-estimate.json'))  # in-network event estimate for 2 persistent C256 runs (not jobbench-measurable)
for x in sp:ours.append(dict(id=x['id'],symbol=x['symbol'],grid=x['grid'],threads=x['threads'],us=x['us'],err='',family='C256',position=None,estimate=1))
bad=[r for r in ours+dan if r['err']];print('bad',len(bad),[(r['id'],r['err']) for r in bad][:10])
def write(rows,name):
    with open(O/name,'w',newline='') as f:
        w=csv.writer(f);w.writerow(['id','symbol','family','grid','threads','median_us','status'])
        for r in rows:w.writerow([r['id'],r['symbol'],r['family'],r['grid'],r['threads'],f"{r['us']:.3f}",'estimate_in_network_event' if r.get('estimate') else (r['err'] or 'ok')])
write(ours,'ours-900-dispatch.csv');write(dan,'daniel-900-dispatch.csv')
def agg(rows,key):
    a=collections.OrderedDict()
    for r in rows:
        x=a.setdefault(key(r),[0,0.0,set()]);x[0]+=1;x[1]+=r['us'];x[2].add(f"{r['grid']}x{r['threads']}")
    return a
tot=sum(r['us'] for r in ours);dtot=sum(r['us'] for r in dan)
ka=agg(ours,lambda r:r['symbol']);rank=sorted(ka.items(),key=lambda x:-x[1][1])
with open(O/'ours-900-kernels.csv','w',newline='') as f:
    w=csv.writer(f);w.writerow(['rank','kernel','family','calls','total_us','per_call_us','share_pct','shapes'])
    for i,(k,(c,us,sh)) in enumerate(rank,1):w.writerow([i,k,fam_ours(k),c,f'{us:.1f}',f'{us/c:.2f}',f'{100*us/tot:.2f}',' '.join(sorted(sh))])
fo=agg(ours,lambda r:r['family']);fd=agg(dan,lambda r:r['family'])
with open(O/'family-900.csv','w',newline='') as f:
    w=csv.writer(f);w.writerow(['family','ours_dispatches','ours_us','daniel_dispatches','daniel_us','delta_us'])
    for k in ['C32','C64','C128','C256','C512','head','decoder','ViT']:
        a=fo.get(k,[0,0]);b=fd.get(k,[0,0]);w.writerow([k,a[0],f'{a[1]:.1f}',b[0],f'{b[1]:.1f}',f'{a[1]-b[1]:+.1f}'])
    w.writerow(['TOTAL',len(ours),f'{tot:.1f}',len(dan),f'{dtot:.1f}',f'{tot-dtot:+.1f}'])
print('ours',len(ours),round(tot,1),'daniel',len(dan),round(dtot,1))
