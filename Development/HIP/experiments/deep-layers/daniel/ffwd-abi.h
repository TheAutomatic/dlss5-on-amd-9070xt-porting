#pragma once
#include <cstdint>
#include <cstddef>
// Host 043005..043038; metadata by_value48/alignment8, no implicit arguments.
struct alignas(8) DanielVitFfwdParams {
 const void* input8;       // +0 object270: 4x4-tile FP8 fragments
 const void* external;     // +8 unused in <V,false,false>; nullptr
 void* output8;           // +16 object278
 const void* weights8;     // +24 stage0 packed FP8 weights, actual Daniel format
 int32_t width;            // +32 host ebx
 int32_t height;           // +36 host edi
 int32_t tile_count;       // +40 P=ceil(width/4)*ceil(height/4)
 int32_t reserved;         // +44 padding, initialize0
};
static_assert(sizeof(DanielVitFfwdParams)==48);
static_assert(offsetof(DanielVitFfwdParams,tile_count)==40);
// 1080: symbol _Z14k_reg_vit_ffwdILi2ELb0ELb0EEv13VitFfwdParams
// grid(68,8,1), block(32,1,1), sharedMem=0, width60 height36 P135.
// HIP kernelParams points to one by-value struct: void* args[]={&params};
// Or launch extra-buffer API with48-byte kernarg, not 6 independently packed arguments.
