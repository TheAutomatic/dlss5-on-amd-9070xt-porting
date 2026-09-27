# 第五刀已装剑星（2026-09-27 23:06）

仅替换两份c64-wave2：gfx1201 f60eaee8 / gfx1200 9a0fda18。B+R+C（字节输入整组读取、RTZ配对、直接坐标）已进配方，三个宏默认0，配方开1。host/add-on、运行flags和RE9接口不改；C512实验不在本部署内。

EXACT/AE各七组逐位，AE43复用+41刷新；两批千帧ABBA：900 −0.75%/−0.72%，1080 −0.84%/−0.78%。画面/FPS待Zero；未发包。

备份 `D:\DLSSNR-Lab\mh-round1-20260927\backups\stellar-20260927-230633`。

```powershell
powershell -ExecutionPolicy Bypass -File D:\DLSSNR-Lab\mh-round1-20260927\install.ps1 -RestoreBackup D:\DLSSNR-Lab\mh-round1-20260927\backups\stellar-20260927-230633
```

payload.json记录实测模块与实装基线哈希，installed.json记录备份及受保护文件哈希。二进制在远端与本地payload，不入git。结果 ../../results/mh-round1-20260927/README.md。
