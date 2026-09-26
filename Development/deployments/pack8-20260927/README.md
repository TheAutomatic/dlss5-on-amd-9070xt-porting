# pack8 → 剑星（2026-09-27 04:19 已安装）

只换 `DLSS5-AMD\native-game-tiled-assets\HIP\{gfx1200,gfx1201}\` 下的 `c32-wave1.hsaco`、`c64-wave2.hsaco`（`CW_PACK8 1` + `W2_PACK8 1`，生产配方其余不变）。add-on、flags 不动；两个模块在 `DLSS5_HIP_WAVE_OWNED=1`（0.32 默认）下加载。

- 离线：7 用例逐位；网络 900 −8.7%、1080 −9.1%（`results/pack8-20260927`）。
- 9070 目录 `D:\DLSSNR-Lab\pack8-20260927`（`install.ps1` + `payload\`）。
- 备份：`D:\DLSSNR-Lab\pack8-20260927\backups\stellar-20260927-041916`
- 还原：剑星关着时 `powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\pack8-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\pack8-20260927\backups\stellar-20260927-041916`

待 Zero 实测：1080P 窗口、FSR 原生 AA、主菜单，F8 切 EXACT；对照 0.32 的 47～48 fps。
