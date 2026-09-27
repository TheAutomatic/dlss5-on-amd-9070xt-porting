# ViT 第四轮：显式 FP8 AV + F16 contract 接口

基线为剑星第三刀：c32 gfx1201 1753400c、add-on 86ef4182，任务单 eda801c。实验根 `D:\DLSSNR-Lab\hip-backend\vit-bytestream`。

## 正式分派

新增 `hip/vit_stream.inc`，`HIP_VIT_STREAM_KERNELS` 默认0，新模块vit-stream的生产配方开1。运行开关 `DLSS5_HIP_VIT_STREAM` 默认0：1=AV字节，2=contract半精度，3=两者。通过独立kernel名/host分派绑定生产者和消费者，不改变旧kernel的ABI。

- bit0：现有attention `_bytein_bout` 输出FP8，申请n×1024字节；独立 `vit_stream_project_n64_b` / `_bh` 直接读字节。
- bit1：fragment contract输出F16（F输出的FP8格点精确可表示为F16），申请n×1024×2字节；QKV fragment直接读half，投影残差同步读half。矩阵权重布局、累加顺序、半精度舍入、归一化和最终f32输出不变。
- 保留n64、fragment权重和整组f32边界/AE缓存；每个新增kernel继承reuse_gate。复用命中时不读未生成的中间张量。
- 兼容条件在 `VitStreamCompatible`：既有n64与生产fragment路线，不与legacy byte_stream / split-K / fused-FFN混用。不兼容时mask active=0并保持原路径；请求兼容新路径却缺模块，常规host明确报错；RE9沿现有约定回落并记录requested/active。
- 公共env解析与RE9模板同步；`options-probe.cpp` 检查0..3、布局回落与非法参数拒绝。新增模块独立编译，旧模块不需重编。

## 剩余 f32 边：先估流量再选

生产900/1080的ViT token数n=400/640；下表是八块合计的shader请求量，包含不同wave重复读取，不等于DRAM实测流量。

| 边 | 当前形态与可压形态 | 可省请求量 900 / 1080 | 决定 |
|---|---|---:|---|
| attention AV→n64投影 | f32上的FP8格点→FP8字节 | 读150 / 240 MiB；写9.375 / 15 MiB | V1 |
| contract→QKV | f32上的FP8格点→F16，直接给f16 WMMA | 读600 / 960 MiB | V2 |
| 同一contract→投影残差 | 与上面共用F16张量 | 读6.25 / 10 MiB；contract写另省6.25 / 10 MiB | V2绑定修改 |
| block输出→下一块expand的pack | 当前先f32写出再独立pack；生产者可双写字节 | 七条跨块边省f32读10.9375 / 17.5 MiB，省7次pack派发；字节写总量未减少 | 收益小于QKV，列为后续，不扩大本轮 |
| hidden→contract | 已是FP8字节 | 0 | 不动 |
| QKV→attention | 已是FP8字节 | 0 | 不动 |
| block输入→contract残差 | f32；可能用F16/FP8，但与expand、组边界和AE输入统计共用 | 仅contract读取可减6.25 / 10 MiB（half）；需同时审核入口Gather与缓存统计 | 本轮保留 |
| 整组输入/输出→AE缓存 | f32，判断和差值修正依赖它 | 要改缓存读写与统计，收益不等同于内部接口 | 本轮保留 |

没有新增独立转换/重排kernel。half出口增加每个元素一次精确f32→half，而QKV多次读取的f32→half被整批去掉；收益要扣除生产者增加的指令，以V2整网实测裁决。

## 指令账（gfx1201，循环加权）

计数按每wave；VOPD按一条发射指令，条件尾部按上界，WAIT不是周期。原始static账、加权opcode与循环范围在JSON及ledger.py。

| 核 | 普通向量 A→候选 | VMEM A→候选 | WMMA | 读取/wave |
|---|---:|---:|---:|---:|
| n64投影，仅字节AV | 3128→764 | 452→388 | 256 | 132.5→84.5 KiB |
| n64投影，AV+half残差 | 3128→779 | 452→388 | 256 | 132.5→82.5 KiB |
| QKV fragment，half输入 | 1338→350 | 287→223 | 130（Q/K含2次求平方和） | 129.875→97.875 KiB |
| contract fragment，half输出 | 1191→1214 | 1348→1348 | 1024 | 读取不变，写减半 |

数据形态同时省转换、寄存器与VMEM，因此不能用本实验单独归因“只有带宽”或“只有算术”。相比前轮只砍VALU的DF_PACK8，本轮确实减少生产者→消费者字节量。

## 验证与测速

V1/V2独立对照新host mask0；V3/V4直接对照旧benchmark宿主+当前剑星模块，将新host分派成本也算进去。EXACT/AE各七组12帧；两档ABBA每槽1000帧去前200。

四候选共672个候选帧全部逐位，连基线1344份逐帧hash；EXACT全部还与第三轮实装golden逐帧相同。AE每候选43次reuse、41次refresh，合计336组决策逐字段相同。192行测量、192条启动身份；其中52条来自旧host（没有新stream字段），140条新host有requested/active字段。所有计时槽首尾hash相同。

| 候选 | 900批1 / 批2（ms差） | 1080批1 / 批2（ms差） | 结论 |
|---|---:|---:|---|
| V1：AV字节 | −0.0483 / −0.0190 | −0.0691 / −0.0697 | 组成部分 |
| V2：contract half | +0.0194 / +0.0407 | −0.1013 / −0.0939 | 低档不赚，1080有效 |
| **V3：两者组合** | **+0.0015 / +0.0056** | **−0.1784 / −0.1587** | **采用；900基本持平** |
| V4：组合+QKV unroll2 | −0.0102 / −0.0153 | −0.1547 / −0.1419 | 小幅改善900，但1080少赚，不采用 |

V3的EXACT整网：900 **9.3111→9.3126 / 9.3975→9.4031**；1080 **12.9144→12.7360 / 12.9244→12.7657**。**以标准剑星1080档的整网EXACT为门槛，实测−1.38% / −1.23%，超过0.5%；不声称900也过门槛。** 两个独立候选的百分比不相加。

另测V4（同mask3，QKV强制unroll2）：half输入的自动展开从原f32核的2倍升到8倍，VGPR59→96；强制2倍降至48，无scratch。相应普通向量350→446、WAIT408→512；降低寄存器并未带来更好的1080整网成绩，宏 `HIP_VIT_STREAM_QKV_UNROLL` 默认0、配方保持0。900差异没有被这一试验完全解释，不把它归结成已证实的单一瓶颈。

AE运动序列（sequence1，千帧，计时关闭逐帧诊断同步）另做两批ABBA，V3对旧host：

| 档位 | 批1 A→V3 | 批2 A→V3 |
|---|---:|---:|
| 900 | 8.6687→8.6352（−0.0336ms） | 8.7744→8.7820（+0.0075ms） |
| 1080 | 11.9736→11.9339（−0.0396ms） | 11.9835→11.9409（−0.0426ms） |

1080 AE为−0.33% / −0.36%，符合复用帧跳过ViT后平均收益被稀释；900无稳定收益。这里是指定回放，不是游戏FPS或所有AE命中率下的保证。AE决策覆盖另由逐帧七组日志验证。

## RE9与生产验证

新键走公共 `NativeApplyHipEnvironment`，常规/RE9共用相同解析。RE9 runtime重编，mask0/3各12帧hash同为082162677c863395，日志分别显示vit_stream=0/0、3/3。新模块齐备和缺模块两个smoke均通过，缺模块明确记录 `vit_stream:nomodule vit_stream=3/0`。RE9 DLL留在实验目录，未换RE9游戏。

生产配方双架构重编与实测V3的 `.text/.rodata/.note` 相同；新宏本体默认0，vit-stream模块配方开 `HIP_VIT_STREAM_KERNELS=1`。Options默认mask0，三种发布模板与本次剑星部署设 `DLSS5_HIP_VIT_STREAM=3`。gfx1200仅编译，无实机验证。

## 部署

2026-09-27 21:02已装剑星：新add-on4151123e、新vit-stream两份（gfx1201 ad59f7be / gfx1200 0c9171ee），flags新增stream=3。使用实测模块，旧模块全保留。部署目录 `Development/deployments/vit-bytestream-20260927`，安装脚本按哈希预检、备份/失败回滚/显式还原；不发包。

备份：`D:\DLSSNR-Lab\vit-bytestream-20260927\backups\stellar-20260927-210229`。C512 H无收益，未合入；本次实装是独立测过的V3，没有把其它候选收益相加。画面/FPS待Zero。
