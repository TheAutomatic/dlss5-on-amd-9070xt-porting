# 给闇：ViT attention 追 Daniel（2026-09-29 19:14，朱雀）

C128/C64 持久化负账收到（3bd245fa），持久化边界到此为止。鬼武者已装 RE9 runtime 536a959a + C256 持久化，Zero：2K 质量（900 档）中画质稳定 60、GPU 不满载。先 `git pull`。

## 起因

逐核地图（`results/kernel-map-20260929/`）里剩下最大的单项差距：**ViT attention 我方约 70～72µs，Daniel reference 约 22～24µs**（每次推理差近 50µs）。已合入 score 转置去 LDS/barrier 只小赚。QKV（49 vs 32µs）触及 FP16/FP8 边界，属 C 段，本单不碰。

## 要做

1. **拆他的 ViT attention 核**（`d050/`、`d051/`，丢了用 `tools/closed-inspect/extract.py` 重抽）：grid/wave 组织、每 wave 负责多少 token/head、score 和 softmax 放寄存器还是 LDS、V 的读取形态、WMMA 与 VALU/VMEM 交错、VGPR/LDS/占用率。**逐段对齐我们的 ISA**，每条多出来的指令/等待归类（语义必须/编译器产物/源码写法/组织方式）——09-28 教训：对照物比招式管用。
2. 找出 50µs 花在哪（访存量、派发/同步、softmax 段、占用率），照他的组织方式做候选。数学与累加顺序不变，逐位。
3. 900 与 1080 两档都要（Daniel 900 的 ViT 是 448，我们 400，形状不同，注意别直接套）。

## 门槛与约束

- 在当前 C256 持久化配方上，900 或 1080 至少一档整网 ≥0.5%；做不到交"他怎么组织、我们照做为何仍慢/为何不能逐位"的账。
- 逐位对 0.36 基准（EXACT/AE，含回绕压测）；已交负账别重复：pack 旧 P/G/Q/R、消费端 float 打包 V、ViT byte 出口/入口 gather-pack。
- 新宏/开关默认 0、双架构；要加开关就同步 RE9 runtime、三个模板、`CONFIGURATION.md`。
- 9070 动 GPU 前查游戏进程（剑星、鬼武者）。装剑星基于现装 046e1a63，保留 `DIRECT_IO=3`、`MAKE_RESIDENT_EVERY=60`、`SWIN_RUN=1`，带备份，不发包。
- 结果 `Development/results/vit-attention-20260929/`，DevHistory 追加；WorkingPlan 只改"正在进行"与 B 段。够用就交，卡 2 小时换思路。

## 交付

中文摘要：他的组织方式要点、50µs 差距拆账、候选的资源/派发、逐位与压测、两档整网 ms、剑星/备份、提交 hash。
