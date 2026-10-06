# 压核间空隙（gap-fusion，2026-09-30 深夜）

**结论先行**：列了两档全部派发，找出短核和可以融合的相邻对。能做的只剩两个小口子，都逐位（19 组 SAME），**但都不收**：G（ViT 前后两个 vit_gather 并进 head Down 的尾巴和 decoder39 的头，−2 派发）让 900 三轮都变慢；T（删掉 C512 t8 FFN 里没人读的 f32 contract 写出）让 900 六轮都变快（−0.021～−0.036ms），但 1080 有一轮 +0.008，两次各三轮合并的 1080 p99 也差一点（+0.003），按新规不收。宏默认都是 0，宿主开关 `HIP_VIT_GATHER_FOLD_HOST` 默认 0，没装机，派发数不变（162/158）。

## 1. 派发清单（kernel-map-v3，独立中位 µs）

短核（<15µs）：900 有 60 个，合计 638µs；1080 有 31 个，合计 316µs。

| 核 | 900 次数×µs | 1080 | 前后是谁 | 能不能融合 |
|---|---|---|---|---|
| split_mix_blocked_h16w_m32 | 9×14.4（另 4 个 ≥15） | ≥15 | attn_project → **mix** → ffn_t8 | mix 并进 FFN：split_mix_fused 已经 null，mix→expand→contract 融合在负账 |
| split_ffn_fused_fp8_t8 | 13×14.2 | ≥15 | mix → **ffn** → projection | projection 的 K 要全部 512 通道，并进来组数 752→94，填不满 |
| split_projection_frag | 13×9.0 | 13×14.7 | ffn → **proj** → qkv_attention | 同上；attention 按窗口取行，也不是 1:1 |
| vit_attention_fused_400 | 7×14.6 | ≥15 | qkv → **attn** → project_n64 | 投影按 16 token×64 列一组，attention 按头分组，不对齐 |
| vit_stream_project_n64_bh | 8×8.9 | 8×11.2 | attn → **proj** → pack_input | 附带字节出口删掉 pack：09-28 P/Q/R 已试（负账"ViT byte 出口/入口 gather-pack"） |
| vit_pack_input | 8×3.2 | 8×2.7 | proj/gather → **pack** → expand | 同上，负账 |
| vit_gather ×2 | 2×4.5 | 2×6.5 | head Down → **gather** → ViT；ViT → **gather⁻¹** → decoder39 | **本轮 G** |

另外还有两件：`split_ffn_fused_fp8_t8` 的 f32 `out` 在 c512_proj_tiles 路径下没人读（projection 只读 contract8），每块白写 3.07MB / 4.4MB，这就是**本轮 T**。`mh_pool_project_group_c512`（20µs，只有 25 组）是占用率问题，不是空隙问题。

**PDL 覆盖**：只有 C64/C128/C256 六条链。C512 链在 09-25 `pdl-c512` 做过：逐位，但板功耗钉在 325W，填了哪一族的空隙都会以降频还回来，叠加后不赚，不采用。C32 链和 ViT 都没覆盖，理由一样，而且 ViT 的依赖是全行的，不是 tile 对 tile，没有可以按 tile 放行的旗子。所以不补。

## 2. 候选与结果（ABBA 1000 帧弃 200；19 组 = 7 用例×EXACT/AE×12 帧＋AE CSV＋900/1080 票号回绕）

- **G `HIP_VIT_GATHER_FOLD 1`**（deep_fast-packed 新增导出 `decoder_project2x_h16w_gin`，multihead-fast-padded-wave-packed 新增导出 `mh_pool_project_group_c512_gout`；宿主 `HIP_VIT_GATHER_FOLD_HOST` 用 HasFn 判断两个导出都在才走，否则回旧路径）：gather 只是搬数据，换成写/读地址的置换，值和运算顺序都不变。19 组 SAME。900 +0.004/+0.011/+0.005，1080 +0.004/−0.006/−0.004ms。**不收**：打散的写和读的代价，比两次派发省下的还多。
- **T `C512_T8_NO_F32 1`**（只改 deep_fast-packed，宿主不动）：19 组 SAME。第一次三轮：900 −0.034/−0.033/−0.025，1080 −0.018/−0.000/−0.012；合并 p99：900 7.807→7.779，1080 10.692→10.695。第二次三轮（T2）：900 −0.026/−0.021/−0.036，1080 −0.007/**+0.008**/−0.006；合并 p99：1080 10.693→10.696。**不收**（1080 在噪声里，有一轮变慢，p99 也没变好）。如果以后规矩改成"只看 900"，这刀可以直接开。

宿主 benchmark-P（G 宿主）配现装模块，在 G/T 两次运行里都跑过（T 走的就是它），与 base 相同。模块 gfx1201：Gd 04942285、Gm 3E5BD0F4、T 56646BDF；prod 重编的 `.text` 与现装相同。

## 3. 读法

空隙每派发约 2µs 是真的，但在这张卡上，省派发要和"额外指令/打散访存"对冲；再加上功耗墙会把省下的时间吃掉，剩下能减派发的对子要么已经在负账里，要么不对齐。空隙这条线停。真要再减派发，只能改组织方式，走 C512/ViT 整块融合（B4/B6），不能靠拼接小核。

## 文件

脚本 `Development/HIP/experiments/gap-fusion/`（setup/b1/go/fb/run/full/summarize/p99m/clean）。lab `D:\DLSSNR-Lab\hip-backend\gap-fusion-20260930`（帧转储已删 11GB，D 盘剩 514GB）。
