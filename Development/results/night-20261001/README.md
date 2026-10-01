# 夜间队列（2026-10-01 晚）

## 1. RE9 runtime 从 flags 文件读取 DLSS5_STYLE

- 改动：`src/LmxxfNrRuntime.cpp` 的 flags 白名单加 `DLSS5_STYLE`（一行）。RE9 模板注释、`scripts/CONFIGURATION.md`（含"集成方注意"）、CHANGELOG 中英"未发布/Unreleased"各一行。
- 构建：`scripts/build-runtime.sh`（钉基址）。同一脚本编改动前源码 = **DC2D445E**（与现装逐字节同，说明可复现）；改后 = **73D4C25C**。未装机。
- 回放（`rt9style.txt`，脚本 `Development/HIP/experiments/night-20261001/rt9style.ps1`，现装鬼武者 62 模块，rt_bench 1707x961 12 帧）：

| 用例 | 900 | 1080 |
|---|---|---|
| 旧 runtime 默认 / 新 runtime 默认 / 新 + 文件 STYLE=1 | b2980ada（三者 SAME，= 装机记录） | 758674a8（SAME） |
| 新 + 文件 STYLE=0 | 5c42d337 | b9ac12c0 |
| 新 + 环境变量 0 / 旧 + 环境变量 0 | 5c42d337 | b9ac12c0 |
| 旧 + 文件 STYLE=0（对照：旧白名单不读） | b2980ada（applied=0） | 758674a8 |

  smoke exit 0，SP errors=0。
- 与 add-on 路线 Style 0 的关系：环境变量路径就是 add-on 用的同一个 `StyleFeatureFromEnvironment` + `LoadModule` 写常量（`hip_reference_network.h`/`hip_api.h` 共用）；add-on 那边 Style 0 在 fidelity-ngx 输入上是 76915EC5（`rebuild-baseline` style-psnr）。rt_bench 与 bench_ngx 输入不同，哈希不能直接互比；这里证明的是"文件 0 ≡ 环境 0 ≡ 旧 runtime 环境 0"，而环境 0 与 add-on 是同一段代码。
