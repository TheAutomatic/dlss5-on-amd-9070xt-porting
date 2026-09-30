# D3D 与 HIP 共队列可行性（2026-10-01，只测只调研，未改生产）

**结论先行**：交接那 ~0.2ms **不是"换 API/换上下文"的代价，是"离开游戏队列"的代价**。同一个 D3D12 设备里把活挪到第二条 D3D 队列（COMPUTE 或 DIRECT），用 fence 往返一次，开销和 HIP 一样大（大活 0.20～0.28 vs HIP 0.16～0.39 mean、p50 都是 ≈0.165ms；多轮切换斜率三者都是 **≈0.09ms/往返**）；只有**同一条队列里背靠背录**才是 ≈0.015ms。所以能省钱的只有"网络录进游戏队列本身"，任何"另一条队列 + 同步原语"（含 Vulkan 互操作、AMD 扩展队列）都省不掉。

- 可省上限：探针里同队列比 fence 往返少 **≈0.15～0.19ms/帧**（gap 7.41 vs 7.60，按各自工作量折算）；游戏整帧里 fence 等待部分与别的工作重叠（handoff-gpu 第二轮 D3D→HIP 轮询探针省 0.05～0.08、整帧反慢），实际兑现估 **0.05～0.15ms/帧**，未进游戏实测。
- 推荐：**不开新线**。唯一能真省的两条（网络翻成 D3D12 compute 录进游戏队列；或走 vkd3d-proton 录进同一 VkQueue）要么缺 WMMA/FP8 的 D3D 公开通路、逐位无法保证，要么等于重写后端＋强制用户换 D3D12 翻译层，收益 ≤0.15ms 不值。留作将来 DirectX Linear Algebra 正式版出来再看。

## 实测（`HIP/experiments/same-queue/switch_probe.cpp`，9070，GPU 锁内，原始 [probe-runs.txt](probe-runs.txt)）

每帧：游戏 DIRECT 队列打时间戳 → K 次「Signal → 执行者 Wait → 填 W/K 显存 → 执行者 Signal → DIRECT Wait」→ 打时间戳。over = gap − 执行者自身工作时间（D3D 执行者用它自己队列上的时间戳，HIP 用 hipEvent）。两帧在飞，弃前 10%。顺序 ABBA 对称两轮。

| 执行者 | 4096MiB K=1 over mean / p50 | 4096MiB K=8 over mean（每往返） | 64MiB K=1 over mean |
|---|---|---|---|
| 0 同一 DIRECT 队列（无 fence） | 0.014 / 0.018 | 0.017（—） | 0.011 |
| 1 第二条 D3D COMPUTE 队列 | 0.277、0.206 / 0.247、0.166 | 0.612、0.692（0.077、0.087） | 0.092 |
| 2 第二条 D3D DIRECT 队列 | 0.203、0.215 / 0.165、0.161 | 0.745、0.767（0.093、0.096） | 0.093 |
| 3 HIP（现行 fence 双向） | 0.386、0.384 / 0.165、0.165 | 0.719、0.736（0.090、0.092） | 0.110 |
| 4 HIP，D3D→HIP 改 WriteBufferImmediate＋WaitValue | gap 7.532（hipEvent 起点含等待，over 不可读） | — | — |

（ms。HIP K=1 mean 高于 p50 是每轮有一帧 7.6ms 的长尾，p99 ≈7.6；D3D 队列无此尾。gap 绝对值：同队列 7.41，第二条队列 7.57～7.64，HIP 7.60，HIP 轮询入 7.53。）

读法：
1. 第二条 D3D 队列与 HIP **同量级**，p50 完全一样（0.165），64MiB 小活也一样（0.09 vs 0.11）。WDDM/MES 看来都是"每条队列一个硬件队列槽、fence 等待由调度器解"，HIP 多出来的只是约 0.02ms 和一个偶发长尾。handoff-gpu 说"剩下是两个上下文之间切换"——更准确的说法是**两条队列之间切换**。
2. 斜率 ≈0.09ms/往返与 K 无关：纯同步延迟（fence 完成 → 调度器放行另一队列），不是缓存冷启动。
3. 所以 (c) 类"同一硬件队列"方案若只是换同步原语一律无效；必须**同一条命令流**。

## 路线对比

| 路线 | 能否去掉切换 | 预期省（每帧） | 逐位 | 工程量 | 风险 / 卡点 |
|---|---|---|---|---|---|
| (a) HIP 模块翻成 D3D12 compute，录进游戏队列 | 能 | 0.05～0.15（上限 ≈0.19） | **难**：DXIL 无 WMMA/FP8 公开通路；SM 6.9 Cooperative Vector 是矩阵-向量、DirectX Linear Algebra 2026-04 才进公开预览，精度/舍入由驱动定；AMD 驱动内部 ISA 注入（amdxc / AGS）没有公开接口，AGS 6.x 只有 wave/clock 等内在函数，无 WMMA | 极大：162 派发全部重写或逆向驱动 PSO 格式 | 每次驱动更新都可能坏；D3D 编译器改指令调度，逐位基准要重建 |
| (b) Vulkan compute ＋ D3D12 互操作 | **原生 D3D12 下不能**：还是两条队列＋共享 semaphore，与执行者 1/3 同价 | 0 | — | 大 | mochizuki 能省是因为**他要求游戏跑在 vkd3d-proton 上**（`nr_pe_interop.cpp` 用 `ID3D12DXVKInteropDevice::GetVulkanHandles` 拿 VkDevice/VkQueue，`ID3D12GraphicsCommandListExt::GetVulkanHandle` 把网络录进 vkd3d 的命令缓冲，和游戏同一 VkQueue；D3D11 走 DXVK 同理）。照抄 = 把我们的 add-on 改成要求用户装 vkd3d-proton，外加整个网络从 HIP 移植到 SPIR-V |
| (c) HIP 与 D3D 共享硬件队列 / context | 否 | 0 | 逐位 | — | HIP（PAL/ROCclr）在 Windows 自建 WDDM context 与队列，无"提交到外部 D3D 队列"接口；amdxc/AGS 不开放 HIP 互操作。即使能共享硬件队列，本测表明代价在队列间同步而非 API |
| (d1) 游戏队列上 GPU 轮询（Daniel 分片自旋） | 部分 | 负（handoff-gpu：比 fence 慢 0.04～0.17） | 逐位 | 已做 | 已负账 |
| (d2) D3D→HIP 轮询半边 | 部分 | 探针 0.05～0.08，整帧 −0.01～−0.04（反慢） | 逐位 | 已做（开关默认 0） | 已负账 |
| (d3) 把 D3D 编解码/拷贝挪进 HIP | 否（往返次数仍 1） | 只省拷贝，与切换无关（frame-breakdown 估 0.1～0.25） | 逐位 | 中 | 是另一件事：输入零拷贝那条，值得单独做 |
| (d4) 不改 | — | 0 | — | 0 | — |

## 推荐

1. 切换这条线**停**：代价是队列间同步本身（≈0.09～0.17ms/往返，p50 0.165），我们每帧只有 1 次往返，已是最少；可去掉的只有同队列方案，两条都不划算（上表 a/b）。
2. 若要网络外的钱，转去 (d3) 拷贝/编解码瘦身（frame-breakdown 可做项 2/3），那部分与切换无关、逐位、估 0.1～0.25ms。
3. 进游戏量"切换在整帧里占多少"的方案（未执行，需要 Zero 在场）：剑星 1080 站立，`DLSS5_FRAME_STATS=5`，A = 现装，B = 现装 + `DLSS5_HIP_INPUT_POLL=2`，各 30 秒、ABBA；或用 RGP 抓一帧看游戏 DIRECT 队列在 Wait 上的空泡。本轮没做：离线已给出上限，且结论不依赖游戏内数。

## 文件

- `Development/HIP/experiments/same-queue/switch_probe.cpp`（mingw 交叉编译：`x86_64-w64-mingw32-g++ -O2 -std=c++17 -I../.. switch_probe.cpp -o switch_probe.exe -ld3d12 -ldxgi -ld3dcompiler -static`）、`sq-run.ps1`。
- 9070 现场 `D:\DLSSNR-Lab\same-queue-20261001`（只有 exe/脚本/输出）。游戏文件未动。
