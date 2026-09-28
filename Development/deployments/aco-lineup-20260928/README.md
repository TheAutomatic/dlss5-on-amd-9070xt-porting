# ACO 对齐组合，剑星安装

只换 c32-wave1 / c64-wave2，每架构两文件。基线第五刀，生产源码默认宏 0，配方开 CW_ACT_FMED3=1 和 W2_BOUNDED_RCP=1。

两批 ABBA：900 −0.824%/−0.648%，1080 −0.752%/−0.744%。组合 EXACT/AE 各 84 帧逐位，84 组 AE 决策同；配方复编与实测模块代码/metadata 双架构全同。

备份：`D:\DLSSNR-Lab\aco-lineup-20260928\backups\stellar-20260928-115800`。

恢复：在 9070 执行 `powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\aco-lineup-20260928\install.ps1 -RestoreBackup D:\DLSSNR-Lab\aco-lineup-20260928\backups\stellar-20260928-115800`。

`payload.json` 钉新旧 hash，`installed.json` 是安装回读。其余 56 模块与四个受保护文件未变。gfx1200 只编译，无实机；未发包，游戏验收待 Zero。
