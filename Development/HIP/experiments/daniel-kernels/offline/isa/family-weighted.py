from pathlib import Path
import json,csv,collections
p=Path(__file__).parent;root=p.parent;isa=json.loads((p/'census.json').read_text())['kernels'];schedule=sum([json.loads((root/'dispatch'/n).read_text()) for n in ['swin-schedule.json','deep-schedule.json']],[]);groups={};missing=set()
metrics=['issued_static','vector_slots','VALU','VOPD','VOPD_slots','WMMA','VMEM','VMEM_read_requests','VMEM_write_requests','VMEM_read_bytes_per_lane_static','VMEM_write_bytes_per_lane_static','VMEM_other_requests','VMEM_read_unknown_width','VMEM_write_unknown_width','DS','SALU','SMEM','WAIT','scratch_requests']
def normalize(x):return {**x,'vector_slots':x.get('VALU',0)+x.get('VOPD_slots',0)}
for call in schedule:
 n=call['symbol'];key=(call['resolution'],call['family']);g=groups.setdefault(key,{'resolution':key[0],'family':key[1],'calls':0,'waves':0,'loop_covered_calls':0,'loop_covered_waves':0,'static_wave_weighted':collections.Counter(),'loop_upper_covered_wave_weighted':collections.Counter(),'unknown_loop_symbols':set(),'symbols':set()});g['calls']+=call['calls'];g['waves']+=call['waves'];g['symbols'].add(n)
 if n not in isa:missing.add(n);continue
 d=isa[n];st=normalize(d['static']);up=d['loop_expanded_path_sum_upper']
 for m in metrics:g['static_wave_weighted'][m]+=st.get(m,0)*call['waves']
 if up is not None:
  g['loop_covered_calls']+=call['calls'];g['loop_covered_waves']+=call['waves'];up=normalize(up)
  for m in metrics:g['loop_upper_covered_wave_weighted'][m]+=up.get(m,0)*call['waves']
 else:g['unknown_loop_symbols'].add(n)
assert not missing,missing
rows=[];staticrows=[];looprows=[]
for key,g in sorted(groups.items()):
 for k in ['symbols','unknown_loop_symbols']:g[k]=sorted(g[k])
 g['loop_coverage_waves_fraction']=g['loop_covered_waves']/g['waves'];g['loop_full_family_upper']=g['loop_upper_covered_wave_weighted'] if g['loop_covered_calls']==g['calls'] else None;rows.append(g)
 base={k:g[k] for k in ['resolution','family','calls','waves','loop_covered_calls','loop_covered_waves','loop_coverage_waves_fraction']}
 staticrows.append({**base,**g['static_wave_weighted']});looprows.append({**base,'complete_family':g['loop_full_family_upper'] is not None,**g['loop_upper_covered_wave_weighted']})
def write(name,rs):
 with (p/name).open('w') as f:w=csv.DictWriter(f,list(dict.fromkeys(k for row in rs for k in row)));w.writeheader();w.writerows(rs)
for resolution in sorted(set(r['resolution'] for r in staticrows)):
 for rank,row in enumerate(sorted([r for r in staticrows if r['resolution']==resolution],key=lambda r:r['issued_static'],reverse=True),1):row['static_issued_rank']=rank
write('family-weighted.csv',staticrows);write('family-loop-covered.csv',looprows)
(p/'family-weighted.json').write_text(json.dumps({'metric':'static instruction sites multiplied by host-derived dispatched waves, not executed dynamic instructions; VMEM bytes per active lane request width, not DRAM traffic','loop_metric':'loop-expanded path-sum upper only for covered calls; no sum-of-partial as whole-family value','dispatch_assumptions':'default flags, default 32 MP host path; all three stage geometries derive from host formulas, not runtime capture','families':rows},indent=2))
lines=['# Daniel全族加权账','', 'family-weighted.csv 是静态×推导waves；family-loop-covered.csv 是可证循环展开部分×推导waves。后表covered_calls/waves不足全族时只能看覆盖部分，完整族动态上界为NA。VMEM字节是每活跃lane请求宽度加权，不是实际DRAM流量。所有毫秒差为NA。','', 'Swin/C512/global ViT分族来自dispatch host映射：global ViT=reg1d；C512=reg_vit。', '', '|几何|族|调用|waves|static issued×waves|loop覆盖calls|loop覆盖waves|完整loop上界|','|---|---|---:|---:|---:|---:|---:|---:|']
for g in rows:
 lines.append(f"|{g['resolution']}|{g['family']}|{g['calls']}|{g['waves']}|{g['static_wave_weighted']['issued_static']}|{g['loop_covered_calls']}|{g['loop_covered_waves']}|{g['loop_full_family_upper']['issued_static'] if g['loop_full_family_upper'] is not None else 'NA'}|")
lines+=['','900静态规模排序：C32 > C64 > C128 > C512 > ViT > C256；1080两几何：C32 > C64 > C128 > C256 > C512 > ViT。只排规模，不排速度瓶颈。','', '同几何完整循环路径上界对照：900 C32 ours683590895 vs Daniel696582260 issued，C64 ours216723564 vs Daniel235218716；1080 matched C32 ours982773555 vs Daniel1002073640，C64 ours310692212 vs Daniel337242948。两族我方issued上界均更少，但VMEM请求约两倍；后续应查布局/张量中间写回，不是只追VALU条数。边界waves仍有小幅差异，这不是逐wave同工作量证明。','', '排行只表示静态工作规模，循环展开差异会改变排序，不能拿这个比值推算时间。默认154派发是host推导；生产若覆盖flags/MP阈值，必须重新选路径。C32所有使用flags均可证4次循环（20为lg+scc1的同义回边），可完整加权；C64/128边界变体存在复杂路径时保持NA。']
(p/'FAMILY-WEIGHTED.md').write_text('\n'.join(lines)+'\n');print('\n'.join(lines))
