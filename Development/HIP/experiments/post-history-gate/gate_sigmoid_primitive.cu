// NVIDIA scalar primitive oracle only. This is NOT the original whole post kernel.
// Its sequence matches original post SASS cd20/cd80/cdd0/cde0.
extern "C" __global__ void original_gate_sigmoid(float* out) {
 unsigned i=blockIdx.x*blockDim.x+threadIdx.x;if(i>=65536)return;
 unsigned short h=static_cast<unsigned short>(i);float x,t,e,d,s;
 asm volatile("cvt.f32.f16 %0, %1;" : "=f"(x) : "h"(h));
 asm volatile("mul.ftz.f32 %0, %1, 0fBFB8AA3B;" : "=f"(t) : "f"(x));
 asm volatile("ex2.approx.ftz.f32 %0, %1;" : "=f"(e) : "f"(t));
 asm volatile("add.ftz.f32 %0, %1, 0f3F800000;" : "=f"(d) : "f"(e));
 asm volatile("rcp.approx.ftz.f32 %0, %1;" : "=f"(s) : "f"(d));
 out[i]=s;
}
