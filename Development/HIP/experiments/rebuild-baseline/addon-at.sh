#!/bin/bash
# addon-at.sh <commit> <outdir> : build dlss5-amd.addon64 (--hip) of <commit> in a scratch worktree (output name matters: .edata embeds it)
set -e; c=$1; out=$2; wt=$out/wt-$c; main=/home/lmxxf/work/ai-theorys-study/wechat/assets/297
mkdir -p $out; [ -d $wt ] || git -C $main worktree add -q --detach $wt $c
cp -r $main/third_party/minhook $main/third_party/reshade $wt/third_party/ 2>/dev/null || { mkdir -p $wt/third_party; cp -r $main/third_party/minhook $main/third_party/reshade $wt/third_party/; }
mkdir -p $out/addon-$c; (cd $out/addon-$c && bash $wt/scripts/build-addon-oneclick.sh dlss5-amd.addon64 --hip >/dev/null 2>&1)
echo "$c $(sha256sum $out/addon-$c/dlss5-amd.addon64 | cut -c1-8)"
