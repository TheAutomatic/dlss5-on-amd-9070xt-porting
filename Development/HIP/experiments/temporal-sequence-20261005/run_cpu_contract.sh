#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
probe_dir="$(mktemp -d /tmp/dlss5-temporal-contract.XXXXXX)"
trap 'rm -rf -- "$probe_dir"' EXIT
g++ -std=c++17 -Wall -Wextra -Werror "$script_dir/history_state_probe.cpp" -o "$probe_dir/state-probe"
"$probe_dir/state-probe"
python3 "$script_dir/check_real_manifest.py"
python3 "$script_dir/check_converted.py"
