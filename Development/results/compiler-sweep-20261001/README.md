# 编译器层面逐位提速扫描（2026-10-01 夜，光派单）

不改数学，只改调度/寄存器分配。结论：**c32-wave1 关掉 post-RA 调度 + max-ilp、c512-m32-deep 用 max-ilp**，19 组 SAME，ABBA 两档六轮全快（约 −0.06/−0.08ms）。只进 main 配方，默认不生效（`-RowOpts`），没装机。

## 1. 构建方式盘点
- 编译器：`D:\DLSSNR-Lab\build-0927\rtc_compile.exe`（驱动 `amd_comgr_3.dll`，LLVM21）。环境变量 `RTC_EXTRA_OPTS` 把额外选项追加到前端和 codegen 两段；**`-mllvm` 必须写成连写的 `-mllvm=X`**，分开写 COMGR 会把后面的 `-nogpulib` 当成 LLVM 选项报错（09-16 就踩过，本次复现）。
- 配方 `hip/build-modules.ps1`：31 个模块各一行（defines + 源文件拼接）。本次加了两样：
  - 行字段 `opts`（只在 `-RowOpts` 时生效），以及 `-ExtraOpts`（实验用，追加到所有模块）。不带这两个开关时 `RTC_EXTRA_OPTS` 被清空，**31×2 模块与现装逐条相同**（compare-modules，62/62）。
  - 源码挂点 `HIP_KERNEL_WPE`（`multihead_fast_padded.hip`/`deep_fast.hip`/`c32_fused_ffn_attention.hip`，默认 0 = 不加属性）：给模块里每个 kernel 加 `amdgpu_waves_per_eu(N)`。粒度是模块，不是单核。
- LLVM21 可用的相关隐藏选项见 `llvm21-options.txt`（`-mllvm=--help-hidden` 导出）。**没有 `-amdgpu-schedule-metric`**，只有 `-amdgpu-schedule-metric-bias`；`-amdgpu-sched-strategy` 取 max-ilp / max-memory-clause / iterative-ilp / iterative-minreg / iterative-maxocc。`-misched-postra-direction=bidirectional` 在这版编不过（8 个模块全 FAIL）。

## 2. 静态筛选（gfx1201，8 个热模块 × 26 组选项，`static.txt`，脚本 `isa_stat.py`）
热核取 gap-map-evening 的 1088/900 同口径前 20（c128/c64 wave2、sp_run256、C32 七核、C512 QKV/FFN/投影、ViT contract/QKV/attention/expand、split_projection、mh_ffn c256）。
- **`waves_per_eu` 1/2/4 对所有热核代码逐条不变**（20/20 SAME），6/8 只动了 3～4 个小核：这些核的 VGPR 已经在它们的占用率档位里，提示只能放宽，编译器不理——和 09 月 C32 的结论一致。
- `nohirp`/`nolowocc`/`relaxocc`/`trackers` 只改动零星几个核；`trackers` 把 vit_stream contract 压到 183 VGPR，GPU 上 +161/+194µs，淘汰。
- 淘汰（静态）：`bottomup`、`topdown`、`itminreg`（指令数 +10～20%、s_delay_alu 翻倍）；`unroll600/1200`（C32 指令 +20～30%）；`nounrollpart`（vit contract 出 160B scratch）；`ilp` 在 c512-m32-mh 上溢出 1 个 VGPR + 8B scratch、`topdown` 在 mh_ffn_c256 上溢出 13 个，均不上 GPU。
- 进 GPU：35 个模块×选项组合。

## 3. 链内 µs（`dupc.ps1`，宿主 benchmark-S、现装剑星 gfx1201 模块，每组 300 帧弃 60，SPAN 中位；按两侧 base 线性去漂移）
第一轮（3 轮，整网 span 变化，µs；`pass1-table.txt`）挑出的：

| 模块 | 选项 | 900 | 1152 行 |
|---|---|---:|---:|
| c32-wave1 | post-RA 调度关（`-enable-post-misched=0`） | −53 | −80 |
| c32-wave1 | max-ilp | −22 | −16 |
| c32-wave1 | iterative-ilp | −13 | −22 |
| c512-m32-deep | max-ilp | −6 | −29 |
| c64-wave2 | iterative-ilp | −9 | −11 |
| deep_fast-packed | max-ilp | +11 | −36（不稳） |
| multihead-fast-padded | max-ilp / iterative-ilp / relaxocc | +89 / +70 / +107 | 小 |
| vit-stream | trackers | +161 | +194 |

第二轮（5 轮，`pass2-table.txt`），DUP 列是该族在链内的单份成本（DUP×2 − base）：

| 模块 | 选项 | 整网 900 | 整网 1152 | DUP 900（inst→新） | DUP 1152 |
|---|---|---:|---:|---|---|
| c32-wave1 | post-RA 关 | −52 | −74 | 全族 2260→2153（−107） | 3233→3086（−147） |
| c32-wave1 | post-RA 关 + max-ilp | **−59** | **−84** | | |
| c32-wave1 | post-RA 关 + iterative-ilp | −55 | −68（一轮 +3） | | |
| c64-wave2 | iterative-ilp | −1 | −16 | c128_wave2_bi_bo 608→608 | 857→831 |
| c64-wave2 | post-RA 关 + iterative-ilp | −4 | −3 | | |
| c512-m32-deep | max-ilp | **−10** | **−20** | split_ffn_one 503→505 | 404→353（≈−4/块） |
| c512-m32-deep | post-RA 关 + max-ilp | +4 | −26 | | |
| deep_fast-packed | max-ilp / post-RA 关 | −1 / +3 | −9 / +58 | | |

c64 的 iterative-ilp 900 档为零，不收。

## 4. 合成配方与验证（`full-CS.txt`）
配方 `-RowOpts`：c32-wave1 = `-mllvm=-enable-post-misched=0 -mllvm=-amdgpu-sched-strategy=max-ilp`，c512-m32-deep = `-mllvm=-amdgpu-sched-strategy=max-ilp`。两架构 62 模块编过；与默认构建相比只这 2×2 个模块变（gfx1201 c32 12B60775、c512-deep FE9A1A0B），其余 58 个逐条相同。
候选 = 现装 31 模块 + 这两个（c128-c64-inchain 的回归脚本，`go-cs.ps1`）：
- **19 组 SAME**（7 用例×EXACT/AE×12 帧 + AE CSV + 900/1080 回绕，`-PinIdle`）。
- ABBA 三轮：900 −0.054/−0.043/−0.081，1080 −0.089/−0.091/−0.061ms；合并 p99 900 7.525→7.443、1080 10.277→10.188。六轮全快。

静态上看到的（机制未逐条拆）：C32 关掉 post-RA 调度后 s_delay_alu 少 20～40%（prefix 114→81、mapped 69→43）、VOPD 略多（mapped 158→176）；max-ilp 在 split_ffn_one 上用 96→116 VGPR（占用率 16→12）换掉一半 s_wait（113→55）。都只换指令顺序和寄存器，没新增 FMA 收缩——哈希为证。

## 5. 没收的、负账
- `waves_per_eu`：热核编译器不理（见 §2）。
- 全局开选项（09-16 已证 max-ilp 全局 +0.74ms）——收益全在按模块挑。
- mh_fast / vit-stream / swin / c512-m32-mh：没有一组不慢或不持平。

## 文件
`static.txt`、`pass1.log`/`pass2.log`（原始 SPAN）、`pass1-table.txt`/`pass2-table.txt`、`full-CS.txt`、`llvm21-options.txt`。脚本 `Development/HIP/experiments/compiler-sweep/`（sb.ps1 单模块构建、sweep.ps1 静态扫、isa_stat.py、dupc.ps1 链内测、an.py 去漂移、go-cs.ps1 全流程、guard.sh 游戏看门狗）。lab `D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001`（recipe-off / recipe-on 两套 62 模块）。**未装机。**

## 6. 续（光第二单，10-02）：扩到全部模块、按核细分、post-RA 周边开关
基线 = 82ce821f 配方（c32/c512-deep 已带选项，`dupc.ps1 -Overlay`）。**这一轮没有新收的。**

### 6.1 扫哪些模块
31 个模块里链内只派发 9 个（gap-map 派发表：c32-wave1、c64-wave2、swin-persistent、vit-stream、mh_fast、deep_fast-packed、c512-m32-mh、c512-m32-deep、vit-wide-deep）；另外 22 个是参考/旧路径模块，生产链里不跑，改了也不影响计时，只编不测。9 个模块 × 10 组选项（在 `-RowOpts` 之上叠加），两架构都编过（`sweep2.ps1`，`static2.txt`）。
- `-misched-postra`、`-amdgpu-igrouplp-exact-solver`、`-amdgpu-enable-pre-ra-optimizations=0`：9 个模块代码逐条不变，直接淘汰（源码里的 sched_barrier 不构成 igrouplp 调度组，精确求解器没东西可解）。
- 溢出：c512-m32-mh 和 vit-wide-deep 在 post-RA 关 + max-ilp / iterative-ilp 下溢出 11～94 个 VGPR，不上 GPU。

### 6.2 链内 µs（pass3 三轮，`pass3-table.txt`；整网 span 去漂移，900 / 1152 行）
| 模块 | post-RA 关 | post-RA 关 + max-ilp | 关 s_delay_alu | 关 VOPD | 关 partial-reg 改写 |
|---|---|---|---|---|---|
| c32-wave1（已带配方） | – | – | +68 / +117 | +143 / +225 | −1 / +1 |
| c64-wave2 | **−16 / −20** | −24 / +62 | +54 / +89 | +23 / +63 | −3 / +8 |
| swin-persistent | +4 / +12 | −3 / −13 | −1 / −2 | −1 / +5 | 0 / +5 |
| vit-stream | +3 / −15 | **−2 / −14** | +4 / −9 | −2 / +46 | −3 / +32 |
| mh_fast | +4 / −8 | +86 / −12 | +27 / +48 | +2 / +7 | −4 / −4 |
| deep_fast-packed | +4 / +36 | +6 / −20 | +6 / +41 | +7 / +47 | +3 / −9 |
| c512-m32-mh | −2 / −5 | 溢出 | +9 / +13 | +16 / +23 | +4 / 0 |
| c512-m32-deep（已带 max-ilp） | +3 / +9 | −1 / −4 | +14 / +8 | +14 / −1 | +13 / −10 |
| vit-wide-deep | +2 / 0 | 溢出 | −3 / +5 | −8 / 0 | +10 / −18 |

`s_delay_alu` 和 VOPD 关掉在热模块上一律变慢（C32 关 VOPD +0.14/+0.23ms），说明这两样现在是正贡献，post-RA 周边没有可挖的。

### 6.3 按核细分（pass4 五轮 DUP，`pass4-table.txt`）
- 能不能做：LLVM21 有函数级属性 `"amdgpu-sched-strategy"`（`GCNTargetMachine::createMachineScheduler` 读它），但 **clang 没有任何源码属性能设它**，只能在 bitcode 上改，驱动机上没有 LLVM 工具，配方就得多一步 Linux 环节；**post-RA 调度没有函数级开关**。拆模块要改宿主（kernel→模块是写死的 `modules["vit_stream"]`），等于换宿主。
- 有没有必要：DUP 显示这几处"有的快有的慢"**分的是档位，不是核**：
  - c64-wave2 post-RA 关 + max-ilp：c128_wave2_bi_bo 和 c64_wave2_bi_bo **两核都是** 900 省、1152 亏（模块级 −19 / +57）。
  - mh_fast max-ilp：attention 投影和 ffn_c256 **两核都是** 900 慢（投影 DUP 183→264+76 基线）、1152 持平。
  - vit-stream：contract/QKV 两核同向，差都在噪声内。
  同一个核同时服务两档，编译期选项分不开 token 数，所以按核细分在这几个模块上没有收益，没做。

### 6.4 完整验证（基线 = 现装 + 82ce821f 的 c32/c512-deep）
| 候选 | 19 组 | ABBA 900 三轮 | ABBA 1080 三轮 | 合并 p99 900 / 1080 |
|---|---|---|---|---|
| CS2：c64 post-RA 关 + vit-stream post-RA 关+max-ilp | SAME | −0.017/−0.026/−0.008 | −0.007/−0.013/−0.025 | 7.437→**7.492** / 10.162→10.154 |
| CS3：只 c64 | SAME | **+0.024**/+0.001/−0.015 | −0.031/−0.007/−0.026 | 7.440→**7.482** / 10.231→10.170 |
| CS4：只 vit-stream | SAME | −0.023/**+0.028**/−0.005 | −0.016/−0.049/**+0.014** | 7.451→**7.542** / 10.239→10.227 |

CS2 六轮都快，但 900 合并 p99 变差；拆开后各自都有慢的轮次。收益约 10～20µs，和 ABBA 的轮间噪声一个量级。**按规矩都不收**，配方保持 82ce821f。
