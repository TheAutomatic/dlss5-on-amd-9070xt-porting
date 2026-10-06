# 给闇：自家 LLVM fork——构建管线 + 复现现有模块（2026-09-29 13:00，朱雀）

这是一张新方向的单子，全在 DGX 上做，**不占 9070**，可以和你手上的逐核计时地图并行（地图优先，这张够用就交）。

## 背景（Zero 的决定）

- 我们的内核离线编成 `.hsaco` 随包发，游戏运行时只加载代码对象——**编译器只在构建时出场**，所以可以换成自己改过的 LLVM，用户那边零改动。
- 定位：专为"FP8 推理 + gfx12"做的专用优化，**自己 fork 自己做，不往上游提**（Zero：大项目合入队列早被简历工程和 AI 批量 PR 挤满）。长期可以当独立作品公开，类比 Valve 为游戏 shader 做 ACO（ACO 在 Mesa 里：`src/amd/compiler/`，本机 `~/work/aco-isa/mesa`，约 8 万行）。
- 预期要说清：短期提速不会大——0.36 后我们普通向量指令已不比 Daniel（同一个 LLVM）多，差距在结构。fork 的价值一半是作品，一半是把源码里为绕 LLVM 写的那些手工招式（fmed3、有界倒数、fma(x,y,+0)、去往返、分段 FP16_OVFL）收回到编译器里，源码回归干净。

## 已知事实（朱雀 09-29 查的）

- Zero 已 fork：`github.com/lmxxf/llvm-project`（fork 自 `ROCm/llvm-project`），已克隆到 DGX **`~/work/llvm-project`**。克隆里只有 `amd-staging` 分支（最新 09-28），**没有 tag、没有 ROCm 发布分支**——需要的话加 `ROCm/llvm-project` 为 upstream 再 fetch 对应分支/tag。
- 我们现役模块是 9070 驱动自带 COMGR 编的，`.hsaco` 的 `.comment` 段写着：`clang version 21.0.0git (git@github.com:AMD-Lightning-Internal/llvm-project 590b9320a5be90e40268759c6203c01fde121e68)`、`LLD 21.0.0`。**这是 AMD 内部仓库的提交，公开 fork 里查不到这个 hash**——所以"逐字节复现"可能做不到，只能找最接近的公开版本（clang 21 那一代的 ROCm 7.x 发布分支附近）。
- 编译入口：`hip/rtc_compile.cpp`（调 COMGR）→ `hip/build-modules.ps1`（`-ExtraDefines`、`-Only`），模块比对 `hip/compare-modules.py`（比代码段，hash 因 `__hip_cuid` 会变）。

## 要做

1. **定版本**：从 9070 驱动的 `amd_comgr*.dll` 读版本信息，结合 `.comment` 的 clang 21.0.0git，在 ROCm 公开分支/tag 里找最接近的点（例如对应的 `rocm-7.x` 发布分支），写明选择理由。
2. **构建管线**：在 DGX 上只开 AMDGPU 目标，编 llvm + clang + lld（COMGR 可选——若能直接用 clang 命令行复刻 `rtc_compile.cpp` 的编译参数就不必编 COMGR）；记录配置命令、耗时、产物位置、增量编译流程。脚本入仓（放 297 的 `Development/tools/llvm-fork/`），构建产物不入仓。
3. **复现现役模块**：用自编编译器重编 30 个生产模块（gfx1201 为主，gfx1200 也编），与 9070 现役模块逐核比代码段：完全一致最好；不一致就统计差异规模（每核指令差、资源差），并在 9070 上跑一次 7 用例 EXACT/AE 回归看**输出是否仍逐位**（这是我们真正的门槛）。
4. **第一个补丁的候选清单**（先不写补丁）：从 `results/aco-lineup-20260928` 等已有对照里挑"编译器产物"类（NaN 规范化、`mul`+`add +0` 收缩、可证明无损的 f32↔f16 往返、已知范围的除法、VOPD 配对、等待指令位置），每条写：在哪个 pass 改、合不合 IEEE 语义（我们可以用专用属性/开关限定作用域）、预估影响哪些核。

## 约束

- 9070 只在第 3 步回归时短用，先查游戏进程（剑星、鬼武者 `OnimushaWotS`），且别和你地图的计时撞车。
- fork 仓库的提交推到 `lmxxf/llvm-project`（开个自己的分支，例如 `dlss5-gfx12`），commit 不加 Co-Authored-By；297 仓库照旧只 add 具体文件。
- 结果 `Development/results/llvm-fork-20260929/`，DevHistory 追加；WorkingPlan 只改"正在进行"与 B 段。够用就交；复现卡住（例如差异查不清）超过 2 小时就交现状。

## 交付

中文摘要：选定的版本与理由、构建耗时与流程、30 模块复现结果（一致/差异规模/回归是否逐位）、补丁候选清单前几条、提交 hash。
