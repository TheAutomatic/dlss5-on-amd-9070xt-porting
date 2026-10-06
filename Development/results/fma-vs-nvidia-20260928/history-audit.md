# “逐位”基准的来历

两次float舍入不是从 NVIDIA HFMA2 照抄的，也不是直到 HIP 才偶然出现。它属于已经获准近似的 fast HLSL 路线，之后为了跨核一致主动禁用收缩。

- `Development/history/fast-path-plan.md:3`：2026-09-08 09:04 用户允许不再对5090逐字节一致，冻结exact链，允许硬件算术差异。
- `Development/history/DevHistory-full-20260923.md:252`附近：fast-epilogue主动删激活的三次中间half舍入；最初 fast 全网对exact约42dB，不是逐位。
- `4b80815`（09-10 08:23）C32融合：HLSL scalar tail的FMA收缩随上下文改变，为使原分离核/新融合核逐位，两边加 `precise`。`05c8f99`（同日10:08）多头链继承这条约定。
- `shaders/dx12-network/native_wave_c32_ffn_blocked.hlsl:113-120`、`native_wave_ffn_fused.hlsl:33-42`：`NATIVE_*_PRECISE_CHAIN` 注释明确是 FAST PATH，为融合核对齐，不是原版精度合同。
- `Development/HIP/PRODUCTION_ROUNDING_AUDIT.md`（09-14）第1/3/4条，已经写清 fast FFN/归一化/softmax 和 legacy NVIDIA 参考有显著差别，HIP需先对实际 production CSO，而不是把旧 exact 参考和fast混在一起。
- `hip/rtc_compile.cpp:26`前端选项是 `-O3 -nogpuinc -nogpulib` 加外部选项；没有显式 `-ffp-contract=off`。现在的分离乘加是对既有fast输出的移植合同，不能简单归咎HIP编译器默认值。

最早“逐位对NVIDIA”并非虚构：有原DLL提取CUBIN独立执行，恢复参数/布局后逐段对拍，再连接整个RGB0→70与时序。这里再次读回旧完整1080 fixture：`release/native-rgb-valid1080/amd-full/gpu-main.f32` 与 `oracle-final.f32` 的 **6,635,520个32位值全字节相同**，SHA256同为 `c1d6ab580e4d3bfb46acb90646d1a65d609cbcf6dbdcdde12d1bef18703afbe3`。本轮重核的是保留的原CUBIN oracle和旧exact AMD产物，并非新跑整套NVIDIA网络；scope是受控RGB fixture，不把它冒充本轮游戏实帧。

因此需区分三条线：原版CUBIN → 0.01 exact → 获批fast/HIP。最近几轮的逐位，指 **HIP优化前后**，不是仍然逐位等于 NVIDIA。上轮“两个独立舍入是语义必须”的表述应收窄为“保持当前fast输出所需”；它不构成反对另立FMA候选的理由。
