#!/usr/bin/env python3
"""Generate isolated C64/C128 FFN weight-reuse candidate."""
from pathlib import Path
import argparse,subprocess
p=argparse.ArgumentParser();p.add_argument('--source',type=Path,default=None);p.add_argument('--output',type=Path,default=Path('/tmp/c512-fusion/code/wave_owned_mh_small.inc'));a=p.parse_args()
s=a.source.read_text() if a.source else subprocess.check_output(['git','show','8c9a61db:hip/wave_owned_mh.inc'],cwd=Path(__file__).resolve().parents[4],text=True);anchor='#ifndef W2_FFN_QT_BATCH\n';assert s.count(anchor)==1
s=s.replace(anchor,'''// Optional reuse at smaller channel counts: bit0=C64, bit1=C128.
#ifndef W2_FFN_QT_SMALL_MASK
#define W2_FFN_QT_SMALL_MASK 0
#endif
#if W2_FFN_QT_SMALL_MASK < 0 || W2_FFN_QT_SMALL_MASK > 3
#error W2_FFN_QT_SMALL_MASK must be 0..3
#endif
'''+anchor)
old=' if constexpr(C==256){';assert s.count(old)==1
s=s.replace(old,' if constexpr(C==256 || (C==64 && (W2_FFN_QT_SMALL_MASK&1)) || (C==128 && (W2_FFN_QT_SMALL_MASK&2))){')
a.output.parent.mkdir(parents=True,exist_ok=True);a.output.write_text(s);print(a.output)
