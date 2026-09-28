#!/usr/bin/env python3
"""Check seven EXACT and seven AE 12-frame cases against the approved 09-28 float-FMA baseline."""
import argparse,csv
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('collected_hashes',type=Path);p.add_argument('--set',default='P');p.add_argument('--baseline',type=Path,default=Path(__file__).resolve().parents[3]/'results/float-fma-20260928/new-baseline-hashes.csv');a=p.parse_args()
expected={(x['mode'],x['case'],x['frame']):x['sha'] for x in csv.DictReader(a.baseline.open(encoding='utf-8-sig'))}
actual={}
for x in csv.DictReader(a.collected_hashes.open(encoding='utf-8-sig')):
 if x['batch'] not in (f'runtime-regression-{a.set}-correct',f'runtime-regression-{a.set}-adaptive') or not x['slot'].endswith('-True'):continue
 mode='AE' if x['batch'].endswith('-adaptive') else 'EXACT';actual[mode,x['slot'][:-5],x['frame']]=x['sha']
assert len(expected)==168,len(expected)
assert expected.keys()==actual.keys(),f'Coverage mismatch: missing {len(expected.keys()-actual.keys())}, extra {len(actual.keys()-expected.keys())}'
bad=[k for k in expected if expected[k]!=actual[k]]
if bad:raise SystemExit(f'FAIL {len(bad)} changed frames; first {bad[:4]}')
print('PASS: 168 EXACT/AE frame hashes match the 2026-09-28 float-FMA baseline')
