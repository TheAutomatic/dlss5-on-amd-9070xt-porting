#!/usr/bin/env python3
"""Pure byte/layout proofs. Never approximate Box-Muller or claim GPU golden equality."""
import struct
# Every binary16 payload, including signed zero and NaN payload bits, survives packing.
for h in range(65536):
 word=h|(h<<16)
 assert struct.unpack('<HH',struct.pack('<I',word))==(h,h)
for width,height in ((1280,768),(1600,960),(1920,1088),(1920,1152),(2560,1472)):
 # Check the current window-major p -> raster address map is a permutation.
 seen=bytearray(width*height)
 for p in range(width*height):
  tile=p//64;x=(tile%(width//8))*8+p%8;y=(tile//(width//8))*8+(p%64)//8
  r=y*width+x
  assert 0<=r<width*height and not seen[r]
  seen[r]=1
 assert all(seen)
 print('LAYOUT_PASS',width,height,'cache_bytes',width*height*8,'MiB',width*height*8/1048576)
print('HALF_PACK_ALL65536_PASS: no GPU/transcendental output claim')
