# 给闇的两件活（2026-09-27，朱雀）

你已读过 `Development/DevHistory.md` 和 `Development/WorkingPlan.md`（仓库 `/home/lmxxf/work/ai-theorys-study/wechat/assets/297`，远端 `git@github.com:lmxxf/dlss5-on-amd-9070xt-porting.git`）。两件活互不依赖，也不碰朱雀这边在改的 `hip/`，可以按任意顺序做。够用就交，别过度打磨。

## 共同规矩

- 9070 机器：`ssh amd9070`，工作根 `D:\DLSSNR-Lab\`。**动 GPU 前确认没游戏在跑**：`SB-Win64-Shipping`（剑星）、`LOP-Win64-Shipping`（匹诺曹）、`OnimushaWotS`（鬼武者）、`re9`；Magpie 空闲可忽略。Zero 现在在 3080 游戏本上，9070 可以自主用。
- PowerShell 坑：含中文路径的 .ps1 要 UTF-8 BOM；含 `C:\Program Files (x86)` 的命令写进脚本文件再跑，别在 ssh 行内引号里拼。
- git：只 commit/push 297 这个仓；**commit 不加 Co-Authored-By**；push 前 `git pull --rebase`（朱雀的分身也在推）。
- 结果写 `Development/results/<名字>-20260927/README.md`，DevHistory 末尾追加一节（按时间正序），WorkingPlan 只改对应条目状态（它是覆盖式文档，别往后续写流水账）。
- 不装游戏、不发包。

## 活 1：PDL tile 旗子的正确性论证（推理为主）

**背景**：prod8 起 C64/C128/C256 链用 PDL（per-tile 完成旗子，`DLSS5_HIP_PDL=1`）让下一层按 tile 等上一层，而不是整层同步，900 约 −1.6%、1080 约 −0.6%，已过 18 槽 2880 帧逐位与生产回归（`results/pdl-chain-20260925`）。但正确性依据是经验判断："相邻复用之间至少隔 4 个 launch + CP 按包序派发工作组"。WorkingPlan「PDL」一节列了待审三点：

1. 累计计数器的相邻复用（旗子是累计计数，不清零？跨帧/跨层怎么区分代次）；
2. 输入张量覆盖与 pool 存活期：下一轮生产者为什么不会覆盖上一轮消费者还在读的缓冲；
3. 生产者发布与消费者可见性：写数据 → 写旗子的顺序与内存序（release/acquire、缓存层级、L2 可见性），消费者读到旗子后读数据是否一定新。

**要做**：读 `Development/HIP/hip_reference_network.h`（PDL 分支、launch 顺序、pool 分配）和 `hip/` 里 `_pdl` 孪生核（`HIP_PDL_KERNELS`，`multihead_fast_padded.hip` 等）的旗子读写代码，给出一份论证：

- 在 HIP on gfx12（同一 stream、同一队列）的保证下，哪些顺序是**硬件/运行时保证的**，哪些是**经验依赖**（例如 CP 按包序派发工作组、前一 launch 的工作组一定先于后一 launch 开始），各有什么文档依据（AMD ISA 文档 / HIP 编程指南 / LLVM AMDGPU 内存模型）。
- 若存在只靠经验的环节，给出最小加固方案（例如旗子带代次号、消费者端 acquire、生产者 release fence、或在复用点加一个真同步），估代价，并在 9070 上用现有回归脚本验证加固后逐位不变、计时变化多少。
- 结论三选一写清：**已证明安全** / **安全但依赖某条未文档化行为（写明是哪条）** / **存在竞态（给出可触发条件）**。

## 活 2：RE9 runtime 两条尾巴（系统调试为主）

源码 `src/LmxxfNrRuntime.cpp`（独立 runtime，C API 在 `include/LmxxfNrApi.h`），构建 `bash scripts/build-runtime.sh <outdir>`（Linux MinGW）；RE9 包里的 runtime 由 `Development/RE9/presr/prepare-host.py` 流程产出，改动需同时让那条流程拿到（它从本仓拷 `src/`）。

1. **几何日志**：现在只在首帧打一行几何信息，用户改分辨率/DLSS 档位后看不到新的。改成**输入尺寸或网络档位变化时**打印一行：`net=WxH color_job=WxH` + 四组开关实际状态（WAVE_OWNED、C512_M32、VIT_PROJ_N64、PDL 的 requested/active）+ flags 文件路径。
2. **切档残余显存泄漏**：0.32 加显存池后，每切一次档仍约 +35MB（旧版约 +180MB/次），来源未查。候选：共享栅栏（D3D12 fence ↔ HIP external semaphore）每次重新导入未释放、codec / 曝光资源重建、shader-cache 或 PSO 重复创建。已知事实：AMD HIP 驱动**从不归还导入过的 D3D12 共享缓冲**（`results/vram-leak-20260926`），所以对导入对象只能复用、不能靠释放。
   - 复现：`results/re9-runtime-flags-20260926` 里的 rt_bench 直调 C API 切档（24 次切档测显存增量）；显存读法见 `Development/tools/vram.ps1` / `benchvram.ps1`。
   - 定位到来源后修（能池化就池化），目标每次切档增量接近 0；回归：rt_bench 多尺寸末帧哈希不变、`runtime-smoke` 过。
   - 修好的 runtime 放 `D:\DLSSNR-Lab\re9-runtime-leak-20260927\`，不装 RE9、不发包，写清下次发包怎么接入。

## 交付

最后给 Zero 一段中文摘要：活 1 的结论（三选一 + 依据 + 若加固的代价）、活 2 的泄漏来源与修复效果（每次切档 MB）、提交 hash。
