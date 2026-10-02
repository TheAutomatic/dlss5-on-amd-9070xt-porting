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
