# C512 mix 第四轮：分段账与精确half供数实验

基线为剑星第三刀；远端 `D:\DLSSNR-Lab\hip-backend\c512-mix`。ViT候选独立测试，本目录测试时ViT stream=0。

## 分段账

沿用第三轮复编一致的C512基线ISA，完整32token的mix wave，K512循环32次，条件路径按上界。普通向量=VALU+VOPD；WAIT是指令不是周期。

| mix段 | 普通向量 | VMEM | WMMA | WAIT |
|---|---:|---:|---:|---:|
| 地址准备 | 50 | 0 | 0 | 9 |
| K512主循环 | 1120 | 256 | 256 | 640 |
| F(Hrtz)量化与写出 | 701 | 64 | 0 | 126 |
| 合计 | 1871 | 320 | 256 | 775 |

主循环A=f32，B=f16；每wave请求A64KiB+B64KiB，同一B已喂32token。把上游A直接变half最多先省32KiB（A+B的25%），但packed张量还被后续projection作残差读取，并且有shift/identity两类生产者，不能只改mix读指针。量化尾部普通算术也不少，故仅靠计数不能断言已经打满DRAM带宽。

其余C512核的加权账（同上轮，单wave）：

| 核 | 普通向量 | VMEM | WMMA | LDS |
|---|---:|---:|---:|---:|
| split_ffn_fused_fp8_t8 | 699 | 56 | 32 | 48 |
| split_projection_frag | 593 | 260 | 128 | 0 |
| mh_qkv_normalize_frag_c512_m32 | 1117 | 198 | 256 | 174 |

已知实测证据：上一轮C512 M32共享权重有效，单改写出很小，投影M32不赚（`../c512-ffn-20260926`）。因此先做数据接口的小实验，再根据收益决定继续；没有用指令数冒充硬件利用率证据。

## H：mix→FFN 的 F16 接口

mix仍以原f32输入、原f16权重做同顺序矩阵乘；把原 `F(Hrtz(acc))` 存成half。F的有限FP8格点（包括正负零）均精确可表示为half，FFN原本也先将这些f32值转成half，直接读取不会改变WMMA操作数。mixed只被此FFN消费，projection的残差仍是原packed f32，避免扩大改动。

`prepare.py` 在实验目录生成默认关闭的 `HIP_C512_HALF_EDGE` 与两个具名kernel：mix_hout、ffn_hin。单独c512-half模块、配套实验host；不改变旧kernel ABI。诊断env `DLSS5_HIP_C512_HALF` 只属于实验host，尚非生产/RE9开关。

- mix写出字节减半，但它额外增加精确f32→half转换：普通向量1871→1938，VMEM320不变，WMMA256不变。
- FFN直接读half：普通向量699→663，VMEM56→52，WMMA32、LDS48不变。
- 相同32token×64通道组：一个mix wave + 八个FFN wave，普通向量合计少221条。mixed写出8→4KiB，FFN的重复mixed读取32→16KiB；主mix的128KiB读取完全没少。
- 没有新增转换kernel，没有MODE切换，没有借用C32/C64的census。若后续尝试MODE，须为实际新段另做census。

双架构已编；无scratch，mix分配VGPR96，FFN107、LDS4160B。详细opcode、数据字节与脚本在本目录/experiments/c512-mix。

## 实测与决定

EXACT与AE各七组84候选帧，连基线336份RGB逐帧hash，全同；AE 43次reuse、41次refresh，84组决策逐字段相同。双架构编译，gfx1200无实机。计时每槽1000帧弃前200，PDL=1，ViT stream=0。

| 档位 | ABBA批1 A→H | 批2 A→H |
|---|---:|---:|
| 900 | 9.3692→9.3837（+0.0145ms） | 9.4227→9.4311（+0.0083ms） |
| 1080 | 12.9272→12.9293（+0.0021ms） | 12.9479→12.9534（+0.0055ms） |

**不采用H，不合生产配方、不装游戏。** 这次同时减少mixed读写与部分转换，仍没有收益，因此不继续推广这条具体接口；不能由此单独排除访存受限，更不能反推出“纯VALU受限”。主mix的输入/权重128KiB读取没有减少，尾部反而增加67条向量指令，各因素的耗时贡献尚未分离；当前证据更适合描述为主循环供数/转换与尾部的混合开销，尚无硬件计数器证明DRAM饱和。

据此，继续做数据形态时应针对真正的packed输入（同时处理shift生产者和projection残差），而不是再压mixed出口；或者先做尾部算术的独立敏感性/census，再决定是否值得用MODE。这里明确保留归因边界，不拿VMEM条数当带宽利用率，也不为零收益接口增加生产复杂度。
