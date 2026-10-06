from pathlib import Path
import csv,json,re,collections
R=Path('/home/lmxxf/work/ai-theorys-study/wechat/assets/297');D=R/'Development/results/daniel-kernels-20260928/dispatch'
meta={k['.name']:k for k in json.load(open('/tmp/kernel-map-900/all-metadata.json'))['amdhsa.kernels']}
geom={x['resolution']:x for x in json.load(open(D/'deep-geometry.json'))};rows=list(csv.DictReader(open(D/'deep-schedule.csv')))
jobs=[];counts=collections.Counter()
for ix,r in enumerate(rows):
 if r['resolution']!='900-default':continue
 resolution=r['resolution'];g=geom[resolution];W,H=g['stages'][4];HW,HH=g['stages'][5];P=g['c512_tiles'];Q=g['head_tiles'];T=g['vit_tokens'];block=int(r['block']);symbol=r['symbol'];family=r['family'];key=(resolution,block,family);slot=counts[key];counts[key]+=1
 j=dict(id=f'daniel.deep.{resolution}.b{block:03d}.{family}.{slot}',family=family,position=f'block{block}',symbol=symbol,module='daniel',grid=[int(r[x]) for x in ['grid_x','grid_y','grid_z']],block=[int(r['threads']),1,1],arg_bytes=meta[symbol]['.args'][0]['.size'],buffers=[],args=[],notes=['Synthetic independent dispatch; no output-equivalence or real-model latency claim.',r['evidence']],geometry=dict(resolution=resolution,c512_width=W,c512_height=H,head_width=HW,head_height=HH,tokens=T,valid_tokens=HW*HH,c512_tiles=P,head_tiles=Q),schedule_row=ix)
 def buf(id,n,init='fp8',amp=.25,output=False,segments=None):
  b=dict(id=id,bytes=n,init='zero' if output else init,amplitude=amp,check=init if output else 'none',role='output' if output else 'input')
  if segments:b['segments']=segments
  j['buffers'].append(b);return id
 def ptr(off,id=None):j['args'].append(dict(offset=off,type='ptr',buffer=id) if id else dict(offset=off,type='u64',value=0))
 def val(off,value,type='i32'):j['args'].append(dict(offset=off,type=type,value=value))
 def seg(off,n,kind,amp):return dict(offset=off,bytes=n,init=kind,amplitude=amp)
 B=P*8192
 if 'reg_vit_ffwd' in symbol:
  ext='ELb1ELb0' in symbol
  inp=buf('input',B);out=buf('output',B,output=True);wei=buf('weights',524288,'fp8',.015625)
  ptr(0,None if ext else inp);ptr(8,buf('external',W*H*512) if ext else None);ptr(16,out);ptr(24,wei);val(32,H);val(36,W);val(40,P)
  j['notes']+=['FFWD +32/+36 are height/width (host042f8a,042f8d), normal variant ignores dimensions; external variant consumes FP8 bytes, not float.']
 elif 'reg_vit_conv' in symbol:
  flags=int(re.search(r'convILi\d+ELi(\d+)',symbol)[1]);stage='contract_project' if slot==1 else 'attention_project'
  inp=buf('input',B);res=buf('residual',B);out=buf('output',B,output=True)
  wei=buf('weights',262144+1024,'fp8',.015625,segments=[seg(262144,1024,'half',.015625)])
  ptr(0,inp);ptr(8,None if flags==1 else res);ptr(16,buf('external_input',W*H*512) if flags==1 else None);ptr(24,out);ptr(32,buf('external_output',W*H*512,output=True) if flags==2 else None);ptr(40,wei);val(48,H);val(52,W);val(56,P)
  ptr(64,buf('pooled_output',Q*8192,output=True) if flags==4 else None);val(72,HH if flags==4 else 0);val(76,HW if flags==4 else 0)
  j['variant']=dict(flags=flags,stage=stage);j['notes']+=['Flag1 external-input,2 external-output,4 pool-output. FP8 matrix262144B followed by512 half residual scales, ISA D0074/D0190. All output padding startszero; finite check does not prove full coverage.']
 elif 'reg_vit_attn3' in symbol:
  sh=[(0,0),(-4,-4),(-4,0),(0,-4)][((block-23) if block<31 else (block-40))%4]
  inp=buf('input',B);out=buf('output',B,output=True);wei=buf('weights',917568,'fp8',.015625,segments=[seg(786432,131072,'half',.015625),seg(917504,64,'f32',.015625)])
  ptr(0,inp);ptr(8,out);ptr(16,wei);val(24,H);val(28,W);val(32,sh[0]);val(36,sh[1]);j['geometry']['shift']=sh
  j['notes']+=['Weight:3*512*512FP8 +16*64*64half bias +16f32norm scale, EAB70/EC140. Window grid unchanged from schedule.']
 elif 'k_expand2' in symbol:
  ptr(0,buf('input',T*1024));ptr(8,buf('output',T*4096,output=True));ptr(16,buf('weights',4096*1024,'fp8',.015625));ptr(24)
 elif 'reg1d_conv' in symbol:
  contract=slot==1;K=4096 if contract else 1024;M=K*1024;split='ELb1ELb0' in symbol
  ptr(0,buf('input',T*K));ptr(8,buf('skip',T*1024));ptr(16,buf('output',T*1024,output=True));ptr(24,buf('weights',M+2048,'fp8',.015625,segments=[seg(M,2048,'half',.015625)]))
  val(32,K);val(36,M);val(40,4);ptr(48);ptr(56,buf('split_scratch',3*T*8192,'zero') if split else None);val(64,T);ptr(72,buf('split_flags',80*(T//64),'zero') if split else None)
  j['variant']=dict(stage='contract' if contract else 'projection',split4=split);j['notes']+=['Split4 flags initiallyzero. ISA F2E98 atomic-increment and F2EF4 finalizer reset tozero; launches must remain stream-ordered. Scratch logical allocated capacity follows host03df5b.']
 elif 'reg1d_qkv' in symbol:
  ptr(0,buf('input',T*1024));ptr(8,buf('Q',T*1024,output=True));ptr(16,buf('K',T*1024,output=True));ptr(24,buf('V',T*1024,output=True))
  ptr(32,buf('weights',3*1024*1024+128,'fp8',.015625,segments=[seg(0,128,'f32',.015625)]));val(40,T);ptr(48);ptr(56);ptr(64)
  j['notes']+=['Reference QKV weight allocation:128B scale prefix +3MiBFP8 matrix. Matrix load starts+0x80 at101574; scale load frombase at1025B0. Q/K/V separate packed byte arrays; padding zero initialized.']
 elif 'reg1d_attn' in symbol:
  for off,id in [(0,'Q'),(8,'K'),(16,'V')]:ptr(off,buf(id,T*1024))
  ptr(24,buf('output',T*1024,output=True));val(32,T);val(36,HW*HH);ptr(40)
 elif 'k_repack' in symbol:
  direction=1 if block==30 else 0
  ptr(0,buf('input',Q*16384 if direction else T*1024));ptr(8,buf('output',T*1024 if direction else Q*16384,output=True));val(16,HH);val(20,HW);val(24,T);val(28,direction);val(32,1);val(36,HW);val(40,HH)
  j['notes']+=['Repack48 ABI host038dfe..38e46 and03a992..a9e6; dimensions16/20 follow CHW H/W, content dims36/40 followobject378/37c W/H; defaulttokens config keeps full validT.']
 elif 'reg_head' in symbol:
  ptr(0,buf('input',Q*8192));ptr(8,buf('output',Q*16384,output=True));ptr(16,buf('weights',512*1024,'fp8',.015625))
 elif 'reg_decup' in symbol:
  ptr(0,buf('input',Q*16384));ptr(8,buf('skip',B));ptr(16,buf('output',B,output=True));ptr(24,buf('weights',524288+1024,'fp8',.015625,segments=[seg(524288,1024,'half',.015625)]));val(32,(HH+3)//4);val(36,W//4);val(40,H//4);val(44,W//4)
  j['notes']+=['DecUpReg48 host03aeab..aee7: source head tileheight at32; output tilewidth,height,width at36/40/44.1024→512FP8 matrix plus512half skip scales(ISA C05DC).']
 else:raise Exception(symbol)
 for a in j['args']:assert a['offset']+({'ptr':8,'u64':8}.get(a['type'],4))<=j['arg_bytes'],(symbol,a)
 jobs.append(j)
Path('/tmp/kernel-map-900/daniel-deep-900.json').write_text(json.dumps(jobs,indent=2))
print(len(jobs),'jobs',len({j['symbol'] for j in jobs}),'symbols')
