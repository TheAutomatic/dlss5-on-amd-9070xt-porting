#!/usr/bin/env python3
from pathlib import Path
import argparse,json
p=argparse.ArgumentParser();p.add_argument('log',type=Path);p.add_argument('output',type=Path);a=p.parse_args();b=a.log.read_bytes();s=b.decode('utf-16') if b.startswith((b'\xff\xfe',b'\xfe\xff')) else b.decode('utf-8-sig')
jobs=[json.loads(x[4:]) for x in s.splitlines() if x.startswith('JOB ')];assert len(jobs)==169,'Task b99e9ef6 recorder expects169 launches';a.output.write_text(json.dumps(jobs,indent=2)+'\n');print(len(jobs))
