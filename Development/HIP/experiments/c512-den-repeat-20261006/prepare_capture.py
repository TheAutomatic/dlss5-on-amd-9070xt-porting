"""Isolated source-only denominator capture; not a performance candidate."""
from pathlib import Path
import argparse,json,hashlib
p=argparse.ArgumentParser();p.add_argument('canonical_source',type=Path);p.add_argument('output',type=Path);a=p.parse_args();s=a.canonical_source.read_text()
needle='  i2 prob[4];\n  _Pragma("unroll 4") for(uint key=0;key<4;key++){'
assert s.count(needle)==1
capture='''  // Debug output allocation must be at least windows*16*NW*QT*32*8*4 bytes.
  // Reinterpret output as u32; preserve sum0/sum1 addition exactly.
  // Every lane/e is captured independently: no uniformity assertion.
  uint*debug_den=reinterpret_cast<uint*>(out);
  for(uint e=0;e<8;e++)debug_den[((((win*16+head)*NW+wave)*QT+t)*32+tid%32)*8+e]=bits(sums[0][e]+sums[1][e]);
  continue;
'''
s=s.replace(needle,capture+needle);a.output.write_text(s)
a.output.with_suffix('.json').write_text(json.dumps({'scope':'capture actual F16 denominator per window/head/wave/t/lane/e; unchanged QKV/QK/exponent/WMMA sequence; no candidate speed/numerical claim','source_sha':hashlib.sha256(a.canonical_source.read_bytes()).hexdigest(),'capture_sha':hashlib.sha256(s.encode()).hexdigest()},indent=2)+'\n')
