# C128/C64 持久化分 stage 实验

基线固定 `d7b29df2` / 生产 C256 持久化。`build.sh <外部目录>` 从该提交生成隔离宿主，只增加 `SP_SMALL_CHANNELS`（1=C64，2=C128，0=不新增）及 `SP_SMALL_SIDES`（1=encoder，2=decoder，3=两侧）实验选择。C256 始终保留两段，不被 sides 遮掉。故障注入只作用于小通道，避免只测到先经过的 C256。

GPU 模块直接复用上一单的双架构生产 `swin-persistent.hsaco`，没有新编译器、算术或模块变动。`setup.ps1` 查游戏进程、快照现装62模块和4个宿主/配置文件，并在独立lab中复制 baseline/flat-A/flat-P。A是上一单canonical host，P是实验host；两边都设 DLSS5_HIP_SWIN_RUN=1、PDL=1。

`screen.ps1 -Channel 2 -Side 1` 先七用例×EXACT/AE×12帧，再240帧ABBA（弃32）。`remaining.ps1` 按C128 decoder→C64 encoder→C64 decoder执行其余筛选。`formal.ps1 -Round 1 -ProductionBaseline` 对现役host；`-Round 2|3` 同一实验host仅切小stage，排除诊断解析开销。每stage、每档1000帧ABBA弃200。`stress.ps1` 每stage两档history用例EXACT/AE，强制票号回绕及异步超时重算。`trace.ps1` 用独立trace host获取真实派发，再查询HIP理论占用率；trace不计时。

`finish.ps1` 串行执行一轮现役对照及两轮同host计时、压力、trace、现场哈希核验及采集；只在screen全部通过后运行。`collect.ps1 -Label final` 归档日志/CSV/逐帧SHA，不收f16和二进制。`analyze.py <解包目录> <结果目录>` 独立验0.36 golden、AE决策、错误/恢复计数，重算每个ABBA槽。

本次执行中先跑timing1与matched2、压力、trace，再由`confirm.ps1`追加matched3并重新收集。`finish.ps1`为复现时的一次完整入口，结果相同但将两轮matched排在压力前。

Windows路径固定 `D:\DLSSNR-Lab\hip-backend\swin-small-20260929`；资产/捕获来自上一轮同一套lab，不是可在空目录独立运行的下载包。所有脚本应在9070无游戏时运行。产物与生成宿主源码放repo外。

occupancy.cpp 用 [HIP occupancy API](https://rocm.docs.amd.com/projects/HIP/en/latest/doxygen/html/group___occupancy.html) 查询 `hipModuleOccupancyMaxActiveBlocksPerMultiprocessor`；返回资源约束下的理论驻留上限，不代表执行时测得的活跃wave比例。
