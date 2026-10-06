/*
Copyright (c) 2015 - 2023 Advanced Micro Devices, Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#pragma once
#include <cstdint>
#include <cstddef>
// Structural excerpt from ROCm/hip rocm-7.0.2; scoped to avoid existing ABI names.
namespace hip_graph_abi_702 {
struct dim3 {uint32_t x,y,z;};
typedef enum hipGraphNodeType {
  hipGraphNodeTypeKernel = 0,             ///< GPU kernel node
  hipGraphNodeTypeMemcpy = 1,             ///< Memcpy node
  hipGraphNodeTypeMemset = 2,             ///< Memset node
  hipGraphNodeTypeHost = 3,               ///< Host (executable) node
  hipGraphNodeTypeGraph = 4,              ///< Node which executes an embedded graph
  hipGraphNodeTypeEmpty = 5,              ///< Empty (no-op) node
  hipGraphNodeTypeWaitEvent = 6,          ///< External event wait node
  hipGraphNodeTypeEventRecord = 7,        ///< External event record node
  hipGraphNodeTypeExtSemaphoreSignal = 8, ///< External Semaphore signal node
  hipGraphNodeTypeExtSemaphoreWait = 9,   ///< External Semaphore wait node
  hipGraphNodeTypeMemAlloc = 10,          ///< Memory alloc node
  hipGraphNodeTypeMemFree = 11,           ///< Memory free node
  hipGraphNodeTypeMemcpyFromSymbol = 12,  ///< MemcpyFromSymbol node
  hipGraphNodeTypeMemcpyToSymbol = 13,    ///< MemcpyToSymbol node
  hipGraphNodeTypeBatchMemOp = 14,        ///< BatchMemOp node
  hipGraphNodeTypeCount
} hipGraphNodeType;
typedef struct hipKernelNodeParams {
  dim3 blockDim;
  void** extra;
  void* func;
  dim3 gridDim;
  void** kernelParams;
  unsigned int sharedMemBytes;
} hipKernelNodeParams;
typedef enum hipStreamCaptureMode {
  hipStreamCaptureModeGlobal = 0,
  hipStreamCaptureModeThreadLocal,
  hipStreamCaptureModeRelaxed
} hipStreamCaptureMode;
typedef enum hipStreamCaptureStatus {
  hipStreamCaptureStatusNone = 0,    ///< Stream is not capturing
  hipStreamCaptureStatusActive,      ///< Stream is actively capturing
  hipStreamCaptureStatusInvalidated  ///< Stream is part of a capture sequence that has been
                                     ///< invalidated, but not terminated
} hipStreamCaptureStatus;
using GetKernelParams=int(*)(void*,hipKernelNodeParams*);
using GetNodeType=int(*)(void*,hipGraphNodeType*);
using GetNodes=int(*)(void*,void**,size_t*);
using IsCapturing=int(*)(void*,hipStreamCaptureStatus*);
using EndCapture=int(*)(void*,void**);
}
