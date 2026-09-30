# 小件三项（2026-09-30）：C32 对角残差逐位但不过门槛，C256 FFN 标量量化无收益，ViT QKV 归一化不能逐位——都不收

**结论**：三项合计不过 0.5%，没装。D（对角残差）逐位、稳定为正，留作下次合包的现成件（宏默认 0，配方未改）。

## 1. C32 对角残差跳过全零 K16 半块（`CW_DIAG_ONLY`，默认 0）

09-25 在旧 chain 上做过（`c32-diag-zero-20260925`），09-26 换 wave-owned 核后这一段原样带了过来：`hip/wave_owned_c32.inc` 的 Chain 残差仍是 3 段 × 2 ci × 2 kt = 12 条 WMMA，其中 `kt≠ci` 的 6 条乘的是对角矩阵的全零半块。宏只加一行 `if(kt!=ci)continue;`。影响 chain/finish/finish_dcrop 三核（块 2/3/4/67/68/69），其余 14 函数逐条同。数值依据沿用 09-25：六组真实权重 × 全部有限 E4M3，49,152 个 f32 结果逐位同。

- 逐位：base 宿主＋flat-D，7 用例 × EXACT/AE × 12 帧同、AE CSV 同、回绕同（18 SAME，`full-D.log`；回绕那轮用了 base 宿主，DK 轮改用 Proll 补上，`full-DK.log`）。
- ABBA：900 −0.022/−0.019ms（0.28%/0.24%），1080 −0.024/−0.029ms（0.22%/0.27%）。**不过门槛。**

## 2. C256 FFN 标量量化/地址开销

900 独有（1080 C256 走 `c256_wave2_bi`；持久化 `sp_run256` 用 `swin_wave2_body`，不走这个核），每帧 4 次 `mh_ffn_fused_c256_frag_project_mapped_g128_qkv(_bytein)_fb_pdl` 共 ~195µs。激活写 `hidden` 的布局是"行 = token、列 = 隐藏维"，而 WMMA D 片段里一个 lane 持有的 8 个值是**不同 token 的同一列**，所以只能逐字节 `ds_store_b8`——这是组织方式，不是编译器产物；要打包写就得把 expand 的 A/B 对调成转置输出，是整核重排，不是小件。

现成的 `HIP_FFN_PK_ACT 1`（两值一条 `cvt_pk_fp8`、零选择留在字节上，逐位）：该核静态 VALU 855→831（−3%），模块其余 54 函数不变；与 D 合测（DK）900 0.31%/0.26%、1080 0.31%/0.35%，和 D 单独（0.28/0.24、0.22/0.27）差在噪声内——**PK_ACT 本身测不出收益，不收**。（它的宏编译本身正常；第一次编译失败是远端传参带了引号，不是源码问题。）

## 3. ViT QKV 归一化段（W5 尾部）

现役：acc 经 LDS 转置（16 写＋barrier＋16 读），half 平方，再用两条 f16 WMMA 与全 1 相乘求和（f32 累加），`rsq`。Daniel 用 bpermute 树求和。求和顺序就是数值：WMMA 内部的 32 项累加顺序/舍入不是逐加法可复现的，换成 bpermute 树加法不能保证逐位；保留 WMMA 求和、只把 LDS 转置换成 16 条 bpermute，省的是一次 barrier 与 LDS 往返，量级约 8 次调用 × 1µs 以内。**不能逐位的部分不做（属 C 段有损），能逐位的部分收益低于测量噪声，不做。**

## 汇总

| 项 | 逐位 | 900 | 1080 | 处理 |
|---|---|---|---|---|
| D 对角残差 | 是 | −0.02ms（0.24～0.28%）| −0.02～−0.03ms（0.22～0.27%）| 不收，留合包（宏默认 0） |
| PK_ACT | 是 | ≈0 | 不运行 | 不收 |
| ViT QKV 归一化 | 换求和不能 | — | — | 不做 |
| 三项合并（DK） | 是 | 0.26～0.31% | 0.31～0.35% | 不过 0.5% |

参考：D 叠加到已装的 C32 字节 skip 上（BD）比单 B 再省约 0.03ms，见 `../c32-align-20260930/README.md`。复现脚本同 `Development/HIP/experiments/c32-align/`（`mkset.ps1`/`bmh.ps1` 拼 flat-D/DK）。

## 更新（09-30 08:01）：Zero 批准，D 已开进生产

配方 c32-wave1 加 `CW_DIAG_ONLY 1`（配方直编与测过的 SD 候选 .text 两架构逐字节同）。在现役 a80db313 配方上复测（base = benchmark-P＋flat-B，候选 = 同宿主＋flat-F）：7 用例 × EXACT/AE 168 帧、AE CSV、回绕全同，18 SAME（`full-F.log`）。一轮 ABBA：900 7.823797→7.816520（−0.007ms，0.09%，本轮在噪声内），1080 10.737017→10.698926（−0.038ms，0.35%）。只换模块：宿主 a80db313、RE9 runtime fd4b2c0c 不变，flags 不动；新 c32-wave1 gfx1201 30c3d107 / gfx1200 ba026a91。备份：剑星 `D:\DLSSNR-Lab\hip-backend\c32-align-20260930\backups\stellar-20260930-080147-c32skip`，鬼武者 `D:\DLSSNR-Lab\onimusha-backups\20260930-080147-c32skip`（模块与剑星对齐）。脚本 `experiments/c32-align/install-diag.ps1`。
