#!/usr/bin/env bash
# Extracts the PRE_UPSCALE=auto decision block (RequestedMode / AutoDecision / Mode / AutoDecide / Enabled)
# from src/native_pre_upscale.h verbatim, so the unit test compiles the production code text, not a copy.
# usage: bash extract-auto-block.sh PATH_TO_native_pre_upscale.h OUT.inc
set -euo pipefail
src=$1; out=$2
start=$(grep -n '/\* DLSS5_PRE_UPSCALE = 1 | 0 | auto' "$src" | head -1 | cut -d: -f1)
end=$(grep -n 'inline bool Enabled(){return Mode()!=0;}' "$src" | head -1 | cut -d: -f1)
[[ -n "$start" && -n "$end" && "$end" -gt "$start" ]] || { echo "auto block boundaries not found in $src" >&2; exit 1; }
for fn in RequestedMode AutoDecision Mode AutoDecide Enabled; do
  sed -n "${start},${end}p" "$src" | grep -q "inline.*${fn}(" || { echo "auto block is missing $fn" >&2; exit 1; }
done
sed -n "${start},${end}p" "$src" > "$out"
echo "extracted lines $start..$end -> $out"
