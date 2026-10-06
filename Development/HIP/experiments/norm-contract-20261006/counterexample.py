"""Mathematical counterexample, not hardware WMMA golden ordering."""
import numpy as np,json
q=np.full(32,50,dtype=np.float32)
with np.errstate(over='ignore'):
 square=(q*q).astype(np.float16);current_sum=np.float32(square.astype(np.float32).sum())
 partial=np.float32((q[:16]*q[:16]).sum()).astype(np.float16)
 mochi_sum=np.float16(partial+partial)
print(json.dumps({'rawQ':[50]*32,'current_half_squares_f32sum':float(current_sum),'M_half_local_sum':float(partial),'M_half_cross_sum':str(mochi_sum),'current_rsqrt_nonzero':True,'M_rsqrt_zero':True,'scope':'positive equal terms total80000 exactly representable f32; no WMMA tree assumption needed for this equal-value example; mathematical domain counterexample not observed network input'}))
