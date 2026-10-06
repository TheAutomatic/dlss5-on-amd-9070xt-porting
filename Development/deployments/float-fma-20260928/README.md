# 剑星 float FMA（不发包）

已替换15个模块×gfx1200/gfx1201，30文件；源与验证见 `../../results/float-fma-20260928/README.md`。

备份：`D:\DLSSNR-Lab\float-fma-20260928\backups\stellar-20260928-153921`。

宿主/INI/flags/dxgi及另30模块不变。`payload.json`锁定旧/新SHA，`installed.json`是安装回读收据。

`install.ps1 -RestoreBackup <备份路径>`回滚；游戏运行会拒绝安装或回滚。`stage.ps1`只复制验证后的实验产物到payload，不改游戏。
