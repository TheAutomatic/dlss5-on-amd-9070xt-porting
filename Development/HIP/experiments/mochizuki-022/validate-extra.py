from pathlib import Path
import csv,json,re,sys,collections
p=Path(sys.argv[1])
def rows(name):
 b=(p/name).read_bytes();s=b.decode('utf-16') if b[:2]==b'\xff\xfe' else b.decode('utf-8-sig');return list(csv.DictReader(s.splitlines()))
summary=json.loads((p/'summary.json').read_text());assert set(summary)==set('C F G H I O P S V'.split())
standard=sum(sum(v['correctness'].values()) for v in summary.values());decisions=sum(v['adaptive']['matched_decisions'] for v in summary.values());assert (standard,decisions)==(1512,756)
h=rows('frame-hashes.csv');lookup={(r['set_batch'],r['tag'],r['frame']):r['sha256'] for r in h};n=0
for key,sha in lookup.items():
 set_batch,tag,frame=key
 if set_batch.rsplit('-',1)[1] not in ('wrap','wrapae') or not tag.endswith('-True'):continue
 assert lookup[(set_batch,tag.removesuffix('-True')+'-False',frame)]==sha,key;n+=1
assert n==120,n
assert len(h)==2*(standard+n),len(h)
traces=rows('tchain-traces.csv');wraps=[]
for r in traces:
 if not r['case'].endswith('-True'):continue
 m=re.fullmatch(r'TCHAIN c512=(\d+) vit=(\d+) wraps=(\d+)',r['trace']);assert m,r
 c,v,w=map(int,m.groups());assert (c,v)==((156,0) if r['set']=='S' else (0,96)),r
 if r['batch'] in ('wrap','wrapae'):assert w>0;wraps.append(r)
groups=rows('group4-traces.csv')
for r in groups:
 if r['batch'] in ('correct','adaptive') and r['case'].endswith('-True'):assert r['trace']=='WG4 calls=156',r
ids_raw=(p/'installed-identity.json').read_bytes();ids=json.loads(ids_raw.decode('utf-16') if ids_raw[:2]==b'\xff\xfe' else ids_raw.decode('utf-8-sig'));assert all(x['same'] for x in ids)
print(json.dumps({'standard_candidate_frames':standard,'standard_adaptive_decisions':decisions,'extra_stress_candidate_frames':n,'total_candidate_frames':standard+n,'all_frame_hash_rows':len(h),'wrap_traces':wraps,'group4_replaced_per_frame':13,'installed_modules_checked':len(ids),'installed_modules_unchanged':True},indent=2))
