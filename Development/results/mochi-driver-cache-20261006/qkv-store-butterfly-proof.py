"""Symbolic byte provenance proof; not hardware shuffle gold."""
a=[[[ (l//16*8+e,j*16+l%16) for e in range(8)] for j in range(2)] for l in range(32)]
for b in range(3):
 old=a
 a=[[[old[l^(1<<b) if ((l>>b)&1)!=((e>>b)&1) else l][j][e^(1<<b) if ((l>>b)&1)!=((e>>b)&1) else e] for e in range(8)] for j in range(2)] for l in range(32)]
old=a
a=[old[(l&7)|((l&8)<<1)|((l&16)>>1)] for l in range(32)]
for l in range(32):
 for j in range(2):
  for k in range(8): assert a[l][j][k]==(l%16,j*16+(l//16)*8+k)
print('512 unique byte positions pass; no hardware claim')
