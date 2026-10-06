"""Finite CPU model: half RTZ then E4M3 RNE versus direct E4M3 RNE.
Not a GPU intrinsic/NaN-mode proof. Enumerate every critical FP8 midpoint.
"""
import bisect,struct,json,hashlib
from pathlib import Path
out=Path(__file__).resolve().parents[3]/'results/c32-direct-feature-20261006';out.mkdir(parents=True,exist_ok=True)
def f(bits):return struct.unpack('<f',struct.pack('<I',bits))[0]
def bits(x):return struct.unpack('<I',struct.pack('<f',x))[0]
def half_rtz(b):
 sign=(b>>16)&0x8000;mag=b&0x7fffffff
 if mag>=0x7f800000:return sign|0x7c00|(0x200 if mag>0x7f800000 else 0)
 exp=(mag>>23)-127;mant=(mag&0x7fffff)|0x800000
 if exp>15:return sign|0x7bff
 if exp>=-14:return sign|((exp+15)<<10)|((mag&0x7fffff)>>13)
 if exp<-24:return sign
 return sign|(mant>>(-exp-1))
def half(h):return struct.unpack('<e',struct.pack('<H',h))[0]
levels=[(c&7)*2**-9 if c<8 else (1+(c&7)/8)*2**((c>>3)-7)for c in range(127)]
def fp8(x,negative=False):
 a=min(abs(x),448.0);i=bisect.bisect_left(levels,a)
 if i==0:c=0
 elif i>=127:c=126
 elif levels[i]==a:c=i
 else:
  l=i-1;dl=a-levels[l];dh=levels[i]-a;c=l if dl<dh or(dl==dh and l%2==0)else i
 return c|(0x80 if negative else 0)
samples={0,0x80000000,0x7f800000,0xff800000,0x7fc00000,0xffc00000,0x3f880001,0xbf880001}
count_positive=0;intervals=[]
for c in range(126):
 mid=(levels[c]+levels[c+1])/2;mb=bits(mid);hb=half_rtz(mb);assert half(hb)==mid;nb=bits(half(hb+1))
 for b in (mb-1,mb,mb+1,nb-1,nb,nb+1):samples.add(b);samples.add(b|0x80000000)
 if c%2==0:
  count_positive+=nb-mb-1;intervals.append({'lower_fp8':c,'mid_f32bits':mb,'last_diff_f32bits':nb-1,'float_code_count':nb-mb-1})
rows=[];raw=bytearray()
for b in sorted(samples):
 x=f(b);h=half_rtz(b);row={'a_bits':f'{b:08x}','residual_half_bits':f'{h:04x}','old_fp8':None,'direct_fp8':None,'class':'nonfinite'if (b&0x7fffffff)>=0x7f800000 else 'finite'}
 if row['class']=='finite':row['old_fp8']=fp8(half(h),bool(b>>31));row['direct_fp8']=fp8(x,bool(b>>31))
 rows.append(row);raw+=struct.pack('<I',b)
anchor=next(r for r in rows if r['a_bits']=='3f880001');assert anchor['old_fp8']==0x38 and anchor['direct_fp8']==0x39
assert count_positive==516033
(out/'a32f.bin').write_bytes(raw);(out/'cpu-codes.json').write_text(json.dumps({'scope':'finite IEEE halfRTZ/E4M3RNE CPU model, hardware fmed3/NaN not proven','historical_counterexample':anchor,'positive_code_diff_count_abs_le448':count_positive,'signed_code_diff_count_abs_le448':2*count_positive,'all_critical_midpoint_intervals':intervals,'samples':rows,'sample_diffs':sum(r['old_fp8']!=r['direct_fp8']for r in rows if r['class']=='finite'),'payload_SHA':hashlib.sha256(raw).hexdigest()},indent=2)+'\n')
print('CPU finite differing float encodings',count_positive*2,'boundary samples',len(rows),'sample diffs',sum(r['old_fp8']!=r['direct_fp8']for r in rows if r['class']=='finite'),'anchor',anchor)
