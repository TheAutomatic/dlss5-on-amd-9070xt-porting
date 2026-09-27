from pathlib import Path
import importlib.util,json,re,sys
root=Path(__file__).resolve().parents[4]
spec=importlib.util.spec_from_file_location('stats',root/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(spec);spec.loader.exec_module(S)
rows=[]
for k,b in S.llvm_kernels(Path(sys.argv[1]).read_text()):
 if not k.startswith('c32_wave1'):continue
 opened=None;segments=[]
 for i,l in enumerate(b):
  if 's_setreg' in l:
   if 'HW_REG_MODE, 23, 1' not in l:
    assert opened is None, ('other MODE field changed inside FP8 segment',k,i,l)
    assert 'HW_REG_MODE, 2, 2' in l and re.search(r', 0\s*$',l),l
    continue
   if re.search(r', 1\s*$',l):assert opened is None;opened=i
   elif re.search(r', 0\s*$',l):
    assert opened is not None
    ops=list(S.ops_of(b[opened+1:i]));bad=[op for op,txt in ops if any(x in op for x in ('cvt_f16_f32','cvt_pkrtz_f16','wmma_f32_16x16x16_f16','fma_mixlo','fma_mixhi','v_pk_'))]
    assert not bad,(k,opened,bad)
    assert sum(op=='v_cvt_pk_fp8_f32' for op,txt in ops)==4,(k,opened)
    segments.append(dict(begin=opened,end=i,fp8_conversions=4,half_narrowing=0));opened=None
   else:raise ValueError(l)
 assert opened is None
 rows.append(dict(kernel=k,segments=segments))
assert len(rows)==6 and all(r['segments'] for r in rows)
print(json.dumps(rows,indent=2))
