# 配方与对照口径

基线为 `d7b29df2` 中的 C256 持久化生产版，剑星宿主046e1a63；实际62模块全部与hip/SHA256SUMS匹配。实验对照两边都开启C256、PDL、wave-owned及既有上采样融合，候选只另选一个小通道stage。模块未改，泛型sp_run64/128及恢复核已在上一单两架构产物中。

| 标签 | 改动段 | 原内部派发 | 队列方案 | 边界 |
|---|---|---:|---:|---|
| c2-s1 | C128 encoder 10–13，4层 | 4 | init/run/recover=3 | block9/14保留 |
| c2-s2 | C128 decoder 57–60，4层 | 4 | 3 | Up+block56融合保留，block61保留 |
| c1-s1 | C64 encoder 6–7，2层 | 2 | 3 | block5/8保留 |
| c1-s2 | C64 decoder 63–64，2层 | 2 | 3 | Up+block62融合保留，block65保留 |

小通道候选与上一单一样，内部替代逐层PDL，段边界为普通stream顺序；网络其它段继续PDL。C256 encoder16–21/decoder49–54不受小通道方向选择影响。C32的上采样融合首块也不动。

一个WG一窗口，C64 64线程、C128 128线程。ready queue、依赖计数和广播槽在device；至多4父/子窗口，release/acquire和全wave输出汇合后发布。六层改四/两层不会改变数学或窗口定义。按层独立输出，超时约100ms后终止队列，在同stream单WG按层重算，并禁用本实例；沿用drain/clear/同步回绕。

资源表来自双架构ELF元数据。普通与持久化的C64都为140VGPR/8KiB LDS，C128都为159VGPR/16KiB LDS，无spill；SGPR分别30→45、25→40。这说明这次不是通过降低VGPR/LDS获得额外驻留能力。`occupancy.csv` 用驱动API测理论block上限，不能当实测执行占用率。

正确性：7用例×12帧×EXACT/AE，每候选168帧（其中720确认禁用尺寸回退）；SHA对09-28float FMA golden，AE逐行逐字段比较。候选必须先过回归才计时。短ABBA每槽240帧弃32；正式ABBA每槽1000弃200，900/1080分别测：先一轮实验宿主对现役宿主（timing1），再两轮同一实验宿主仅切小stage（matched2/3），排除SP_*环境解析的宿主差异。计时为完整NativeGameFrame wall，首尾读回，非纯HIP及游戏FPS；均与同批A两端配对，不能跨批直接相减。

压力对每个stage分别做900/1080 history × EXACT/AE：ticket start=4294967290、limit=1024强制回绕；故障注入只针对小通道，压住初层后继发布。超时用无诊断同步的异步路径，检查输出、AE和实际fallback/disabled/errors计数；不能把仅设置注入参数当已经触发。实验宿主开启诊断宏，生产无新配置入口。

数据归档允许统一UTF-8/LF及去日志行尾空格；不改CSV字段/数值。原始压缩包在外部产物目录另存SHA。复算脚本 `Development/HIP/experiments/swin-small/analyze.py`。

当前实验宿主开启HIP_SWIN_PERSISTENT_DIAGNOSTICS，正常计时SP_VALIDATE/TRACE均为0，但SpEnv仍读取环境。现役宿主诊断宏0会把它折叠成常量，所以两种host的差异不应全记到stage头上；matched用同一exe并在每槽显式设SP_SMALL_CHANNELS=0或候选mask，C256始终开。若matched过门槛仍需canonical生产候选复验才能装机。

与C256收益差别最大的已知结构：900的C256原内部六层为12次派发，队列3次，单边净省9次；1080六层6→3净省3次。C128现役已经每层完整融合，四层4→3只省1次；C64两层2→3反增1次。小通道同时有更多窗口任务：C128每段1581/2257、C64每段3111/4453（900/1080），C256只有624/893。窗口级原子与队列管理没有随C减到零，这是负账的结构解释；没有单独测出每个原子/等待的精确周期，不把结构分析写成硬件stall测量。

实测trace（含初始化和正常退出的恢复核）：基线179/162，任一C128 stage178/161，任一C64 stage180/163。驱动occupancy API报告32个multiprocessor、每个上限2048线程；普通/队列C64均8个64线程WG，C128均4个128线程WG，均512/2048=25%。这是该Windows HIP API口径的理论上限，不是GPU profiler采样值。
