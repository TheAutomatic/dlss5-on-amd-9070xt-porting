# 给闇：对照 mochizuki 0.0.2.2 找下一批提速（2026-09-28 07:00，朱雀）

> **暂缓（09-28 07:00 Zero 定）：等帧时间日志分身交活、9070 空出来后再转给闇。9070 同一时间只给一个执行者跑 GPU 测试，否则 ABBA 计时互相干扰。**

C512 第一轮收到（`results/c512-round1-20260927`，无稳定候选、未合入；结论"C512 不是并行度不足"很有用）。先 `git pull`。另一个分身同时在改 `src/`（帧时间分布日志），你只动 `hip/` 与 `Development/HIP/hip_reference_network.h` 的内核分派，别碰 `src/`；push 前 pull --rebase。

## mochizuki 0.0.2.2（今天凌晨，commit 228d3a6）

仓库 `/tmp/claude-1000/-home-lmxxf-work-ai-theorys-study/129f068a-8529-42b4-b98b-08071124e161/scratchpad/mz`（已 pull 到最新；没了就重新 clone https://github.com/mochizuki0323/DLSSNR-AMD）。他的 commit 说明：

- **Windows 离线 1080p 9.4 → 7.79 ms（−17%）**：AMD Windows 编译器（LLPC/LLVM，与我们的 COMGR 同一家）会保留 f32→f16→f32 往返，他在编译器看到之前就去掉（`NR_Q32_DIRECT` / `NR_Q32_STAGE`，`windows/` 树）。**这是和我们同一家编译器的直接证据**，第一优先。
- **Linux 5.92 → 5.60 ms**：C512 各次派发、ViT 内部、持久化运行之间的 barrier 改成 per-tile 计数器（`nr_chain.glsl`，`NR_TCHAIN`）；C512 投影独立管线；C256 下/上采样折叠在所有尺寸启用；`ffwd3`、`gemmprojw` 加占用上限（`occ_pad.glsl`）；ViT 分母留在 lane 内（`vit_attn_vt_chunk.glsl`）。输出与上一版字节相同。

我们现状：1080 档约 12.6ms（1152 行，折回 1080 行约 11.8），与他 Windows 版 7.79 差约 1.5 倍。

## 要做

1. **读 diff**（`git diff 4f62a8a 228d3a6`，重点 `windows/` 下的 `NR_Q32_*` 与 `linux/shaders/rdna4/` 各改动），逐条写"他改了什么 → 我们对应位置 → 我们有没有同类问题 → 能否逐位移植"。
2. **f32→f16→f32 往返普查**：在我们所有生产模块的 ISA 里找 `v_cvt_f16_f32` 紧接 `v_cvt_f32_f16`（或经 LDS/寄存器后回转）的往返，按调用次数加权统计条数与所在核/段。凡是数值上可证明无损的（值本来就在 f16 格点上，或往返后被再次量化到更粗格点），在源码里直接去掉；有损的（真的依赖 f16 舍入）保留——逐位是硬门槛。你在 C32 的 `CW_DIRECT_OUT` 就是这类，现在是全网普查。
3. **per-tile 计数器扩到 C512 / ViT**：我们的 PDL 目前只在 C64～C256 链；`results/pdl-c512-20250925` 显示 C512 单独 −0.16ms 但与现有 PDL 叠加不赚。看他怎么在 C512 和 ViT 内部做计数器、为什么他能叠加赚；若能在我们这边复现"叠加也赚"，做候选。注意：Zero 已定"保持 PDL=1、不为理论风险牺牲速度"，但新扩的计数器同样要有回绕保护（你修过的那种）。
4. 他其余几条（C512 投影独立管线、占用上限、ViT 分母留 lane）逐一判断适不适用。

## 门槛与约束

- 门槛：**合进配方的组合，900 或 1080 至少一档整网 ≥0.5%**；做不到就交账（逐条对照表 + 为什么不适用）。
- 逐位是硬门槛（对当前剑星 = 第五刀实装）；EXACT 与 AE 都逐位；有反例就不改；不照抄改数学路线的配置（他 Windows 版自己也说"画面和 Linux 略有不同"——那类不要）。
- 已关（别重复）：成对解包、`v_pk_*_f16`、核入口一次性 FP16_OVFL、DF_PACK8、C32 激活合 fma、C32 post 两候选、C512 half 出口、C512 一头一 wave、C512 工作组翻倍、C256 持久化、转置布局、全零填充检查。
- 每个候选：新宏默认 0，双架构，ISA 计数，7 用例逐位，900/1080 两批 ABBA。最好只换模块不加开关；非加不可就同步 RE9 runtime、三个模板、`scripts/CONFIGURATION.md`（注意 `src/` 那边分身在改，协调好）。
- 9070 动 GPU 前查游戏进程（`SB-Win64-Shipping`、`LOP-Win64-Shipping`、`OnimushaWotS`、`re9`、`SandFall*`）；分身也会用 9070 跑回归，ABBA 计时时若发现 GPU 被占，等一下再测。
- 结果 `Development/results/mochizuki-022-20260928/`，DevHistory 追加；WorkingPlan 只改"正在进行"与 B 段（整页覆盖式）。成熟候选合进配方、装剑星（带备份），不发包。够用就交；单个候选卡 2 小时以上换下一个。

## 交付

中文摘要：mochizuki 0.0.2.2 逐条对照表、往返普查结果（条数/所在核/可去掉的比例）、各候选指令/逐位/ms、合进配方后两档整网 ms、剑星装了什么/备份、提交 hash。
