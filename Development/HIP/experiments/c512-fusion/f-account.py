from pathlib import Path
import sys,re,json,collections
R=Path(__file__).resolve().parents[4];sys.path.insert(0,str(R/'Development/results/aco-isa-20260927/tools'));import isa_stats as S
sys.path.insert(0,str(R/'Development/HIP/experiments/mh-round1'));import cfg
base=Path('/tmp/daniel-kernels/ours-current');f=Path('/tmp/c512-fusion/build-F-gfx1201/c512-m32-mh.hsaco.s');old=dict(S.llvm_kernels((base/'c512-m32-mh.hsaco.s').read_text()));new=dict(S.llvm_kernels(f.read_text()))
# Exact text for old functions (not addresses); metadata fields individually.
def canon(ls):return [re.sub(r'\s+',' ',x.strip()) for _,x in S.ops_of(ls)]
def meta(t,n):
 for c in t.split('  - .args:'):
  if re.search(r'\.name:\s+'+re.escape(n)+r'\s',c):return dict(re.findall(r'\.(vgpr_count|sgpr_count|private_segment_fixed_size|group_segment_fixed_size|vgpr_spill_count|sgpr_spill_count):\s+(\d+)',c))
checks={n:{'isa_equal':canon(b)==canon(new[n]),'resources_equal':meta((base/'c512-m32-mh.hsaco.s').read_text(),n)==meta(f.read_text(),n)} for n,b in old.items() if n in new}
def count(b,tt):
 ls,reach=cfg.analyze(b);assert len(ls)==len(tt),(len(ls),tt);c=collections.Counter()
 for i,l in enumerate(b):
  if i not in reach:continue
  w=1
  for q,t in zip(ls,tt):
   if i in q['lines']:w*=t
  for op,x in S.ops_of([l]):
   c[S.classify(op)]+=w
   if op.startswith(('global_load','global_store')):
    rw='read' if 'load' in op else 'write';m=re.search(r'_[biu](8|16|32|64|96|128)(?:_|$)',op)
    if m:c['global_'+rw+'_bytes_fullwave']+=w*int(m[1])//8*32
   if op.startswith('s_barrier_signal'):c['barrier_signal']+=w
 return dict(c)
a=dict(S.llvm_kernels((base/'multihead_fused_attention.hsaco.s').read_text()))['mh_attention_fused_fp8_out'];ls=cfg.analyze(a)[0];print('attention loop',[(a[q['header']],[a[i].strip() for i in q['lines'] if 's_cmp' in a[i] or 's_add' in a[i]][-7:]) for q in ls])
result={'unchanged_exports':checks,'f_per_wave':count(new['c512_qkv_attention_fused'],[3,4,2]),'qkv_m32_per_wave':count(old['mh_qkv_normalize_frag_c512_m32'],[8,2]),'attention_per_wave':count(a,[2]),'notes':'Counts are path sums; full-wave global request bytes include all lanes, not unique tensor nor DRAM bytes. Old QKV represents 32token*2heads*1part: per window/head multiply3. F 2waves per window/head. Attention normalization needs dispatch work coverage.'}
Path('/tmp/c512-fusion/isa/f-account.json').write_text(json.dumps(result,indent=2));print({k:v for k,v in result.items() if k not in ['unchanged_exports']});print('changed',[(n,d) for n,d in checks.items() if not all(d.values())])
