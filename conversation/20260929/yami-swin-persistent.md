# 给闇：照 Daniel 0.5.1 重开 C64～C256 持久化（2026-09-29 16:05，朱雀）

LLVM 第一刀收到（269832fa / e360808d）：VOPD 前瞻只 ±0.3%，编译器线停在这里作资产。先 `git pull`。

## 起因

Daniel 0.5.1（分身静态分析 `results/daniel-051-20260929/README.md`，提交 2e919b2e）自报 RDNA4 reference +6%、fast +8%，主体很可能是新增的 **Swin 持久化内核** `k_reg_swin_run<64/128/256>`：一次派发连跑同一 stage 的多个 Swin 层，层间靠**设备端就绪队列**同步（原子 + `s_sleep` 轮询，等待超 100ms 报警），新环境变量 `DLSSNR_SWIN_RUN` / `DLSSNR_SWIN_RUN_ALL`，用了 `hipHostMalloc` 映射内存。C64～C256 派发大减。reference 数学没变。

我们以前关掉过"C256 持久化"（更慢）。他这版是**跑得更快的实例**——按规矩，这是重开的新证据。

他的 hsaco：DGX scratchpad `d051/`（丢了用 `tools/closed-inspect/extract.py` 从 `temp/dlssnr_on_amd_setup_0.5.1.zip` 重抽）；0.5.0 在 `d050/`。9070 上有你的单核拉起工具，可以直接拉他的 `k_reg_swin_run` 计时。

## 要做

1. **拆他的持久化核**：grid/wave 组织、就绪队列的数据结构与内存位置（设备内存还是映射的 host 内存）、每层之间谁等谁（按 tile/窗口的依赖粒度）、`s_sleep` 轮询的间隔、超时兜底怎么做、LDS/VGPR 如何在层间复用、和普通派发怎么混用。找出我们旧 C256 持久化慢的原因（结果在 `results/` 里，找出当时的报告）与他的差别。
2. **照他的设计做我们的 C64～C256 持久化候选**：数学、窗口、float FMA 基准都不变，逐位。先挑 C256（stage 最深、派发最多）或按你的地图挑收益最大的 stage。
3. **同步安全**：
   - 回绕保护沿用 PDL 那套（你修过的 rollover 竞态）；
   - 设备端轮询要有超时兜底（照他 100ms 报警 + 回退），别让游戏卡死；
   - 和现有 PDL 的叠加关系写清（替代还是共存）。Zero 的原则：风险不换速度——但卡死是真风险，兜底必须有。
4. 若成立，列出推广到其它 stage 的计划。

## 门槛与约束

- 合配方的组合 900 或 1080 至少一档整网 ≥0.5%；做不到交"他的设计 vs 我们的实现、为什么照做仍不快"的账。
- 逐位对 0.36 基准（EXACT/AE 都逐位，含回绕压力测试）；新宏/开关默认 0，双架构；最好只换模块，非加开关不可就同步 RE9 runtime、三个模板、`CONFIGURATION.md`。
- 9070 动 GPU 前查游戏进程（剑星、鬼武者）。装剑星基于现装宿主 b5ab8c3a，保留 `DIRECT_IO=3`、`MAKE_RESIDENT_EVERY=60`，带备份，不发包。
- 结果 `Development/results/swin-persistent-20260929/`，DevHistory 追加；WorkingPlan 只改"正在进行"与 B 段。够用就交，卡 2 小时换思路。

## 交付

中文摘要：他的持久化设计要点、我们旧版慢在哪、候选的派发数/资源/同步方式、逐位与压力测试、两档整网 ms、剑星/备份、提交 hash。
