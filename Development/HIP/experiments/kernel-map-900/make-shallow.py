from pathlib import Path
import json
O=Path('/tmp/kernel-map-900');schedule=json.load(open(Path('/home/lmxxf/work/ai-theorys-study/wechat/assets/297')/'Development/results/daniel-kernels-20260928/dispatch/swin-schedule.json'));shifts=[(0,0),(-4,-4),(-4,0),(0,-4)]
jobs=[]
for row in schedule:
 if row['resolution']!='900-default':continue
 C=int(row['family'][1:]);F=row['variant'];W,H=1600,960;scale=C//16 if row['part'] not in ['prefix','post'] else 1;w,h=W//scale,H//scale;sx,sy=shifts[row['shift_index']];np=w*h;B=[];A=[]
 def buf(id,bytes,init='fp8',value=.25):
  B.append({'id':id,'bytes':int(bytes),'init':init,'value':value,'check':'none' if init!='zero' else ('f32' if id=='post_rgba_output' else 'fp8'),'check_bytes':int(bytes)});return id
 def ptr(off,id):A.append({'offset':off,'type':'ptr','buffer':id})
 def val(off,v,type='i32'):A.append({'offset':off,'type':type,'value':v})
 # Every user pointer is independent, allocated with conservatively sized payload; harness owns outer guards.
 ptr(0,buf('input',np*C*4));ptr(8,buf('output',np*C*4,'zero',0));ptr(16,buf('weights',max(4*1024*1024,32*C*C),'fp8',1/64))
 # Mixed packed layouts: ISA scale loads and half positional-bias ranges.
 ffbase=8192 if C==32 else 5*C*C+128*C
 norm={32:19552,64:57504,128:180512,256:623136}[C]
 if F==8:norm={32:21664,64:65792,128:213504,256:754688}[C]
 if F==20:norm=20576
 if F==32:norm=19664
 bias=norm-8192*(C//32);qkv=bias-3*C*C
 scale_start=ffbase+(2*C*C if F==8 else 0)
 weight=B[-1]
 weight['segments']=[{'offset':scale_start,'bytes':qkv-scale_start,'init':'half','value':1.0},{'offset':bias,'bytes':norm-bias,'init':'half','value':1/64},{'offset':norm,'bytes':((4*(C//32)+15)//16)*16,'init':'f32','value':1.0}]
 weight['patches']=[{'offset':norm,'type':'f32','value':1.0,'count':C//32}]
 if F==20:weight['segments'].insert(1,{'offset':ffbase,'bytes':1024,'init':'half','value':1/64})
 for off,v in [(24,w),(28,h),(32,sx),(36,sy),(40,F)]:val(off,v)
 # +176/+184 are two int32 dimension pairs, never pointers.
 if F&4:
  ptr(56,buf('down_output',((w+1)//2)*((h+1)//2)*C*8,'zero',0));val(176,(w+1)//2);val(180,(h+1)//2)
 if F==8:
  ptr(48,buf('up_low',((w+1)//2)*((h+1)//2)*2*C*4));val(184,(w+1)//2);val(188,(h+1)//2)
 if F==20:
  # Prefix input0 is unused; direct raw input at+64, optional auxiliary at+72; history+112 stays null.
  ptr(64,buf('raw_rgb_float',np*12,'f32',.25));ptr(72,buf('prefix_aux',np*16,'f32',.25))
  for off in [80,84,88,92,96,100]:val(off,1.0 if off==80 else 0.0,'f32')
  val(104,123,'u32')
 if F==32:
  ptr(120,buf('post_rgba_output',np*16,'zero',0));ptr(128,buf('post_rgb_input',np*12,'f32',.25))
  val(144,1.0,'f32');val(148,0.0,'f32');val(152,1,'u32');ptr(160,buf('post_low_feature',((w+1)//2)*((h+1)//2)*C*4))
 jobs.append({'id':f"daniel-{row['resolution']}-block{row['block']}",'family':row['family'],'position':row['block'],'symbol':row['symbol'],'module':'daniel','grid':[row['grid_x'],row['grid_y'],1],'block':[row['threads'],1,1],'arg_bytes':192,'buffers':B,'args':A,'notes':f"reference flags{F}; synthetic finite nonzero; independent inputs not model output; 4-byte-capacity feature buffers conservative, not traffic; prefix calibration identity and history disabled, post no optional history. Guard/finite smoke required before timing.",'geometry':{'resolution':row['resolution'],'width':w,'height':h,'channels':C,'shift':[sx,sy],'flags':F,'phase':row['part'],'waves':row['waves']}})
(O/'daniel-shallow-900.json').write_text(json.dumps(jobs,indent=2));print('jobs',len(jobs),'per geometry',len(jobs)//2)
