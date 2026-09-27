import re
# Natural loops on actual assembly CFG, including unnamed fall-through blocks.
def analyze(lines):
 labels={m[1]:i for i,l in enumerate(lines) if (m:=re.match(r'(\.LBB\w+):',l))};leaders={0,*labels.values()};branches={}
 for i,l in enumerate(lines):
  if m:=re.search(r'\b(s_(?:cbranch_\w+|branch)) (\.LBB\w+)',l):branches[i]=(m[1],labels[m[2]],None);leaders.add(i+1)
  elif re.search(r'\bs_endpgm\b',l):branches[i]=('end',None,None);leaders.add(i+1)
 starts=sorted(x for x in leaders if x<len(lines));ends=starts[1:]+[len(lines)];at={i:j for j,(a,b) in enumerate(zip(starts,ends)) for i in range(a,b)}
 edges={j:set() for j in range(len(starts))}
 for j,(a,b) in enumerate(zip(starts,ends)):
  last=branches.get(b-1)
  if last and last[1] is not None and last[2] is not False:edges[j].add(at[last[1]])
  if (not last or (last[0].startswith('s_cbranch') and last[2] is not True)) and j+1<len(starts):edges[j].add(j+1)
 reachable={0};todo=[0]
 while todo:
  for v in edges[todo.pop()]:
   if v not in reachable:reachable.add(v);todo.append(v)
 pred={j:set() for j in reachable}
 for j in reachable:
  for v in edges[j]:pred[v].add(j)
 dom={j:({0} if j==0 else reachable.copy()) for j in reachable}
 while True:
  changed=False
  for j in sorted(reachable-{0}):
   v={j}|set.intersection(*(dom[p] for p in pred[j]));changed|=v!=dom[j];dom[j]=v
  if not changed:break
 found={}
 for j in reachable:
  for h in edges[j]:
   if h in dom[j]:
    nodes={h,j};todo=[] if j==h else [j]
    while todo:
     for v in pred[todo.pop()]:
      if v not in nodes:nodes.add(v);todo.append(v)
    found.setdefault(h,set()).update(nodes)
 return [{'header':starts[h],'ranges':[(starts[j],ends[j]) for j in sorted(ns)],'lines':set(i for j in ns for i in range(starts[j],ends[j]))} for h,ns in sorted(found.items())],set(i for j in reachable for i in range(starts[j],ends[j]))
def loops(lines):return analyze(lines)[0]
