# C512 激活查表小筛：数学成立，性能不收（2026-10-04）

**停止，不合生产、不装游戏。** 1080 处理档的孤立 FFN 三轮 ABBA 一快、一慢、一平，查表没有稳定收益。900 档虽快，但 baseline 槽波动很大，且另一档不成立；不选择性取最好结果。本轮没有全网 19 组验收、整网 ABBA/p99，不能称全网逐位或整帧提速。

## 数学与实际入口

基线 `170f7b3c` 的 `hip/c512_m32_deep.inc` 中，实际生产 `split_ffn_one_w2f8` 在 expand 后执行：

`v = Hrtz(ex)` → `g=clamp(v,-4,4)` → `p=fma(g,fma(abs(g),-.055908203125,.447265625),.89453125)` → `byte_F(v*p)`。

Hrtz 后没有动态 bias/scale。其值已处于 half 格点，固定映射可以制成 65536 字节表。保留原 `v_cvt_pkrtz_f16_f32` 舍入，以低 16 位索引；没有新增量化。表由**GPU 原 helper**一次生成，非 CPU 多项式近似。实验 helper 默认宏 0 保留原算术；启用宏 1 才用模块内设备表。探针先初始化表并同步完成，再跑 FFN；未接入游戏热路径。

全 65536 half 位码（63488 finite、2048 nonfinite，含正负零/次正规/Inf/NaN）原 helper 与 lookup byte **0 不同**。真实 block23 FFN 权重，合成 E4M3 格点输入，actual `split_ffn_one_w2f8` 的两档输出均逐 byte 相同（917504 / 1146880 bytes）。这是孤立域和实际 kernel 检查，未覆盖完整模型中每块真实输入。

## 两档预热后小筛

每槽 50 次预热，600 次连续 actual FFN 派发；计时前额外交错预热两实现各 2000 次。每轮 A-B-B-A，GPU event 同流包住整批、同步 end 后读取；CPU wall 同时记录，不把异 API 时钟相减。两者对 1080 的结论一致。

| token 档 | 轮 | baseline µs/调用 | LUT µs/调用 | LUT − baseline µs |
|---|---:|---:|---:|---:|
| 1792（900） | 0 | 30.672 | 22.106 | −8.566 |
| 1792 | 1 | 40.727 | 21.682 | −19.045 |
| 1792 | 2 | 36.748 | 21.388 | −15.360 |
| 2240（1080） | 0 | 26.992 | 26.666 | −0.326 |
| 2240 | 1 | 26.924 | 27.257 | +0.333 |
| 2240 | 2 | 27.111 | 27.112 | +0.001 |

900 baseline 槽内约 23.6–40.8µs，不能拿这种隔离差额乘 16 块声称整网收益。更稳定的 1080 三轮平均几乎完全抵消，按小筛止损，不继续压缩表或折腾 cache 布局。

ISA：gfx1201 的 w2f8 静态体 964→903 行、8 条 FMA→0，增加 8 条 `global_load_u8`；VGPR 116、SGPR 42、零 spill、24 条 WMMA 均不变。指令减少没有换来稳定时间收益，查表增加的依赖读取仍在关键路径。

## 复现与证据

源码位于 `Development/HIP/experiments/c512-activation-lut/`：`prepare.py` 固定取 170f7b3c 原源码生成 baseline/macro0/candidate，`activation_lut.inc` 是实验补丁，`probe_kernels.inc`、`probe.cpp` 为域与 actual FFN 探针，`build.ps1`、`run.ps1` 编译及受控执行。**生产 hip/src 没有改动**。

- Windows：`D:\DLSSNR-Lab\c512-activation-lut-20261004`，认可的 multi-pass-predict RTC/COMGR（LLVM21），max-ilp 同生产行。两架构编译，实际 GPU 仅 gfx1201。
- gfx1200 ELF flags `0x48`，gfx1201 `0x4e`；macro0 对 untouched baseline 的 `.text/.rodata/.note` 两架构全字节同。完整模块 SHA 的非执行字符串等变化不当成机器码变化。
- 生成源码 SHA：baseline `d5e22b8c9a58d5138292dfface95f284e06346845ab5f4168c8cd6b4c4ccf3e8`；macro0 `22b83b7fcf12f6de6d5fd8d7a5372e6a6f630013adb0e5915cc34102a3947397`；candidate `3036211bbab3981468a3fba3770d406b6e73cc5e3fff8fd3f6a43929504944f0`。
- GPU 表 SHA `e6c645c6478ab172d53896313d17ee1219890c105f461051215d9aec98ab0d80`；完整模块/真实权重 SHA 和码域计数见 `summary.json`。权重取 current assets 的 block23-ffwd.f16，经 half→float 精确拓宽为探针输入，没有修改权重。
- `probe.log` / `timing.csv` 是最终原始槽，`first-cold.log` 保留首轮；首轮运行脚本误读空 ExitCode，已用保留 Process.Handle 修复，最终返回 PROBE_DONE。两个实际 GPU 探针均完成。
- GPU 运行有 game-check、原子独占 gpu.lock、15 秒看门狗；D 盘约394GB。锁已释放，无游戏载荷/配置修改，无帧 dump。未把查表挂到原模型初始化，因此没有声称模块缺失回落或整网兼容已验收。
