# HIP↔D3D 交接改 GPU 轮询（2026-09-30）：交接约 0.16～0.18ms/帧，轮询候选未过门槛，不收、未装机

**结论**：用独立探针量出现行交接（D3D Signal 共享 fence → HIP WaitExternalSemaphore → HIP 工作 → HIP SignalExternalSemaphore → D3D 队列 Wait）的往返代价：HIP 工作 7.4ms（接近 900 网络）时 **mean 0.16～0.18ms、p50 0.12～0.16ms**，过了"≥0.1ms 才做"的线。拆两半：
- **D3D→HIP 改 GPU 轮询**（D3D `WriteBufferImmediate` 写标志 + HIP `hipStreamWaitValue32`，等待在 HIP 命令处理器里，不经 OS）：两轮 A/B 各省 **0.054ms**（gap 7.587→7.532、7.599→7.546），p99 也好（7.71→7.70、7.77→7.71）。安全、无自旋着色器。**但单独只有 ~0.05ms，达不到"avg 省 ≥0.1ms"**。
- **HIP→D3D 改 GPU 轮询**（Daniel 那半）：余下约 0.10～0.12ms 在这里。朴素做法——HIP `hipStreamWriteValue32`/`hipMemsetD32Async` 写标志、D3D 队列一个 1 线程 compute 自旋读——**直接出事**：无界自旋版设备移除（0x887A0005，TDR）；有界版不挂但 HIP 的 64MiB memset 从 0.03ms 被拖到 ~490ms（自旋着色器占住 GPU 调度，HIP 队列排不进来）。这正是 Daniel 注释"纯 compute spin 会触发看门狗"、改用 1 像素 draw 分片自旋的原因。要做就得照他的分片方案（每片短自旋、片间让出调度），这是新的一段工程，本轮 2 小时内没做到可测的程度。

所以 B 本轮**不收、不改生产代码、不加开关、不装机、不发包**；剑星现装保持 b77bbc3c（DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、SWIN_RUN=1 未动）。

## 探针（`Development/HIP/experiments/handoff-poll/handoff_probe.cpp`）

与 `hip_d3d12_bridge.h` Enqueue 同一套 API：同一 D3D 直接队列上，HIP 段前一条命令列表写时间戳、HIP 段后（D3D Wait 之后）一条列表写时间戳，两者同一时钟相减 = gap；HIP 段用 memset 模拟网络，hipEvent 量其自身时长；handoff = gap − HIP 工作。CPU 节奏像游戏：提交第 i 帧前等第 i−2 帧完成（两帧在飞）。对照：
- mode 0（无 HIP，两列表背靠背）gap 0.008ms p50 —— 列表边界本身可忽略；
- mode 1（现行 fence 双向）：HIP 1MiB/64MiB 时 handoff 0.09～0.12ms；HIP 7.4ms 时 0.16～0.18ms（mean）、p99 0.21～0.26；
- mode 3（D3D→HIP 轮询，HIP→D3D 仍 fence）：见上，省 0.05ms；mode 3 的 hipEvent 起点记在队列内等待之前、工作时长被夸大，只比 gap；
- mode 4/5（HIP→D3D 自旋）：TDR / HIP 饿死，见上。

原始输出 [probe-runs.txt](probe-runs.txt)。注意有两行 mode 4 与一批 jobbench 同机混跑（那批 jobbench 已作废重跑），但 mode 4 的 490ms 是数量级问题，不受这点影响。

## 为什么没用完整帧回放量

`frame-breakdown-20260928/replay.ps1` 的 wall 是 CPU 每帧等完成的整帧时间，交接只是其中两段空泡，和编码/解码/拷贝混在一起，且 `DLSS5_HIP_SPAN_PROBE` 在 benchmark 里要写进 flags 文件才生效（bench 会 clear 掉 DLSS5_* 环境变量——本轮 kernel-map-900 的事件探针就是这样踩到的）。探针能把交接单独拿出来、同一 D3D 时钟量，先用它定量更干净。

## 下一步（若要继续）

1. D3D→HIP 半边已证实可做且安全：`D3D12Bridge::Enqueue` 里把 `queue->Signal`＋`hipWaitExternalSemaphoresAsync` 换成 producer 列表尾 `WriteBufferImmediate(flag, seq)`＋`hipStreamWaitValue32(flag>=seq)`（标志放已有共享 input 缓冲尾部或新建 64KB 共享缓冲），新开关默认 0、RE9 runtime 开口、三个 flags 模板、CONFIGURATION.md。单独约 0.05ms，按门槛不能单独收；要与第 2 条一起凑够 0.1ms。
2. HIP→D3D 半边照 Daniel：游戏队列上一串 1 像素 draw，每个 draw 的像素着色器自旋有界短时间（~几十µs）读标志、满足即丢弃后续（predication 或着色器内早退），让 MES 在片间调度 HIP 队列。先在探针里做 mode 6 验证 HIP 不被饿死、gap 降到 fence 以下，再进生产。
3. 两半都要做 ≥10 分钟长跑（约 7 万帧）无挂死验证，再测帧时间 avg/p99。
