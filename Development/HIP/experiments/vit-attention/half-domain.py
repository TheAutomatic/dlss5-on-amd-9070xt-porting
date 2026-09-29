#!/usr/bin/env python3
"""Exhaust every half code the clamped exponent bit-map can produce."""
import struct,json
bits=lambda x:struct.unpack('<I',struct.pack('<f',x))[0]
lo,hi=map(bits,[1.439453125,1.9775390625])
codes=[((h-0x1c000)*16+0x4000)&65535 for h in range(lo>>13,(hi>>13)+1)]
assert len(codes)==552 and len(set(codes))==552
for u in codes:
 e=(u>>10)&31;m=u&1023;s=(u&0x8000)<<16
 assert s==0 and 0<e<31
 soft=s|((e+112)<<23)|(m<<13)
 native=bits(struct.unpack('<e',struct.pack('<H',u))[0])
 assert soft==native
print(json.dumps(dict(clamp=[1.439453125,1.9775390625],half_min=hex(min(codes)),half_max=hex(max(codes)),distinct_half_bits=len(codes),all_positive_normal=True,all_exact=True),indent=2))
