# 快速数值路径做成运行时选项 `DLSS5_FAST_NUMERIC`（2026-10-03，光派单，Zero 已批）

**结论先行**：新配置项 `DLSS5_FAST_NUMERIC=0/1`，默认 0，add-on 和 RE9 runtime 都读。=1 时宿主改装 `c32-wave1-fast` / `c64-wave2-fast` 两个模块（`CW_FAST_NUM 3` / `W2_FAST_NUM 3`，即 fast-tier 的 CF+MF）。默认 0：19 组 SAME，RE9 回放 SAME，ABBA 中性。=1：900 −0.07～−0.13ms、1080 −0.09～−0.10ms，对逐位版最差帧 51.83 dB、各 case 均值 53.07～55.46 dB；对 NVIDIA（Style 0）几乎不变：跳块 44.26→44.23，全 71 块 47.43→47.55 dB。已装剑星和鬼武者（默认关）。

## 1. 实现

- **多模块，不用多导出**：做法照搬 RTZ_TALL。配方 `hip/build-modules.ps1` 加两行 `c32-wave1-fast`、`c64-wave2-fast`，分别等于 `c32-wave1`、`c64-wave2` 那两行再加上 `CW_FAST_NUM 3`、`W2_FAST_NUM 3`，同样用 LLVM23 预编（行选项和 `l23defines` 照旧）。导出名一个不改，调用点也不动（两架构的导出符号表与正常版逐个相同：c32 48 个，c64 232 个）。
- **没做 `c32-wave1-rtz-fast`**：编出来以后，两架构反汇编和 `c32-wave1-fast` 逐条相同。原因是 `CW_FAST_NUM` bit0 让 Hrtz 变成恒等，`HIP_C32_RTZ_ISA` 就没东西可改了。所以 =1 时每一档（含 1080 的两种行数）的 C32 都用 `c32-wave1-fast`，不另发一个内容相同的文件。
- **宿主**（`Development/HIP/hip_reference_network.h`）：新函数 `FastNumericFromEnvironment()`。未设、空、`0` → 关；`1` → 开；其它值往 stderr 写一行，按 0 处理。在 wave_owned 模块装载处：先照旧按几何定 `c32-wave1` 或 `c32-wave1-rtz`，=1 时再把 c32 换成 `c32-wave1-fast`、c64 换成 `c64-wave2-fast`。`-fast` 文件不存在就退回正常模块，并往 stderr 写一行 `DLSS5_FAST_NUMERIC=1: X-fast.hsaco missing, using Y.hsaco`。默认路径比现装宿主只多一次 `getenv`，不多做文件检查。
- **RE9 runtime**（`src/LmxxfNrRuntime.cpp`）：flags 文件白名单加 `DLSS5_FAST_NUMERIC`。add-on 本来就把 flags 里所有 `DLSS5_*` 都放进环境变量，不用改。
- 网络创建时读一次，不热重载。

## 2. 默认 0：逐位与速度

- **路由探针**（`route.ps1`；`flat-X` = 现装 + 两个垃圾 `-fast` 文件，`flat-Y` = `flat-F` 里只把 `c32-wave1-fast` 换成垃圾文件）。720/900/1080/1080@1088 四种几何：
  - 主线宿主（未设）、新宿主（未设、=0）在 flat-X 上全部正常跑完，输出哈希两两相同。这说明默认路径从不打开 `-fast` 文件。
  - 新宿主 =1 在 flat-X 上，四种几何都在 `c64-wave2-fast.hsaco` 报 hipErrorInvalidImage；在 flat-Y 上，四种几何都在 `c32-wave1-fast.hsaco` 报这个错（1080 也一样，说明 fast C32 取代了 rtz 那份）。
  - 新宿主 =1 在 flat-A（没有 `-fast` 文件）上正常跑，stderr 有退回日志，输出与主线宿主逐位相同。
- **19 组 SAME（-PinIdle）**：候选 = 新宿主 + flat-F（现装 + 两个 fast 文件）、选项未设；基准 = 主线 64d9cfde 宿主 + 现装。第一次跑时，AE 批的 720-motion 有 1/12 帧不同（frame 1；两边 AE 决策 csv 完全相同）。宿主在这条路径上走的代码与现装相同，按 prefix-post F1 的先例判为偶发；重跑 19 组全 SAME（`go-first.log` / `go-D.log`）。
- **ABBA（代码等价口径）**：900 +0.002/−0.016/+0.002、1080 −0.003/−0.029/−0.048ms；合并 p99 900 7.313→7.239、1080 10.088→10.042（`abba-D.txt`）。
- **RE9 runtime 回放**（`rt9.ps1`，1707×961）：old = 现装 runtime + 现装模块，new = 新 runtime + 现装模块 + fast 模块、选项未设。900 b2980ada、1080 758674a8，两边 SAME。runtime-smoke exit 0（`re9-smoke.log`）。另外两组：=1 走环境变量（fastenv），=1 写在 DLL 旁的 `DLSS5-AMD\native-game-flags.txt`（fastfile，日志 `applied=1`）。两组哈希相同（900 2e203868、1080 5774662f），且都和默认不同。说明 runtime 从 flags 文件读到了这个选项。

## 3. =1：速度与画质

| 项 | 900 三轮 ms | 1080 三轮 ms | 合并 avg / p99 |
|---|---|---|---|
| `DLSS5_FAST_NUMERIC=1`（单项，`abba-N.txt`） | −0.125 / −0.070 / −0.067 | −0.093 / −0.104 / −0.102 | 900 7.044→6.957 / 7.285→7.196；1080 9.749→9.650 / 10.041→9.928 |

1080 的收益比 fast-tier 时（CF −0.13～−0.15 加 MF）小。原因：现装 1080 的 C32 已经换成 rtz 核（逐位且快约 0.04ms），fast 核替换的起点更快了。

**对现装逐位版的 PSNR**（7 case × 12 帧，8-bit ppm，`psnr-N.txt`）：

| case | 均值 dB | 最差帧 dB |
|---|---|---|
| 900-static | 53.30 | 53.30 |
| 900-motion | 53.26 | 52.45 |
| 1080-static | 53.22 | 53.22 |
| 1080-motion | 53.62 | 53.22 |
| 720-motion | 53.07 | **51.83** |
| 900-history | 55.46 | 53.30 |
| 1080-history | 55.36 | 53.22 |

**对 NVIDIA**（fidelity-ngx 同口径：1080p 单帧，Style 0，mochizuki 公开的 NVIDIA 输出；`ngx.ps1`，`ngx-psnr.txt`；新宿主 + flat-F）：

| 配置 | =0 | =1 | =0 对 =1 |
|---|---|---|---|
| 发布配方，跳 42/43/46 | 44.26（76915EC5，与 10-01 测值逐位同） | 44.23 | 47.50 |
| 全 71 块 | 47.43（29920953，同上） | **47.55** | 47.89 |
| 全 71 块 + 1088 行 | 45.76 | 45.67 | 47.65 |

fast 自身引入的偏差约 47.5～47.9 dB。在 NGX 这条路径上，它与"我们对 NVIDIA 的误差"差不多正交，所以叠加后对 NVIDIA 的 PSNR 基本不动。全 71 块时还高了 0.12 dB，可能是 f32 激活更接近 NVIDIA 的算法，但只有这一帧，不能当规律。这里 =0 对 =1 的 47.5 dB 比 regression 测的 53 dB 低，是因为口径不同：NGX 路径是 sRGB 编码后的整幅 1080p 输出，regression 是 residual RGB ppm。

## 4. 快速模式全开的整网成绩，与 mochizuki 比

基准都是现装默认配置（发布配方跳 42/43/46，AE 关，1152 行）。

| 组 | 候选额外开关 | 序列 | 900 三轮 / 合并 ms | 1080 三轮 / 合并 ms | p99 |
|---|---|---|---|---|---|
| NA（全算） | FAST_NUMERIC=1 + 1080_ROWS=1088 | 默认（静止） | −0.121/−0.116/−0.077；7.042→**6.937** | −0.459/−0.470/−0.470；9.758→**9.291** | 7.327→7.168；10.049→9.587 |
| ALL（含 AE） | 上面两项 + VIT_ADAPTIVE=1 + REUSE_PERIOD=4 | 运动（seq 1） | −0.449/−0.518/−0.509；7.063→**6.571** | −1.232/−1.225/−1.228；9.766→**8.537** | 7.287→7.277；10.080→9.628 |

- mochizuki（fast-tier 记录：900 6.02、1080 用 1088 行 7.81，都是全算）。可比的是 NA 组：差距 900 **0.92ms**、1080 **1.48ms**（fast-tier 当时是 1.11/1.56）。差距的主体仍是 C512 和组织方式，见 fast-tier §2。
- ALL 组含 AE 复用，他没有这一项，不能直接与他比。这组只说明"快速模式全开、运动画面"时，用户相对默认配置大约能拿到 −0.5ms（900）/ −1.2ms（1080）。
- `DLSS5_NETWORK_HEIGHT=900` 没放进测量：开了它两档都是 900，1080 的数就没意义了。

## 5. 安装（10-03 03:52）

`Development/deployments/fast-numeric-20261003/install.ps1`（lab 包 `D:\DLSSNR-Lab\deployments-fast-numeric-20261003`，先 DryRun 过）：
- 剑星 add-on **9D1FA493**；鬼武者 RE9 runtime **DBAB5E88**（含 `_storage_`）；两游戏两架构各加 `c32-wave1-fast`（gfx1201 8EDFBCB8 / gfx1200 188D4161）、`c64-wave2-fast`（CC4E29D7 / 8CF2D379）；HIP SUMS **F3EFDC16**（两游戏相同）。其余模块和 flags 文件都没动，两游戏 EXACT；默认关，所以游戏行为不变。
- 备份 `stellar-backups` / `onimusha-backups\20261003-035207-fastnum`，`fast-tier\backups\20261003-035207-install-fastnum`；还原用 `install.ps1 -RestoreBackup 20261003-035207`。
- fast-tier：`exact\` 快照已同步（SUMS 两份，两个 `-fast` 文件也放了一份）；`switch.ps1` 换成标了过时的版本，`-Tier fast` 会拒绝并提示改用 flags 加一行，exact/status 照常可用；`README-Zero.txt` 开头加了过时说明。
- add-on 只在导出表名（.edata）上与现装 A1B28916 不同，代码段逐字节相同（`pecmp.py`；现装那份是用别的输出文件名编的）。新的 9D1FA493 代码只多了这个选项。

## 文件

脚本 `Development/HIP/experiments/fast-numeric/`（setup / route / go / guard / rt9 / ngx / psnr）；lab `D:\DLSSNR-Lab\hip-backend\fast-numeric-20261003`；部署 `Development/deployments/fast-numeric-20261003`。预编：DGX `python3 Development/tools/llvm-fork/compile-modules.py --bin ~/work/llvm-build-23/bin --target-feature=-real-true16 --row-opts --compiler-rows llvm23 --out <dir>`。同一命令重编的 `c32-wave1-rtz`、`c64-wave2` 与现装文件哈希相同（99B0B1E2 / A0CAD8CB）。
