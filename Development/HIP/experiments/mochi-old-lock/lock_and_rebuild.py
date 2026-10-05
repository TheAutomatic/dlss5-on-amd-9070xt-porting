#!/usr/bin/env python3
"""CPU-only old-asset fingerprint and isolated shader replay; never runs nr_graph.exe."""
import argparse, hashlib, importlib.util, json, os, subprocess, sys
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
sys.dont_write_bytecode=True
ap=argparse.ArgumentParser();ap.add_argument('source',type=Path);ap.add_argument('assets',type=Path);ap.add_argument('output',type=Path);ap.add_argument('--rebuild',action='store_true');a=ap.parse_args();a.output.mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
commit=subprocess.check_output(['git','-C',str(a.source),'rev-parse','HEAD'],text=True).strip()
if commit!='d1185d25141b1714d7837151b6fa782e6427568b':raise SystemExit('Refuse a different source revision')
if subprocess.check_output(['git','-C',str(a.source),'status','--short','--untracked-files=no'],text=True).strip():raise SystemExit('Tracked source is dirty')
manifest={str(p.relative_to(a.assets)):{'bytes':p.stat().st_size,'sha256':sha(p)} for p in a.assets.rglob('*') if p.is_file()}
(a.output/'local-manifest.json').write_text(json.dumps({'source_commit':commit,'assets_root':str(a.assets),'files':manifest},indent=2))
if a.rebuild:
    # Load the pinned builder without putting Python cache in the old source tree.
    spec=importlib.util.spec_from_file_location('pinned_network_builder',a.source/'windows/build/build_network.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
    os.environ['NR_Q32_DIRECT']='1';m.QUAD=True
    table=json.loads((a.source/'windows/shaders/rdna4/pipelines.json').read_text());out=a.output/'rebuilt-spv';out.mkdir(exist_ok=True)
    def one(item):
        name,e=item;p=out/f'g_{name}.spv';m.glslang('rdna4',a.source/'windows/shaders/rdna4'/e['source'],e['defines'],p,unroll=e['source']=='fswin_t.comp',network=True)
        old=a.assets/'spv'/p.name
        return {'pipeline':name,'rebuild_sha256':sha(p),'old_sha256':sha(old),'equal':sha(p)==sha(old)}
    with ThreadPoolExecutor(max_workers=4) as pool:checks=list(pool.map(one,table['pipelines'].items()))
    report={'source_commit':commit,'NR_Q32_DIRECT':'1','QUAD':True,'checks':checks,'all_equal':all(x['equal'] for x in checks)}
    (a.output/'network-rebuild-check.json').write_text(json.dumps(report,indent=2))
    if not report['all_equal']:raise SystemExit('Some SPV differ; do not call the recipe verified')
print('CPU_OLD_LOCK_PASS; no GPU submissions, old files unchanged')
