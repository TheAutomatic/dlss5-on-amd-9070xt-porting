# 9070 D 盘清理（2026-09-30）：删已交账实验逐位帧转储 486.7GB，D 盘 35GB→527GB 空闲；基准自检 168/168

**结论**：`D:\DLSSNR-Lab\hip-backend`（592GB）里 .f16 408GB + .ppm 151GB 几乎全是各实验逐位比对时的输出帧转储（runtime-regression-*/regression*/base*/candidate*/adaptive*/timing* 等子目录）。结论与哈希早已写进各 `results/*/README.md`，转储本身不再被引用，删之。删后 D 盘空闲 **566.5e9 字节（约 527GiB）**。

## 删了什么（清单：`cleanup-20260930.csv`，1261 个子目录，按实验汇总见脚本输出）

- 范围：`hip-backend\<实验>\<子目录>\**\*.f16|*.ppm`，即实验目录下一层子目录里的帧转储。合计 **486.7GB**，最大几项 mochizuki-022 40.4、swin-small 26.2、mh-round1 24.2、network-fixed-shapes 20.8、c256-w16 19.2GB。
- 为什么可删：都是候选/基线逐位比对的产出帧，比对结果（SAME/哈希）与计时都已交账；复现可用同目录脚本重跑生成。

## 没动什么

- 实验目录根下的文件（62GB：benchmark exe、flat-* 模块集、`live-menu-before.f16` 等回归输入、脚本、CSV、日志）；hip-backend 根文件。
- 子目录名以 `capture|assets|backups|input|fixture|golden` 开头的；路径含 `\backups\` 的；名字含 `fma` 的实验（float FMA 基准相关）与 `deep-tail-20260930`（最近一单）整目录。
- `hip-backend` 之外全部不动：`onimusha-backups`、`zero-copy-io-20260928\assets`（回归输入 capture）、`geom1088-20260930`、`product-fmt-20260930`、`float-fma-20260928`。
- 除 .f16/.ppm 外的扩展名（.f32 dump、hsaco、.s、json、exe、zip、log）一律不删。

## 基准在哪、还能不能用

逐位基准是**哈希**不是帧：`results/float-fma-20260928/new-baseline-hashes.csv`（9070 副本 `hip-backend\compiler-versions-20260929\new-baseline-hashes.csv`），168 行 = 7 用例 × EXACT/AE × 12 帧。回归每次都现场跑 flat-A（现装 31 模块）当基线，输入是 `zero-copy-io-20260928\assets` 与 `hip-backend\live-menu-before.f16`，均未动。

**删后自检**（`selfcheck.ps1`）：deep-tail lab 用 `full.ps1 -Set A -Cand base -RollHost base -SkipTiming` 跑一遍现装模块 A 对 A（EXACT/AE、AE CSV、900/1080 票号回绕），全部 SAME；再把 A 的 168 帧逐个对 `new-baseline-hashes.csv`：**ok=168 bad=0**。
