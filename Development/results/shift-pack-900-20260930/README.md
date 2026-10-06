# 去掉 900 档 C512 的 mh_shift_pack：宿主分配补齐 16 token，逐位通过，已装剑星＋鬼武者（2026-09-30）

**结论**：900 档 C512 网格 50×30=1500 token，不是 16 的倍数，`CompactC512Body` 每块先 `mh_shift_pack` 把 f32 特征拷进补零到 1504 token 的缓冲（13 次约 129µs）。改为**生产者直接分配 1504 token 的缓冲**（C256→C512 的 Down、decoder39 的 Up、每个 C512 块的输出），C512 块原地读输入，pack 消失。**只改宿主，不改任何模块**；宏 `HIP_C512_PAD16`（宿主，默认 1；0 = 旧路径）。1080 的 60×36 本来整除，分配大小不变、行为不变。

- 逐位：7 用例 × EXACT/AE × 12 帧逐帧 SHA 同、AE 决策 CSV 同；900/1080 history × EXACT/AE 强制票号回绕同；另把补齐行灌 NaN（`HIP_C512_PAD16_POISON=1`）再跑一遍全部用例＋回绕，仍全同。36 组 SAME、432 帧，无差。基线 = vit-qkv lab 的 benchmark-P.exe（剑星现装宿主 b77bbc3c 同源）＋剑星现装 31 模块。
- 整网 ABBA（A = 同源 `-DHIP_C512_PAD16=0`，P = 默认；同一套现装模块；1000 帧弃 200，A-P-P-A）：

| 轮 | 档 | 基线 ms | 候选 ms | 省 ms | 提升 |
|---|---|---:|---:|---:|---:|
| 1 | 900 | 8.030295 | 7.917743 | 0.112552 | **1.40%** |
| 1 | 1080 | 10.849617 | 10.840531 | 0.009086 | 0.08% |
| 2 | 900 | 8.030651 | 7.941734 | 0.088917 | **1.11%** |
| 2 | 1080 | 10.841452 | 10.852488 | −0.011036 | −0.10% |

900 省 0.09～0.11ms，与地图里 pack 的 129µs 对得上；1080 在噪声内（±0.1%）。

## 为什么天然逐位（补齐行是什么都不影响）

C512 块里所有核都是"按 token 行独立"：`split_mix_blocked_h16w_m32`/`split_ffn_fused_fp8_t8`/`split_projection_frag` 是 WMMA 的 A 行 = token，输出第 i 行只依赖输入第 i 行；`c512_qkv_attention_compact` 按 (x,y) 只读、只写有效像素；`mh_attention_project_frag_c512` 走 crop 分支，y≥h 的行直接跳过。所以补齐的 4 行即使是垃圾（缓冲池复用来的旧数据）也只流向补齐行、永不进有效输出。POISON 版把这 4 行每帧 memset 成 0xFF（NaN）实测全同，作为证据。

## 代码改动（`Development/HIP/hip_reference_network.h`，add-on 与 RE9 runtime 共用）

- `NewPad16(valid,ch)`：按 16 对齐分配，`bytes` 仍记有效大小（Stage 转储不变）。
- `CompactC512Body`：输入 `capacity ≥ n·512·4` 就原地用，不够（旧宿主路径/其它来源）照旧 pack——**自带回退**；输出改 `NewPad16`。
- `Down`（c==256 的 group 路径）、`Up`（oc==512 非 byte）输出改 `NewPad16`。
- 无新用户开关、无模块变化，旧模块照常可用。

## 装机

- 剑星：只换 add-on，flags 原样（DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、SWIN_RUN=1），31×2 模块/SHA256SUMS 不动。新宿主 **62803606**（`62803606a48da241329f973e004197f8f20884448e02b797844253e1dc2e06ce`）。备份 `D:\DLSSNR-Lab\hip-backend\shift-pack-900-20260930\backups\stellar-20260930-004205`。
- RE9 runtime **be828151**（`be8281515c39157a5fe468042f652da43070550ecf933e3073674271f3638689`）：旧 runtime 2c103f6e vs 新，同模块 900/1080 hash 同（b2980ada643da964 / 758674a8bbd0206d，与 09-29 相同），runtime-smoke 通过。
- 鬼武者：Content 与 `_storage_` 两份 runtime 换新，HIP 模块与剑星对齐（未变），备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-004205-shiftpack`。
- 没发包、没启动游戏。回滚：`install.ps1 -RestoreStellar <备份>` / `-RestoreOni <备份>`。

复现：`Development/HIP/experiments/shift-pack-900/`（build-hosts.sh → setup.ps1 → full.ps1 → runtime-check.ps1 → install.ps1）；lab `D:\DLSSNR-Lab\hip-backend\shift-pack-900-20260930`。日志 full.log。
