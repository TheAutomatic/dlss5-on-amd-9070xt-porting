# 网络外面那一圈（outside-net，2026-10-02）：拆账 + runtime 输入直写（收）+ 输出信号后 hipStreamQuery（过线，宏默认 0 待定）

**结论先行**
- 网络外面那一圈在 GPU 上每帧只有 **0.35～0.5ms**（1080 档）：D3D pass 约 0.12（add-on）/ 0.33（ABI 改前）ms，跨队列交接约 0.15～0.3ms。串行宿主（每帧 CPU 等 GPU）再多 CPU 录制/发核/唤醒约 0.1～0.25ms。**wall − span 那 0.5ms = D3D pass 0.12 + 交接 ~0.2 + CPU 侧 ~0.15**。
- **ABI 路径比 add-on 多一次 35MB 拷贝**：runtime 一直没用 DIRECT_IO，`RecordInputs` 的 GPU 段 1080 档 0.22ms（add-on 同段 0.05ms）。已改：runtime 输入直写（`DLSS5_DIRECT_IO` bit 1，默认 1，同 add-on）→ 0.08ms。逐位、流水线 ABBA 六轮全快（1080 −0.07～−0.08ms），串行中性。**收，进 main，未装机**。
- 候选 Q（HIP 输出 signal 后一次非阻塞 `hipStreamQuery`，宏 `DLSS5_HIP_POST_SIGNAL_QUERY`）：add-on 19 组 SAME、ABBA 六轮全快（900 −0.01～−0.10、1080 −0.05～−0.12ms，合并 p99 两档都好）；runtime 串行 900 −0.03～−0.07、流水线中性。**按派单"新宏默认 0"留 0，等光拍板**（机制是 Windows HIP 批次提交时机，属驱动行为）。
- TheAutomatic 的 "1080 约 17ms" 是他机器负载下的 **GetTimings 本身**（他的文档：Final runtime 1080 PDL1 median 18.56、PDL0 17.20），不是网络外一圈；我们这边同一读数约 9.2～9.3ms。差的是 GPU 被别的负载抢，不是交接。

## 1. 拆账（1080 档；900 档见原始日志 `probe-p1.txt`，ms，中位数）

工具：add-on = bench 宿主 `DLSS5_GAME_PROBE=1`（D3D 段时间戳，每帧 Flush）+ `DLSS5_HIP_SPAN_PROBE=1`（hipEvent 网络段 + CPU 发核时间）+ 不带探针的 wall；ABI = 新宿主 `rt_outside`（RecordInputs/RecordOutputs 两侧 D3D 时间戳、CPU QPC 七个点、GetTimings、GetClockCalibration）。GetClockCalibration 在这台机器上有约 3ms 常数偏移，所以"发射延迟"和"唤醒延迟"只报两者之和（偏移相消）。

| 段 | add-on（bench） | ABI 改前（rt-base 串行） | ABI 改后（rt-D 串行） | ABI 流水线（3 帧在飞，改前→改后） |
|---|---:|---:|---:|---:|
| CPU 录制（PrepareFrame + Record*） | —（含在 wall） | 0.048 | 0.046 | 同 |
| D3D 输入段（encode + RGB 输入 [+ 35MB 拷贝]） | 0.015 + 0.033 = 0.048 | **0.220** | 0.084 | 0.220 → 0.084 |
| 交接 D3D→HIP→D3D（gap − 网络） | ≈0.12～0.19 | 0.21～0.24 | 0.27～0.31（见注） | 含在 gap 9.36～9.37 |
| HIP 网络 | span 9.46～9.53 | 9.31 | 9.34 | — |
| D3D 输出段（neural + decode [+ copy]） | 0.022 + 0.044 + 0.008 = 0.074 | 0.109 | 0.114 | 0.11 |
| 发射 + 唤醒延迟（串行才有） | ≈0.13 | ≈0.18 | ≈0.18 | 0（不等） |
| CPU `EnqueueHip`（发 ~150 核，与 GPU 重叠） | 0.32～0.34 | 0.32～0.36 | 0.34～0.40 | 0.31～0.38 |
| **整帧** | wall 9.86～9.90 | wall 10.10 | wall 10.09 | 帧间隔 9.71 → 9.57 |

注：串行宿主里改后交接"变大"是因为输入段缩到 0.08ms，而 HIP 要等 CPU 把核发完（约 0.3ms）才开跑，省下的 GPU 时间被 CPU 发核吃掉；流水线（游戏真实形态，CPU 跑在 GPU 前面）没有这个问题，帧间隔直接省 0.14ms。

**wall 和 span 差的 0.5ms（add-on 1080）**：D3D pass ≈0.12、交接 ≈0.15、发射+唤醒+bench 空提交 ≈0.13，其余是 SPAN 与 wall 不同次运行的波动。**ABI 比 add-on 多的**：35MB 拷贝（0.17ms GPU）；输出段多 0.035ms（decode 输出路径/格式不同）；其它一样。

**游戏内（Zero，剑星 2K 原生 AA，1080 档，GAME_PROBE，111 个窗口）**：encode 21、input 55、network 9440、neural 58、decode 121、copy 0（DIRECT_IO bit 2）µs，GPU 合计 ≈9.69ms，网络外 GPU 段 ≈0.25ms；cpu_frame 12.9ms。游戏内 pass 比离线大约 2 倍（与游戏渲染争用 + 每帧 Flush 让 pass 冷启动），但量级仍只有 0.25ms。**GAME_PROBE 每帧 Flush，量不到交接等待和与游戏渲染的重叠**——不 Flush 的测法见 §4。

## 2. 可压缩点（按收益）

| # | 点 | 收益 | 状态 |
|---|---|---|---|
| 1 | ABI 输入直写（去 35MB 拷贝） | GPU −0.14ms/帧（1080），−0.045（900） | **收**（逐位，流水线六轮全快） |
| 2 | 输出 signal 后 hipStreamQuery（催 HIP 提交） | add-on 串行 −0.01～−0.12ms；runtime 流水线 0 | 过线，宏默认 0，待定 |
| 3 | 交接 fence 往返 | ≈0.165ms 下限 | 不做（same-queue 已证只能同队列消掉） |
| 4 | CPU 发核 0.3ms | 只在串行宿主或 GPU 空闲时露出来 | 不做；文档让集成方保持流水线 |
| 5 | 输出解码与下一帧重叠 | 0：解码依赖本帧网络输出，下一帧的输入段本来就在同一 GPU 队列上排着，流水线下已无空泡 | 不做 |
| 6 | Signal/Wait 次数 | 已是每帧一次往返（最少） | — |
| 7 | 每帧重复建资源 | 查过：PrepareFrame 稳态无建资源、无等待（只在尺寸/格式/曝光/指针变化时重建或 drain） | — |
| 8 | Poll/Retire 设计 | Poll 只报 CPU 状态、Retire 不等 GPU，不逼串行；**但上一帧没 Retire 就 PrepareFrame 会 DrainGpu**（CPU 等空 GPU）——写进文档 | 文档 |
| 9 | IO_FUSE（neural 并进 decode） | add-on −0.015～−0.024 | 旧账，p99 不过，不动 |

文档问题：仓库里原本没有给集成方的调用顺序说明，头文件只描述单个函数；RE9 宿主（TheAutomatic 1.9.0）本身的顺序是对的（拆分列表、Between 钩子里 EnqueueHip、紧接着提交后半、Retire），他的 harness 在每帧等完队列后再读 GetTimings 只是测试写法。新写 `include/LmxxfNrApi-call-order.md` / `.zh-CN.md`，头文件首行指过去。

## 3. 候选验证（lab `D:\DLSSNR-Lab\hip-backend\outside-net-20261002`，GPU 锁 + guard 看门狗，`validate-v1.txt`）

- runtime 哈希（rt_bench 1707×961 × 720/900/1080 + rt_outside 1600×900/1920×1080）：base A9BA5502 / D 0FAD1343 / DQ D9E5BC07 / D 加 `DLSS5_DIRECT_IO=0` 全部 SAME（720 88106a93、900 b2980ada、1080 758674a8 = 装机记录）。smoke D、DQ exit 0、errors=0。
- runtime ABBA（base,cand,cand,base ×3，400 帧；串行 = rt_bench mean wall，流水线 = rt_outside 帧间隔中位）：
  - D：串行 900 −0.008/−0.005/+0.002、1080 −0.008/+0.023/+0.021（中性）；**流水线 900 −0.037/−0.034/−0.044、1080 −0.077/−0.068/−0.077**。
  - DQ：串行 900 −0.066/−0.059/−0.034、1080 −0.003/−0.015/+0.011；流水线 900 −0.024/−0.017/−0.009、1080 −0.071/−0.063/−0.072（≈D）。
- add-on Q（benchmark-Q vs base，full.ps1，-PinIdle）：**19 组 SAME**；ABBA 900 −0.014/−0.102/−0.083、1080 −0.058/−0.117/−0.046；合并 900 7.154→7.087 p99 7.832→7.708，1080 9.948→9.874 p99 10.609→10.535。
- 判 D 收的口径：整帧 wall。串行宿主每帧等 GPU，不是游戏形态，且在噪声内；流水线宿主是整帧间隔，六轮全快。

## 4. 游戏内不 Flush 的测法（给 Zero）

GAME_PROBE 每帧 Flush，只能给"各 pass 多大"。网络外真正的成本（交接等待、与游戏渲染的重叠损失）只有在不 Flush 的帧时间里才看得到。做法是用 `DLSS5_FRAME_STATS` 的帧间隔，开/关 NR 做差：
1. 关游戏。`powershell -File D:\DLSSNR-Lab\hip-backend\outside-net-20261002\ingame-probe.ps1 -Mode stats`（自动备份 flags，加 `DLSS5_FRAME_STATS=5`）。
2. 剑星本机，2K 原生 AA、EXACT，站同一位置不动：NR 开 30 秒，按 F6 关 NR 30 秒，再按 F6 开 30 秒。退出。
3. 读数：`frame-stats.txt` 每 5 秒一行，带"network ran / bypassed"计数。NR 开窗口的帧间隔均值 − F6 关窗口 = NR 在游戏里的**全部**代价（不 Flush、含交接和重叠）。减去 GAME_PROBE 的网络 9.44ms（或离线 GetTimings ≈9.3ms）= 网络外一圈的真实成本。
4. （可选，已做过）`-Mode probe` 再跑一次 GAME_PROBE 拿分段。
5. `-Mode restore` 还原 flags，日志拷到 `D:\DLSSNR-Lab\outside-net-ingame\<时间>\`。
注意：游戏若 CPU 受限（GAME_PROBE 那次 cpu_frame 12.9ms > GPU 9.7ms），差值会被 CPU 掩盖一部分；站在 GPU 重的场景、帧率不锁。

## 5. history=0 reset=100 是设计，不是 bug

剑星走 pre-upscale 路径：`native_pre_upscale.h` 调 `OnSubmitted(..., reset=true, ...)`（注释 "reset=true means the network never samples motion/history in this prototype"），one-shot 只有 lab 根目录存在 `temporal-history.txt` 才建时序配置（`native_game_oneshot.h:71`）。README "How it works" 也写明：网络自己的时序历史每帧重置，时间累积交给后面的 FSR。所以 `use_history = r.temporal && motion && !reset && HasHistory()` 恒为 false，与 GAME_PROBE 的 Flush 无关、与 EXACT 无关（nomotion=0 说明运动向量正常传进来了，只是不用）。画质：NVIDIA 在此路径同样逐帧独立推理，时序稳定性由 FSR 负责，没有损失；性能：不跑 history/sampler/smooth 几个 pass，反而更省。

## 文件
- 代码：`src/LmxxfNrRuntime.cpp`（`RuntimeDirectInput()`，两处 `RequestDirectInput`，`RedirectOutput`，flags 白名单加 `DLSS5_DIRECT_IO`）；`Development/HIP/hip_d3d12_bridge.h`（`DLSS5_HIP_POST_SIGNAL_QUERY`，默认 0 不编译，宏 0 与改前代码同）；`include/LmxxfNrApi.h` 首行注释；`include/LmxxfNrApi-call-order{,.zh-CN}.md`；CHANGELOG 中英（集成方注意）；`scripts/CONFIGURATION.md`。
- 工具：`Development/HIP/experiments/outside-net/`（rt_outside.cpp、setup/probe/rt/go.ps1、guard.sh、ingame-probe.ps1）。
- 原始：`probe-p1.txt`（两轮拆账）、`validate-v1.txt`（哈希/ABBA/smoke/19 组）、`addon-game-probe-offline.txt`、`game-probe-stellar-20261002.txt`（Zero 游戏内）。
- 未装机、未打包；游戏文件没动。
