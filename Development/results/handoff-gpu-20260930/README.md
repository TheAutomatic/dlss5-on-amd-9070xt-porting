# HIP↔D3D 交接两半都改 GPU 侧同步（2026-09-30）：HIP→D3D 分片自旋在我们这儿只会更慢，不收、没装机

**结论**：照 Daniel 的做法做了 HIP→D3D 的 1 像素 draw 分片自旋（带 predication 的分片），放进探针测。**所有配置都比 fence 慢**：HIP 7.4ms 这档，两边都走 GPU 轮询（mode 7）gap 7.61～7.68ms，只做 D3D→HIP 轮询（mode 3）是 7.50～7.51ms，现行 fence（mode 1）是 7.59～7.60ms。分片自旋额外多花 0.04～0.17ms，p99 也更差；HIP 小活（64MiB）这档 0.27 对 0.084ms。原因不是分片没切对，是**所谓 HIP→D3D 那"0.1ms"本来就不是 fence 延迟**：mode 3 下 gap 减去 HIP 工作时间约等于 0（p50 −0.007），剩下的时间是 GPU 在两个上下文之间切换，自旋省不掉。自旋的 wave 反倒跟 HIP 抢资源（hip_work 7.48→7.63）。
D3D→HIP 轮询这一半在本轮又复测了一次：省 0.08ms（7.59→7.51，两轮），p99 更好。它**单独还是不够 avg ≥0.1ms**，另一半又凑不上来，所以**两半都不改生产代码、不加开关、不装机、不发包**。剑星（a80db313）和鬼武者（RE9 runtime fd4b2c0c）都没动。本轮没做完整帧回放和长跑：探针阶段已经判负。

## Daniel 0.5.1 的 HIP→D3D 半程（静态拆解：`extract.py` 抽出 mod.dll，读 ini 默认值和内嵌 DXBC）

- ini 键和默认值（`GetPrivateProfileInt` 调用点的立即数）：`SpinDraw=1`、`PredSlices=64`、`PollSpacing=0`，`InlineWaitMs=200`，钳在 50～5000ms 之间；另有 `HipActiveWaitUs`（设 `ROC_ACTIVE_WAIT_TIMEOUT`）。
- 分片：游戏队列上连着排 `PredSlices` 个 draw。VS（DXBC @536032）用 SV_VertexID 生成一个盖住 (0,0) 的大三角形；PS（@534880）循环 `i < cb.z(maxIter)`，每次用 `InterlockedAdd(+0)` 原子读完成标志，`≥ target` 就 break；按 `PollSpacing` 掩码隔几次再读一下 **abort word**（主机看门狗写入），读到就退出；最后写一个结构化结果（predication 字）。后面没跑的分片被 predication 跳过（字符串 "predicated spin slices (preemptible between slices)"）。另有 compute 版本（@533408，开头先读结果字，已完成就直接 ret），只在 `SpinDraw=0` 或 predication 缓冲不可用时用。他的注释说 compute 自旋"不会被 OS 调度器抢占，几分钟就触发一次 GPU 看门狗重置"。
- 每片的上限：迭代上限 = 预算 ms × 标定得到的 iter/ms（日志 "~%.0f iter/ms"），再平均分给各片。
- 失败退路：超时 = 这一帧输出不可信，显示上一帧残差（"previous residual shown"）；预算自适应，超时后降，连续 clean 若干帧后回到默认（"wait budget back to %d ms"）；主机看门狗写 abort word 强制所有分片退出；还有一个启动自检（"inline flag check"），驱动不支持时让用户关掉 Inline。**他没有退回 fence 的路径**：D3D12 没有条件 fence wait，GPU 那边超时以后只能"放行并标脏"。
- 前提：他的 inline 模式是游戏队列在等网络、HIP 已经在跑。

## 探针（`HIP/experiments/handoff-poll/handoff_probe.cpp` 新增 mode 6/7）

- mode 6：D3D→HIP 走 fence，HIP→D3D 走 `hipStreamWriteValue32` 标志 + 分片自旋；mode 7：两边都走 GPU 轮询。分片做法：每帧先 `WriteBufferImmediate` 把 predication 字清零，然后 `SetPredication(NOT_EQUAL_ZERO)`，循环 N 次「draw + UAV barrier」；PS 每片最多原子读 `PROBE_ITER` 次，读到标志就写 predication 字，最后一片还没读到就计一次超时。环境变量 `PROBE_SLICES`/`PROBE_ITER`，`PROBE_PRESYNC` 是诊断用（HIP 先在 CPU 上同步完再提交 D3D）。
- **mode 6 每一帧都超时**（64 片 × 4096 次，gap 30ms，HIP 被拖到 3～5ms）。加 `PROBE_PRESYNC` 后超时为 0，说明标志是能看到的，问题在 **D3D 一开始自旋，还在等 fence 的 HIP 就排不进来**。这和上一轮 compute 自旋把 HIP 拖到 490ms 是同一件事，改成 draw 分片也只好一点。
- mode 7 不饿死，因为 HIP 在轮询等待，D3D 开始自旋之前 HIP 已经在跑了。可是 64 片 × 512 次的预算约 4ms，比 7.4ms 的 HIP 活短，照理应该超时，实际只有第一帧超时——说明 D3D 的分片要等 HIP 做完才真正上 GPU，两个上下文是轮流跑的，不是同时跑。

## 数（9070，GPU 空闲，第一帧不计，原始输出 [probe-runs.txt](probe-runs.txt)）

| HIP 活 | mode 1 fence 双向 | mode 3 仅 D3D→HIP 轮询 | mode 7 两边轮询＋分片 |
|---|---|---|---|
| 4096MiB（≈7.4ms），64×2048 | 7.5960 / 7.5928（p99 7.84 / 7.73）| 7.5119 / 7.5118（p99 7.65 / 7.67）| 7.6138 / 7.6168（p99 7.78 / 7.83）|
| 同上，8×16384 | — | 7.5045 | 7.6474（p99 8.00）|
| 同上，256×128 | — | — | 7.6773 |
| 1024MiB，8×16384 | — | 1.8024 | 1.8433 |
| 64MiB，64×2048 | — | 0.0840 | 0.2731（p99 0.64）|

（gap_mean，单位 ms；ABBA 顺序 1-3-7-7-3-1。）

## 如果以后还要动

- 交接剩下的时间在上下文切换上。能改变它的只有"不切换"：把 D3D 的活挪进 HIP，或者整段放在同一个队列里，而不是换一种同步原语。
- D3D→HIP 轮询（mode 3）约省 0.05～0.08ms、安全，一直都在，将来跟别的小件合包一起过线时可以直接拿来用（做法写在 `results/handoff-poll-20260930` 的"下一步 1"）。

## 第二轮（同日，新验收规则：逐位＋离线为正＋p99/另一档不变差）：D3D→HIP 轮询进生产代码，完整帧回放是负的，不装

实现：`Development/HIP/hip_d3d12_bridge.h` 新增开关 `DLSS5_HIP_INPUT_POLL`，默认 0；普通 add-on 和 RE9 runtime 共用这份桥接头，所以两边都读这个开关。
- 取 `1`：Enqueue 时在游戏队列上执行一条预录的命令列表，里面只有一条 `WriteBufferImmediate(MARKER_OUT)`，把槽位值 1..8 写进一块 64KB 共享缓冲；HIP 流用 `hipStreamWaitValue32(EQ)` 等这个值。
- 取 `2`：同一条 marker 直接录进 RecordInput 的输入拷贝列表，省掉一次 ExecuteCommandLists。
- 退回 fence 的保护（1/2 都有）：启动时做一次自检，marker→等待 200ms 内过不去就不启用；另起一条看门狗线程，如果 marker 在 D3D 侧已完成、但它后面的 HIP 等待 200ms 还没过，就从另一条 HIP 流把值写进去放行，之后所有帧走 fence。HIP→D3D 半程不动，仍然走 fence。

逐位（基线 = 同源宿主开关 0 ＋ 剑星现装 31 模块）：两种模式都是 7 用例 × EXACT/AE × 12 帧 SAME、AE 决策 CSV SAME、900/1080 票号回绕 SAME，也就是 18 组全 SAME；stderr 里每个候选进程都出现 `hip_input_poll enabled`，没有看门狗放行。

完整帧回放 ABBA（avg / p99，ms，基线→候选）：

| 模式 | 轮 | 900 | 1080 |
|---|---|---|---|
| 1 独立 marker 列表 | 1 | 7.816→7.837（+0.021）/ 8.052→8.073 | 10.691→10.719（+0.028）/ 10.948→10.965 |
| 1 | 2 | 7.817→7.855（+0.037）/ 8.072→8.065 | 10.705→10.725（+0.021）/ 10.984→10.978 |
| 2 marker 录进输入列表 | 1 | 7.829→7.839（+0.010）/ 8.048→8.008 | 10.713→10.741（+0.028）/ 10.957→10.991 |
| 2 | 2 | 7.855→7.867（+0.012）/ 8.078→8.053 | 10.726→10.742（+0.016）/ 11.015→10.996 |

两种模式、两档、两轮 avg 都变慢了 0.01～0.04ms。探针里单独测交接是省 0.05～0.08ms，放进真实流水线就没了：fence 的等待在整帧里本来就和别的工作重叠，GPU 轮询多出来的 marker 和等待开销反而露了出来。按新规"离线要为正"，这次不收。开关保留、默认 0，没改模板、没装机，剑星 a80db313、鬼武者 fd4b2c0c 都没动。因为不装，10 分钟长跑没有跑。
