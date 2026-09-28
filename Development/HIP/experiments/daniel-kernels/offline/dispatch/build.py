import pathlib,json,subprocess,re,csv,collections,yaml
O=pathlib.Path('/tmp/daniel-kernels/dispatch'); D=pathlib.Path('/tmp/claude-1000/-home-lmxxf-work-ai-theorys-study/129f068a-8529-42b4-b98b-08071124e161/scratchpad/d050'); R=pathlib.Path('/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results')
s=subprocess.check_output(['llvm-readobj','--notes',str(D/'x/gfx1201.hsaco')],text=True);md=yaml.safe_load(s[s.index('amdhsa.kernels:'):s.index('\n...',s.index('amdhsa.kernels:'))]);ks=md['amdhsa.kernels'];refs=json.loads((O/'host-launch-refs.json').read_text());lines=pathlib.Path('/tmp/fma-vs-nvidia/daniel-host.s').read_text().splitlines()
rows=[]
for k in ks:
 n=k['.name']; dem=subprocess.check_output(['c++filt',n],text=True).strip();bs=re.findall('Lb([01])E',n);quality=('fast' if bs[-1]=='1' else 'reference') if bs else 'shared';family='other'
 if 'reg_swin32' in n or 'swin_varILi32' in n:family='C32'
 elif 'swin_mh' in n or 'swin_var' in n or 'swin_chain' in n:family='C'+re.search(r'ILi(\d+)',n)[1]
 elif any(x in n for x in ['reg1d','expand2','contract2','qkv2','attention2']):family='ViT'
 elif any(x in n for x in ['vit','ffwd','conv_res','qkv_attn']):family='C512'
 elif any(x in n for x in ['decup','dec_upsample']):family='decoder'
 elif 'head' in n:family='head'
 elif any(x in n for x in ['import','export','reproject','noise','mean']):family='frame-I/O'
 rr=[r for r in refs if r['symbol']==n and 0x180020230<=int(r['address'],16)<0x180044b80]
 threads=[]
 for r in rr:
  i=r['line']-1
  for l in reversed(lines[max(0,i-60):i]):
   m=re.search(r'movabsq\s+\$0x100000([0-9a-f]+),',l)
   if m:threads.append(int(m[1],16));break
 rows.append(dict(symbol=n,demangled=dem,quality=quality,family=family,wave_size=k.get('.wavefront_size'),vgpr=k.get('.vgpr_count'),sgpr=k.get('.sgpr_count'),lds_bytes=k.get('.group_segment_fixed_size'),scratch_bytes=k.get('.private_segment_fixed_size'),metadata_max_threads=k.get('.max_flat_workgroup_size'),host_block_x_candidates=sorted(set(threads)),host_launch_sites=[r['address'] for r in rr],calls_per_frame=None,grid=None,status='symbol/metadata proven; host block candidates require branch context; runtime activation unknown'))
(O/'all-kernel-map.json').write_text(json.dumps(rows,indent=2));
with (O/'all-kernel-map.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(rows[0]));w.writeheader();w.writerows(rows)
# proven logical stage schedule (default reg path; no chain). Shifts taken from PE constants.
exec((O/'hostmap.py').read_text().split('lines=')[0])
def rd(va,n):
 for lo,hi,off in secs:
  p=va-off
  if lo<=p<hi:return struct.unpack_from('<'+'i'*n,b,p)
shifts={hex(a):rd(a,n) for a,n in [(0x180085380,4),(0x180083478,4),(0x180083490,4),(0x1800834a0,4),(0x18007b4c0,8)]};(O/'host-constants.json').write_text(json.dumps(shifts,indent=2))
# ours dispatch counts are actual existing 214-dispatch census, no assumed Daniel trace.
w=json.loads((R/'mochizuki-022-20260928/conversion-dispatch-weighted.json').read_text())['kernels'];(O/'ours-dispatch-waves.json').write_text(json.dumps({k:{r:{x:v[r][x] for x in ['calls','waves']} for r in ['900','1080'] if r in v} for k,v in w.items()},indent=2))
print('kernels',len(rows),'quality',collections.Counter(r['quality'] for r in rows),'shifts',shifts)
sh=rd(0x18007b4c0,8);xy=[sh[i:i+2] for i in range(0,8,2)]
schedule=[]
for C,first,n,dec,decsh in [(32,1,4,66,[0,1,2,3]),(64,5,4,62,[0,1,2,3]),(128,9,6,56,[2]+list(rd(0x1800834cc,4))+[3]),(256,15,8,48,[0]+list(rd(0x1800834b0,7)))]:
 for j in range(n):schedule.append((C,first+j,(1 if j==0 else 0)+(4 if j==n-1 else 0),j%4,'encoder'))
 for j in range(n):schedule.append((C,dec+j,8 if j==0 else (2 if j==n-1 else 0),decsh[j],'decoder'))
schedule.extend([(32,0,20,0,'prefix'),(32,70,32,0,'post')]);sched=[]
for W,H,label in [(1600,960,'900-default'),(1920,1088,'1080-daniel-default'),(1920,1152,'1080-matched-ours')]:
 for C,block,flag,shift,part in schedule:
  scale=C//16 if part not in ['prefix','post'] else 1;w=W//scale;h=H//scale;sx,sy=xy[shift];gx=(w-sx+7)//8;gy=(h-sy+7)//8
  name=f'_Z12k_reg_swin32ILi{flag}ELb0EEv9VarParams' if C==32 else f'_Z13k_reg_swin_mhILi{C}ELi{flag}ELb0EEv9VarParams'
  sched.append(dict(resolution=label,block=block,family='C'+str(C),part=part,variant=flag,symbol=name,shift_index=shift,grid_x=gx,grid_y=gy,grid_z=1,threads=C,waves=gx*gy*(C//32),calls=1,shape_status='grid formula and shifts host-proven; W/H per stage inferred from network topology'))
(O/'swin-schedule.json').write_text(json.dumps(sched,indent=2))
with (O/'swin-schedule.csv').open('w') as f:
 w=csv.DictWriter(f,fieldnames=list(sched[0]));w.writeheader();w.writerows(sched)
agg={}
for x in sched:
 key=x['resolution']+':'+x['symbol'];a=agg.setdefault(key,dict(symbol=x['symbol'],resolution=x['resolution'],calls=0,waves=0));a['calls']+=1;a['waves']+=x['waves']
(O/'swin-weighted.json').write_text(json.dumps(list(agg.values()),indent=2))
