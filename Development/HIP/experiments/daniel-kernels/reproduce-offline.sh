#!/usr/bin/env bash
set -euo pipefail
# Run from the 297 repository. Original Daniel files and our COMGR ISA snapshots
# are the task-supplied /tmp paths, locked by results/.../provenance.json.
cp Development/HIP/experiments/daniel-kernels/offline/dispatch/*.py /tmp/daniel-kernels/dispatch/
cp Development/HIP/experiments/daniel-kernels/offline/isa/*.py /tmp/daniel-kernels/isa/
python3 /tmp/daniel-kernels/dispatch/hostmap.py
python3 /tmp/daniel-kernels/dispatch/build.py
python3 /tmp/daniel-kernels/dispatch/deep.py
python3 /tmp/daniel-kernels/isa/census.py
python3 Development/HIP/experiments/daniel-kernels/ours-census.py /tmp/daniel-kernels/ours-current /tmp/daniel-kernels/ours
python3 /tmp/daniel-kernels/isa/compare-weighted.py
python3 /tmp/daniel-kernels/isa/weighted-summary.py
python3 /tmp/daniel-kernels/isa/family-weighted.py
python3 Development/HIP/experiments/daniel-kernels/layer-pairs.py
python3 Development/HIP/experiments/daniel-kernels/family-budgets.py
