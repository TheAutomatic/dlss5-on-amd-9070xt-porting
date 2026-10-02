# 网络 GPU 耗时接口（net-timing，2026-10-02）

起因：TheAutomatic 在 OptiScaler 集成里叠字 "NR GPU: 2～3 ms"。只读排查结论：ABI 里原本**没有**耗时接口，他用的是自己的 D3D12 时间戳；网络跑在 HIP 流上，夹在 RecordInputs/RecordOutputs 列表里的时间戳只量到 D3D12 那几个 pass。本单把整网 HIP 时间正式暴露出来。**没装机**（留到下一版）。

## 改动
- `Development/HIP/hip_d3d12_bridge.h`：4 槽 hipEvent 环，打点位置同 SPAN_PROBE（等完生产者之后、通知消费者之前）；下一次 Enqueue / Poll 时只用 hipEventQuery 收割，绝不同步；槽占满就这一帧不计时；任何 HIP 错误只关计时、不影响帧。默认关，`EnableNetworkTiming()` 或 `DLSS5_NET_TIMING=1` 打开。
- `include/LmxxfNrApi.h`：`LmxxfNrTimings{struct_size, valid, network_ms, reserved, frame_id}`；函数表末尾 `GetTimings`；`LMXXF_NR_API_V1_SIZE=136`。ABI 版本号不变。
- `src/LmxxfNrRuntime.cpp`：GetApi 接受 136（旧宿主，不写 GetTimings 槽）和新大小；GetStatus 追加 `net_gpu_ms=X.XX (frame N)` / `n/a` / `off`；Job 记 frame_id 作标签；**第一次 GetTimings 才开始记 event**（见 ABBA），HIP 重建后保持。GetTimings 成功时不碰错误槽（不吞 PrepareFrame 留给宿主的提示）。
- `src/native_hip_network.h`：add-on 侧透传（共用桥接代码，不开计时）。
- 文档：CHANGELOG 中英 Unreleased（集成方注意）、CONFIGURATION `DLSS5_NET_TIMING`。

## 构建（钉基址）
| 件 | 哈希 |
|---|---|
| runtime main（改前） | 73D4C25C（= 现装，可复现） |
| runtime 常开版（第一轮） | 338F3714 / 61BAFD2A（后者只改错误槽，代码同） |
| runtime 最终（懒开启） | **3103A0A7** |
| add-on main / 新 | 053C3589（= 现装）/ 15CCBA82（计时代码在但不开） |
| bench 宿主 base / T | FD276ADF / 91A66EDF |

## 验证（lab `D:\DLSSNR-Lab\hip-backend\net-timing-20261002`，现装 62 模块，GPU 锁 + guard.sh 看门狗）
**add-on 路径（`go-T-E.txt`，next-candidate 同一 harness，idle 钉住）**
- T = 新宿主默认（计时关）：**19 组 SAME**；ABBA 900 −0.004/−0.009/−0.027，1080 +0.019/+0.004/+0.010，合并 p99 900 7.387→7.336、1080 10.184→10.174。噪声内。
- E = 新宿主 + `DLSS5_NET_TIMING=1`（每帧记 event）：**19 组 SAME**；ABBA 900 +0.007/+0.012/−0.008，1080 −0.011/+0.035/−0.000。噪声内（harness ±0.03）。

**RE9 runtime（`rt.ps1`）**
- rt_bench（旧头文件编 = 旧宿主传 136）old/new 与 rt_timing（新头文件）三者：900 **b2980ada** SAME，1080 **758674a8** SAME（= 装机记录）。
- runtime-smoke exit 0，SP errors=0。
- 常开版 rt ABBA（`rt-alwayson.txt`，old,new,new,old×3，400 帧）：900 +0.043/+0.048/+0.051，1080 +0.013/+0.034/+0.102 —— **六轮全慢**。按规则改成懒开启。
- 懒开启版（`rt-lazy.txt`）：900 −0.021/−0.003/+0.022，1080 +0.012/−0.011/−0.014 —— 中性。状态行 `net_gpu_ms=off`。
- add-on E 组不慢、runtime 常开慢，没追到原因（rt_bench 每帧 CPU 等 GPU，event 开销可能在 CPU 提交侧更显眼）；懒开启后无关。

**rt_timing（ABI + 读数）**：旧大小 OK 且不越界写；错大小拒绝；GetTimings 参数检查；首帧前 valid=0；每帧 EnqueueHip 后立即读，必须是上一帧的 frame_id —— 三档各 400 帧 lag_mismatch=0。

| 档（输入 1707x961） | network_ms 中位（min–max，后 300 帧） |
|---|---|
| 720 | **4.66**（4.48–4.89） |
| 900 | **6.53**（6.24–6.83） |
| 1080 | **9.24**（8.97–9.54） |

720 档以前没单独测过，这次补上：约 4.7ms。2～3ms 不是任何一档的整网时间。

## 已知瑕疵
偶有单帧明显偏短：(重)建后第一帧 2.6～3.1ms（现有 `DLSS5_HIP_SPAN_PROBE` 也有同样现象，是 HIP 侧行为），常开版运行中另见过 2.93ms、0.05ms 各一次（约 1/1200）。对照：同时开 SPAN_PROBE 跑 4×400 帧，除首帧外两边都无异常值。根因没查清；头文件和 CHANGELOG 已写明"显示时取几帧中位数"。

脚本：`Development/HIP/experiments/net-timing/`（setup/go/rt.ps1、guard.sh、rt_timing.cpp）。

## 第二单：TheAutomatic 报 PDL=1 下 GetTimings 连续几帧 ≈0.001ms（未复现，未改代码）

结论：**在 lab 里没能复现他的现象**；试的两种"修法"都比现行版本（main fe4d1d73，hipEventQuery 收割）更差，已全部撤回，桥接代码不变。只提交了排查工具。

复现尝试（全部 PDL=1、SWIN_RUN=1，三个模板 `scripts/hip-{game,magpie,re9}-flags.txt`，`pdl.ps1`）：
- runtime，现行 DLL（3103A0A7）：串行宿主 720/900/1080 各 400 帧、**流水线宿主**（`rt_timing` 新加 `RT_PIPE=1`：不逐帧等 GPU，3 帧在途，每帧读两次 + GetStatus）三模板 × 720/900/1080 各 1000 帧 → 无 <1ms 读数，帧号滞后检查全过（`pdl-repro-search.txt`）。注意 1080 档 PDL 实际不生效（状态 `pdl=1/0`），720/900 生效（`1/1`）。
- add-on 路径（bench 宿主，诊断打印版，三模板 900 × 300 帧）：不开 SPAN_PROBE 时干净。
- **唯一见到 ≈0.0004ms 的情形：同时开 `DLSS5_HIP_SPAN_PROBE=1`**（同一流上两对 event，探针每帧 hipEventSynchronize）：前 ~16 帧里大量 0.0004，之后正常；PDL=0 时一样（`pdl-v1v2-spanprobe.txt`、`pdl-repro-search.txt` sp 段）。探针自己同期也有 −37ms、1245ms 这种怪值。和 PDL 无关，和他的现象不是一回事——除非他那边也开了 SPAN_PROBE 或别的 event 探针。

试过的修法（都撤回）：
| 版本 | 改法 | 结果 |
|---|---|---|
| v3 | end event 前插普通顺序 4 字节 hipMemsetAsync（协调者思路 1）+ 改用 D3D 共享栅栏判完成后 hipEventSynchronize 收割 | E 组 ABBA +0.11～+0.16ms 六轮全慢；串行 1080 400 帧 45 帧 <2ms（低至 0.005）；19 组 SAME（`pdl-v3-memset-fencegate.txt`） |
| v4 | 只留栅栏判完成 + hipEventSynchronize，去掉 memset | E 组仍 +0.11～+0.17ms；串行 1080 52 帧偏短、帧号滞后 39 次（`pdl-v4-fencegate.txt`） |
→ 现行版（hipEventQuery 判完成）在同样测试下更干净、不慢。说明问题在 HIP event 完成状态/时间戳的读法上很敏感，但我们这边的组合触发不了他的那种。

需要他提供：runtime 文件哈希（是哪次编的）、Adrenalin/HIP 版本、游戏分辨率与网络档（状态行 `net=`）、调用 GetTimings 的位置/线程/频率、flags 文件全文、是否开了 SPAN_PROBE 或别的 HIP 探针、0.001 出现在启动后多久、持续多少帧。

工具：`Development/HIP/experiments/net-timing/pdl.ps1`（runtime + add-on，三模板，可选 SPAN_PROBE/流水线/额外 flags 行；add-on 段依赖桥接的 `DLSS5_NET_TIMING=2` 打印，那是 v2～v4 里的诊断代码，现行桥接没有，需要时临时加）、`lockrun.ps1`、`rt_timing.cpp`（`RT_PIPE=1`）。

## 第三单：并入 TheAutomatic 的修法（record(end) 后立刻非阻塞 query end）

他的定位：独立后台 D3D12/HIP harness 下读数连续塌成 ~0.001ms，PDL 开关都塌；`hipEventRecord(end)` 后、外部输出 signal 前立刻 `hipEventQuery(end)` 一次（success / NotReady 都收）即修好。工作解释：Windows HIP 延迟提交/物化事件批次。

**改动**：`Development/HIP/hip_d3d12_bridge.h` `TimingEnd()` 加一次 `timing_query(timing_end[k])`，非 0 且非 600 才关计时；无同步、无轮询、无新 GPU 依赖。add-on 与 runtime 共用这份桥接，一处覆盖。

**复现（成功）**：`rt_timing` 加 `RT_AFTER_WAIT=1`，按他的顺序：首帧前 GetTimings 一次；每帧 EnqueueHip → 执行输出列表 → 等队列 → GetTimings → Retire（串行 ABI1 宿主）。我们之前没塌，是因为 rt_timing 在 EnqueueHip 后立即读（读的是 N-1）。1000 帧，"塌" = 原始 ms < 0.01：

| 档 | 旧 PDL1：塌 / <1ms / 中位 | 旧 PDL0 | 新 PDL1 | 新 PDL0 |
|---|---|---|---|---|
| 720 | 0 / 0 / 4.78 | 1 / 1 / 4.80 | 0 / 0 / 4.77 | 0 / 0 / 4.81 |
| 900 | 1 / 4 / 6.61 | 0 / 2 / 6.64 | 0 / 0 / 6.62 | 0 / 0 / 6.65 |
| 1080 | **70 / 701 / 0.093** | **92 / 806 / 0.078** | 0 / 0 / 9.28 | 0 / 0 / 9.29 |

旧版另一个现象：队列已等完，GetTimings 仍拿不到本帧（lag_mismatch 998～1000/1000，只能拿到 N-1）——end event 在 GPU 做完后仍不被视为完成，和"批次没物化"的解释一致。新版 1000/1000 拿到本帧，lag 0。默认顺序（EnqueueHip 后立即读）新版三档 lag 0、0 塌。输出哈希新旧一致（720 88106a93 / 900 b2980ada / 1080 758674a8）。

**回归**（lab `net-timing-fix-20261002`，GPU 锁 + guard 看门狗，`fix-go.txt`）：
- add-on T（计时关）：**19 组 SAME**，ABBA 合并 900 7.120→7.132、1080 9.937→9.930，中性。
- add-on E（`DLSS5_NET_TIMING=1`）：**19 组 SAME**；ABBA 900 +0.058～+0.091、1080 +0.107～+0.151ms，**六轮全慢**（修前 E 组是中性）。即每帧那次 query 本身有成本（推测就是它促使 HIP 提前提交批次）。计时是诊断/懒开启功能，按派单照收。
- RE9 runtime 720/900/1080 old/new SAME；rt_bench（不调 GetTimings = 永不开计时）ABBA 900 +0.003/−0.002/+0.028、1080 +0.003/−0.005/+0.013，中性；smoke exit 0，SP errors=0。

运行时 old 77A35681（main 583037df）/ new A9BA5502；bench base 9F5BF87E / T 582DB1C9；rt_timing D0B90B40。未装机。脚本 `Development/HIP/experiments/net-timing-fix/`。
