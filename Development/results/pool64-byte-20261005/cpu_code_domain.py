#!/usr/bin/env python3
"""CPU representation proof only; not a substitute for native GPU helper proof.
E4M3 finite codes decode exactly to binary32. Re-encoding an exact lattice
value preserves its code, including both zero signs. Codes 0x7f/0xff are
NaNs and are excluded from this representation identity.
"""
import math, struct, json

def decode(b):
    sign=-1.0 if b & 128 else 1.0
    e=(b >> 3) & 15; m=b & 7
    if e==15 and m==7: return math.nan
    return sign * (math.ldexp(m, -9) if e==0 else math.ldexp(8+m,e-10))

def bits(x): return struct.pack('<f', x)
finite=[b for b in range(256) if b not in (127,255)]
for b in finite:
    v=decode(b)
    # Explicit sign-aware exact inverse, no rounded conversion emulation.
    matches=[c for c in finite if bits(decode(c))==bits(v)]
    assert matches==[b], (b,matches)
print(json.dumps(dict(finite_codes=len(finite), unique_binary32_decode=True,
    positive_zero=bits(decode(0)).hex(), negative_zero=bits(decode(128)).hex(),
    gpu_helper_equivalence="PENDING", scope="representation-only"),indent=2))
