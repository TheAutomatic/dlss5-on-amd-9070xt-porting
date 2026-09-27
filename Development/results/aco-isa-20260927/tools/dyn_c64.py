#!/usr/bin/env python3
"""Per-window dynamic instruction estimate for our c64_wave2_bi_bo: loop bodies weighted by their trip counts
(counters traced by hand: s26 inner x4 inside s23 outer x4; s3, s24, s5 loops x4 each; PDL spin loops once)."""
import collections, re, sys
sys.path.insert(0, __file__.rsplit('/', 1)[0]); import isa_stats as S
kernel = sys.argv[2] if len(sys.argv) > 2 else 'c64_wave2_bi_bo'
t = open(sys.argv[1]).read()
b = next([l.split(';')[0].rstrip() for l in body] for k, body in S.llvm_kernels(t) if k == kernel)
def w(n):
    if 666 <= n <= 889: return 16
    if 647 <= n <= 1040: return 4
    if 1122 <= n <= 1434 or 3250 <= n <= 3820 or 3869 <= n <= 4262: return 4
    return 1
c = collections.Counter(); v = collections.Counter()
for n, l in enumerate(b):
    s = l.strip()
    if not s or s.endswith(':') or s.startswith('.'): continue
    op = s.split()[0]; k = S.classify(op)
    if not k: continue
    c[k] += w(n)
    if k in ('VALU', 'VOPD'): v[op] += w(n)
tot = sum(c.values())
print(f"{kernel} dynamic/window: total {tot} " + " ".join(f"{k} {c[k]}" for k in ('VALU','VOPD','WMMA','DS','VMEM','SALU','SMEM','WAIT')))
for op, n in v.most_common(int(sys.argv[3]) if len(sys.argv) > 3 else 25): print(f"   {n:6} {op}")
