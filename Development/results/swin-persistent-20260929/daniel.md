# Daniel 0.5.1 持久化核静态账

来源为已有解包的 `d051/mod.dll`、gfx1201 hsaco，Capstone/PE 导入与 AMDGPU 反汇编交叉检查。不是执行对方整网计时；未复现他发布时的 env 配方。小范围反汇编存 `daniel/`，地址为该 DLL 的 VA 或 hsaco 反汇编地址。

## 队列与层间依赖

Host `0x1800423c0..0x180042b35` 构建 392 字节 RunParams：8组32字节层描述（input/output/weight指针、signed shift），0x100层数、0x104/108尺寸、0x10c各层窗口宽、0x12c前缀任务偏移；0x150 head、0x158 tail、0x160依赖计数、0x168就绪队列、0x170错误指针、0x178超时tick、0x180每WG广播槽。首层任务直接就绪，其余由前层窗口推进。

设备工作区对象字段 +0x1e0 来自 hipMalloc（0x180040135..40194，经0x18007ccd0 thunk）；不是整张就绪队列放 host。0x1800401a5..401da 另分配 hipHostMalloc(size=4, flags=2)，对象+0x250为host地址、+0x258为device alias，仅错误计数映射。

C256 reference run 起点0x2a2b00：0x2a2b9c领 head 票；0x2a2c84为 s_sleep 2；0x2a2d1c为超时 system atomic。窗口完成后0x2a928c更新下层依赖计数，最后一个父窗口满足依赖时0x2a9420抢tail，0x2a9484发布队列槽。窗口shift最多造成2×2相邻依赖。任务输出发布后核退出，没有继续领下一任务的外层循环。C64/128/256对应64/128/256线程WG；一WG完成一个窗口，LDS被该任务内部各算子复用。

参考核资源：C64 168 VGPR / LDS4096 / private80 / spill3；C128 186 / LDS16384 / private0；C256 159 / LDS32768 / private0。各项见run-metadata.json。资源/静态条数不等于动态周期。

## 轮询、报警与选择

阈值0x989680 = 10,000,000 realtime ticks，约100ms；不要把s_sleep immediate2翻成2ms。相关 ISA 背景见 [AMD RDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/radeon-tech-docs/instruction-set-architectures/rdna4-instruction-set-architecture.pdf)，host映射API见 [HIP host memory](https://rocmdocs.amd.com/projects/HIP/en/develop/how-to/hip_runtime_api/memory_management/host_memory.html)。这两项文档说明API/指令，具体程序路径证据来自上述二进制。

Host 0x180037b04..37bbc读错误数、记录“frame output not trustworthy”并累计，函数到37bfa返回；这个路径未调用重算，也未清除持久化掩码。因此任务单“照他报警+回退”的回退不能当作已存在事实，我们另行实现了可逐位恢复的路径。

构造函数0x180028d53明确把+0x1d8的run掩码清零。0x18003e9ab..3e9c4只有getenv取到DLSSNR_SWIN_RUN才写回；不支持路径0x18003ea03再次清零。RUN_ALL进一步控制stage选择；host另有occupancy/grid筛选，未选择的stage仍用普通派发。安装器外层/OptiScaler中未找到独立设置该变量的字符串；不能据此证明所有用户配置都关闭，但**没有依据把默认的+6%宣传数字归给持久化**。

我方保留边界层、不照搬双缓冲：为了超时后原输入仍完好，六层各用独立输出。CPU预计算通用依赖图，GPU只推进图；其余关键结构（单WG/窗口、设备队列、窗口级依赖、sleep2、有界计时）与此设计对应。
