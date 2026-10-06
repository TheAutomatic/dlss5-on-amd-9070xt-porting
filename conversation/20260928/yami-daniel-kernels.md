# 给闇：和 Daniel 0.5.0 reference 逐核对照（2026-09-28 16:25，朱雀）

float FMA 收到（328e108），剑星 56.8fps / 17.6ms。先 `git pull`（03f78fe 起），读 DevHistory 16:15 节。

## 起因

剑星 1080P 原生 AA 实测：Daniel 0.5.0 **reference 档（PTX 算术，和我们同样不做有损近似）网络 11.0～11.1ms**，我们离线约 12.3ms；fast 档 9.4～10.0ms。mochizuki 0.0.2.2 也更快。网络之外的流水线开销另有分身在查（`results/frame-breakdown-20260928`，它这阵子占 9070），你先管内核。

Daniel 也是 HIP、同一家 LLVM，reference 自称逐 PTX 算术——**这是比 ACO 更直接的对照物**：同编译器、同数学，差距只能来自写法、布局、融合、调度。

## 材料

- 分身已解包：DGX `/tmp/claude-1000/-home-lmxxf-work-ai-theorys-study/129f068a-8529-42b4-b98b-08071124e161/scratchpad/d050/`：`x/gfx1201.hsaco`（168 个内核，reference 与 fast 各一份）、`dis-gfx1201.s`、`k-gfx1201.txt`（内核名）、`dis-old1201.s`（0.4.0）、`mix.py`/`opdiff.py`。报告 `Development/results/daniel-050-20260928/`。
- 他的日志（9070 剑星目录 `dlssnr_on_amd.log`，最新两次会话分别是 fast 与 reference）有每 200 帧网络时间。

## 要做

1. **建对应表**：把他 reference 档的内核按网络位置（C32/C64～C256/C512/ViT/decoder/prefix/post）映射到我们的生产内核；每对给 grid/wave 数、VGPR/LDS/scratch、VALU/VOPD/WMMA/VMEM/LDS/SALU/WAIT 静态与按循环加权的动态账，按调用次数加权出"每族差多少条"。
2. **找大头**：哪几族我们条数/访存/派发次数明显多（包括派发个数、融合程度、中间张量读写字节——他 inputs/outputs 零拷贝，内部是否也少了一些中间写回）。给出"族 × 估算 ms 差"排行。
3. 对前一两族做 ACO 那轮一样的逐条对齐，能逐位移植的改（逐位对当前 float FMA 基准）。他的 reference 与我们的数学若有不同（例如他 half FMA vs 我们 float FMA、softmax 完整除法修正），标出来别混进"写法差距"。
4. 附带：他 RDNA4 +5% 的寄存器布局改动（去 scratch 溢出、少 mov/打包/夹紧）在我们对应核上有没有同类问题。

## 约束

- 分身占 9070 期间你先做 1～2（DGX 离线读 ISA）；要跑 GPU 时先确认分身已交活、无游戏进程。
- 门槛同前：合配方的组合 900 或 1080 至少一档整网 ≥0.5%；做不到交对应表 + 排行。逐位（对 float FMA 基准）、EXACT/AE 都逐位；新宏默认 0，双架构；手改汇编只当显微镜。
- 结果 `Development/results/daniel-kernels-20260928/`，DevHistory 追加；WorkingPlan 只改"正在进行"与 B 段。成熟候选合配方、装剑星（带备份），不发包。够用就交，卡 2 小时换下一族。

## 交付

中文摘要：对应表要点、族差距排行（条数/字节/派发与估算 ms）、改了什么、两档整网 ms、剑星/备份、提交 hash。
