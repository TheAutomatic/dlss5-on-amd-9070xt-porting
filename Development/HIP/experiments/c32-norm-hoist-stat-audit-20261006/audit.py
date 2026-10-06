"""CPU-only original CSV audit; exact decimal p99 endpoints, no new benchmark or acceptance rule."""
from pathlib import Path
from decimal import Decimal,ROUND_FLOOR
import argparse,csv,json,numpy as np,math
p=argparse.ArgumentParser();p.add_argument('root',type=Path);p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
def load(d):
 rows=list(csv.DictReader((d/'frame.csv').open()));return [Decimal(z['wall_ms'])*1000 for z in rows[80:]]
def perc(x,q=Decimal('.99')):
 s=sorted(x);r=(len(s)-1)*q;i=int(r.to_integral_value(rounding=ROUND_FLOOR));w=r-i;j=min(i+1,len(s)-1);v=s[i]+w*(s[j]-s[i]);return {'n':len(s),'fractional_zero_based_rank':str(r),'lower_rank_1based':i+1,'upper_rank_1based':j+1,'lower_us':str(s[i]),'upper_us':str(s[j]),'weight':str(w),'linear_us':str(v),'nearest_rank_us':str(s[math.ceil(float(q)*len(s))-1])}
pooledA=[];pooledH=[];rounds=[]
for round in [1,2,3]:
 d=a.root/f'ABBA-900-round{round}';samples=[load(d/f'slot-{i}') for i in range(4)];ps=[perc(x) for x in samples];A=samples[0]+samples[3];H=samples[1]+samples[2];pa=perc(A);ph=perc(H);pooledA+=A;pooledH+=H
 rounds.append({'round':round,'slot_p99':ps,'A3_minus_A0_p99_us':str(Decimal(ps[3]['linear_us'])-Decimal(ps[0]['linear_us'])),'H2_minus_H1_p99_us':str(Decimal(ps[2]['linear_us'])-Decimal(ps[1]['linear_us'])),'merged_A_p99':pa,'merged_H_p99':ph,'H_minus_A_p99_us':str(Decimal(ph['linear_us'])-Decimal(pa['linear_us'])),'all_CSV_wall_integer_us':all(v==v.to_integral_value() for x in samples for v in x)})
pa=perc(pooledA);ph=perc(pooledH)
# Empirical rank neighborhood is sensitivity, not a replacement gate.
rank_sensitivity={}
for label,x in [('A',pooledA),('H',pooledH)]:
 s=sorted(x);rank_sensitivity[label]={str(q):str(s[q-1]) for q in range(math.ceil(.985*len(s)),min(len(s),math.ceil(.995*len(s)))+1)}
j={'timer_precision_CSV_us':1,'rounds':rounds,'three_rounds_pooled_A':pa,'three_rounds_pooled_H':ph,'pooled_H_minus_A_p99_us':str(Decimal(ph['linear_us'])-Decimal(pa['linear_us'])),'pooled_rank_neighborhood_us':rank_sensitivity,'scope':'same original three rounds only; pooled descriptor not acceptance replacement, no tolerance/no futuretail guarantee'}
(a.out/'audit.json').write_text(json.dumps(j,indent=2)+'\n');print(json.dumps(j,indent=2))
