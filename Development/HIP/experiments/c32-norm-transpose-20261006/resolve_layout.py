"""Resolve existing fixture against independent exact dot and dyadic square sums; no GPU."""
from pathlib import Path
import numpy as np,json,argparse
p=argparse.ArgumentParser();p.add_argument('data',type=Path);a=p.parse_args()
old=np.fromfile(a.data/'fixture1-0.u32','<f4').reshape(6,16,32);trial=np.fromfile(a.data/'fixture1-1.u32','<f4').reshape(6,16,32)
# Old trace falsely treated C-element as token; undo independently per ci tile.
transpose=lambda x:np.c_[x[:,:16].T,x[:,16:].T]
q=transpose(old[0]);sq=transpose(old[1]);ss=transpose(old[2]);
# Fixture arrays reproduce immutable gold_probe.cpp in/w construction; FP8 bytes32/160 are +/-1/8.
x=np.array([-.125 if i%3==0 else .125 for i in range(512)],dtype=np.float64).reshape(16,32)
w=np.array([-.125 if i%5==0 else .125 for i in range(1024)],dtype=np.float64).reshape(32,32)
dot=x@w.T;units=sq.astype(np.float64)*1024
assert np.array_equal(q,dot)
assert np.all(units==np.rint(units))
exact=units.sum(1).astype(np.int64)/1024
expected=np.repeat(exact[:,None],32,axis=1)
assert np.array_equal(ss,expected)
assert np.all(ss==ss[:,0,None])
j={'raw_independent_exactdot_diff':int(np.count_nonzero(q!=dot)),'square_integer_units_denominator':1024,'row_sum_integer_units':[int(z) for z in units.sum(1)],'sum_exact_diff':int(np.count_nonzero(ss!=expected)),'same_lane_all8_C_elements_sum_identical':True,'correct_A_C_layout':'token=lane%16, feature=ci*16+(lane/16)*8+element','previous_trace_axes':'token=(lane/16)*8+element, feature=ci*16+lane%16; wrong, undo each16tiletranspose','scope':'immutable captured signedfinitefixture, exact multiples1/1024; not allinputhardwaregold nor orderingproof for unequal wideexponent inputs'}
print(json.dumps(j,indent=2))
