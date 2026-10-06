"""CPU model of candidate.patch logical batches; no GPU-completion claim."""
import json
MAX=(1<<64)-1
SMALL=8*1024*1024
class Block:
    def __init__(self,capacity=SMALL,refs=1,pooled=True):
        self.capacity,self.refs,self.pooled,self.stamp=capacity,refs,pooled,0
class Policy:
    def __init__(self,graph=False,batch=0):
        self.graph,self.batch,self.disabled=graph,batch,False
    def P(self,t):
        if t.pooled and not self.graph and not self.disabled:
            t.stamp=min(self.batch+1,MAX)
    def advance(self,physical_launches=1):
        assert physical_launches>0
        if not self.graph and not self.disabled:
            if self.batch==MAX:self.disabled=True
            else:self.batch+=1
    def eligible(self,t,requested):
        if t.refs!=1 or t.capacity<requested:return False
        cold=(not self.graph and not self.disabled and requested<=SMALL
              and t.stamp!=0 and t.stamp>=self.batch)
        return not cold
results={}
def passed(name):results[name]='PASS'
p=Policy();t=Block()
assert p.eligible(t,SMALL);passed('never_used_stamp_zero')
p.P(t);p.advance(2)
assert p.batch==1 and t.stamp==1 and not p.eligible(t,SMALL)
p.advance();assert p.eligible(t,SMALL)
passed('two_physical_launches_one_batch_then_one_intervening_batch')
p=Policy();t=Block();p.P(t)
assert p.batch==0 and t.stamp==1 and not p.eligible(t,SMALL)
p.advance();assert not p.eligible(t,SMALL)
p.advance();assert p.eligible(t,SMALL)
passed('nonlaunch_P_conservatively_overdelays')
p=Policy();t=Block(refs=2)
assert not p.eligible(t,SMALL)
t.refs=3;assert not p.eligible(t,SMALL)
t.refs=1;assert p.eligible(t,SMALL)
passed('shared_refs_and_PDL_refs_preserved')
p=Policy(graph=True,batch=9);t=Block();t.stamp=MAX
p.P(t);p.advance(3)
assert t.stamp==MAX and p.batch==9 and p.eligible(t,SMALL)
passed('graph_bypasses_stamping_counter_and_cold_filter')
p=Policy();t=Block(capacity=64*1024*1024);p.P(t);p.advance()
assert not p.eligible(t,SMALL)
assert p.eligible(t,SMALL+4)
passed('recent_large_capacity_rejected_for_small_request_only')
p=Policy(batch=MAX-1);t=Block();p.P(t);p.advance()
assert p.batch==MAX and not p.disabled and not p.eligible(t,SMALL)
p.P(t);assert t.stamp==MAX
p.advance();assert p.disabled and p.batch==MAX and p.eligible(t,SMALL)
passed('uint64_saturates_then_next_advance_disables_without_wrap')
report={'scope':'allocation-selection CPU semantics only; not GPU lifetime/completion proof',
        'candidate_patch':'/tmp/297-vit-contract-host/Development/HIP/experiments/pool-coldage-20261006/candidate.patch',
        'passed':len(results),'cases':results}
with open('/tmp/cold-policy-model.json','w')as f:json.dump(report,f,indent=2);f.write('\n')
print(json.dumps(report,indent=2))
