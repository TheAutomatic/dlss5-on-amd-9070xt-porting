import argparse,csv,json,re,hashlib
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('lab',type=Path);p.add_argument('output',type=Path);a=p.parse_args();rows=[];raw={};large={}
for d in sorted(x for x in a.lab.iterdir() if x.is_dir() and re.match(r'^(1088|1152)-\d\d-',x.name)):
    ph,slot,kind=d.name.split('-');ph=int(ph);t=(d/'stdout.log').read_text(encoding='utf-8-sig');row={'slot':d.name,'kind':kind,'comparison_proc_h':ph,'mochi_proc_h':1088,'tokens_both':640}
    if kind=='M':
        m=re.search(r'measurement wall ([0-9.]+) ms, GPU total ([0-9.]+) ms over (\d+) frames',t);cpu,gpu,n=float(m[1]),float(m[2]),int(m[3]);row.update(frames=n,gpu_mean_ms=gpu/n,cpu_mean_ms=cpu/n);f=d/'final.rgba32f';v=np.fromfile(f,dtype='<f4').reshape(1080,1920,4);row.update(nonfinite=int(np.count_nonzero(~np.isfinite(v))),alpha_all_one=bool((v[:,:,3]==1).all()));raw[d.name]=hashlib.sha256(f.read_bytes()).hexdigest()
    else:
        s=list(csv.DictReader((d/'timing.csv').open()));g=np.array([float(x['gpu_ms']) for x in s]);c=np.array([float(x['cpu_ms']) for x in s]);assert (g>0).all() and np.isfinite(g).all();row.update(frames=len(s),gpu_mean_ms=float(g.mean()),gpu_p99_ms=float(np.quantile(g,.99)),cpu_mean_ms=float(c.mean()),first5_gpu_mean_ms=float(g[:5].mean()));first=(d/'first.rgb32f').read_bytes();last=(d/'last.rgb32f').read_bytes();v=np.frombuffer(last,dtype='<f4').reshape(ph,1920,3);row.update(repeat_bitdiff=int(np.count_nonzero(np.frombuffer(first,dtype='<u4')!=np.frombuffer(last,dtype='<u4'))),nonfinite=int(np.count_nonzero(~np.isfinite(v))));raw[d.name]=hashlib.sha256(last).hexdigest()
    assert row['frames']==160 and row['nonfinite']==0
    for f in d.glob('*.rgb*'):large[str(f.relative_to(a.lab))]={'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
    rows.append(row)
assert len(rows)==16;groups={}
for ph in [1088,1152]:
    rr=[x for x in rows if x['comparison_proc_h']==ph]
    for fast,ss in [('FAST1',rr[:4]),('FAST0',rr[4:])]:
        ours=[x for x in ss if x['kind']!='M'];m=[x for x in ss if x['kind']=='M'];ga=np.mean([x['gpu_mean_ms'] for x in ours]);gb=np.mean([x['gpu_mean_ms'] for x in m]);groups[f'{ph}-{fast}']={'ours_gpu_mean_ms':float(ga),'mochi_gpu_mean_ms':float(gb),'gap_ms':float(ga-gb),'ours_cpu_mean_ms':float(np.mean([x['cpu_mean_ms'] for x in ours])),'mochi_cpu_mean_ms':float(np.mean([x['cpu_mean_ms'] for x in m])),'same_raster':ph==1088,'same_ViT_tokens':True}
assert len({raw[x['slot']] for x in rows if x['kind']=='M'})==1
assert all(x.get('repeat_bitdiff',0)==0 for x in rows)
a.output.write_text(json.dumps({'slots':rows,'groups':groups,'raw_sha':raw,'all_finite':True,'mochi_repeat_exact':True,'large_raw':large},indent=2));print(json.dumps(groups,indent=2))
