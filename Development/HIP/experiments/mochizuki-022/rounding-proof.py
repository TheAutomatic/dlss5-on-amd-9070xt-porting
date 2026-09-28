"""Exact dyadic counterexample: a coarser destination does not make an earlier rounding redundant."""
import struct,json
from pathlib import Path
f=lambda u:struct.unpack('<f',struct.pack('<I',u))[0]
x=f(0x3f880001);half=struct.unpack('<e',struct.pack('<e',x))[0]
fp8=lambda v:min(range(127),key=lambda u:(abs(((u%8)/512 if u<8 else (1+(u%8)/8)*2**((u>>3)-7))-v),u&1))
assert fp8(x)==0x39 and fp8(half)==0x38
finite=0
for u in range(65536):
 if u&0x7c00==0x7c00:continue
 raw=struct.pack('<H',u);v=struct.unpack('<e',raw)[0];assert struct.pack('<e',v)==raw;finite+=1
out={'f32_bits':'3f880001','x':x,'half_rne':half,'direct_fp8':hex(fp8(x)),'via_half_fp8':hex(fp8(half)),'finite_half_identity_checked':finite,'scope':'Half-grid identity is valid; deleting real half rounding before FP8 is not. This is a scalar mathematical counterexample, not a full-frame benchmark.'}
print(json.dumps(out,indent=2))
