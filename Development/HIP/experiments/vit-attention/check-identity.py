#!/usr/bin/env python3
import argparse,importlib.util,json,subprocess
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('artifacts',type=Path);p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];sp=importlib.util.spec_from_file_location('elf',r/'Development/tools/llvm-fork/compare-kernels.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
changed={'vit_attention_fused_400_bytein_bout','vit_attention_fused_640_bytein_bout'};result={};probe={}
for arch in ['gfx1200','gfx1201']:
 b,bk,bf=m.elf(a.artifacts/'baseline'/arch/'deep_fast-packed.hsaco')
 o,ok,of=m.elf(a.artifacts/'production/production-0'/arch/'deep_fast-packed.hsaco')
 c,ck,cf=m.elf(a.artifacts/'production/production-1'/arch/'deep_fast-packed.hsaco')
 same={x:b[x]==o[x] for x in ['.text','.note','.rodata']};assert all(same.values())
 assert set(bf)==set(cf) and {n for n in bf if bf[n][2]!=cf[n][2]}==changed
 assert all(bk[n]==ck[n] for n in bk if n not in changed)
 result[arch]=dict(off_sections_same=same,changed_functions=sorted(changed),other_functions_same=len(bf)-2,other_metadata_same=True,candidate_metadata={n:ck[n] for n in sorted(changed)})
 _,pk,pf=m.elf(a.artifacts/'probe-final'/arch/'probe.hsaco')
 probe[arch]={}
 for n in sorted(changed):
  samecode=pf['vit_probe_pair_transpose'][2]==cf[n][2]
  fields=lambda k:{x:v for x,v in k.items() if x not in ['.name','.symbol']}
  samemeta=fields(pk['vit_probe_pair_transpose'])==fields(ck[n]);assert samecode and samemeta
  probe[arch][n]=dict(same_code=samecode,bytes=len(cf[n][2]),same_metadata=samemeta)
(a.out/'production-identity.json').write_text(json.dumps(result,indent=2)+'\n')
(a.out/'probe-production-identity.json').write_text(json.dumps(probe,indent=2)+'\n')
snapshot=json.loads((a.artifacts/'collected-final/snapshot.json').read_text(encoding='utf-8-sig'))
manifest={x.split()[1]:x.split()[0] for x in subprocess.check_output(['git','show','629b0555:hip/SHA256SUMS'],cwd=r,text=True).splitlines()}
modules=[x for x in snapshot if x.get('arch')];assert len(modules)==62
for x in modules:assert x['sha256'].lower()==manifest[x['arch']+'/'+x['name']]
print('PASS: 62 baseline hashes, default-off identity, only 2 exports changed, probe == production')
