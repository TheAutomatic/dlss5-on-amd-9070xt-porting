# 原版算术与尺寸审计（隔离实验）

基线 `2137a35`，现场是 ACO-lineup 已安装模块；不改生产源、配方、flags、游戏安装。
结果：`../../../results/fma-vs-nvidia-20260928/README.md`。

候选只改 C32 10 块 + C64/C128 20 块的激活（C256 FFN、其余数学保持基线）：

- F：两处多项式显式 `__builtin_fmaf`，仍是 float32。
- H：expand 先 RNE half；两次 `v_fma_mixlo_f16`，末次乘法再 RNE half。仅恢复激活段的 half 舍入，矩阵仍是当前 float32 累加；它不是完整 NVIDIA 重实现，也不是已优化好的 packed-half 路线。
- Z：原样生产复编，与现场两模块全文件 hash 一致。

`prepare.py <临时目录>` 复制当前 `hip/` 再定点生成 F/H/Z；源码来源由提交与结果 provenance 锁定。源文件没有实验宏混进生产配方。

远端目录 `D:\DLSSNR-Lab\hip-backend\fma-vs-nvidia`：

1. 传生成的 `hip-Z/hip-F/hip-H`；`build.ps1` 独立编译 gfx1201，并从游戏只读复制 **30 个**现场模块到每个 `flat-*` 目录。游戏运行即停止。
2. `run.ps1`：两候选各七用例×12帧，允许输出变化但拒绝非有限；随后900/1080两轮ABBA，1000帧/槽，弃前200，计时只读首尾。每槽输出实际模块路径与C32/C64 hash。AE未测：本轮不做可部署逐位候选。
3. `raw-network.cpp` 从 `src/native_hip_network.h` 基线提取生产 fast 选项、启用当前模块选项，**不跳任何块**，对原始随机RGB fixture做1080→1152镜像（已逐值核对原post color）。只跑一次 raw RGB0→70，不经过游戏codec；`raw.ps1` 分别运行A/F/H。编译 `x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -IDevelopment/HIP .../raw-network.cpp -o <临时目录>/raw-network.exe`。
4. `collect.ps1` 导出逐帧hash与32个计时槽；`analyze.py <结果目录>` 计算ABBA与变更帧数。
5. `activation-probe.py [输出目录]`：CPU穷举63,488个有限half，以及已存原CUBIN block1 oracle的隔离激活控制。需要release原样本，不访问GPU。
6. `fresh-cubin.py [临时输出目录]` 在Spark重跑原DLL普通/inpview C32，确认raw8MiB和float oracle的溯源。先提取CUBIN到 `/tmp/fma-vs-nvidia/cubins`，需CUDA。
7. `evidence.py /tmp/fma-vs-nvidia <结果目录>/isa` 导出原SASS/Daniel片段；`extract_embedded_cubins.py` 从原DLL提取，CUDA cuobjdump反汇编。大DLL/整核ISA/二进制只留临时目录和远端。

第一次回归误沿用旧脚本的架构子目录选择，候选根目录文件被忽略；发现H输出竟然不变后停止。全部该轮目录改名 `*-invalid-old-module-path`，不纳入误差/计时。最终脚本只认显式 `flat-*`，检查模块数、打印hash，A/Z与现场相同。不得把旧轮“逐位”当候选通过。
