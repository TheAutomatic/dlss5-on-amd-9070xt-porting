# ViT typed stream 已装剑星（2026-09-27 21:02）

新add-on4151123e、vit-stream两份（gfx1201 ad59f7be / gfx1200 0c9171ee）、DLSS5_HIP_VIT_STREAM=3；保留全部旧HIP模块。原目录没有HIP/SHA256SUMS，本次创建包含全套60模块的清单。dxgi、INI、两份C32哈希保持不变。

EXACT/AE逐位；1080 EXACT两批−1.38%/−1.23%，AE运动回放−0.040/−0.043ms；900无稳定收益。C512实验不在部署内。画面/FPS待Zero，未发包。

备份 `D:\DLSSNR-Lab\vit-bytestream-20260927\backups\stellar-20260927-210229`。

```powershell
powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\vit-bytestream-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\vit-bytestream-20260927\backups\stellar-20260927-210229
```

payload.json列出旧/新文件哈希，installed.json记录备份与保护项。还原会恢复旧add-on/flags、移除新增模块和本次新增的清单。二进制只在远端与本地payload，不入git。详见 ../../results/vit-bytestream-20260927/README.md。
