"""CPU-only receipt analysis; mean-to-mean, do not infer FPS or per-family causes."""
import argparse,csv,json,re,hashlib
from pathlib import Path
import numpy as np
ap=argparse.ArgumentParser();ap.add_argument('lab',type=Path);ap.add_argument('output',type=Path);a=ap.parse_args();rows=[];raw={};large={}
for d in sorted(x for x in a.lab.iterdir() if x.is_dir() and re.match(r'^\d\d-',x.name)):
    text=(d/'stdout.log').read_text(encoding='utf-8-sig');kind=d.name.split('-')[1];row={'slot':d.name,'kind':kind}
    if kind=='M':
        m=re.search(r'measurement wall ([0-9.]+) ms, GPU total ([0-9.]+) ms over (\d+) frames',text)
        if not m:raise ValueError('Missing mochi GPU total')
        cpu,gpu,n=float(m[1]),float(m[2]),int(m[3]);row.update(frames=n,gpu_mean_ms=gpu/n,cpu_mean_ms=cpu/n)
        f=d/'final.rgba32f';v=np.fromfile(f,dtype='<f4').reshape(900,1600,4);row.update(nonfinite=int(np.count_nonzero(~np.isfinite(v))),alpha_all_one=bool((v[:,:,3]==1).all()));raw[d.name]=hashlib.sha256(f.read_bytes()).hexdigest()
    else:
        samples=list(csv.DictReader((d/'timing.csv').open(encoding='utf-8-sig')));gpu=np.array([float(s['gpu_ms']) for s in samples]);cpu=np.array([float(s['cpu_ms']) for s in samples]);assert (gpu>0).all() and np.isfinite(gpu).all()
        row.update(frames=len(samples),gpu_mean_ms=float(gpu.mean()),gpu_median_ms=float(np.median(gpu)),gpu_p99_ms=float(np.quantile(gpu,.99)),cpu_mean_ms=float(cpu.mean()))
        first=(d/'first.rgb32f').read_bytes();last=(d/'last.rgb32f').read_bytes();v=np.frombuffer(last,dtype='<f4').reshape(960,1600,3);row.update(repeat_bitdiff=int(np.count_nonzero(np.frombuffer(first,dtype='<u4')!=np.frombuffer(last,dtype='<u4'))),nonfinite=int(np.count_nonzero(~np.isfinite(v))));raw[d.name]=hashlib.sha256(last).hexdigest()
    assert row['frames']==160 and row['nonfinite']==0
    for f in d.glob('*.rgb*'):large[str(f.relative_to(a.lab))]={'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
    rows.append(row)
assert len(rows)==8
groups={}
for fast,slots in [('FAST0',rows[:4]),('FAST1',rows[4:])]:
    ours=[x for x in slots if x['kind']!='M'];mz=[x for x in slots if x['kind']=='M'];av=sum(x['gpu_mean_ms'] for x in ours)/2;bv=sum(x['gpu_mean_ms'] for x in mz)/2
    groups[fast]={'ours_gpu_mean_ms':av,'mochi_gpu_mean_ms':bv,'gap_ms':av-bv,'mochi_faster_fraction_of_ours':(av-bv)/av,'ours_cpu_mean_ms':sum(x['cpu_mean_ms'] for x in ours)/2,'mochi_cpu_mean_ms':sum(x['cpu_mean_ms'] for x in mz)/2}
report={'slots':rows,'groups':groups,'raw_sha':raw,'all_finite':True,'mochi_raw_repeated_exact':len(set(raw[x['slot']] for x in rows if x['kind']=='M'))==1,'large_raw':large}
assert report['mochi_raw_repeated_exact'] and all(x.get('repeat_bitdiff',0)==0 for x in rows)
a.output.write_text(json.dumps(report,indent=2));print(json.dumps(groups,indent=2))
