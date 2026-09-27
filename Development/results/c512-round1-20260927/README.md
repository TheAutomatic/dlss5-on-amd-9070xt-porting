# 第六刀：C512 的驻留、并行度与精确尾部（进行中）

基线：09-27 23:06 装剑星的第五刀（c64-wave2 gfx1201 f60eaee8），ViT stream=3，PDL=1。实验根 `D:\DLSSNR-Lab\hip-backend\c512-round1`，从游戏现场复制两架构模块，未修改游戏。目标900整网至少−0.5%，1080不退步，EXACT/AE各七用例逐位。禁止split-K。

## 测量与暂态阻塞

900已完成三组ABBA重复派发（每槽20预热+160计时，每个目标额外重复两次，增量除以2）。每槽后原始FP32整网输出与固定fixture逐位比较；六核共75次检查。复制派发改变缓存复用/功耗，这是边际成本，不是六段独占时间，不能直接相加还原整帧。

1080运行期间用户启动《33号远征》`SandFall-WinGDK-Shipping.exe`；基线12.5ms逐渐涨至21ms。已停本实验的ledger进程，未关闭游戏。`rejected-1080-game`保留受污染原始数据，禁止纳入结论。原Idle只列四个游戏，漏了新游戏；本实验脚本改为匹配所有`Shipping`进程及RE9/鬼武者。等游戏关闭重跑1080账本和候选GPU验证。候选编译不使用GPU，已经进行。

## 首轮900资源账

通过实际生产`Run`记录每次grid、threads；`hipFuncGetAttribute`取VGPR/LDS/private，`hipModuleOccupancyMaxActiveBlocksPerMultiprocessor`取静态驻留上限。驱动报32 MP（WGP）、wave32、2048 threads/MP、64KiB LDS/MP。64 CU不是此API的MP单位。API容量不是动态占用率；不使用旧trace工具的REALTIME消息计数（它会串行化）。

| 核（13次/帧） | 900组数/次 | wave/组 | VGPR | LDS字节 | API组/MP | 全卡可驻留wave | 三轮边际均值ms |
|---|---:|---:|---:|---:|---:|---:|---:|
| mix M32 |448/560|1|96|0|64|2048|0.231|
| split FFN t8 |896/1120|4|112|4160|12|1536|0.222|
| FFN projection |896/1120|1|83|0|56|1792|0.185|
| QKV M32+norm |1344/1680|1|155|5456|12|384|0.478|
| attention |448/560|4|103|15360|4|512|0.168|
| attention projection |896/1120|1|80|0|64|2048|0.236|

所有核private=0。当前C512实际工作token为1792/2240（6/7层），即28/35个8×8窗口；1080为2560即40窗口。旧“104/135窗口”不能用于本次C512核账；104是本次C256 attention可见的组数。注意力本来按16头拆组，不是只有28/35组。

mix总wave仅API容量的22%/27%，但仍有每SIMD约3.5/4.4个wave，不能由此宣判“CU没有工作”。QKV则有3.5/4.375轮驻留容量，LDS限制比组数少更直接。按输出通道拆mix可能增加并行度，也会重读A，必须测净值。

## 候选

全部只生成在实验目录，宏默认0。R/Q/N/L/Z双架构已编，双架构Z共四个模块`.text/.rodata/.note`与现场基线完全同；GPU七用例和计时尚待。

- R，`C512_MIX_PAIR`：两个独立结果共享RTZ转换和FP8打包；保留clamp、精确零规范化、原K顺序。每wave普通向量1871→1657，VMEM320、WMMA256不变；VGPR96→97，LDS0。
- Q，`C512_QKV_DIRECT`：用现有`q8_fused_round`替代`q8(F(...))`，不碰归一化求和、MODE。普通向量1117→939，VMEM198、WMMA256不变。
- N，`C512_MIX_N32`：独立具名核每wave输出32token×32通道，组数翻倍，K512从头到尾仍由同一wave顺序累加，非split-K。单wave普通向量1509、VMEM224、WMMA128；两wave才等价旧一个，指令/重复A读取增加；VGPR62。配套实验host按候选模块目录选择新导出，生产host未改。
- L，`C512_QKV_LDS_ALIAS`：QKV串行归一化后raw[0..1039]已死，输出复用其头1024字节；系数保留raw[1040..1071]，与输出不重叠。现有同步隔开写raw、读raw/写系数、写字节、读字节四阶段。无新增转换，无接口变化。编译LDS5456→4420B、VGPR155不变、private0；仅按64KiB LDS可容纳14组（原12），实际API容量及GPU收益待验证。

ISA用实际CFG自然循环加权，mix K16×32，QKV K循环×8、token尾循环×2；WMMA分别用独立公式校核256/256（N128）。互斥分支按上界，WAIT是条数不是周期。完整脚本`isa.py`和`isa-weighted.json`。

## ACO并行度对照

读取本机`~/work/aco-isa`实际SPV manifest与对应host，非仅shader默认宏：`ffwd_wgw=4`、`ffwd_fm2_min=2560`、`gemm_proj_mt=32`、`gemm_proj_nt=128`。文件SHA在aco-source-hashes.json。

- ffwd3：每wave负责一个64通道组，4wave/工作组；小几何每wave16token，达到阈值才32token。组数`ceil(M/16)/FM * (8/4)`。为同一填充M归一化，900为224/280组、896/1120wave；2560token宽版160组、640wave。其实际M来自有效tile域，不等于我们的padding域，以上是尺度对照，不是对方运行计数。
- 它将mix→expand→contract融合，片段在寄存器传递，选择较少的wave换中间搬运；不是普遍把组数加到最多。其数学/量化不同，不直接照抄。
- gemmproj实际tile32×128（4wave，各32×32）：同M、N512时224/280/320组，每组4wave；我们16×64、1wave组896/1120/1280。总wave相同，分组形态不同，不能用组数直接判断哪边快。
- C512 attention的host按窗口XY×headZ=16派发，源码注明头拆分。我们的生产attention同样按头分组；“对方有按头拆分”不是一个尚未采用的新改法。

## 剑星900实测设置

`DLSS5_NETWORK_HEIGHT=auto`（或显式900），1600×900窗口+FSR原生AA最直接；2560×1440+FSR质量档通常render=1707×961，两轴都在1600×900的110%内，auto同样选900。固定同一中画质/场景，F8切EXACT、看黄字小数和900网络几何。若场景贴60，换主菜单或较重场景；不能拿锁60的读数判断0.5%收益。此处依据已有剑星实测记录及ForInput实现，本轮未启动/改动游戏设置。

## 续跑

游戏关闭后用实验根`resume.ps1`：归档受污染1080目录，重测1080资源/边际账，再依序R/Q/N/L的EXACT七组、AE七组与两批长槽ABBA。逐帧RGB比较由regression.ps1执行，collect-adaptive.ps1导出决策后须再核对相同。任何候选未过900≥0.5%门槛不合配方；通过后再做最终组合/生产代码身份与安装备份。当前所有候选均未验逐位、未计时、未采用。

本地重建：prepare.py复制当前源码并编ledger，variants.py在实验副本生成宏与候选，prepare-n.py编N专用回放host；复制实验树至远端后用build.ps1。不要重跑stage.ps1覆盖既有基线。所有exe/hsaco只留实验目录，不提交仓库。

HIP占用率查询API依据：[AMD HIP Occupancy](https://rocm.docs.amd.com/projects/HIP/en/latest/reference/hip_runtime_api/modules/occupancy.html)。本报告表内资源值来自本机实查，而非从文档推算。
