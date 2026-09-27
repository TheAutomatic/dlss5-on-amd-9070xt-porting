# 给闇：C32 融合核 ACO 对照审计 + 逐位提速（2026-09-27 17:00，朱雀）

先 `git pull`（最新 516c664，0.34 已发布、tag 0.34 = 9bd416fa）。读 `Development/WorkingPlan.md`（B 段第 1 条、"研究判断"）和这几份结果，它们就是这件活的方法论：

- `Development/results/aco-isa-20260927/`：在本机（DGX Spark）用 Mesa RADV + drm-shim 假 gfx1201 拿到 ACO 给 mochizuki DLSSNR-AMD 网络编的 ISA，工具在 `results/aco-isa-20260927/tools/`（dump_isa.cpp、isa_stats.py、dyn_c64.py 循环加权统计、run.sh）；Mesa 构建和完整 ISA 在 `~/work/aco-isa/`（`LD_PRELOAD=libamdgpu_noop_drm_shim.so AMDGPU_GPU_ID=gfx1201`）。mochizuki 仓库 clone 在 `/tmp/claude-1000/-home-lmxxf-work-ai-theorys-study/129f068a-8529-42b4-b98b-08071124e161/scratchpad/mz`（没了就重新 clone https://github.com/mochizuki0323/DLSSNR-AMD）。
- `Development/results/fmed3-ovfl-20260927/`、`ovfl-census-20260927/`、`c64-hand-asm-20260927/`：C64～C256 上已经做过的一轮（fmed3 去规范化、分段 FP16_OVFL、fma(x,y,+0) 合并），每条都逐位。
- `Development/HIP/experiments/c64-hand-asm/`：`asm_compile.cpp`（调驱动的 amd_comgr_3.dll 把 .hsaco.s 汇编回模块，往返零成本），当显微镜用。

## 目标

对 **c32-wave1**（`hip/c32_fused_ffn_attention.hip` + `hip/wave_owned_c32.inc`，生产配方见 `hip/build-modules.ps1` 的 c32-wave1 行，含 CW_PACK8、HIP_FP8_SAT_MODE 3）做同样的事：

1. **循环加权 VALU 账**：仿 `dyn_c64.py`，按 ISA 里追出的循环次数加权，给出每窗口动态 VALU/VOPD/WMMA/VMEM/LDS 条数和分段（输入准备、FFN 展开/激活/收缩、注意力 QKV/softmax/AV、投影、尾部写出/下采样）。
2. **ACO 对照**：mochizuki 的 C32 对应管线是 `fswin32` / `fswinds32` / `fswinimagepre*32` / `fswinimagepost32`（`linux/shaders/rdna4/pipelines.json`），用假设备导出 ACO ISA 做同段比较：同一种运算 ACO 用几条、我们用几条，差在哪（冗余 cvt、规范化、未收缩的 mul+add、exec 掩码处理、VOPD 配对、s_waitcnt 排布等）。
3. **找 3～5 个逐位候选**，在 HIP 源码里用写法/内建函数（`__builtin_fmaf`、`__builtin_amdgcn_fmed3f`、分段 `s_setreg` 等）落实；拿不准时先用 asm_compile 手改 .s 验证"删这几条后逐位不变且变快"，确认后再回源码。**不要把手改汇编放进生产**。
4. 每个候选：新宏默认 0，双架构编译、ISA 计数、7 用例逐位（720/900/1080、运动、历史），900/1080 两批 ABBA（1000 帧/槽）；成熟的合成一套写进 `hip/build-modules.ps1` 配方。

## 约束（照旧）

- **逐位是硬门槛**：跟现在的生产 c32-wave1（0.34 包里的）输出一个比特都不差。放弃跟 NVIDIA f16 对齐的那类改法（mochizuki 的 NR_ACC_F16=0 等）不要照抄。
- 已关的路线别重复：`v_cvt_pk_f32_fp8` 成对解包在 gfx1201 返回同字节两份；`v_pk_*_f16` 需切 f16 舍入模式；核入口一次性 FP16_OVFL 在 720 不逐位（分段可以，C64 已用）。
- 9070：`ssh amd9070`，动 GPU 前确认没游戏在跑（`SB-Win64-Shipping`、`LOP-Win64-Shipping`、`OnimushaWotS`、`re9`；Magpie 空闲可忽略）。含中文路径的 .ps1 要 UTF-8 BOM，`(x86)` 路径写进脚本文件。
- git：只推 297，commit 不加 Co-Authored-By，push 前 `git pull --rebase`。结果写 `Development/results/c32-aco-20260927/README.md`，DevHistory 末尾追加一节，WorkingPlan 只改 B 段对应条目。
- 成熟候选可以照 `Development/deployments/` 模板装剑星（带备份、写清还原），**不发包**。Zero 实测按标准：1080P 窗口 + FSR 原生 AA，F8 切 EXACT，对照主菜单 50～51 / 场景 54。
- 够用就交；单个候选卡 2 小时以上就记下原因换下一个。

## 交付

给 Zero 一段中文摘要：C32 的 VALU 账（我们 vs ACO，差在哪几段）、每个候选的指令变化/逐位/ms、合进配方的组合与整网 ms、剑星装了什么/备份路径、提交 hash。
