#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../../.."
OUT=/tmp/pdl-audit-20260927
mkdir -p "$OUT"
python3 - <<'PY'
from pathlib import Path
import shutil
out=Path('/tmp/pdl-audit-20260927')
for part in ('src','Development/HIP'):
 d=out/part;d.mkdir(parents=True,exist_ok=True)
 for p in Path(part).glob('*.h'):shutil.copy2(p,d/p.name)
p=out/'Development/HIP/hip_reference_network.h';s=p.read_text();needle='pdl_total[s]>std::numeric_limits<unsigned>::max()-waves';assert needle in s
p.write_text(s.replace(needle,'pdl_total[s]>64u-waves').replace('pdl_total[s]=0;', 'pdl_total[s]=0;std::printf("PDL_ROLLOVER slot=%u\\n",s);'))
PY
CXX=x86_64-w64-mingw32-g++
"$CXX" -std=c++17 -O2 -static -municode -I src -I Development/HIP Development/HIP/benchmark_vit_reuse.cpp -o "$OUT/benchmark.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
# Same host with only the rollover threshold lowered, to exercise the real drain/clear path in short tests.
"$CXX" -std=c++17 -O2 -static -municode -I "$OUT/src" -I "$OUT/Development/HIP" Development/HIP/benchmark_vit_reuse.cpp -o "$OUT/benchmark-rollover.exe" -ld3d12 -ldxgi -ld3dcompiler -ldxguid
