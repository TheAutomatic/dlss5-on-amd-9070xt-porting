# C256 跨层就绪队列：通过，已装剑星（2026-09-29）

在不改数学、窗口、float FMA 基准的前提下，把 encoder 16–21、decoder 49–54 各六层放进一次队列派发。两轮完整 NativeGameFrame wall ABBA 均过 0.5% 门槛。不是纯 HIP 时间，也不是游戏 FPS。

| 轮次 | 档位 | 驱动现役 A / ms | 生产候选 Q / ms | 节省 |
|---|---|---:|---:|---:|
| 1 | 900 | 8.347714 | 8.189269 | 0.158445 / 1.898% |
| 2 | 900 | 8.398949 | 8.235931 | 0.163018 / 1.941% |
| 1 | 1080 | 11.189376 | 11.125522 | 0.063854 / 0.571% |
| 2 | 1080 | 11.204741 | 11.136764 | 0.067977 / 0.607% |

每槽 1000 帧，弃前 200，A-Q-Q-A；两档两轮共 16 槽。首尾读回，其余计时不读回。原始 CSV 在 `raw/`，独立复算见 `timings-Q.json` / `timing-slots-Q.json`。编译器仍为驱动 COMGR3 / LLVM21，没有续做 LLVM 补丁。

## 对照设计与历史纠正

详见 [Daniel 静态拆解](daniel.md)。Daniel 是“一 WG 一窗口任务、一 launch 跨多层”，不是少量常驻 WG 不断取任务。队列/依赖计数都在设备内存，只有 4 字节错误计数映射到 host；`s_sleep 2` + realtime 计时约 100ms。找到的 host 超时路径只报警并累计不可信输出，没有重跑或禁用。`DLSSNR_SWIN_RUN` 默认掩码为 0，所以不能把他自报的 +6%/+8% 直接归因于持久化。

旧 [transpose-persist](../transpose-persist-20260927/README.md) 只有估算、未落地。“以前 C256 持久化慢”应改为“以前单层整块融合慢”；该实验已在 [C256 历史分析](../c256-fusion-20260928/history-analysis.md) 查清：FFN 权重重复读取/寄存器组织，后用多 token 共权重修正。不是本次队列机制的负证据。

## 实现与成本

- 新 `swin-persistent.hsaco`，两架构各新增一份，31/架构、共 62；旧 60 模块原样保留。`DLSS5_HIP_SWIN_RUN=0` 为源码和三个模板默认，1 仅启用合配方 1600×960 / 1920×1152 的 C256 内层；其它尺寸、graph、observer、dump 等走旧路。缺模块自动回旧路。RE9 共用解析与 requested/active 日志。
- C256 每 WG 256 线程、一个 8×8 窗口；sp_run256 为 **154 VGPR / 48 SGPR / 32768 B LDS / private 0**。LDS 和同一数学函数按窗口复用，参数 568 字节按值传入。全部资源见 `kernel-resources.json`。
- 每段 `sp_init → sp_run256 → sp_recover256` 三次普通 stream 派发；正常 recovery 仅一个 WG 检查后退出。900 每段 624 任务/104 初始任务；1080 每段 893/160。整网真实 trace：**197→179 / 168→162**，已计入初始化和恢复核。
- CPU 预建相邻层裁剪窗口依赖图，每任务至多四个父/子；GPU head 领票、完成计数最后一位父任务发布后继，tail 保留槽，release 发布 `child+1`。轮询 relaxed 后 acquire；每 wave 的写出经 agent fence + WG barrier 汇合，再由 leader 发布。不是只同步 leader 的写出。
- 每层保留独立输出，原始段输入不覆盖。相对 Daniel 的双缓冲增加内存，换取无损恢复。两个 C256 段的六层 byte 输出约 18.432 MB（900）/26.542 MB（1080），这里是所持有总量，不冒充相对旧池的峰值增量。
- 新段替代内部 PDL，段边界使用普通 stream 顺序、清理前一 PDL 链状态；其余网络仍用 PDL。

## 超时与回绕

每个空队列轮询读取 steady counter，阈值 10,000,000 tick；`s_sleep 2` 是 ISA immediate，不是 2ms。超时/非法队列置全局 abort，后续 WG 退出。随后同 stream 的单 WG recovery 无轮询、按层逐窗口重算全段，保留原算术。完成后才会运行网络后续层，因此坏的中间结果不直接流向最终图像。

仅 8 字节 host 映射错误/恢复计数，GPU 在失败时做 system-scope atomic。host 后续调用检测后禁用本实例并写 stderr/OutputDebugString；不依赖 CPU 每段阻塞才能恢复。累计票号靠近 uint32 上限时先 drain、清空、再次同步再归零，沿用 PDL 的回绕原则；不能只清计数让旧写入追上新一轮。

故障注入人为阻止第一层发布后继：1080 诊断段一次记录约 **127.244ms**（含约100ms等待及串行恢复），不是所有故障下整帧延迟上界。正常无限轮询已消除；GPU/驱动本身失去执行能力不在该软件回退保证内。

第一版 CPU 每段 synchronize/readback 比原版慢（900 +0.485ms，1080 +0.685ms）；异步恢复版才过门槛。这个失败版本也保留短测 CSV，不能把最终收益归功于“少派发”而忽略同步成本。

## 逐位与安全验证

- 生产 Q：EXACT/AE 各 7×12，共 **168 候选帧**全命中 09-28 float FMA golden；连 A 共336帧无非有限。AE84行全部字段相同，44复用/40刷新。
- 原型 P 同样168候选帧通过；生产七个 sp 函数代码与元数据逐一同 P（`production-identity.json`），并另跑上述生产 Q 全回归与计时。
- 压力 P：回绕48帧、强制超时48帧、无诊断同步的异步超时48帧，共 **144 候选帧**逐位；AE72行同。每个故障实例恢复一次且禁用；回绕样本确实触发重置（1080每12帧24次），不是仅设置参数。见 `pressure.json` 和原始 run.log。
- 生产关闭开关/缺模块各12帧同基线。gfx1200/1201 都编译，旧 c64 三段 `.text/.rodata/.note` 不变；GPU 实跑为9070 XT/gfx1201，未声称gfx1200真机实测。
- RE9 runtime off/on 两档各12帧输出 hash 同：900 `b2980ada643da964`、1080 `758674a8bbd0206d`；日志 active=1，缺模块 active=0 且900 hash同。runtime smoke通过，RE9游戏未换装。

## 安装与回退

已在无游戏/GPU实验进程时装剑星。任务单的 b5ab8c3a 已过时，实际逐文件校验的旧宿主为 **ba010de7**（逐核地图成果）。新宿主 **046e1a63**，旧60模块、dxgi、OptiScaler.ini哈希保留；新增2模块，flags只追加 `DLSS5_HIP_SWIN_RUN=1`，DIRECT_IO=3 / MAKE_RESIDENT_EVERY=60 原样保留。没有发包或修改0.36标签。

备份：`D:\DLSSNR-Lab\hip-backend\swin-persistent-20260929\backups\stellar-20260929-172155`。
完整安装清单/哈希见 `installed.json`；源脚本 `Development/HIP/experiments/swin-persistent/install.ps1` 支持 `-RestoreBackup <该目录>`，恢复旧宿主/flags/清单并删除此次新增模块。安装脚本含进程、旧文件和payload哈希检查、异常自动回滚。

未启动游戏；剑星本机画面/FPS观察留待Zero，不把离线提升写成游戏实测。

## 后续推广顺序

1. C128 内部四层，复用同一图和恢复协议，先分别测 encoder/decoder，再组合；同样全回归、故障/回绕、两轮ABBA过0.5%才开。
2. C64 仅两层，三次安全派发未必能摊薄，先做隔离计时再投入；不因已有泛型内核就默认开。
3. 第一/最后层包含格式转换、Up/Down/skip边界，暂保留；要扩进去需重新证明布局与依赖图。
4. 双缓冲可降存储，但跨两层重用会引入反依赖，必须先证明所有旧读者已结束再复用；本次不为这点内存牺牲恢复条件。

复核：`python3 Development/HIP/experiments/swin-persistent/audit.py Development/results/swin-persistent-20260929/raw /tmp/swin-audit`。
