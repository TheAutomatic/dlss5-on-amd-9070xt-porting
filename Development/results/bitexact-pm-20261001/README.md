# 逐位路线下一批（bitexact-pm，2026-10-01 下午）

基准 = 剑星现装（add-on 0D739130，31 模块见 `installed.txt` 口径：deep_fast-packed EEC7D4A6，decode shader 3762D2F1）。宿主 base = main f7c48ebe 源码（6f0a580e 之后，两边 `-PinIdle`）。19 组 = 7 用例×EXACT/AE×12 帧 + AE CSV + 900/1080 票号回绕。ABBA 1000 帧弃 200。原始行 `abba-step1.txt`。

## 1. 三个擦线小件

### 1.0 DEC_WIDE 与 DEC_F8W 为什么互斥，怎么叠
宿主 `Up()` 先按导出把核名改成 `decoder_project2x_h16w[_byteout]_w`，再判 F8W 时要求核名**恰好**是不带后缀的两个名字，于是有 `_w` 就不走 `_f8`；模块里也没有"宽出口 + fp8 主循环"的核。改法：`decoder_project2x_h16w_wide_body` 加模板参数 W8（主循环逐字照 `decoder_project2x_h16w_body<..,W8=true>`），两宏同开时导出 `*_w_f8`；宿主 F8W 判断接受 `_w` 名。逐位（DWF 19 组 SAME）。

### 1.1 IO_FUSE 宿主防呆
`native_game_frame.h`：`DLSS5_IO_FUSE=1` 时先读 `native_codec_decode.hlsl`，没有 `NATIVE_CODEC_NEURAL_BUFFER` 就拒绝融合（`frame_create_step detail=io_fuse_refused_old_decode_shader`），走原路径。验证 G：旧 shader + IO_FUSE=1，19 组 SAME，日志 10 次 refused。

### 1.2 单项（各三轮）
| 件 | 逐位 | 900 三轮 | 1080 三轮 | 合并 p99 900 / 1080 | 判 |
|---|---|---|---|---|---|
| IOF（IO_FUSE=1 + 新 decode shader A70789A1） | 19 SAME | −0.010 / −0.018 / −0.016 | −0.004 / −0.027 / −0.003 | 7.465→7.453 / 10.175→10.163 | 过 |
| DW（`HIP_DEC_WIDE 1`） | 19 SAME | −0.005 / −0.012 / −0.061 | −0.013 / −0.002 / −0.081 | 7.450→7.355 / 10.159→10.116 | 过 |
| DF（`HIP_DEC_F8W 1`） | 19 SAME | +0.002 / +0.026 / −0.002 | +0.022 / −0.016 / −0.001 | 7.460→7.492 / 10.192→10.172 | 不过 |
| DWF（两宏，`_w_f8`） | 19 SAME | +0.006 / −0.009 / +0.013 | +0.002 / −0.028 / +0.001 | 7.502→7.531 / 10.289→10.300 | 不过 |

DF 今天这一批比 10-01 上午更差，DWF 也没比 DW 好：fp8 主循环在这两个核上不赚，叠了反而抵掉宽出口的钱。选 DW。

### 1.3 合包 PK = DW + IOF（宿主 P3 = 本分支）
| 批 | 900 三轮 | 1080 三轮 | 合并 p99 900 / 1080 |
|---|---|---|---|
| PK（含 19 组，SAME） | −0.022 / −0.021 / **+0.002** | −0.033 / −0.030 / −0.013 | **7.508→7.565** / 10.323→10.282 |
| PK2（复测，只计时） | −0.007 / −0.016 / −0.002 | −0.017 / −0.062 / −0.027 | **7.520→7.578** / 10.345→10.299 |

六轮 avg 五负一平，但 **900 合并 p99 两批都变差（+0.06）**，和 input-slim 当时 IO_FUSE 的 900 p99 现象同型（decode 改读 f32 多 10MB、非纹理路径，尾帧受影响）。按规则合包不收。IOF 单测虽过，但一进包就复现 900 p99 变差，**IO_FUSE 不装**；开关、防呆、shader 留在源码。

### 1.4 装机（DW 单独，模块级）
现装 add-on 和 RE9 runtime 本来就按导出挑 `_w`，所以只换 deep_fast-packed：gfx1201 EEC7D4A6→**7FDA5868**，gfx1200 54D388A7→**E55635E2**（`HIP_DEC_WIDE 1`）。add-on 0D739130、flags、decode shader、RE9 runtime 2CB95057 都没动。SUMS 56ECA0A7（62 模块）。鬼武者镜像。RE9 回放 900/1080 old/new/fallback 三方 SAME，smoke 0。
备份：`D:\DLSSNR-Lab\hip-backend\bitexact-pm-20261001\backups\stellar-20261001-135929-decwide`（真正的原状；13:59:29 第一次装机脚本因 `H` 与 PowerShell 别名冲突，已写入 gfx1200 一个文件后中断，已从该备份恢复并核对 0 差，再重装，第二份备份 `...-135944-decwide`）、`D:\DLSSNR-Lab\onimusha-backups\20261001-135944-decwide`、fast-tier `backups\20261001-135944-install-decwide`。
fast-tier：`exact\` 的 deep_fast-packed 与两份 SUMS 已同步；`fast\deep_fast-packed` 也换成同一个（它原配方只有逐位的 DEC_F8W，现在 F8W 不赚）。status：两游戏 EXACT。
配方：`hip/build-modules.ps1` deep_fast-packed 加 `HIP_DEC_WIDE 1`。
