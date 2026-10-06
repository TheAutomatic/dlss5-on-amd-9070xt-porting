"""All 512 byte positions and all byte codes; representation only, not WMMA math."""
import numpy as np,json
natural=np.arange(512,dtype=np.uint16).reshape(16,32).astype(np.uint8)
old=np.empty((2,32,8),np.uint8);new=np.empty_like(old);scratch=np.empty((16,32),np.uint8)
for ci in range(2):
 for lane in range(32):
  r=lane%16;g=lane//16
  for e in range(8):
   old[ci,lane,e]=natural[g*8+e,ci*16+r]
   new[ci,lane,e]=natural[r,ci*16+g*8+e]
   scratch[r,ci*16+g*8+e]=new[ci,lane,e]
restored=np.empty_like(old)
for ci in range(2):
 for lane in range(32):
  for e in range(8):restored[ci,lane,e]=scratch[(lane//16)*8+e,ci*16+lane%16]
assert np.array_equal(old,restored)
print(json.dumps({'positions':512,'all256bytecodes_present':True,'FP8_layout_bitdiff':0,'scope':'pure bit-layout restoration includesNaN bytes; no arithmetic gold or hardware synchronization proof'}))
