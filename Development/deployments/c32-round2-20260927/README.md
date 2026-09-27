# C32 round2 E 部署（2026-09-27 19:20）

已装剑星，仅替换两架构c32-wave1。新增固定段MODE、prefix直接量化、prefix完整窗口三个编译期开关，保留上轮配方。详见 ../../results/c32-round2-20260927/README.md。

部署根：`D:\DLSSNR-Lab\c32-round2-20260927`。
备份：`backups\stellar-20260927-192033`。
游戏关闭时还原：

```powershell
powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\c32-round2-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\c32-round2-20260927\backups\stellar-20260927-192033
```

payload.json记录源文件哈希；installed.json记录备份与未改文件的哈希。模块二进制在远端及本地payload中，不入git。离线回归/ABBA通过，画面与FPS待Zero；未发包。
