# MAKE_RESIDENT_EVERY 周期尖峰测试（2026-09-29，离线回放）

## 方法
- 回放路径：`frame-breakdown-20260928/replay.ps1` 同款（`benchmark.exe` -> `NativeGameFrame::ProcessSubmittedFrame`，剑星 30 模块与 flags，1080 档，`DLSS5_BENCH_PLAIN=1`）。`native_game_frame.h:368` 的 `DLSS5_MAKE_RESIDENT_EVERY` 就在该函数里，回放会走到（benchmark.exe 内含该变量名；环境变量与 flags 文件同时设置）。
- A/B/A/B = 60、0、60、0，每轮 1200 帧，丢弃前 200，取 1000 帧；每帧 `wall_ms`（含 CPU 侧 MakeResident，逐帧 Flush 同步，所以 CPU 阻塞会直接算进去）。
- 未动任何游戏文件，产物在 `D:\DLSSNR-Lab\resident-spike-20260929\`。脚本 `run.ps1`，分析 `analyze.py`，原始 csv 同目录。

## 结果（ms）
| 轮 | every | avg | p50 | p99 | max | 帧号%60==0 的均值 | >中位+3ms 帧数 |
|---|---:|---:|---:|---:|---:|---:|---:|
| A1 | 60 | 12.055 | 12.060 | 12.279 | 12.45 | 12.063 | 0 |
| B1 | 0 | 12.128 | 12.098 | 12.392 | 28.84 (帧857, %60=17) | 12.112 | 3 |
| A2 | 60 | 12.175 | 12.170 | 12.423 | 12.65 | 12.190 | 0 |
| B2 | 0 | 12.229 | 12.165 | 12.891 | 13.14 | 12.348 | 0 |

## 结论
- 开 60 与关 0 没有可见差异：60 两轮无任何 >3ms 的尖峰，周期位置（60 的倍数附近）上的帧也不比其他帧慢（+0.01～0.02ms 以内）；唯一的大尖峰（28.8ms）出在 every=0 那轮，且不在 60 倍数上，是随机噪声。avg 的差异（0.07～0.12ms）在 A1/A2 之间的漂移（0.12）量级内，A/B 顺序无方向性。
- 所以"MakeResident 每 60 帧造成 ~30ms 尖峰"在离线回放里不成立。
- 局限：回放里被追踪（tracked）的资源集合比游戏内小，`NativeMakeAllResident` 的耗时未单独计时；游戏内显存吃紧、资源被 OS 降级时，MakeResident 可能更贵，这是回放测不到的。

## 建议
- 15:48 站立数据里 p99≈30ms（约每 5 秒 3 帧）的来源不是它的第一嫌疑；更像 Splashtop/系统噪声（回放里同样能出一次随机 28ms 尖峰）。
- 游戏内确认（Zero 在机时，约 3 分钟）：本机（非 Splashtop）站立 60 秒记 `frame-stats.txt`（every=60），再把 `native-game-flags.txt` 的 `DLSS5_MAKE_RESIDENT_EVERY=0` 重进游戏站立 60 秒，对比 p99/max；若两边尖峰同频（约 5 秒）就与它无关。别为它改默认值，pinned 资源被降级的问题（见 `native_pinned_resource.h` 注释）才是它存在的理由。
