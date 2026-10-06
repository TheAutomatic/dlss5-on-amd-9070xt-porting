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
#include <mma.h>
#include <cuda_fp16.h>
// Native HMMA.F16 primitive oracle. Same two K16 chunks as the original
// head SASS; weights duplicated over unused output columns. Not a whole-model oracle.
extern "C" __global__ void original_gate_head_hw(const half*features,const half*weight,half*out,unsigned n){
 using namespace nvcuda;unsigned tile=blockIdx.x,tid=threadIdx.x;if(tile*16>=n)return;
 __shared__ __align__(32) half b[256];__shared__ __align__(32) half c[256];
 wmma::fragment<wmma::matrix_a,16,16,16,half,wmma::row_major>a;
 wmma::fragment<wmma::matrix_b,16,16,16,half,wmma::col_major>bf;
 wmma::fragment<wmma::accumulator,16,16,16,half>acc;
 wmma::fill_fragment(acc,__float2half(0.f));
 for(unsigned k=0;k<2;k++){
  for(unsigned i=tid;i<256;i+=32)b[i]=weight[k*16+i%16];__syncwarp();
  wmma::load_matrix_sync(a,features+tile*16*32+k*16,32);
  wmma::load_matrix_sync(bf,b,16);wmma::mma_sync(acc,a,bf,acc);__syncwarp();
 }
 wmma::store_matrix_sync(c,acc,16,wmma::mem_row_major);__syncwarp();
 if(tid<16)out[tile*16+tid]=c[tid*16];
}
