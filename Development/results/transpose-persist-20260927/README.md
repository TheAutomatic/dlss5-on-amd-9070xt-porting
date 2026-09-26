# 转置布局 / 持久化内核：可行性判断（2026-09-27，未改源码）

对照 mochizuki0323/DLSSNR-AMD 的两条做法，结论是两条在我们这里都没有明显收益，没做实现。

## 转置布局（[feature][token]，累加器直接当下一次 WMMA 的操作数）

- 我们的 C64/C128/C256 wave 核（`hip/wave_owned_mh.inc`，c64-wave2）**已经这么做了**：FFN 展开用 `wmma(b=weights, a=activations)`，结果直接量化成下一次收缩的 B 片段（注释"Expanded fragments never enter LDS"）；V 反向计算直接成 P·V 的 B 片段（"no V transpose/staging needed"）。
- 剩下的 LDS 往返（`plane0`/`plane1`）全是**跨头交换**：一 wave 一头，FFN 混合、QKV、输出投影都要读所有头的通道，这不是排布能省掉的。
- ISA（pack8 全开的 c64_wave2 单核）：总 4649 条，WMMA 150，VALU 2933，ds 70，global 195，barrier 8。瓶颈是 VALU，不是 LDS。
- VALU 构成前几位：`v_med3_num_f32` 336（E4M3 前 clamp）、`v_add_f32` 336（`+0.f` 把 −0 归 +0）、`v_cvt_pk_fp8_f32` 240、`v_mul_f32` 211。

## 持久化（原子领 (层,窗口)，只等 4 个生产窗口）

- 族账（`results/family-ledger-wave-owned-20260926`）：C256 族 34 次派发，1080 1.86ms；PDL 0→1 只让它 1.954→1.860ms（−0.09）。整帧无标记 wall 15.47 对 GPU 跨度 15.14ms，差值 0.3ms 还包括全帧 host 开销。
- PDL tile 旗子已经让下一派发在生产 tile 就绪时开跑；持久化额外能省的只剩每次派发尾部的空转，估计 ≤0.1ms（整网 <1%）。
- 实现成本：原子领活、核内对 4 个生产窗口的等待、跨层寄存器/LDS 预算，且须逐位。数小时量级，收益比不划算，暂不做。

## 剩下值得做的（记入 WorkingPlan）

1. `+0.f` 的 336 条 add：在"前一步是乘法"的点（FFN 隐层 `a*poly`）把 `+0.f` 移到 clamp 之前，让编译器合成 `fma(a,poly,+0)`（与 mul 同一次舍入，只差零的符号，正是要的）；逐位靠构造保证，需回归确认。
2. 由 +0 初值的 WMMA 累加器出来的值不可能是 −0（RNE 下 +0 与任何零相加得 +0），这些点理论上可以去掉 `+0.f`；但依赖硬件累加对 C 的处理，必须先用探针穷举零组合再用。
3. MODE.FP16_OVFL 只在 FP8 转换段内打开（RADV 的做法）可去掉 med3，但饱和模式对 ±Inf/NaN 的结果与 clamp 不同（变 NaN），0.10 的黑块就是这类问题，不做。
