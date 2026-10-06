#!/usr/bin/env python3
"""Stage historical exact sampler and fixtures, without running any GPU work."""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args()
r=Path(__file__).resolve().parents[4];out=a.output;out.mkdir(parents=True,exist_ok=True);(out/'shaders').mkdir(exist_ok=True)
manifest={}
for name,sha in [('native_temporal_sample.hlsl','aa497e2259cc252159b9438d0f8dd83e4dc0e23aab111b2ecb3b101fd3991d45'),('native_temporal_coordinates.hlsl','c3b9cd8bd59e65b5ad1b876422659f9c681cf352e43977b2653270bdf85cf035')]:
 b=subprocess.check_output(['git','show','450d63b:'+name],cwd=r);assert hashlib.sha256(b).hexdigest()==sha;(out/'shaders'/name).write_bytes(b);manifest['shaders/'+name]=sha
for dst,src in [('input.f32','native-temporal-valid1080/input.f32'),('history.f32','native-temporal-valid1080/history.f32'),('motion.f32','native-temporal-valid1080/motion.f32'),('normalized-output.f32','native-reciprocal/normalized-output.f32')]:
 shutil.copyfile(r/'release'/src,out/dst);manifest[dst]=hashlib.sha256((out/dst).read_bytes()).hexdigest()
(out/'fixture-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
