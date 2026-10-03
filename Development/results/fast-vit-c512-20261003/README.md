# FAST_NUMERIC 加深：ViT 数值放宽 + C512 attention 投影 f16 残差（2026-10-03，朱雀）

任务单：把 fast 数值路径从 C32+c64-wave2 扩展到 ViT 和 C512 attention 投影。方法：每刀 offline 整网 PSNR（7 case × 12 帧，对 FAST=0 逐位基线，最差帧线 ≥50 dB）+ 两档三轮 ABBA（1000 帧弃前 200，同批）。harness 基线沿用 fast-tier 口径（跳 42,43,46 两边一致）。

## 机制（全部接进现有 DLSS5_FAST_NUMERIC=1，无新配置键）

- 新模块宏（默认 0；宏 0 重编 .text 与现装逐字节一致，已验证 deep_fast-packed / vit-stream / mh_fast 三个模块）：
  - `VIT_FAST_NUM`（deep_fast.hip / vit_stream.inc 共用）：
    bit0 = ViT attention epilogue 去 Hrtz（`byte_F(acc*inv)`，E4M3 量化本就主导舍入）；
    bit1 = attention 分母 vit_inv 裸 rcp（除数域 [1/256,2048]，HIP_VIT_ATTN_RCP probe 已保证）；
    bit2 = ViT contract init/epilogue 与 projection init/epilogue 去 RNE 半舍入（`F(H(x))→F(x)`、skip 初始化 `H(s*w)→s*w`）；
    bit3 = C512 FFN 投影 `F(H(acc))→F(acc)`（纯省指令，无额外流量）；
    bit16 = `split_projection_frag_f16res` / `_f16only` 导出（实验，未装）。
  - `C512_FAST_PROJ`（multihead_fast_padded.hip）：`mh_attention_project_frag_c512_f16res` 导出（实验，未装）。
- 宿主（hip_reference_network.h）：`fast_numeric` 构造时缓存；`FastTwin(stem)` 通用化 -fast 交换（deep_fast-packed / vit-stream / multihead-fast-padded-wave-packed(-…) 各加载点 + c32/c64 原逻辑复用）；缺失退回正常模块 + 一行 stderr。
- 配方行（COMGR 同生产编译器）：`deep_fast-packed-fast`（VIT_FAST_NUM 15）、`vit-stream-fast`（VIT_FAST_NUM 4）。两架构同哈希。
- ViT QKV/expand 无 F/Hrtz 往返可省（QKV 归一化已是硬件 rsqf + f16 WMMA 平方和；expand epilogue 是 f32 多项式直接 byte_F）——两族不出刀，记录在案。

## 逐刀结果（ABBA 数字 = candidate − base，负 = 变快）

### HOST（宿主补丁中性，F2 vs base2，flat-A 两边，FAST off）：19 组 SAME + AE CSV SAME + roll ✓
计时中性：900 −0.002 / 1080 −0.025（1 轮），p99 两档更好。

### 刀1 P1 = ViT attention（deep_fast-packed VIT_FAST_NUM 3）：PSNR 最差 54.53 ✓；单独收益在噪声内
900 +0.0085/−0.0320/−0.0125（合并 −0.012、p99 好），1080 −0.0177/+0.0297/−0.0018（合并 +0.003）。结论：PSNR 余量大、单机看不清，作为合包成分交 PF 总账。

### 刀2 P2 = ViT contract + projection（vit-stream VIT_FAST_NUM 4）：PSNR 最差 54.41 ✓；噪声内
900 合并 −0.001，1080 合并 +0.015（一轮 +0.049）。结论同上。

### 刀3 P3 = C512 f16 残差投影：值逐位精确但两轮实验都慢，不收
- v1（f32+f16 双写残差）：7 case 全 diff=0/12、PSNR ∞；ABBA 900 三轮全正（+0.0078/+0.0065/+0.0338，合并 +0.016），1080 合并 +0.003。
- v2（f16only，省 f32 写）：同样全 0/12；更差，900 合并 +0.059（+0.0435/+0.0689/+0.0635）。
- 结论：C512 attention 投影族对残差流量不敏感（残差读只占核 ~15-25%，消融 2.5-5µs/块），生产端散写 2B store 的成本 > 读端省下的流量——与 C512_PROJ_FB8 历史负账同构，线停。代码留仓（宏默认 0、配方不装、宿主分支已撤）。

### FB = F2 + FAST=1 但无 -fast 文件（flat-A 回落）：7 case 全 diff=0/12 ✓（退回逐位，stderr 一行）

### PF = 全 fast 默认（c32-wave1-fast + c64-wave2-fast + deep_fast-packed-fast + vit-stream-fast，FAST=1）：收
- PSNR 对逐位：最差帧 **52.13**（720-motion），全 case ≥52.13，均值 53.01～55.61。
- ABBA：900 −0.0936/−0.0833/−0.0902（合并 **−0.0891**），1080 −0.0763/−0.1049/−0.1187（合并 **−0.1000**）；三轮全快、无慢轮，合并 p99 两档都更好（7.834→7.749、10.614→10.528）。
- 对照 fast-numeric（只 c32+c64）：900 −0.07..−0.13、1080 −0.09..−0.10、最差 51.83。加深后 1080 合并收益持平偏好、PSNR 略升（52.13 vs 51.83）。

## 收刀结论
- 收：PF 整包（ViT attention bits0+1、contract/projection bit2、C512 FFN 投影 bit3 随包）。满足规矩：PSNR 最差 ≥50 dB、两档三轮无慢轮、合并 p99 不差。
- 不收：C512 attention 投影 f16 残差（两形态，精确但慢）；ViT QKV/expand（无刀口）。
- 默认行为：宏 0 模块 .text 与现装逐字节同；HOST 19 SAME；FAST=1 缺文件回落逐位（FB 验证）。未装机（等光/Zero 拍板）；9070 `build\final{,1200}\` 有两架构 twin 可装。

## 环境
- 9070 lab：`D:\DLSSNR-Lab\hip-backend\fast-vit-20261003\`（harness 克隆自 fast-numeric-20261003，两侧统一追加强制键 FAST_NUMERIC=0/MULTI_PASS=1——游戏的 native-game-flags.txt 10-03 多起 FAST_NUMERIC=1 + MULTI_PASS=3，不中和会污染基线；benchmark 宿主是 **benchmark_vit_reuse.cpp**（每帧 dump），不是 benchmark_live_capture.cpp）。
- COMGR 构建：`fast-vit-20261003\src` + `build\{macro0,c1,c2,c3,final,final1200}\`。
- 实验脚本：`Development/HIP/experiments/fast-vit/{setup-lab.ps1,go.ps1,regression.ps1,regression-cmp.ps1}`。
