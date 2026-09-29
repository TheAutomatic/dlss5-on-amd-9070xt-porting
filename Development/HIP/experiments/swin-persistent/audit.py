#!/usr/bin/env python3
"""Audit archived hashes/AE decisions, injected faults and raw ABBA CSVs."""
import argparse, csv, json, re, subprocess, sys
from pathlib import Path

p = argparse.ArgumentParser(__doc__)
p.add_argument('collected', type=Path)
p.add_argument('out', type=Path)
a = p.parse_args()
a.out.mkdir(parents=True, exist_ok=True)
repo = Path(__file__).resolve().parents[4]
rows = list(csv.DictReader((a.collected / 'hashes.csv').open(encoding='utf-8-sig')))
for version in ('P', 'Q'):
    selected = [r for r in rows if r['batch'] in
                (f'runtime-regression-{version}-correct', f'runtime-regression-{version}-adaptive')]
    with (a.collected / f'hashes-{version}.csv').open('w') as f:
        w = csv.DictWriter(f, fieldnames=rows[0], lineterminator="\n"); w.writeheader(); w.writerows(selected)
    subprocess.run([sys.executable, str(repo / 'Development/tools/compiler-versions/analyze-results.py'),
                    '--version', version, '--collected', str(a.collected), '--out', str(a.out)], check=True)
    validation = json.loads((a.out / f'validation-{version}.json').read_text())
    assert validation['pass'], validation

def readlog(path):
    b = path.read_bytes()
    return b.decode('utf-16' if b[:2] in (b'\xff\xfe', b'\xfe\xff') else 'utf-8-sig')

pressure = []
for batch in sorted({r['batch'] for r in rows if re.search(r'-P-(roll|timeout)', r['batch'])}):
    selected = [r for r in rows if r['batch'] == batch]
    lookup = {(r['slot'], r['frame']): r['sha'] for r in selected}
    for slot in sorted({r['slot'] for r in selected if r['slot'].endswith('-True')}):
        baseline = slot[:-4] + 'False'
        frames = [r for r in selected if r['slot'] == slot]
        assert len(frames) == 12
        assert all(r['sha'] == lookup[baseline, r['frame']] for r in frames)
        root = a.collected / batch
        data = list(csv.DictReader((root / slot / 'rgb.csv').open()))
        assert len(data) == 12 and all(r['checked'] == '1' and int(r['invalid']) == 0 for r in data)
        ae = 0
        if batch.endswith('-1'):
            b = list(csv.reader((root / baseline / 'adaptive.csv').open()))
            c = list(csv.reader((root / slot / 'adaptive.csv').open()))
            assert b == c and len(c) == 12
            ae = len(c)
        stats = re.search(r'SP_STATS (.*)', readlog(root / slot / 'run.log'))
        assert stats
        stats = {k: int(v) for k, v in re.findall(r'(\w+)=(\d+)', stats[1])}
        if '-roll-' in batch:
            assert stats['rollover'] > 0 and stats['fallback'] == stats['errors'] == stats['disabled'] == 0
        else:
            assert stats['fallback'] == stats['errors'] == stats['disabled'] == 1
        pressure.append(dict(batch=batch, slot=slot, exact_frames=12, ae_rows=ae, **stats))
assert sum(r['exact_frames'] for r in pressure) == 144
(a.out / 'pressure.json').write_text(json.dumps(pressure, indent=2) + '\n')
for batch in ('off', 'missing'):
    rr = [r for r in rows if r['batch'] == f'runtime-regression-Q-{batch}']
    assert len(rr) == 24
    assert {r['frame']: r['sha'] for r in rr if r['slot'].endswith('-True')} == {
        r['frame']: r['sha'] for r in rr if r['slot'].endswith('-False')}
print('PASS: P/Q golden + AE, 144 pressure frames, disabled and missing-module paths')
