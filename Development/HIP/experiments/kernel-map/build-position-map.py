#!/usr/bin/env python3
import csv,json,argparse
from pathlib import Path
from collections import defaultdict,Counter
p=argparse.ArgumentParser();p.add_argument('--repo',type=Path,default=Path('/home/lmxxf/work/ai-theorys-study/wechat/assets/297'));p.add_argument('--out',type=Path,default=Path('/tmp/kernel-map'));a=p.parse_args();r=a.repo;o=a.out;o.mkdir(exist_ok=True,parents=True)
source=r/'Development/results';trace=list(csv.reader((source/'deep-layers-20260929/topology-1080.csv').open()));assert len(trace)==169
schedules=source/'daniel-kernels-20260928/dispatch';native='1080-daniel-default'
drows=[x for file in ['swin-schedule.csv','deep-schedule.csv'] for x in csv.DictReader((schedules/file).open()) if x['resolution']==native];assert len(drows)==154,len(drows)
jobs=[];idx=0;skip={42,43,46};boundary=[{4,5},{8,9},{14,15},{22,23},{47,48},{55,56},{61,62},{65,66}]
def group(b,ph):
 if ph=='entry_gather':return 'vit.entry'
 if ph=='exit_gather':return 'vit.exit'
 if b==30:return 'b030.head_boundary'
 for ss in boundary:
  if b in ss:return 'b%03d-%03d.boundary'%(min(ss),max(ss))
 return f'b{b:03d}.{ph}'
def whc(b,ours):
 dims=[(960,576),(480,288),(240,144),(120,72),(60,36)] if ours else [(960,544),(480,272),(240,136),(120,68),(60,36)]
 if b in [0,70]:return (1920,1152 if ours else 1088,32)
 if b<=4 or 66<=b<=69:i=0
 elif b<=8 or 62<=b<=65:i=1
 elif b<=14 or 56<=b<=61:i=2
 elif b<=22 or 48<=b<=55:i=3
 elif b<=30 or b>=39:i=4
 else:return (32,20,1024)
 return (*dims[i],32*(2**i))
def shape(b,ph,ours,shift=None):
 w,h,c=whc(b,ours);s={'valid_w':w,'valid_h':h,'channels':c}
 if ph in ['entry_gather','exit_gather','head'] or 31<=b<=38:s.update(tokens=640,token_grid_w=32,token_grid_h=20,vit_valid_tokens=640,vit_padded_tokens=640)
 if ph in ['entry_gather','exit_gather']:s.update(valid_w=32,valid_h=20,channels=1024)
 if ph=='head':s.update(input_w=60,input_h=36,input_channels=512,output_w=32,output_h=20,output_channels=1024)
 if 31<=b<=38:
  if ph=='expand':s.update(matrix_k=1024,matrix_n=4096)
  elif ph=='contract':s.update(matrix_k=4096,matrix_n=1024)
  elif ph=='qkv':s.update(matrix_k=1024,matrix_n=3072)
  elif ph=='projection':s.update(matrix_k=1024,matrix_n=1024)
  elif ph=='attention':s.update(heads=32,head_channels=32,keys=640)
 if ph=='down_projection':s.update(output_w=w//2,output_h=h//2,input_channels=c,output_channels=c*2)
 if b in [48,56,62,66]:
  prev={48:39,56:48,62:56,66:62}[b];iw,ih,ic=whc(prev,ours);s.update(upstream_w=iw,upstream_h=ih,upstream_channels=ic)

 if (23<=b<=30 or 40<=b<=47) and ph!='head':
  s['pointwise_tokens']=2160;s['ffn_grouped_channels']=64
  if ph=='qkv_attention':s.update(attention_heads=16,keys_per_window=64,window_w=8,window_h=8)
 if ours:
  shifts=[0,3,1,2]*2
  if 23<=b<=30:sh=shifts[b-23]
  elif 40<=b<=69:sh=[0,3,1,2,0,3,1,2,0,3,1,2,0,3,1,2,1,2,0,3,1,2,0,3,1,2,0,3,1,2][b-40]
  elif b==70:sh=3
  elif b==0:sh=0
  else:
   start=1 if b<=4 else 5 if b<=8 else 9 if b<=14 else 15
   sh=shifts[(b-start)%8]
  sx=(sh&1)*4;sy=((sh>>1)&1)*4
  if not 31<=b<=39 and ph not in ['entry_gather','exit_gather','head']:s.update(shift_x=-sx,shift_y=-sy,attention_work_w=(w+sx+7)//8*8,attention_work_h=(h+sy+7)//8*8)
 elif shift is not None:s['host_shift_index']=int(shift)
 if b==70:s['post_shift_policy']='(-4,-4)' if ours else '(0,0)'
 if b==39:s.update(input_grid_w=32,input_grid_h=20,input_channels=1024,output_grid_w=60,output_grid_h=36,output_channels=512)
 return s
def addours(b,ph,n=1):
 global idx
 for q in range(n):
  row=trace[idx];idx+=1;assert row[0]=='TOPO'
  _,mod,ker,count,groups,threads=row
  jobs.append({'dispatch_id':f'O{idx:03d}','job_id':f'ours.1080.b{b:03d}.{ph}.{q}','backend':'ours','resolution':'1080','group_id':group(b,ph),'block':b,'phase':ph,'module':mod,'kernel':ker,'shape_json':json.dumps(shape(b,ph,True),sort_keys=True),'grid_x':int(groups),'grid_y':1,'grid_z':1,'threads':int(threads),'host_count':int(count),'calls_per_frame':1,'evidence':'deep-layers topology-1080.csv line '+str(idx),'median_us':'','measurement_job_id':''})
addours(0,'core')
for lo,hi in [(1,4),(5,8),(9,14),(15,22)]:
 for b in range(lo,hi+1):addours(b,'core')
 addours(hi,'down_projection')
def deep(b):
 addours(b,'ffwd',2);addours(b,'ffn_projection');addours(b,'qkv_attention');addours(b,'attention_projection')
for b in range(23,31):deep(b)
addours(30,'head',2);addours(30,'entry_gather')
for b in range(31,39):
 addours(b,'expand',2);addours(b,'contract');addours(b,'qkv');addours(b,'attention');addours(b,'projection')
addours(38,'exit_gather');addours(39,'up')
for b in range(40,48):
 if b not in skip:deep(b)
addours(48,'up');addours(48,'core')
for b in range(49,71):addours(b,'core')
assert idx==169,idx
# Validate position sequence against actual export names, preventing silent trace drift.
for j in jobs:
 k=j['kernel'];ph=j['phase']
 if ph=='ffwd':assert k in ['split_mix_blocked_h16w_m32','split_ffn_fused_fp8_t8']
 if ph=='qkv_attention':assert k=='c512_qkv_attention_compact'
 if ph in ['entry_gather','exit_gather']:assert k=='vit_gather'
 if ph=='expand':assert k in ['vit_pack_input','vit_expand_blocked_fp8_frag_bytein']
seen=Counter()
for di,d in enumerate(drows,1):
 b=int(d['block']);fam=d['family'];key=(b,fam);part=seen[key];seen[key]+=1
 if fam=='C512':ph=['ffwd','ffn_projection','qkv_attention','attention_projection'][part]
 elif fam=='ViT':ph=['expand','contract','qkv','attention','projection'][part]
 elif fam=='ViT-repack':ph='entry_gather' if b==30 else 'exit_gather'
 elif fam=='head':ph='head'
 elif fam=='decoder':ph='up'
 else:ph='core'
 jobs.append({'dispatch_id':f'D{di:03d}','job_id':f'daniel.native1080.b{b:03d}.{ph}.0','backend':'daniel','resolution':'1080-native','group_id':group(b,ph),'block':b,'phase':ph,'module':'gfx1201.hsaco','kernel':d['symbol'],'shape_json':json.dumps(shape(b,ph,False,d.get('shift_index')),sort_keys=True),'grid_x':int(d['grid_x']),'grid_y':int(d['grid_y']),'grid_z':int(d['grid_z']),'threads':int(d['threads']),'host_count':'','calls_per_frame':int(d['calls']),'evidence':d.get('evidence',d.get('shape_status','')),'median_us':'','measurement_job_id':''})
for j in jobs:
 sh=json.loads(j['shape_json'])
 if j['backend']=='ours' and j['module'] in ['c32_wave1','c64_wave2']:
  sh['actual_window_count']=j['grid_x'];sh['window_token_capacity']=j['grid_x']*64
 if j['backend']=='daniel' and ('k_reg_swin' in j['kernel']):
  sh['actual_window_count']=j['grid_x']*j['grid_y'];sh['window_token_capacity']=sh['actual_window_count']*64
  j['measurement_job_id']='daniel-1080-daniel-default-block'+str(j['block'])
 j['shape_json']=json.dumps(sh,sort_keys=True)
assert len({j['job_id'] for j in jobs})==323
by=defaultdict(list)
for j in jobs:by[j['group_id']].append(j)
positions=[]
for gid,js in by.items():
 oj=[j for j in js if j['backend']=='ours'];dj=[j for j in js if j['backend']=='daniel'];blocks=sorted({j['block'] for j in js});ratios=[]
 for b in blocks:
  ow,oh,_=whc(b,True);dw,dh,_=whc(b,False);ratios.append(ow*oh/(dw*dh))
 different=any(abs(x-1)>1e-9 for x in ratios);post=70 in blocks;skipped=all(b in skip for b in blocks)
 policy='skip_difference_exclude_implementation_rank' if skipped else 'post_shift_mismatch_separate' if post else 'native_area_estimate_only' if different else 'same_valid_shape_check_work_abi'
 positions.append({'group_id':gid,'blocks':';'.join(map(str,blocks)),'ours_dispatch_ids':';'.join(j['dispatch_id'] for j in oj),'daniel_dispatch_ids':';'.join(j['dispatch_id'] for j in dj),'ours_job_ids':';'.join(j['job_id'] for j in oj),'daniel_job_ids':';'.join(j['job_id'] for j in dj),'ours_kernels':' + '.join(j['kernel'] for j in oj),'daniel_kernels':' + '.join(j['kernel'] for j in dj),'ours_shapes_json':json.dumps([json.loads(j['shape_json']) for j in oj],sort_keys=True),'daniel_shapes_json':json.dumps([json.loads(j['shape_json']) for j in dj],sort_keys=True),'ours_dispatches':len(oj),'daniel_dispatches':len(dj),'comparison_policy':policy,'area_ours_over_daniel':ratios[0] if len(set(ratios))==1 else '', 'area_ratio_by_block_json':json.dumps(dict(zip(blocks,ratios))),'actual_window_work_ratio':(oj[0]['grid_x']/(dj[0]['grid_x']*dj[0]['grid_y']) if len(oj)==len(dj)==1 and oj[0]['phase']=='core' else ''),'matched_shape_plan':'native timing first; optional reconfigure Daniel per its ABI to ours shape, recompute grid; post shift still differs' if different or post else 'time both at recorded shape; retain own grid and mathematical path','ours_us':'','daniel_us':'','delta_us':'','eligible_exact_shape_rank':int(not different and not post and not skipped),'status':'awaiting timing','note':'all listed kernels form one indivisible comparison group; sum per-dispatch medians, not frame latency; no output-equality claim'})
positions.sort(key=lambda x:(min(map(int,x['blocks'].split(';'))),x['group_id']))
for name,rs in [('dispatch-jobs.csv',jobs),('position-map.csv',positions)]:
 with (o/name).open('w',newline='') as f:w=csv.DictWriter(f,lineterminator="\n",fieldnames=rs[0]);w.writeheader();w.writerows(rs)
coverage={'ours_dispatches':sum(x['ours_dispatches'] for x in positions),'daniel_dispatches':sum(x['daniel_dispatches'] for x in positions),'groups':len(positions),'skip_blocks':[42,43,46],'all_dispatch_ids_unique':len({j['dispatch_id'] for j in jobs})==323,'unassigned':[]}
assert coverage['ours_dispatches']==169 and coverage['daniel_dispatches']==154
(o/'coverage.json').write_text(json.dumps(coverage,indent=2)+'\n');print(coverage)
