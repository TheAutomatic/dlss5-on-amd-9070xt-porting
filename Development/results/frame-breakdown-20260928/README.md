# 剑星 1080 一帧时间账：我们 vs Daniel 0.5.0 reference（2026-09-28，分身）

结论先行：**"Daniel 整帧约 14ms、我们网络外多 1.5～2ms"这个判断不成立**，来自对他日志 slack 的误读（他贴 60 上限，呈现周期 16.7ms 不是真实帧时）。按现有数据自洽的账是：两边整帧差约 **1.1ms**，其中内核约 0.65ms、网络外流水线约 0.45ms。游戏内的最终确认需 Zero 做一次 F6 对照（见末节）。

## 数据来源

- 我们游戏内：`frame-stats.txt` 15:48（float FMA 版，站立）avg 17.61ms / 56.8fps；pre-upscale 日志 `async=1`、`history_reset=1`（Stellar 路径不喂时序历史）。
- 我们离线：本轮 `replay.ps1`（NativeGameFrame 完整回放 = 编码 + 桥接 + HIP 网络 + 解码 + 拷贝，现场剑星 30 模块与 flags，1080 档 1920×1152，600 帧弃前 200）**wall 12.32 / 12.36ms**。09-27 `tier900` 纯 HIP：1080 GPU 跨度 12.08、wall 12.45（0.35 模块）；此后第五刀 −0.8%、ACO 两刀 −0.75%、FMA −1.2%，推算纯 HIP 网络现约 **11.75ms**。
- Daniel 0.5.0 reference：`network 11.0～11.1ms`（其 HIP 计时）、游戏队列 `spin waiting on us 11.1`、`capture copies 0.02`、`residual copy+apply 0.09`，inline 同帧、输入输出零拷贝。
- `DLSS5_HIP_SPAN_PROBE` 在当前 benchmark 构建里未输出，`DLSS5_GAME_PROBE` 回放未落日志（且 DevHistory 记录它每帧 Flush 会破坏游戏内异步时序），本轮没用它们。

## 时间账（1080，每帧）

| 项 | 我们 | Daniel reference | 差 |
|---|---:|---:|---:|
| 网络 GPU | ≈11.75（推算） | 11.1 | ≈0.65 |
| 网络外 NR 流水线 | ≈0.55（12.32 回放 − 11.75） | ≈0.11 | ≈0.45 |
| NR 总开销 | ≈12.3 | ≈11.2 | ≈1.1 |
| 游戏自身 G（含 FSR） | 17.6 − 12.3 ≈ 5.3（假设游戏内=离线） | 同一游戏 | 0 |
| 整帧 | 17.6（56.8fps） | ≈16.5（≈60.6fps，被 60 上限截住） | ≈1.1 |

用同一个 G 反推 Daniel 整帧 ≈16.5ms，与"他稳定贴 60、我们 57"一致；不需要假设额外的神秘开销。

## 结构对照（代码：`src/native_pre_upscale.h` Process、`src/native_game_frame.h` ProcessSubmittedFrame、`Development/HIP/hip_d3d12_bridge.h`）

| 环节 | 我们 | Daniel |
|---|---|---|
| 输入 | 游戏颜色 → 私有 `low` 纹理整拷（16.6MB FP16）；encode pass 写 RGBA32F（1920×1152×16B≈35MB）；桥接 `CopyBufferRegion` 再拷进 HIP 共享缓冲（≈35MB 读+写） | inputs shared zero-copy |
| D3D→HIP | 游戏队列 Signal 共享 fence → HIP `WaitExternalSemaphores` | 标志位 + GPU 侧轮询 |
| HIP→D3D | HIP `SignalExternalSemaphores` → 游戏队列 `Wait`（队列挂起，经 OS 调度器唤醒） | 游戏队列 predicated spin draw 轮询标志（不经调度器） |
| 输出 | decode pass（读 26.5MB 网络输出 + 原图，写 FP16）→ `CopyTextureRegion/CopyResource` 回 `low`；FFX 读 `low` | output shared zero-copy，residual copy+apply 0.09ms |
| 每帧附加 | fps 叠字；`DLSS5_MAKE_RESIDENT_EVERY=60`（CPU 侧每 60 帧 MakeResident） | — |

按 640GB/s 粗估我们多出的纯拷贝约 0.2～0.3ms（颜色整拷 ≈0.05、输入二次拷 ≈0.11、输出回拷 ≈0.05，外加 encode/decode 自身），与回放差 0.55ms 同量级；余下是两次跨 API 交接的队列空泡。

## 可做项（逐位对网络输出不变，按收益排）

1. **内核 ≈0.65ms**：Daniel reference 是 PTX 算术，与我们同类；0.5.0 相对 0.4.0 的 +5% 来自寄存器布局（去 scratch 溢出、mov/打包/夹紧大减，C32 VALU 2433→1830，见 `results/daniel-050-20260928`）。继续闇的逐段对齐路线。
2. **输入零拷贝 ≈0.1～0.15ms**：encode 直接把 UAV 写进桥接共享缓冲（省 `RecordInput` 的 35MB 二次拷贝）；可进一步让 encode 直接读游戏颜色，省 `low` 整拷（需确认 FFX 回放前颜色未被改写；async 路径下颜色被后续帧复用的风险要看 Cyberpunk quirk）。纯数据搬运，输出应逐位。
3. **输出少一次拷贝 ≈0.05～0.1ms**：decode 直接写 `low`（或把 FFX 的颜色输入换成 decode 输出本身），省回拷。
4. （待测，可能 0.1～0.3ms）**HIP→D3D 交接改 GPU 侧轮询**：Daniel 专门做了 spin draw，说明 OS 调度器唤醒有可见延迟；这项涉及看门狗与抢占（他注释：纯 compute spin 会触发 GPU 看门狗），不是小改动，先测交接空泡大小再定。

本轮未改代码、未装机。

## 要 Zero 做的一次确认（约 2 分钟）

目的：量出游戏自身 G，确认"游戏内 NR 开销 = 离线 12.3"。

1. 剑星照常（1080P 窗口、FSR 原生 AA、EXACT），`DLSS5_FRAME_STATS=5` 已开；**在 9070 本机**（Splashtop 会吃 GPU）。
2. 站立不动 30 秒（NR 开）。
3. 按 **F6**（切到游戏原生 FSR 直通，黄字状态会变），保持站立 30 秒。
4. 再按 F6 切回，退出游戏。

日志 `DLSS5-AMD\logs\frame-stats.txt` 里 `bypass=284` 的窗口就是 G。若 17.6 − G ≈ 12.3，上面的账成立；若明显大于 12.3，差额就是游戏内特有开销（交接空泡、MakeResident 等），再按第 4 项查。

另注：15:48 那段站立数据 p99≈30ms（约每 5 秒 3 帧），早上站立 p99=max≈18.5。可能是 Splashtop，也可能是 `MAKE_RESIDENT_EVERY=60`；F6 测试时本机看 p99 即可分辨。
