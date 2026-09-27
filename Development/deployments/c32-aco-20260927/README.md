# C32 ACO 候选 E（2026-09-27）

已在 17:34 装进剑星。只换 gfx1200/gfx1201 的 c32-wave1；完整实验见 ../../results/c32-aco-20260927/README.md。

配方：CW_DIRECT_OUT=1 + CW_RTZ_PAIR=1，其余沿用0.34。已过7用例逐位、两档两批ABBA、标量边界探针；gfx1200仅编译。

远端：`D:\DLSSNR-Lab\c32-aco-20260927`。
备份：`backups\stellar-20260927-173404`。
还原（游戏关闭时）：

```powershell
powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\c32-aco-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\c32-aco-20260927\backups\stellar-20260927-173404
```

payload.json 记录基线/候选完整SHA256；installed.json记录备份和未改文件的哈希。二进制保存在远端及本地payload目录，不入git。未发包；游戏画面/FPS待Zero标准测试。
