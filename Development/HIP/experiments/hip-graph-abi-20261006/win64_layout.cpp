#include "official_abi_excerpt.h"
using namespace hip_graph_abi_702;
static_assert(sizeof(void*)==8,"Win64");
static_assert(sizeof(dim3)==12 && alignof(dim3)==4,"dim3");
static_assert(offsetof(hipKernelNodeParams,blockDim)==0,"block");
static_assert(offsetof(hipKernelNodeParams,extra)==16,"extra");
static_assert(offsetof(hipKernelNodeParams,func)==24,"func");
static_assert(offsetof(hipKernelNodeParams,gridDim)==32,"grid");
static_assert(offsetof(hipKernelNodeParams,kernelParams)==48,"params");
static_assert(offsetof(hipKernelNodeParams,sharedMemBytes)==56,"shared");
static_assert(sizeof(hipKernelNodeParams)==64 && alignof(hipKernelNodeParams)==8,"layout");
static_assert(sizeof(hipGraphNodeType)==4,"enumABI");
int main(){return 0;}
