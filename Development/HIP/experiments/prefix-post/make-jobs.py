#!/usr/bin/env python3
# Jobbench jobs for prefix/mapped/finish(69)/post: current (flat-A, installed) and byte variants (flat-X, CW_PREPOST_BYTE 1).
# Source: results/kernel-map-900-20260930/ours{900,1080}-jobs.json. usage: make-jobs.py OUTJSON
import json,copy,sys
R='results/kernel-map-900-20260930/'
ids={'900':['o900-000','o900-001','o900-171','o900-172'],'1080':['o1080-000','o1080-001','o1080-154','o1080-155']}
new={'c32_wave1_prefix':('c32_wave1_prefix_b8d','b4','out'),'c32_wave1_mapped':('c32_wave1_mapped_b8','b0','in'),
     'c32_wave1_finish':('c32_wave1_finish_b8','b3','out'),'c32_wave1_post':('c32_wave1_post_b8','b0','in')}
out=[]
for h,l in ids.items():
    jobs={j['id']:j for j in json.load(open(R+f'ours{h}-jobs.json'))}
    for i in l:
        a=copy.deepcopy(jobs[i]);a['module_file']='flat-A/c32-wave1.hsaco';a['id']=i+'-cur';out.append(a)
        b=copy.deepcopy(jobs[i]);sym,buf,kind=new[b['symbol']];b['symbol']=sym;b['module_file']='flat-X/c32-wave1.hsaco';b['id']=i+'-b8'
        for x in b['buffers']:
            if x['id']==buf:
                assert x['bytes']%4==0;x['bytes']//=4;x['check_bytes']=x['bytes']
                if kind=='in':x['init']='fp8'
                else:x['check']='fp8'
        out.append(b)
json.dump(out,open(sys.argv[1],'w'),indent=1);print(len(out))
