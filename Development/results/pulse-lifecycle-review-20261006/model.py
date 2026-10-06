"""CPU control model only; does not call HIP or prove runtime stress behavior."""
import json
from pathlib import Path
class Pulse:
 def __init__(self, failures=()):
  self.failures=set(failures); self.handles=[]; self.active=False; self.pending=False; self.log=[]; self.old_work=0
 def call(self,name):
  self.log.append(name); return name not in self.failures
 def create(self):
  if not self.call('select_device') or not self.call('export'):return
  for n in ('create0','create1'):
   if not self.call(n):self.close();return
   self.handles.append(n)
  self.active=True
 def frame(self):
  # Caller device-selection failure remains a preexisting fatal NN error.
  if self.active:
   for n in ('record0','record1'):
    if not self.call(n):self.active=False;break
    self.pending=True
  self.old_work+=1 # A successful first marker does not require undoing NN work.
 def close(self):
  self.active=False
  if not self.handles:return
  if not self.call('select_cleanup_device'):return
  if self.pending and not self.call('drain'):return # retain, do not destroy in-flight handles
  for h in list(self.handles):
   if self.call('destroy_'+h):self.handles.remove(h)
rows=[]
for fail in ((),('export',),('create0',),('create1',),('record0',),('record1',),('drain',),('select_cleanup_device',),('destroy_create0',)):
 p=Pulse(fail);p.create();p.frame();p.frame();p.close()
 assert p.old_work==2
 if 'drain' in fail or 'select_cleanup_device' in fail:assert p.handles
 elif 'destroy_create0' in fail:assert p.handles==['create0']
 else:assert not p.handles
 if 'record0' in fail:assert p.log.count('record0')==1 and 'record1' not in p.log
 if 'record1' in fail:assert p.log.count('record1')==1
 if 'drain' in p.log:
  assert all(p.log.index('drain')<i for i,n in enumerate(p.log) if n.startswith('destroy_'))
 rows.append({'failures':fail,'calls':p.log,'retained_handles':p.handles,'old_work':p.old_work})
Path(__file__).with_name('model-results.json').write_text(json.dumps({'scope':'CPU proposed optional-pulse control model, not actual HIP implementation','cases':rows},indent=2)+'\n')
print('PASS 9 CPU control cases; no HIP/GPU calls')
