# 给闇：第三刀（2026-09-27 19:40，朱雀）

第二刀剑星实测通过：1080P 原生 AA，EXACT 普通场景 55～56 → **56～57**，画质同前（DevHistory 19:36 节）。先 `git pull`（c3ee576 起）。

## 1. post（加权 26%，第一优先）

post 每窗口普通向量指令 5835 → 4909（第二刀的固定段 MODE 已覆盖），但它和 prefix 一样跑全分辨率、只一次调用，份额最大。按你 chain 那张分账表的格式，先给 post 单独出一张段账（它有 RGB 输出头/post70 的特有部分），再找逐位候选：重复量化/往返、可提到 wave-uniform 的逐像素判断、LDS 读写向量化（上一轮 RTZ_PAIR 那招）、输出头的打包写出。

## 2. finish / finish_dcrop 的标量开销

你已查明 finish_dcrop 尾部约 1682 SALU、1587 WAIT，是对每个像素重复计算同形式的标量边界（已 wave-uniform，不是分歧）。prefix 用 `CW_PREFIX_FULL_TILE` 在完整窗口去掉了恒真判断；finish 系能否同法：**完整内部窗口走无裁切快路径、只有边缘窗口保留逐像素裁切**（按窗口坐标一次判定，wave-uniform 分支）。注意 finish_dcrop 的下采样裁切语义要逐位保住。

## 3. 离开 C32：C512 / ViT 的 ACO 对照（C32 做完后）

整网里 C512 与 ViT 各约 14.5%，还没做过 ACO 对照。已知：ViT 真在跑的核（如 `vit_project_frag_n64`）读 f32 输入、访存受限（VMEM 164 vs WMMA 64），所以 DF_PACK8 砍 VALU 不赚（`results/ovfl-census-20260927`）。

- 对照 mochizuki 的 `gemmvqkv*`、`gemmvproj`、`gemmvact`、`vitattn`（`linux/shaders/rdna4/pipelines.json`、`vit_attn.comp`、`gemm1x1.comp`），重点看**数据形态**：它的 ViT gemm 读的是生产者直接写好的 E4M3/f16 字节，我们读 f32。先量化"如果输入改成 E4M3/f16 字节，VMEM 字节数和指令数能降多少"。
- 我们对应的现成路线是 `vit_byte_stream`（Options 里有，默认关），它和自适应 ViT 复用（`DLSS5_VIT_ADAPTIVE`，常规包默认开）互斥。评估：能否让复用缓存存字节流形态、或者只在 EXACT/复用失效帧走字节流；若逐位可行就做候选，不可行写清原因。
- C512（`c512_m32_*`、`deep_fast` 的 C512 段）同样做一张 VALU/VMEM 账，看瓶颈是 VALU 还是访存，再决定用 C64/C32 那套（fmed3、分段 MODE、去往返）还是走数据形态。

## 约束（同前）

- 逐位是硬门槛（对当前剑星实装）；有反例就不改（你上轮 FMA 反例的做法很好）；不照抄 mochizuki 改数学路线的配置。
- 已关：`v_cvt_pk_f32_fp8` 成对解包、`v_pk_*_f16`、核入口一次性 FP16_OVFL、DF_PACK8（单砍 VALU）。
- 每个候选：新宏默认 0，双架构，ISA 计数，7 用例逐位，900/1080 两批 ABBA；手改汇编只当显微镜。
- 9070 动 GPU 前查游戏进程；git 只推 297、不加 Co-Authored-By、push 前 pull --rebase。结果按部分写 `Development/results/c32-round3-20260927/`、`vit-c512-aco-20260927/`，DevHistory 追加，WorkingPlan 只改 B 段。
- 成熟候选合进配方、装剑星（带备份），不发包。够用就交；单个候选卡 2 小时以上换下一个。第 3 部分若很大，做到"账 + 可行性判断 + 一个最小原型"就算交付点。

## 交付

中文摘要：post/finish 各候选的指令变化/逐位/ms；ViT/C512 的账与数据形态结论（字节流路线能否与复用兼容）；合进配方后整网 ms；剑星装了什么/备份；提交 hash。
