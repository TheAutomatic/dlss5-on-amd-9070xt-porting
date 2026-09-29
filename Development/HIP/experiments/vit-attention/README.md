# ViT attention 对照与复现

结果在 `Development/results/vit-attention-20260929/README.md`。所有产物放repo外；lab固定 `D:\DLSSNR-Lab\hip-backend\vit-attention-20260929`。本轮只换模块，benchmark沿用上一单canonical C256 host（setup.ps1复制为benchmark-base.exe），并在flags里显式开SWIN_RUN=1、MAKE_RESIDENT_EVERY=60。

1. `setup.ps1` 查游戏/实验进程，保存剑星66项快照，复制双架构31模块到独立lab。不会修改游戏。
2. `prepare.py --out <目录>` 从固定629b0555的deep_fast.hip生成各组织探针及native/pair/AV-transpose变体；`probe.inc`保留原数学、仅改分组/预取。生产源码不依赖这些实验导出。`build.ps1` 调驱动COMGR3编双架构。生成源码名固定probe.hip，迭代覆盖；最终生成器含全部变体。
3. `make-jobs.py --out <目录>` 生成400/448/640 fixture；用既有 `Development/HIP/experiments/kernel-map/pack-jobs.py jobs.json jobs` 编二进制job。`jobbench.cpp` 是原jobbench加输出golden比较：ours/constv基线先写golden，后续完整输出逐字节比较，失败在计时前退出；每次计时前后检查guard、finite、非零和输出。编译：`x86_64-w64-mingw32-g++ -std=c++17 -O2 -static -I Development/HIP Development/HIP/experiments/vit-attention/jobbench.cpp -o <外部目录>/jobbench.exe`。
4. `micro.ps1 -Batch <名字>` 每job 7轮×128 graph launches；用OnlyPrefix/Match筛选。micro1组织版，micro2加native，micro3加native与组织组合，micro4/6是const-V诊断，micro5是pair，micro7为最终AV转置及组合。先前批次是最终生成器的子集，归档日志保留各自实际执行job列表。Daniel050/051原hsaco单独复制进lab，参考核不作与我方数值相等的声明。
5. constv的V平面限定为FP8+1，对比正常读取与硬编码常量片段；两者先逐位再计时。**nov是限定夹具的诊断，不是通用候选，不可替换生产。** 448也仅作形状对照，不增加生产尺寸。
6. `half-domain.py` 穷举bit-map可达的552种half位型并核对精确widening；`isa.py --artifacts <目录> --out <结果目录>` 用已有llvm-objdump和msgpack读取各内核，记录完整反汇编/元数据/静态指令族。loop静态包数不能当动态周期。
7. `build-production.ps1` 从ZIP根的hip/deep_fast.hip、build-modules.ps1生成三宏全0与全1的双架构deep_fast-packed；ZIP文件名production-source.zip。只更新lab flat-P的该模块。默认关三段同基线，开启只两个函数改变，另74导出及元数据同；两目标函数与已测probe_pair_transpose代码/ABI元数据相同。
8. `make-regression.py --out <目录>` 生成七用例驱动。`full.ps1` 先168帧EXACT/AE，再48帧回绕（benchmark-roll.exe为同源码加HIP_SWIN_PERSISTENT_DIAGNOSTICS=1），再两轮1000帧ABBA弃200。回绕host编译沿用 `Development/HIP/benchmark_vit_reuse.cpp`、MinGW C++17/O2/static/municode，链接d3d12/dxgi/d3dcompiler/dxguid；其余测试复用现役host。
9. `post.ps1` 查询理论occupancy，用同一既有RE9 runtime对照两个module目录，检查现场SHA未变。occupancy.cpp编译与jobbench相同，使用 [HIP occupancy API](https://rocm.docs.amd.com/projects/HIP/en/latest/doxygen/html/group___occupancy.html)，不是硬件实时占用率采样。
10. `collect.ps1 -Label final` 收集CSV/逐帧SHA/日志，`audit.py <解包目录> <输出目录>` 独立核golden、AE、回绕、微测golden结果和各轮原始时间；没有f16或编译产物入仓。
11. `install.ps1` 仅在无游戏时核snapshot与payload，备份后换2模块、重建HIP/SHA256SUMS，校验其它64项未改；异常自动回滚，支持 `-RestoreBackup <目录>`。payload只包含两hsaco与manifest.json。不改宿主、flags、RE9游戏或发布包。

实际编译选项、二进制SHA、微测job与正式配方均随结果保存。文件路径依赖已存在的9070捕获/weights/shaders实验环境，脚本不在空Windows系统自动下载这些资产。
