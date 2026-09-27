#!/usr/bin/env bash
set -euo pipefail
ACO_ROOT="${ACO_ROOT:-$HOME/work/aco-isa}"
OUT="${1:-/tmp/c32-aco-20260927/aco}"
mkdir -p "$OUT"
"$ACO_ROOT/run.sh" "$ACO_ROOT/tool/dump_isa" "$OUT" "$ACO_ROOT/spv/g_fswin32.spv" "$ACO_ROOT/spv/g_fswinds32.spv" "$ACO_ROOT/spv/g_fswinimagepreds32.spv" "$ACO_ROOT/spv/g_fswinimagepost32.spv"
