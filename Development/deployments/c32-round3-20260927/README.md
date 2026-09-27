# C32 round3 F 已装剑星（2026-09-27 20:06）

仅两份c32-wave1，新增CW_FINISH_FULL_TILE=1，post候选关闭。gfx1201 1753400c / gfx1200 834c7095。七组逐位、双架构与两批ABBA通过，整网约−0.22～−0.27%。画面/FPS待Zero；未发包。ViT字节原型不在本部署内。

部署根 `D:\DLSSNR-Lab\c32-round3-20260927`，备份 `backups\stellar-20260927-200610`。payload.json为原/新模块哈希，installed.json记录受保护文件哈希。

游戏关闭时还原：

```powershell
powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\c32-round3-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\c32-round3-20260927\backups\stellar-20260927-200610
```

完整结果见 ../../results/c32-round3-20260927/README.md。二进制在payload与远端，不入git。
