# ACO 的 gfx1201 ISA 与我们 COMGR ISA 对照（2026-09-27）

目的：mochizuki 的 DLSSNR-AMD（Vulkan）在 Linux 上网络 1080p 约 6ms、Windows 9.4ms，差别在着色器编译器（Linux = Mesa RADV 的 ACO，Windows = AMD LLPC/LLVM）。我们用 COMGR（LLVM 系）。在没有 AMD 卡的 DGX Spark 上把 ACO 的输出拿出来，看同类运算 ACO 怎么排，找能在 HIP 里逐位复刻的写法。

## 工具链（无 AMD 卡）

全部在 `~/work/aco-isa/`（DGX Spark，aarch64；大文件不进仓库）：

1. Mesa 26.2.3，只编 RADV：`-Dvulkan-drivers=amd -Dgallium-drivers= -Dllvm=disabled -Dtools=drm-shim`。系统 libdrm 2.4.125 太旧，本地编 libdrm 2.4.133；meson 用 venv 里的 1.12。
2. 假设备：旧的 `RADV_FORCE_FAMILY`/null winsys 已删，现在是 **AMDGPU drm-shim**：`LD_PRELOAD=libamdgpu_noop_drm_shim.so AMDGPU_GPU_ID=gfx1201`，vulkaninfo 报 `AMD Radeon RX 9070 XT (RADV GFX1201)`，`VK_KHR_cooperative_matrix`、`VK_EXT_shader_float8`（shaderFloat8CooperativeMatrix=true）、`VK_VALVE_shader_mixed_float_dot_product` 都在。包装脚本 `tools/run.sh`（LD_PRELOAD 只作用于被包的那条命令）。
3. SPIR-V：他们钉的 glslang 16.5.0 只有 x86_64 预编译，本地从源码编；`linux/build/build_network.py rdna4` 出 46 条网络管线。
4. `tools/reflect.py` 用 spirv-dis 反射每条管线的 set 0 绑定；`tools/dump_isa.cpp` 按他们宿主的特性和 `requiredSubgroupSize=32` 建管线，经 `VK_KHR_pipeline_executable_properties` 取统计和 ACO 汇编（本构建没有 LLVM 反汇编器，ACO 输出的是 `print_program` 格式，硬件指令级，够用）。
5. `tools/isa_stats.py` 对两边用同一分类器（WMMA/VALU/VOPD/DS/VMEM/SALU/SMEM/WAIT），与 RADV 自己的统计逐项吻合（fswin64：3363 条、VOPD 440、WMMA 416）。

对照的我们这边：9070 上 `hip-backend/pack8/modules-ALL`（= 0.33 发布的 c32-wave1 `CW_PACK8`、c64-wave2 `W2_PACK8 1`）的 `.hsaco.s`。没在 9070 上跑任何 GPU 任务。

## 结论

统计见 `aco-pipelines.txt`（46 条管线）和 `compare.txt`（同类核并排）。

**必须按动态比。** ACO 的 fswin 全展开（直线代码，8 个分支只是尾部越界守卫）；我们的 `c64_wave2_bi_bo` 有真循环（从 ISA 追出计数器：内层 4×外层 4、另三段各 4 次）。按循环次数加权后，一个 C64 窗口（两边都是 64 线程一个窗口）：

| | 总指令 | VALU | VOPD | WMMA | DS | VMEM |
|---|---|---|---|---|---|---|
| ACO `fswin64` | 3363 | 1759 | 440 | 416 | 128 | 101 |
| 我们 `c64_wave2_bi_bo`（动态估计） | ~10961 | ~6377 | ~1113 | ~456 | ~100 | ~509 |

WMMA 两边接近（416 对 456），说明加权对得上；**普通算术我们约 3.4 倍**。RDNA4 上 FP8 WMMA 和 VALU 不重叠，这就是 C64 族 0.71ms 对 1.83ms 的主因（编译器只是一部分）。

我们 VALU 的大头（动态/窗口）：`v_med3_num_f32` 1216、`v_add_f32` 856+379、`v_mul_f32` 527+261、`v_cvt_pk_fp8_f32` 480、`v_max_num_f32` 281+177（其中大量是 `max x,x,x`）。

ACO 的对应做法：

1. **FP8 饱和靠 MODE 位分段开关，不是一次性设。** fswin64 里 5 次 `s_setreg_imm32_b32 … imm:1473`（MODE 第 23 位 FP16_OVFL）：FP8 转换密集、没有 f16 收窄的段置 1（这段里 192 次 `v_cvt_pk_fp8_f32` 不带 clamp），出现 f16 收窄（`v_cvt_*f16*`、`v_fma_mixlo/hi_f16`、`v_pk_*_f16`）的段前置 0。我们 fp8-sat-mode 实验的 MODE 版是核入口设一次，720 档出错正是 f16 收窄被一起改了语义（溢出变 65504）；**分段开关这条 RADV 的原生做法我们没测过**。
2. 我们每个 FP8 字节的链是 `v_cvt_f32_f16` → `v_max_num_f32 x,x,x`（LLVM 给 fminf/fmaxf 的 IEEE 语义插的 NaN 规范化）→ `v_med3`（clamp ±448）→ `v_add_f32 0,x`（−0→+0）→ 半条 `v_cvt_pk_fp8_f32`，约 4.5 条；ACO 同类段 1.5 条左右。
3. f8→f32 解包：ACO 用 `v_cvt_pk_f32_fp8` 一次两个（fswin64 64 条）；我们用 `v_cvt_f32_fp8_e32` 一次一个（动态 128/窗口）。
4. f16 运算：ACO 大量 `v_pk_add/max/min_f16`（一条两值）和 `v_fma_mix_f32`（f16 操作数直接进 f32 FMA，省掉 `v_cvt_f32_f16`）。
5. VOPD 双发：ACO 440/2199≈20%，我们 1113/7490≈15%；编译器排的，不好控。
6. 我们的链头（非 `_bi` 的 `c64/c128/c256_wave2`）输入暂存还有 64 条只用一半的 `v_cvt_pk_fp8_f32 vX, vY, vY`（ACO 0 条）；只在链头块执行，量小。

## 候选（都要求与现行快速链逐位一致）

按预估收益排；估算以 C64 窗口动态 VALU ~7490 为分母。

| # | 做法 | 在 HIP 里怎么写 | 估计省 VALU/窗口 | 逐位风险 |
|---|---|---|---|---|
| 1 | **FP16_OVFL 分段开关**：只包住 FP8 转换密集段，段内去掉 `med3` 和规范化，段外（任何 f16 收窄之前）关掉 | `__builtin_amdgcn_s_setreg(hwreg(MODE,23,1), 1/0)`；须确认 LLVM 没把 f16 收窄挪进段内（MI 层 FP 指令隐式用 MODE，一般不会越过 s_setreg；IR 层要看 ISA 验证） | ~960 条 med3 + 同段规范化，约 15～19% | 有限值逐位相同（饱和到 ±448 与 clamp 同字节）；±Inf/NaN 会变 FP8 NaN（clamp 下是 ±448）——入口设一次那版 900/1080 逐位，说明这些转换的输入里没有 Inf |
| 2 | 去掉 `max x,x,x`：clamp 用 `__builtin_amdgcn_fmed3f(x,-448,448)` 代替 fminf/fmaxf（C32 的 `HIP_FP8_SAT_MODE 3` 同类，推到 `wave_owned_mh.inc`） | 内建函数 | ~458，约 6% | 仅 sNaN 规范化不同；若做了 #1 这条大部分被吸收 |
| 3 | f8→f32 成对解包 `v_cvt_pk_f32_fp8` | `__builtin_amdgcn_cvt_pk_f32_fp8(word, hi)` | ~64，约 1% | 无（同一转换） |
| 4 | 单次 f16 运算改 `v_pk_*_f16` 两值一条（我们是转 f32 算再收窄的地方） | `__builtin_amdgcn_…`/`half2` 运算 | 视站点，C32/C64 各几十～上百 | 单次加/乘/取大取小在 f32 算再收窄与 f16 直接算逐位相同（f32 精度 ≥ 2×11+2 位）；多步链不行 |
| 5 | 链头输入暂存两值一条 `cvt_pk` | 同 PACK8 | 32/链头块，全网很小 | 无 |

建议下一步先做 #2（便宜、稳），再做 #1 的 C64 原型：在 FFN 隐层量化那一段（`wave_owned_mh.inc` 的 hidden→E4M3）开关一次，看 ISA 里段内 med3 是否消失、段内有没有 f16 收窄，7 用例逐位 + 900/1080 ABBA。

## 没做的

- 没拿到 ACO 汇编的 LLVM 格式反汇编（Mesa 未开 LLVM）；`print_program` 已是硬件指令级，统计与 RADV 自带统计一致。
- 我们 C32/C128/C256 只做了静态统计；动态加权只做了 C64（`tools/dyn_c64.py` 的循环范围是手追的，换模块要重追）。
- 没有测时：假设备不执行。
