# ViT attention：逐位优化通过，已装剑星（2026-09-29）

**采用正常half精确转换＋寄存器内成对FP8编码＋分母/AV输出转置。** 在现役C256持久化基础上，两轮整网900快2.20～2.28%、1080快1.50～1.58%，均超过0.5%。只替换两架构的deep_fast-packed模块，宿主046e1a63不变，没有发包。

## 整网 ABBA

每槽1000帧弃前200，A-P-P-A；同一canonical宿主、同一C256/PDL配方，候选只换一个gfx1201模块。MAKE_RESIDENT_EVERY=60、DIRECT_IO=3、SWIN_RUN=1。完整NativeGameFrame wall，不是纯HIP或游戏FPS。

| 轮次 | 档位 | 基线 ms | 候选 ms | 节省 ms | 提升 |
|---|---|---:|---:|---:|---:|
| 1 | 900 | 8.306088 | 8.117038 | 0.189050 | 2.276% |
| 1 | 1080 | 11.206715 | 11.038179 | 0.168536 | 1.504% |
| 2 | 900 | 8.314972 | 8.132057 | 0.182916 | 2.200% |
| 2 | 1080 | 11.199951 | 11.023446 | 0.176506 | 1.576% |

原始16槽CSV在raw，独立重算timing-slots-P.json / timings-P.json。没有和尖峰测试混跑，没有改MAKE_RESIDENT_EVERY来制造收益。

## Daniel怎样组织，50µs差在哪里

[逐段机器码拆账](isa-account.md)含对应地址、指令族及四类归因；完整反汇编/逐mnemonic计数在isa/。Daniel050/051的这个reference核代码字节完全相同，四wave一组，每wave16query/head，一轮64key；Q/K blocked、V channel-major，score/softmax留寄存器，LDS0，用half-wave bpermute重排。reference的score、分母树、AV中间累积和末端乘法有half舍入，**并不是我们的0.36逐位数学**，不能整体照搬。

我们的主要浪费是已知正常数仍走通用from_half：每16key八份NaN/Inf/denormal分支及EXEC恢复。clamp+bit-map只可达552种正normal half（0x1c20..0x3e90）；穷举确认其float扩大与旧软件解码逐位相同。改native转换，再把已知<2的概率成对编码，去掉冗余clamp与逐字节拼接。AV交换乘法操作数使query落在lane，分母WMMA同样转置，保留逐K16累加顺序，只需每lane一次严格倒数；最后写回原布局。

| 同批微测（micro7） | 400：现役900形状 | 448：仅形状对照 | 640：现役1080形状 |
|---|---:|---:|---:|
| 基线 | 37.991µs | 49.850µs | 70.770µs |
| 仅native half | 16.383 | 20.072 | 50.484 |
| ＋成对概率编码 | 15.106 | 16.090 | 41.946 |
| ＋AV转置（采用） | 15.017 | 16.550 | 37.885 |

640单次attention约50µs差距中，约33µs已由逐位候选实际消掉；仍比Daniel约22～24µs慢约14～16µs。每帧有8个attention派发，微测差值不可直接相加冒充整帧收益。400和Daniel900的448不混比；448没有加入生产档位。

剩余差异有明确结构证据：同64key，我方V读取64条u8、Daniel8条b64（逻辑V字节量相同，不等于DRAM带宽比）；我们还保留4条float累加的分母WMMA，Daniel用half归约。限定V=+1的诊断（先逐位，再把读取替成常量片段）显示640移除V相关取数/地址/打包代码约省6～10µs，但这不单独等于访存时间。剩余每一微秒未唯一分解成硬件stall；没有为追平改成他的half算法。

## 试过哪些组织方式

只改head顺序、四wave同组、四keytile预取、组合，以及native转换后再叠加，均做了隔离输出逐字节检查再计时。多数持平或变慢；四wave＋四tile在640约72～73µs，叠native后仍约55.6µs，比保留单wave差。它们没有进入生产。寄存器成对概率编码不改变张量布局，没有重跑旧P/G/Q/R或消费端float打包V路线。123个隔离job过程/7轮TIME全部保留在micro.json和raw/micro*。

## 资源、代码身份、同步

- 原/新都block32、每wave16query/head；900 grid800、1080 grid1280，派发数不变，整网仍179/162。没有新增LDS、barrier、轮询或全局队列；C256持久化及PDL原样保留。
- 两个目标核 VGPR **72→68**、SGPR **16→12**，LDS/private/spill均0；机器码 **5600→2944B**。驱动occupancy API两者都100%，Daniel为75%，这是理论上限，不是运行时profiler测量。
- 同16key静态循环体：branch/EXEC42→1、wait/delay133→11、VALU245→84；VMEM18、WMMA5均不变。含不可达异常分支的静态数，不当动态执行次数或周期。
- 三宏 `HIP_VIT_ATTN_NATIVE_HALF`、`HIP_VIT_ATTN_PROB_PAIR`、`HIP_VIT_ATTN_TRANSPOSED_AV` 源码默认0，生产deep_fast-packed配方显式开1。两架构强制全0的.text/.rodata/.note逐段同基线；开1只改变400/640两个bytein_bout函数，另74函数及其元数据相同。
- 生产两个目标函数与微测probe_pair_transpose机器码、ABI元数据（去函数名）逐项相同；双架构均确认。gfx1201有9070实跑，gfx1200编译/静态验证。

## 逐位与回绕

正式EXACT/AE各7×12=168候选帧全部命中09-28 float FMA golden，无非有限，AE84行逐字段相同（44复用/40刷新）。再做900/1080 history×EXACT/AE的48帧强制回绕，全部命中golden，AE24行同；每12帧确实24次C256票号重置，无错误或回退。合计**216候选帧、108行AE**。

RE9共用后端另用同一既有runtime和两个module目录，对照1707×961输入、900/1080各12帧，输出hash分别仍为b2980ada643da964、758674a8bbd0206d。未重编DLL，未替换鬼武者或RE9游戏。

## 剑星安装

19:47已安装，备份：`D:\DLSSNR-Lab\hip-backend\vit-attention-20260929\backups\stellar-20260929-194730`。仅替换：

- gfx1200/deep_fast-packed.hsaco：`1d816dc11d2fdbad641dabb992f395efa7bc912cc0ef571a8d8c31b06d10a180`
- gfx1201/deep_fast-packed.hsaco：`1750899ddf3e6b30283bb195630f5252ce1dbc3c5c0089abcb178038084228aa`

宿主046e1a63、其余60模块、dxgi/ini/flags全部原SHA，模块总数仍62；DIRECT_IO3、MAKE_RESIDENT_EVERY60、SWIN_RUN1保留，HIP/SHA256SUMS重建并读回验证。安装前66项快照未变；无游戏进程时操作。install.ps1备份3个改动文件，异常回滚，支持-RestoreBackup。installed.json含完整载荷与备份记录。

没有启动游戏，现场画面/FPS尚未观察；没有发布新包或改0.36标签。GPU计时全部结束，之前压着的尖峰实验可以另排。

复现入口 `Development/HIP/experiments/vit-attention/README.md`，原始产物在DGX `/home/lmxxf/work/vit-attention-20260929`、9070同名lab；hsaco/exe/f16不入仓，SHA见artifact-hashes.json。

```sh
python3 Development/HIP/experiments/vit-attention/audit.py Development/results/vit-attention-20260929/raw /tmp/vit-attention-audit
```
