import pathlib,json,csv,collections
O=pathlib.Path('/tmp/daniel-kernels/dispatch');allrows=json.loads((O/'all-kernel-map.json').read_text());known={r['symbol'] for r in allrows}
rows=[];geometry=[];buffers=[]
def ceildiv(x,d):return (x+d-1)//d
def add(label,block,family,symbol,g,threads,why):
 assert symbol in known,symbol
 rows.append(dict(resolution=label,block=block,family=family,symbol=symbol,grid_x=g[0],grid_y=g[1],grid_z=g[2],threads=threads,waves=g[0]*g[1]*g[2]*threads//32,calls=1,evidence=why,status='static default path; no env overrides; inferred from host + historical 32 MP device'))
for W,H,label in [(1600,960,'900-default'),(1920,1088,'1080-daniel-default'),(1920,1152,'1080-matched-ours')]:
 # DEFAULT extent mode0, even for matched external W/H (not PAD128 mode2).
 shapes=[(W//2,H//2)]
 for i in range(5):shapes.append(tuple(ceildiv(ceildiv(v,2),4)*4 for v in shapes[-1]))
 cw,ch=shapes[4];hw,hh=shapes[5];P=ceildiv(cw,4)*ceildiv(ch,4);Q=ceildiv(hw,4)*ceildiv(hh,4);T=ceildiv(hw*hh,64)*64;t=T//64;v=2 if P>=128 else 1
 geometry.append(dict(resolution=label,W=W,H=H,stages=shapes,c512_tiles=P,head_tiles=Q,vit_tokens=T))
 for block in list(range(23,31))+list(range(40,48)):
  first=block==23;flag=1 if first else 0
  add(label,block,'C512',f'_Z14k_reg_vit_ffwdILi{v}ELb{int(first)}ELb0EEv13VitFfwdParams',(ceildiv(P,v),8,1),32,'042f93 threshold128; grid(P/v,8,1); r14 ext-input only block23')
  add(label,block,'C512',f'_Z14k_reg_vit_convILi{v}ELi{flag}ELb0EEv13VitConvParams',(ceildiv(P,v),8,1),32,'043a4d..aeb ->0214d0; flags1 external-input block23, else0')
  shift=(block-23)%4 if block<31 else (block-40)%4;sx,sy=[(0,0),(-4,-4),(-4,0),(0,-4)][shift]
  add(label,block,'C512','_Z15k_reg_vit_attn3ILb0EEv10AttnParams',(ceildiv(cw-sx,8),ceildiv(ch-sy,8),16),64,'043c67..d29: QKV + attention,16heads')
  flag=4 if block==30 else (2 if block==47 else 0)
  add(label,block,'C512',f'_Z14k_reg_vit_convILi{v}ELi{flag}ELb0EEv13VitConvParams',(ceildiv(P,v),8,1),32,'043d62..e14; flags4 pool-out block30,flags2 boundary-out block47')
 for block in range(31,39):
  add(label,block,'ViT','_Z9k_expand2ILi1ELb1ELb0EEv12ExpandParams',(t,32,1),256,'038fb7..39098 default reg')
  split=8*t<=64 # 2*MP from old device evidence, default threshold=-1
  sym=f'_Z12k_reg1d_convILi1ELb{int(split)}ELb0EEv12ConvParams1d'
  add(label,block,'ViT',sym,(t,8,4 if split else 1),256,'039306..39db5 contract; split if8*t<=2*MP; buffers allocated')
  add(label,block,'ViT','_Z11k_reg1d_qkvILb0ELb0EEv14Reg1dQkvParams',(t,12,1),256,'03a12c..217; split threshold default0 at03a913')
  add(label,block,'ViT','_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams',(t,32,1),128,'03a500..5c6')
  add(label,block,'ViT',sym,(t,8,4 if split else 1),256,'03a632..6f7 final projection; same wrapper/split threshold')
 for block in [30,38]:add(label,block,'ViT-repack','_Z8k_repack12RepackParams',(256,1,1),256,'038dad..e94 and03a93a..aa34:fixed256groups,looping copy')
 add(label,30,'head','_Z10k_reg_headILi4EEv13HeadRegParams',(Q,16,1),32,'038aa4/38b16..bc2')
 add(label,39,'decoder','_Z11k_reg_decupILb0EEv14DecUpRegParams',(Q,8,1),32,'03aa94/03ae57..af36')
 for obj in ['270','278','280','288']:
  buffers.append(dict(resolution=label,object_offset=obj,bytes=8192*P,kind='C512 intermediate allocation; not measured traffic',evidence='03dc0b..dd71:16*C512*ceil(W/4)*ceil(H/4)'))
 buffers.append(dict(resolution=label,object_offset='2e0',bytes=3*T*8192,kind='ViT split temporary allocation; not measured traffic',evidence='03df5b..dfba'))
 buffers.append(dict(resolution=label,object_offset='2f8',bytes=t*80,kind='ViT split synchronization allocation',evidence='03dfc1..e030'))
(O/'deep-schedule.json').write_text(json.dumps(rows,indent=2));(O/'deep-geometry.json').write_text(json.dumps(geometry,indent=2));(O/'deep-buffer-allocations.json').write_text(json.dumps(buffers,indent=2))
with (O/'deep-schedule.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
agg={}
for r in rows:
 key=(r['resolution'],r['symbol']);a=agg.setdefault(key,dict(resolution=r['resolution'],family=r['family'],symbol=r['symbol'],calls=0,waves=0));a['calls']+=1;a['waves']+=r['waves']
(O/'deep-weighted.json').write_text(json.dumps(list(agg.values()),indent=2));print(json.dumps(geometry));print(collections.Counter((r['resolution'],r['family']) for r in rows))
