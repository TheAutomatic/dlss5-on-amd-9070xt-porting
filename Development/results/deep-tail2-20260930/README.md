# 剩余两个列布局字节出口（2026-09-30）：ViT expand、C256 FFN/QKV 各一候选，均逐位但不快，不收；未装机

**结论**：两个候选都是逐位 19 组 SAME（7 用例 × EXACT/AE × 12 帧、AE CSV、900/1080 票号回绕），但按新规要求的“两档都为正”没做到，**都不收**。宏源码默认 0，配方不开，剑星/鬼武者不动（add-on 6d059845、RE9 runtime 5e601d57、deep_fast-packed 7ffaa65f、multihead-fast-padded-wave 不变），没有新备份，也不发包。

| 候选 | 改动 | 静态（gfx1201） | 900 三轮 | 1080 三轮 | 合并 avg / p99 |
|---|---|---|---|---|---|
| E `VIT_EXPAND_TAIL_VEC 1`（deep_fast-packed） | vit_expand_blocked_body 的 16×64 hidden 字节先写 LDS，每 lane 2×b128 | expand 核 63×b8 → 0，b128 3，ds 67 | +0.011 / +0.012 / +0.012 | +0.005 / −0.004 / −0.006 | 900 7.6707→7.6825（p99 7.918→7.931）；1080 10.5083→10.5069（p99 10.826→10.833） |
| Q `HIP_FFN_LINE_STORES 1`＋`MH_PAD_ZERO_VEC 1`（multihead-fast-padded-wave） | FFN+QKV 尾巴 out/norm 经 LDS 整行写（09-24 mh_fast 已收的那套）＋映射填充零块改 8 字节写 | C256 pdl 两核 global store 13→6（9×b8 全消） | +0.010 / +0.002 / +0.002 | +0.011 / −0.007 / −0.001 | 900 7.6774→7.6819（p99 7.918→7.913）；1080 10.5123→10.5132（p99 10.816→10.828） |

## 读数

- **C256 那 9×b8 不在热路径**：现装 ISA 里 C256 fused FFN/QKV 的主输出因 `HIP_FFN_TRANSPOSED_TAIL` 早已是每 lane b64；9 个 b8 全在映射填充零块分支（上下 padding 整 16 行块写 0），冷路径。所以 Q 实际测的是 LINE_STORES 在 900 档 C256 上的收益——在这里没有兑现（09-24 在 mh_fast 上的 −0.6% 不能照搬到这个模块）。
- **E**：expand 核 900 每帧 8 次 174µs，63 个 b8 写换成 LDS 转置加宽写后，900 反而三轮一致慢约 0.012ms。字节出口是 4096 步长行，每 lane 原本写 32 字节散到 16 行，改宽写后 LDS 往返与 wave_barrier 的代价大于省下的写指令。
- 列布局字节出口这条线（`results/deep-tail-20260930` 的清单）至此做完：收了 C512 t8，ViT QKV w5、ViT expand、C256 FFN/QKV 都不收。

## 复现

`Development/HIP/experiments/deep-tail2/`：setup →（build 已在 b.ps1 里）→ `run.ps1 -Name E -NoBuild` / `-Name Q -NoBuild` → p99m。lab `D:\DLSSNR-Lab\hip-backend\deep-tail2-20260930`（逐位帧转储已删）。配方旧默认编出的两个模块与现装 `.text/.rodata/.note` 逐字节相同。install.ps1/final.ps1 已改成能按模块换，本次没有用到。
