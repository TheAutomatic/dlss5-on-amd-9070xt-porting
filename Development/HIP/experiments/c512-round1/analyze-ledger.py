from pathlib import Path
import csv,json,statistics,collections,sys
out=Path(sys.argv[1]);result={}
for height in (900,1080):
 d=out/str(height);data=(d/'run.log').read_bytes();log=data.decode('utf-16') if data[:2]==b'\xff\xfe' else data.decode()
 assert 'PASS c512 ledger' in log,'incomplete/polluted ledger is not accepted'
 resources=collections.defaultdict(set);counts=collections.Counter()
 for l in log.splitlines():
  if not l.startswith('TOPO,'):continue
  _,stage,module,kernel,groups,threads,regs,lds,scratch,blocks=l.split(',')
  if kernel not in ['split_mix_blocked_h16w_m32','split_ffn_fused_fp8_t8','split_projection_frag','mh_qkv_normalize_frag_c512_m32','mh_attention_fused_fp8_out','mh_attention_project_frag_c512','mh_shift_pack']:continue
  resources[kernel].add(tuple(map(int,[groups,threads,regs,lds,scratch,blocks])));counts[kernel]+=1
 times=collections.defaultdict(list)
 for r in csv.DictReader((d/'marginal.csv').open()):times[r['kernel'].rstrip('$')].append(float(r['ms']))
 vals={}
 for k,rs in resources.items():
  x=times.get(k,[]);delta=[(x[i+1]+x[i+2]-x[i]-x[i+3])/4 for i in range(0,len(x)-3,4)]
  vals[k]={'calls':counts[k],'resources':[dict(zip(['groups','threads','vgpr','lds','scratch','resident_groups_per_mp'],r),waves=r[0]*r[1]//32,total_resident_waves=32*r[5]*r[1]//32,grid_to_resident_capacity=r[0]/(32*r[5])) for r in sorted(rs)],'marginal_round_ms':delta,'marginal_mean_ms':statistics.mean(delta) if delta else None}
 result[str(height)]=vals
print(json.dumps(result,indent=2))
