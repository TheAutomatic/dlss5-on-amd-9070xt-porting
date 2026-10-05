"""Pair raw-output fidelity with actual whole-network TimingOnlyABBA; no micro-to-network addition."""
import argparse,csv,json
from pathlib import Path
import numpy as np
p=argparse.ArgumentParser();p.add_argument('root',type=Path);a=p.parse_args();results={}
for shape in ('900','1088','1152'):
    runs=[]
    for slot in range(4):
        d=a.root/f'{shape}-{slot}'
        if not (d/'timing.csv').exists():break
        rows=list(csv.DictReader((d/'timing.csv').open()));gpu=np.array([float(r['gpu_ms']) for r in rows]);runs.append({'slot':slot,'mean_ms':float(gpu.mean()),'p99_ms':float(np.percentile(gpu,99)),'frames':len(gpu)})
    if len(runs)==4:
        base=np.r_[np.loadtxt(a.root/f'{shape}-0/timing.csv',delimiter=',',skiprows=1)[:,1],np.loadtxt(a.root/f'{shape}-3/timing.csv',delimiter=',',skiprows=1)[:,1]]
        cand=np.r_[np.loadtxt(a.root/f'{shape}-1/timing.csv',delimiter=',',skiprows=1)[:,1],np.loadtxt(a.root/f'{shape}-2/timing.csv',delimiter=',',skiprows=1)[:,1]]
        x=np.fromfile(a.root/f'{shape}-0/last.rgb32f','<f4').astype(np.float64);y=np.fromfile(a.root/f'{shape}-1/last.rgb32f','<f4').astype(np.float64);mse=np.mean((x-y)**2)
        results[shape]={'slots':runs,'avg_delta_ms':float(cand.mean()-base.mean()),'p99_delta_ms':float(np.percentile(cand,99)-np.percentile(base,99)),'B_slots_each_faster_than_both_A':bool(max(runs[1]['mean_ms'],runs[2]['mean_ms'])<min(runs[0]['mean_ms'],runs[3]['mean_ms'])),'fidelity_vs_current_A':{'peak1_psnr_db':float(-10*np.log10(mse)) if mse else 'inf','maxabs':float(np.max(abs(x-y))),'finite':bool(np.isfinite(y).all())},'scope':'actualfull71 sameinput/nohistory; relative currentA not NVIDIA oracle'}
print(json.dumps(results,indent=2));(a.root/'summary.json').write_text(json.dumps(results,indent=2)+'\n')
