# 网友报告：剑星系统内存每秒约 10MB 上涨（2026-10-01，静态排查）

网友原话：显存不涨；内存以约 10MB/s 上涨，32GB 机器从约 11000MB 涨到约 27000MB，在约 98% 附近浮动不爆；体感是加载变慢、偶尔未响应、等一会儿能恢复。按 57fps 算，约 175KB/帧。

**结论先说：宿主代码里没找到按帧线性增长的主机内存分配。** 所有每帧路径上的容器都有上限，或者每帧都被清空。"涨到约 98% 稳住、不爆、加载变慢、短暂卡死"更像是**显存超额后溢出到系统内存（共享 GPU 内存）、加上工作集被修剪和换页**，而不是进程泄漏。真泄漏会让提交大小持续上涨，最终触发 OOM 或者把页面文件撑满，不会自己稳在一个值上。这一条要靠实测确认，所以这一单没有修复。

## 1. 每帧和周期路径排查（按可疑程度从高到低）

| # | 位置 | 每帧做了什么 | 是否有上限 | 判断 |
|---|---|---|---|---|
| 1 | `src/native_game_frame.h:378-379` + `src/native_pinned_resource.h:25` | `DLSS5_MAKE_RESIDENT_EVERY=60`（默认模板开启）：每 60 帧对所有 ≥32MiB 的缓冲调用 `MakeResident`，并且从不 `Evict`；同时 `RESIDENCY_PRIORITY=maximum` | MakeResident 是引用计数，每秒 +1，只是一个计数，不占主机内存 | **不是主机泄漏，但跟现象最相关**：我们约 1–2GB 的缓冲被钉死在显存里，游戏的流式纹理会更早被挤到系统内存。也就是说"显存满但不涨、系统内存涨"有可能是我们放大的，开关可以直接对照 |
| 2 | `src/native_pre_upscale.h:160-163, 269` `retired` 队列 | 异步时每帧把 Job（持有 7 个资源引用 + list）入队，`Retire()` 按 fence 完成值出队 | 有上限（只在设备移除、`Completed()==UINT64_MAX` 时停止出队）| 低。`logs/native-pre-upscale.txt` 每 100 帧会打印 `retained=`，可以直接核对 |
| 3 | `src/native_pre_upscale.h:96, 143` `Jobs()` 映射 | 以 command list 指针为键，在 DIRECT 队列 Execute 时取走 | 同一个 list 指针在旧 Job 未取走前不会再捕获（`count(native)` 时返回 false）| 低。最坏情况是游戏 list 池的大小 |
| 4 | `Development/HIP/hip_reference_network.h:534-541` ViT 自适应 reset | idle 超时或输入/seed 变化时 `Upload(...,persistent)` 重新 hipMalloc 32B，并从池里取 anchor | 旧的 shared_ptr 会释放；anchor 走池 | 低（旧 VRAM 的 HIP 泄漏只针对导入的 D3D12 缓冲，hipMalloc/hipFree 正常）|
| 5 | `Development/HIP/hip_reference_network.h:149` 张量池 `New()` | 每帧取用池里的张量 | 只有找不到空闲项时才增长，稳态后不再增长 | 低 |
| 6 | `Development/HIP/hip_d3d12_bridge.h:200-206` 每帧 `hipWaitExternalSemaphoresAsync` / `hipSignalExternalSemaphoresAsync` / `hipEventRecord` | 驱动内部 | `re9-runtime-leak-20260927/semaphore-1.log`：100 次 import+wait/signal，私有内存 85.684→85.699MiB（约 0.15KB/次）| 排除（量级差 1000 倍）|
| 7 | `src/native_game_codec.h:121-132`、`src/native_temporal_feed.h:47-53` 描述符堆绑定缓存 | 绑定的纹理变化时缓存 | `binding_limit` / 8 | 低 |
| 8 | 日志：`native_submission_order_probe.cpp` 的 `n%100` coverage 行、`native-pre-upscale.txt` 每 100 帧一行、`FRAME_STATS`（默认 0；固定 400 桶直方图，按窗口清零）、`GAME_PROBE`（默认关，固定 8 槽）、event 日志上限 8192 条 | — | 有上限，或者每百帧约 100 字节 | 排除 |
| 9 | `hip_reference_network.h:349` `opt.profile` 每次 launch 都 hipEventCreate 并 push_back、`:358` wall_profile | 只在离线 profile 时 | 游戏模板不开 | 排除 |
| 10 | `DIRECT_IO=3`、热重载（`native_hot_flags.h`，单例）、格式兜底（`s->low` 只在几何/格式变化时重建）| — | 有上限 | 排除 |

以前修过的两类问题都是**切档/重建时**的泄漏，不是每帧的：导入缓冲池（`vram-leak-20260926`），以及驻留名单解绑和 PDL 旗子（`re9-runtime-leak-20260927`）。网友描述的是"持续每秒涨"，不是"切一次档涨一截"。

## 2. "涨到约 98% 稳住"的判断

- 任务管理器"性能 → 内存"里的"使用中"= 所有进程的工作集 + 驱动和内核分配。不包含 standby 缓存（standby 算在"可用"里）。所以这不是"Windows 缓存看起来占用"的假象，确实是有东西在占。
- 但是**稳在 98% 而不爆**，说明那块内存是可以修剪、换出的：内存管理器在高压下修剪工作集，再从页面文件或者 GPU 共享段换回来，于是加载变慢、偶尔未响应。进程私有提交如果真在泄漏，会一直涨，直到"提交限制"（物理内存 + 页面文件）被撑满然后报错，不会停在 98%。
- 最符合描述的机制：**显存满了（网友说"显存不会越来越满"，指的是它一直在上限），游戏边走边流式加载新资源，超出预算的部分被 WDDM 降级到系统内存（共享 GPU 内存）**。这部分在任务管理器里算作系统内存占用，会随游玩时间增长，直到显存和系统内存双双触顶。我们的网络加共享池常驻约 1–2GB 显存，并且用 maximum 优先级加周期 MakeResident 钉死，会让游戏更早溢出。
- 区分办法：看游戏进程的"提交大小"（Private Bytes）和 GPU 的"共享 GPU 内存"，哪个在涨。
  - 提交大小持续涨 → 是进程泄漏（可能在我们这边，也可能在游戏或驱动 UMD），再用开关对照。
  - 提交大小基本平、共享 GPU 内存在涨 → 显存溢出，属于游戏和驱动的行为，我们的影响是常驻量和优先级。

## 3. 复现方案（9070，GPU 空闲时排）

采样脚本：`sample.ps1`（每 10 秒一行 CSV：进程 Private/WorkingSet/Pagefile/句柄/线程、系统提交/可用/standby、该进程的 GPU Dedicated/Shared Usage）。

每组都从同一个存档进同一个场景，原地跑 10 分钟（跑图更好，能触发流式加载）：

| 组 | 改动（只改 `native-game-flags.txt`） | 目的 |
|---|---|---|
| A | 默认 0.39 模板 | 基线 |
| B | `DLSS5_MAKE_RESIDENT_EVERY=0` | 周期钉驻留 |
| C | B + `DLSS5_RESIDENCY_PRIORITY` 删除或改成 normal | 优先级 |
| D | `DLSS5_VIT_ADAPTIVE=0` | 自适应复用状态 |
| E | `DLSS5_PRE_UPSCALE_ASYNC=0` | retired 队列 |
| F | 不装 DLSS5（只用原版 OptiScaler/FSR）| 游戏本身 |

判读：
- 斜率 = 线性拟合 `private_MiB`（MiB/分钟）。A 约 600MiB/min 才对得上网友的数字。
- `gpu_shared_MiB` 涨而 `private_MiB` 平，说明是溢出；对比 A/B/C/F 的 shared 斜率，就能看出我们的常驻占用放大了多少。
- 只有 A 涨、D 或 E 不涨，就指向对应的路径；A 和 F 一样涨，就是游戏或驱动。
- 附带核对 `DLSS5-AMD\logs\native-pre-upscale.txt` 里的 `retained=` 是否恒定。

离线（不进游戏）：`re9-runtime-leak-20260927` 里的 bridge 探针目前只测"建→毁"，没测稳态。如果游戏里 A 组 private 在涨，可以给 bridge_probe 加一个"单会话连续 Enqueue 3 万帧，每 1000 帧打一次 PrivateUsage"的模式，把问题定位到 HIP 网络/桥接（目前还没写，等实测结果再决定）。

## 4. 给网友的回复草稿

> 谢谢反馈！我们查了一遍代码，没找到每帧都会涨的内存分配，所以想请你帮忙确认一下是哪一种情况：
> 1. 你用的是哪个版本（比如 0.39）、哪个包（常规 OptiScaler 包 / HIP / Magpie），`DLSS5-AMD\native-game-flags.txt` 有没有改过？方便的话直接把这个文件发我们。
> 2. 玩一会儿以后，打开任务管理器的"详细信息"页，在列标题上右键 → 选择列 → 勾上"提交大小"，看剑星（SB-Win64-Shipping.exe）的"提交大小"是不是一直在涨。
> 3. 同时看"性能 → GPU"页下面的"共享 GPU 内存"是不是也在涨。
> 4. 如果方便，把 `native-game-flags.txt` 里的 `DLSS5_MAKE_RESIDENT_EVERY=60` 改成 `0`，重进游戏，再看内存还涨不涨。
>
> 如果"提交大小"不涨、只是"共享 GPU 内存"在涨，那是显存装满之后游戏的资源被挪到了内存里（换地图或者加载时会变慢），不是程序泄漏；第 4 步会减少我们这边占着的显存，可能会有改善。如果"提交大小"一直在涨，那就是我们或者驱动的问题，请把 `DLSS5-AMD\logs` 文件夹打包发过来。

## 5. 修复

没有明确的每帧 bug，**这一单不改代码**。可以留作候选的改动（等实测结果再定）：把 `MAKE_RESIDENT_EVERY` 默认改成 0，或者改成只在 `QueryVideoMemoryInfo` 报告我们的资源被降级时才调用。MakeResident 不配对 Evict，引用计数会无限累加（每秒 +1）。这本身无害，但语义上不干净。
