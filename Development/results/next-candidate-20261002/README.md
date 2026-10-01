# 下一版候选整套（next-candidate，2026-10-02，光派单）

**没装机。** 整套在 `D:\DLSSNR-Lab\next-candidate\`，`install.ps1 -DryRun` 已过（只检查，不动游戏）。Zero 看数字决定。

## 内容（源码 main b6c508a5）
| 件 | 说明 |
|---|---|
| 62 模块 | `hip/build-modules.ps1 -RowOpts -PrebuiltDir`（配方里有的全编，含 82ce821f 选项、d48cdae3 的 LLVM23 两件、已收的 HIP_DEC_WIDE 等）。对 0.39 现装按代码段比：**56 同、6 不同** = c32-wave1、c64-wave2（LLVM23.1.2，DGX 预编，与 d48cdae3 测过的逐字节同）、c512-m32-deep（max-ilp），两架构 |
| add-on | HEAD 编，钉基址，**053C3589，与现装逐字节同**（0.39 之后宿主源码没动） |
| RE9 runtime | HEAD 编 73D4C25C（现装 DC2D445E；差别只是从 flags 文件读 DLSS5_STYLE，night-20261001 #1 已回放 SAME） |
| 着色器 / flags | 不变 |

## 验证（lab `D:\DLSSNR-Lab\hip-backend\next-candidate-20261002`，`full-N.txt`）
基线 = 0.39 现装：剑星 gfx1201 31 模块 + 现装 assets；两边用同一个 HEAD 编的 bench 宿主（宿主源码与现装 add-on 同源），回绕用同源改阈值的 Nroll。
- **19 组 SAME**（7 用例×EXACT/AE×12 帧 + AE CSV + 900/1080 回绕，idle 钉住）。
- ABBA 三轮：900 −0.106/−0.125/−0.139ms，1080 −0.189/−0.180/−0.176ms；合并 p99 900 7.455→7.332，1080 10.347→10.143。六轮全快。
  - 比分项相加（−0.06/−0.08 + −0.06/−0.04）略大，尤其 1080；同批同宿主交替跑，按实测记。

## 整网单帧（`wall.txt`，1000 帧弃 200，wall 中位 / span 中位，ms，两次）
| 档 | 现装 | 候选 |
|---|---|---|
| 900（1152 行） | 7.403 / 6.898，7.435 / 6.926 | 7.301 / 6.797，7.317 / 6.809 |
| 1080（1152 行） | 10.163 / 9.624，10.264 / 9.744 | 9.988 / 9.460，10.014 / 9.464 |
| 1080（1088 行） | 9.844 / 9.299，9.794 / 9.286 | 9.684 / 9.153，9.704 / 9.162 |

## install.ps1
先查游戏/基准进程和 gpu.lock，要求两游戏都在 exact 档，校验包内 SHA256SUMS；备份（`D:\DLSSNR-Lab\stellar-backups\<时间>-next`、`onimusha-backups\<时间>-next`、fast-tier `backups\<时间>-install-next`）；剑星换 62 模块 + add-on、重写 HIP\SHA256SUMS；鬼武者镜像模块 + SUMS + runtime（含 `_storage_`）；同步 fast-tier `exact\` 快照（c32/c64/deep_fast-packed、两份 SUMS、flags）；最后打印档位状态和哈希。`-DryRun` 只做检查。包 SHA256SUMS = `package-SHA256SUMS`。

注意：fast-tier `fast\` 下的 c32/c64 仍是旧 fast 配方，没随这次变。

脚本：`Development/HIP/experiments/next-candidate/`（setup/go/wall/pack/install.ps1、guard.sh、README.txt）。
