# Swin 持久化实验（2026-09-29）

结果与安装状态见 `Development/results/swin-persistent-20260929/README.md`。生产实现是 `hip/swin_persistent.inc` + `Development/HIP/swin_persistent_{network,types}.h`；这里保留试验生成器和实跑脚本，不是另一套生产入口。

- `prepare.py` / `build-runner.sh <外部目录>`：从固定 `70533d96` 生成基线/异步原型 host 和 HIP 源码；原型配置 SP_*，生产默认不接受这些诊断变量。需要 MinGW x86_64 工具链。
- `build.ps1` 编原型，`build-production.ps1` 用驱动 COMGR3 编双架构生产模块及 c64 不变性探针。后者读取 lab 的 `production-source.zip`：将 `hip/` 顶层源码、build-modules.ps1 及 `Development/HIP/swin_persistent_types.h` 一起放在 ZIP 根。普通生产构建直接用 `hip/build-modules.ps1 -SourceDir hip`，自动解析共享类型头。
- `prepare-tests.py` / `prepare-production-tests.py --out <目录>` 生成基于既有 kernel-map 七用例回放的 PowerShell 驱动。lab 根固定 `D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929`，沿用既有捕获、资产和基线模块；不能只复制单个脚本便假定资产存在。
- `snapshot.ps1`、`prepare-lab.ps1` 保存现场哈希、复制基线模块；`screen.ps1` / `short-timing.ps1` 为早期筛选，`run-async.ps1` / `stress.ps1` / `formal.ps1` 为异步原型正式回归、故障注入和计时。
- `production-check.ps1` 对 canonical host 全回归，关闭/缺模块回退，再两轮 ABBA；`runtime-check.ps1` 检验 RE9；`trace.ps1` 用单独 trace 二进制数派发，trace 构建不计时。
- `collect.ps1 -Label final` 收集逐帧SHA、CSV、日志；不把 f16 输出或编译产物入仓。`audit.py <解包目录> <输出目录>` 独立验 golden/AE/压力并复算 ABBA。已归档 raw 可直接作为输入。
- `install.ps1` 安装前核对现场64项快照与payload清单、查游戏进程，备份后更新宿主/新2模块/开关，读回验证，异常回滚；`-RestoreBackup <目录>` 回退。它是本次现场脚本，不是通用发布器。payload三文件哈希见结果 installed.json。

常规 addon/runtime 构建走原有项目构建入口；本轮未改发布版本、未生成发布包。gfx1200仅编译与静态检查，运行测试均在gfx1201 / RX9070 XT。
