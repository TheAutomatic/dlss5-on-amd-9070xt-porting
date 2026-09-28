# C512融合与小通道权重复用（2026-09-28）

**已合生产、已装剑星：C512 QKV＋归一化＋attention融合，加C64/C128 FFN两qt共用权重。900两轮快3.59%/3.59%，1080快2.55%/2.63%，均约省0.31～0.33ms。**
最终组合168帧EXACT/AE逐位，驻留设置60及DIRECT_IO=3不变，不发包。C512 FFN M32、删无用float出口、900 C256 wave16未采用；ViT及边界融合本轮不扩。

## 基线与范围

- 任务：`conversation/20260928/yami-c512-fusion.md`，起点8c9a61db。
- 剑星基线宿主：61a81c75（上一轮C256 1080融合已安装）；1080工作尺寸1920×1152、900为1600×960，原post(-4,-4)、float FMA基准。
- 900保留原C256 split/PDL路径，1080保留上轮C256两qt融合；本轮900收益来自F和Sboth。
- 部署必须基于现装宿主，保留 `DLSS5_DIRECT_IO=3`。
- **`DLSS5_MAKE_RESIDENT_EVERY=60` 全程不改**；疑似每60帧尖刺由Zero另测，不混进内核提速账。
- 数学严格逐位：不改Q/K的32项平方和顺序、不改softmax树/倒数、不改FP8/half舍入边界。
- ViT每块6→5次、入口打包、C64/C128/C32边界融合属余力项，本轮不扩。

## Daniel实际组织：四个buffer不是Q/K/V/output

C512默认每块四派发：FFWD → conv → attn3 → conv；Daniel跑16块，我们当前有效13块。
不能直接把“我们的92对他的64”相减，当成同一网络能删掉的派发次数。

| object字段 | 角色 | host证据 |
|---|---|---|
| +270 | 当前块输入/前块最终输出，最后conv写回；首块可用外部输入 | 042f56、043a6c、043d8b |
| +278 | FFWD输出、第一conv主输入 | 042f64、043a54 |
| +280 | 第一conv输出feature、attn3输入、最后conv残差 | 043a83、043b19→043cab |
| +288 | attn3的attention输出、最后conv主输入 | 043b20→043cb3 |

最后conv通过`pshufd 0x4e`交换相邻280/288，明确得到主输入288、残差280、输出270。
四个buffer容量均为8192×P；容量不等于每次访问量，更不等于DRAM实际流量。
QKV在attn3内部6144B LDS中；feature必须跨attention保留供残差。

Daniel attn3：每窗口每head一个64线程组、两wave，VGPR116、LDS6144B、private/spill0。
QKV的LDS写后仅一对barrier signal/wait；attention随后只读LDS，最后写AV。
没有完整证明它两wave的精确Q/K/V分工；本候选采用明确的每wave32查询token，不照猜测写代码。

## F：删除QKV与attention之间的派发边界

新导出`c512_qkv_attention_fused`加入现c512-m32-mh模块，旧导出代码与资源保持不变。
每组一个8×8窗口、一个32通道头，64线程；Q/K/V共6144B FP8留LDS，仅一次组同步。
每wave负责两个16-token tile，QKV矩阵乘共用权重；归一化用顺序前缀传递替代float LDS往返。
attention的exp/prob片段留寄存器，AV仍写原raster FP8格式，最终projection/crop沿用现行代码。
host只跳过旧QKV生产和独立attention，接回原残差、输出布局、Stage及PDL生命周期管理。
新宏默认0；候选/生产配方显式启用，未新增用户运行时开关。

算术对照了C512原`mh_attention_fused_fp8_out`，没有盲套C256：

- QKV保持原K16片段顺序；WMMA交换A/B只改变输出排布，点积顺序不变。
- Q/K仍逐通道0..31顺次平方和、原rsqrt/max/scale、原`q8(F())`。
- softmax分母side0为key0/key2、side1为key1/key3，最后相加；仍普通`1.f/x`。
- affine乘加、半精度指数位映射、AV的key0..3累加及`fp8(F())`出口不变。

| 等工作量：一个64-token窗口、一个head | QKV WMMA | attention WMMA | 合计 |
|---|---:|---:|---:|
| 旧：3份等量QKV wave＋4 attention wave | 3×256=768 | 4×20=80 | **848** |
| 新：两wave，每wave同时做QKV与attention | 2×384=768 | 2×40=80 | **848** |

ISA静态出现52条WMMA不代表只做52次，必须乘循环次数和工作覆盖。
F资源：VGPR122、LDS6144B、64线程、零private/零spill。
每帧13块各少一次派发，实抓900 **214→201**、1080 **198→185**，C512族92→79。见两档 `topology-*.csv`；trace不参与计时。

全局QKV每窗口/head省6144B写＋完整6144B逻辑读；900/1080合计约81.20/102.24MB逻辑中间量。
但新组织由双head共用输入变为单head，输入读取重复增加：
按ISA全活跃lane请求宽度的可达路径和上界，等量旧read165632B、新212992B；旧write8192B、新2048B。
因此**不能声称总global读取减少**，更不能把请求字节说成DRAM字节或拿峰值带宽直接预测收益。
旧QKV等量21个group-sync加attention的3个，与新的一次组同步也不是可直接相加的耗时。

## S：C64/C128复用同一份FFN权重

把上轮C256 B的两qt权重共用推广到C64/C128；每个累加器的K、ht/tile顺序不变。
宏`W2_FFN_QT_SMALL_MASK`默认0，1=C64、2=C128、3=两者；C256和attention-only路径不改。

| 主力bi_bo（每wave） | WMMA旧/新 | FFN权重请求旧→新 | 每lane权重字节旧→新 | VGPR旧→新 |
|---|---:|---:|---:|---:|
| C64 | 456/456 | 192→96 | 1536→768 | 140→140 |
| C128 | 744/744 | 320→160 | 2560→1280 | 144→159 |

两者LDS仍8/16KiB、零spill；C128增加15个VGPR，不能只报加载减半而不记资源代价。
S64、S128分别短筛都有小收益，Sboth进入组合；不会通过修改其他通道来混淆其收益。

## 已关候选

| 候选 | 做法 | 结果与决定 |
|---|---|---|
| D | `_t8`只删后续无人消费的float contract写，保留contract8 | 未见明确计时收益，不采用 |
| M | C512 FFN每组16→32 token，共用expand/contract权重 | 短筛慢约0.10～0.15ms，不采用 |
| MD | M加D | 仍慢约0.10～0.15ms，不采用 |
| W16 | 900 C256每head两wave、每wave两qt，K/V通过原两平面交换 | 逐位但短筛慢0.12174ms，不采用 |

D删除的float出口按张量为900约54.13MB、1080约68.16MB逻辑写；计时仍在噪声附近，不能用这些字节代替收益。
M/MD每等量输出WMMA不变、权重请求减半，但VGPR113→216，LDS4160→8320B；无spill不代表驻留不受影响。
W16四导出VGPR208/200/208/200、32KiB LDS、零spill，比8wave组织多两次barrier。
W16的900-motion12帧逐位；900短ABBA基线8.9411875ms、候选9.06292857ms，约+1.36%。
1080不启W16，仅作为控制，差约+0.00861ms；不会把控制噪声说成新路径收益。
不重跑已失败的mix→expand→contract融合；本轮F是不同的QKV→attention边界。

## 正式验证与计时

组合C按最终生产host及双架构配方构建，EXACT/AE各7×12帧共168帧同09-28 float FMA goldens，无NaN/Inf；AE仍44复用/40刷新，84行全部决策字段相同。独立F也通过168帧，8个短筛候选各12帧，共432个候选帧同golden。另按游戏当前CODEC_SRGB=0配置补F/C各12帧，均与基线逐位；它们单列为24帧，不混进CODEC_SRGB=1固定回放goldens。

最终两轮ABBA每槽1000帧丢200，只在首尾读回。所有运行前后查游戏/benchmark进程；保留DIRECT_IO=3、MAKE_RESIDENT_EVERY=60、PDL=1、BENCH_PLAIN=1。离线验证覆盖输入直写，不冒充游戏FSR输出直交测试。

|档位|第一轮基线→组合 ms|第二轮基线→组合 ms|Δms / 百分比|
|---|---|---|---|
|900|9.046038→8.721419|9.108684→8.781375|−0.324618/−0.327309；−3.589%/−3.593%|
|1080|12.131856→11.822138|12.149375→11.829512|−0.309719/−0.319863；−2.553%/−2.633%|

短筛为200帧弃32。F的900/1080分别−0.233473/−0.177164ms；S64 −0.055723/−0.044045；S128 −0.037568/−0.063872；Sboth −0.101991/−0.157682。D只有−0.006542/−0.002509ms，未取；M +0.113899/+0.143658、MD +0.102473/+0.139048、W16 +0.121741/+0.008613（1080为未启用控制）。组合使用上表实测，不是短筛相加。

80个短/长计时槽原序列在 `timing-series.json`，均独立复算；逐位/AE与统计见 `frame-hashes.csv`、`adaptive-decisions.csv`、`summary.json`。C256四个整块导出及两个attention-only导出的ISA也核对不变（`c256-unchanged.json`）。两模块双架构新宏关闭时.text/.rodata/.note同原版；生产gfx1201与实测F/Sboth代码相同，见 `module-code-identity.json`。gfx1200仅编译核对，真卡测试gfx1201。

## 剑星部署

新宿主 **257a2fdb** 基于61a81c75；只增加C512融合路由，复用原projection/crop尾部。每架构更换c512-m32-mh和c64-wave2，共4个模块；gfx1201分别 **51c2fa1a / abffcd1a**，gfx1200 **7d9e0068 / dfdf3970**。其他56个模块、flags、输入shader、dxgi/OptiScaler均保持原哈希。

备份：`D:\DLSSNR-Lab\hip-backend\c512-fusion\backups\stellar-20260928-210508`。含原宿主、4模块及SHA256SUMS；安装前查游戏，备份/载荷/安装读回均校验，异常自动还原。可用 `install.ps1 -RestoreBackup <该目录>`还原。完整哈希见 `payload.json`、`installed.json`、`current-host.json`。

**DIRECT_IO=3、MAKE_RESIDENT_EVERY=60未改**。不发包；游戏本机FPS及驻留设置0的p99实验留给Zero/Hikari，不用离线百分比替代。

## 复现入口

`HIP/experiments/c512-fusion`中，`prepare-candidates.py`从8c9a61db生成隔离候选；`make-candidate.py`生成F，`build*.ps1`编模块。`build-runner.sh`构建独立F/M/W host；`build-production-runner.sh`构建最终host及add-on。`regression.ps1`、`validate.ps1`、`collect*.ps1`和`analyze-results.py`完成回放、采集、golden/AE对拍；`trace.ps1`只用于派发核对。`audit.py`、`f-account.py`、`share-account.py`给ISA/资源及等工作量账。二进制、完整RGB及完整ISA只留实验目录，未提交仓库。
