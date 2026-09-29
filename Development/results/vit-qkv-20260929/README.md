# ViT QKV 追 Daniel（逐位部分）：五wave共享权重，逐位通过，已随新宿主装剑星与鬼武者（2026-09-29）

**更新（21:08，协调者批准换宿主）**：生产配方 vit-stream 开 `HIP_VIT_QKV_W5 1`，新 add-on 宿主 **b77bbc3c**（HEAD源码，046e1a63+本改动），RE9 runtime **2c103f6e**。配方模块 gfx1201 e727a883 / gfx1200 9d31ab5f（.text/.rodata与已测w5逐字节同）。复跑216帧全SAME；一轮ABBA 900 8.088514→7.976056（−0.112ms，1.39%）、1080 10.936476→10.819673（−0.117ms，1.07%），见 full-prod.log。RE9 runtime：旧runtime旧模块/新runtime+W5/新runtime旧模块 三者900/1080 hash同（b2980ada643da964/758674a8bbd0206d），smoke通过。剑星只换add-on+两份vit-stream、重建SHA256SUMS（62模块），flags原样（DIRECT_IO3/MAKE_RESIDENT60/SWIN_RUN1），备份 `D:\DLSSNR-Lab\hip-backend\vit-qkv-20260929\backups\stellar-20260929-210818`。鬼武者：Content与_storage_两份runtime换新，HIP模块与剑星对齐，flags不动（无新开关），备份 `D:\DLSSNR-Lab\onimusha-backups\20260929-210818-vitqkv`。没发包、没启动游戏。注：add-on同源码两次构建 .rdata 有约6KB不同（构建不确定），无法用段比对复现旧宿主。脚本 install.ps1（-RestoreStellar/-RestoreOni）、runtime-check.ps1。

**原结论**：新导出 `vit_stream_qkv_frag_hin_w5`（宏 `HIP_VIT_QKV_W5`，默认0）逐位同现役，整网 1080 快 0.74/0.81%（过0.5%），900 快 0.42/0.51%。**它要求宿主按160线程/新grid发射**，只换模块启用不了；按"宿主046e1a63不动"的规矩**没装剑星、没发包**，等 Zero 拍板随下一版宿主一起上。

## 差距拆账（640 token，1080档，单核微测）

| | 我方现役 | 我方w5 | Daniel reference |
|---|---:|---:|---:|
| 单核 µs（3轮中位附近） | 48.8 | 37.0 | 31.8 |
| WMMA | f16 16x16x16 | 同 | **fp8** 16x16x16 |
| 组织 | 3840个1-wave组；每wave 16token×32列(一个head) | 768个5-wave组，一head五token tile | 120个8-wave组；每wave 32token×64列 |
| 权重来源 | 每wave自己从global读 | 每组经LDS共享（8KB块双缓冲，每块1次barrier） | LDS共享 |
| 每K16每wave global读 | 3条b128（1536B） | ≈1.4条（717B） | 按K32：4条b64 / 16 WMMA |
| VGPR/LDS | 96 / 2112B | 113 / 16KB | 168(1 spill) / — |

- **组织方式（已做，逐位）**：我方每条WMMA配1.5条global读，L0/TA带宽先到顶；主循环本身软件流水已很紧（8步展开、等待按序），不是编译器产物问题。w5把权重读取除以5且**不减wave数**（m32/C512投影负账都是减wave死的），640 −11.8µs、400 32.2→26.5µs。
- **数值不同（不做，C段）**：Daniel 激活和权重都是FP8、fp8 WMMA（字节减半、吞吐翻倍），每K32 fp32片内和再**half累加**；余下约5µs基本就在这里。我方FP16 WMMA纯算力下限估约21µs，Daniel FP8约10µs。
- **归一化段**：他 bpermute+rsq，我们 LDS+WMMA平方和（half平方、f32累加是现役数学，必须保留）；尾部占比小，未改。
- **源码写法**：scale 每次store后重读（别名）→ 提前读一次（`HIP_VIT_STREAM_QKV_HOIST`）逐位但微测不快甚至略慢，不收。
- **只换模块的路都试了**：块→(part,token,head)三种重排（`HIP_VIT_QKV_ORDER` 1/2/3）逐位但全部变慢5～8%；CH=4/16、数组写法的w5都更慢（数组版丢掉大半收益），只保留4寄存器CH=8写法。

## 微测（jobbench，每job 7轮×128次，输出与base golden逐字节比较，全部 different=0）

| µs | base | w5 | hoist | o1 | o2 | o3 |
|---|---:|---:|---:|---:|---:|---:|
| 400 | 32.1～32.2 | 25.8～27.2 | 32.6～33.2 | 34.7～34.9 | 35.5～35.9 | 33.4～38.3 |
| 640 | 48.7～48.8 | 36.8～37.1 | 50.3～50.5 | 51.6～51.7 | 52.5～52.8 | 52.5～52.6 |

Daniel 050 640：31.8～31.9µs（不同数学，只作计时参照）。批次间有漂移（首批base400 37µs），以同批三轮为准。原始日志 micro-logs.zip，job定义 micro-jobs.json。

## 逐位

基线=lab现役宿主 benchmark-base.exe + 剑星现装31模块（已核0.36 golden）；候选=新宿主 benchmark-P.exe + 只换 vit-stream.hsaco。EXACT/AE 各7用例×12帧逐帧SHA同、AE决策CSV同；900/1080 history×EXACT/AE强制票号回绕48帧同（benchmark-Proll.exe）。合计216帧，18组 SAME，无差。见 full.log。

## 整网 ABBA（每槽1000帧弃200，A-P-P-A；A=同工具链编的现行宿主 benchmark-A.exe+flat-A，P=新宿主+flat-P）

| 轮 | 档 | 基线 ms | 候选 ms | 省 ms | 提升 |
|---|---|---:|---:|---:|---:|
| 1 | 900 | 8.037864 | 8.004425 | 0.033439 | 0.42% |
| 1 | 1080 | 10.915607 | 10.835310 | 0.080297 | **0.74%** |
| 2 | 900 | 8.073609 | 8.032690 | 0.040919 | 0.51% |
| 2 | 1080 | 10.968955 | 10.879964 | 0.088991 | **0.81%** |

flags同前（SWIN_RUN=1、MAKE_RESIDENT_EVERY=60、DIRECT_IO=3、PDL1）。

## 代码与宿主改动

- `hip/vit_stream.inc`：`HIP_VIT_QKV_W5`、`HIP_VIT_QKV_ORDER`、`HIP_VIT_STREAM_QKV_HOIST` 均默认0。默认编出的 vit-stream 两架构 .text 与现装逐字节同；W5=1 只新增一个导出，另81函数反汇编逐条同（gfx1201）。gfx1200 编译通过（113VGPR/无spill），gfx1201实跑。
- `Development/HIP/hip_reference_network.h`：新增 `HasFn`；vit_stream 模块若导出 `_w5` 则按 threads=160、groups=96·ceil(tokens/80) 发射，否则走原路。**旧宿主+新模块=旧核；新宿主+旧模块=旧核**，互不破坏。生产配方未开W5，所以现有发布/剑星行为不变。
- 启用需要：vit-stream 配方加 `HIP_VIT_QKV_W5 1` + 重编 add-on/RE9 runtime（共用此头文件）。无新用户开关。

复现：`Development/HIP/experiments/vit-qkv/`（setup→build→make-jobs/micro/rounds→full）；lab `D:\DLSSNR-Lab\hip-backend\vit-qkv-20260929`。宿主用 MinGW `-std=c++17 -O2 -static -municode -DHIP_SWIN_PERSISTENT=1`（回绕版加 `-DHIP_SWIN_PERSISTENT_DIAGNOSTICS=1`），-I src 与 Development/HIP。
