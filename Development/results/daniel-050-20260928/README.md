# Daniel 闭源 v0.5.0 静态分析（2026-09-28，分身）

输入：`temp/dlssnr_on_amd_setup.exe`，SHA256 `39df94a0…ab145e`，41.8MB（0.4.0 为 13.2MB）。用 `tools/closed-inspect/extract.py` 静态提取，未运行安装器，未动 9070。对照 0.4.0 旧提取 `/tmp/dlssnr-closed-20260926`（`results/closed-v040-20260926`）。解包与反汇编产物只放 scratchpad。

## 文件与内核

| | 0.4.0 | 0.5.0 |
|---|---|---|
| mod DLL | 10.0MB | 38.7MB（字符串显示：安装时从用户的 `nvngx_dlssnr.dll` 310.8.0.0 抽权重写 `dlssnr_on_amd_weights.bin`，逐张量核对） |
| gfx1201 代码对象 | 1.77MB，86 函数 | 2.99MB，168 函数 |
| gfx1100 代码对象 | 1.13MB | **7.85MB**（与 gfx1201 同一份 168 个内核名） |

内核变化：几乎每个核多了一个尾部 `bool` 模板参数，即 0.4.2 起的 **Quality（reference / fast）** 双份。判别：`Lb1` 版没有 `v_div_scale/fixup`（近似 rcp），`Lb0` 保留完整除法 → **Lb1 = fast，Lb0 = reference**。另新增 `ILi2` 变体（vit_conv / vit_ffwd / expand2 / reg1d_conv，推测一 wave 两份工作）、`k_reg_head<4>`、`k_reg_vit_attn2/3`、`k_w16_decode`（f16 权重解码）、`k_noise`。

## 设置与默认值

默认 INI 与 0.4.0 相比只多 `Quality=fast`、`OverlayKey=End`；`SkinStructure=-1`、`UseAutoMask=1`、`LocalTone=0`、`PreHistory=0` 等 0.4.0 就有。UI 原文：reference = "NVIDIA's own arithmetic (the PTX arithmetic)"；fast = "f32 accumulation, one-rounding e4m3, approximate rsqrt / rcp, hardware noise and sRGB math … about 13% faster on RX 9000; no speed effect on RX 7000"。**默认是 fast**，网友说的"快了"是 fast 档。

新 env：`DLSSNR_EXTENT` / `DLSSNR_EXTENT_NO_W64` / `DLSSNR_PAD128`。日志字符串："not validated on the NVIDIA working extent (and hung in the 128-padded baseline too) … set DLSSNR_PAD128=1"、"NVIDIA's single-tile mode … not ported"。即 **0.5.0 默认改为按 NVIDIA 原生工作尺寸（working extent）跑网络，旧的 128 对齐填充变成可选回退**。

## 三个问题的判断

1. **RDNA4 +5%**（静态证据，未实测）：
   - reference 版相对 0.4.0 同名核：总代码 1.43→1.21MB。C32 `reg_swin32<0>`：VALU 2433→1830、`v_mov` 268→25、`v_lshl_or` 92→0、`v_and` 115→36、`v_pk_min/max_f16` 各 −80、scratch 溢出 24→0；`v_cvt_*` 数不变（数值路线没动）。C64 `reg_swin_mh<64,0>`：溢出 47→2、VOPD 269→57、WMMA 112→176（展开方式变了）。即**寄存器布局/打包清理 + 去溢出 + 少一部分夹紧**，和我们第五刀、C32 三刀同类。
   - 另一可能来源是 working extent：网络按 NVIDIA 的原生尺寸而非 128 对齐跑，像素更少。字符串只能证明默认改了，拿不到具体行数。
2. **RDNA3 +207%**：0.4.x 时 RDNA3 走通用核（寄存器快核是可选 `Rdna3RegKernels`，默认关）；0.5.0 字符串："the register kernels are the only RDNA3 path since 2026-09-27"。算术：gfx1100 全部 11644 条矩阵指令都是 `v_wmma_f32_16x16x16_f16`，权重在显存里另存一份 f16（"an f16 copy of the weights in VRAM"，FP8→f16 无损）。e4m3 舍入用整数位运算软件模拟（C64 核 VALU 约 8066 条，是 RDNA4 的 3.8 倍，主力 `v_bfi/v_lshrrev/v_and/v_pk_add_u16/v_cmp_lt_u16/v_cndmask`），因此 reference 在 RDNA3 上仍按 FP8 语义。**+207% 本质是 RDNA3 从通用核换到寄存器快核（等于 RDNA4 在 0.4.0 那次 42%）**，不是新算术。
3. **"画质更丰富"**：默认视觉参数没变（SkinStructure/UseAutoMask 0.4.0 就有）。可见的改动是 working extent 与 NVIDIA 对齐（"closer to NVIDIA" 与 0.4.2 说明一致）。另一可能是 fast 档改为"one-rounding e4m3"（f32 直接一次舍入到 e4m3，少一道 f16 中转）。没有运行，无法区分。

## 对我们的可借鉴项

- **working extent（最值得查）**：我们 1080 档处理区是 1920×1152。先弄清 NVIDIA 原生工作尺寸是多少（DLL/PTX 的 tile 逻辑，`_NO_W64` 暗示宽度按 64 对齐）；若比 1152 行小，就是既更贴近 NVIDIA 又少算像素的一刀。但输出会变，**不逐位**，需 Zero 拍板（C 段）。
- **fma_mix 与 NVIDIA 原算术**：Daniel 的 reference（自称 PTX 算术）C64 核里 `v_fma_mixlo/hi_f16` 704 条，而闇的 aco-lineup 说我们那段是"乘、加两次独立舍入，语义必须"。值得回查：我们那段的两次舍入是否确实就是 NVIDIA PTX 的写法。若 NVIDIA 本来就是一次 FMA，我们"逐位"的对象就是我们自己的旧版，而不是 NVIDIA。**本条只是疑问，没有核实。**
- **RDNA3 路线样板**：f16 权重副本 + f16 WMMA + 整数位运算模拟 e4m3，给出了"RDNA3 上保 FP8 语义"的一种实现和代价（VALU 约 4 倍）。无卡可测，仅存档。
- reference 版的去溢出、少 `v_mov`/打包，我们已在做，没有新招。

## 复现

`python3 tools/closed-inspect/extract.py <setup.exe> <out>` → `llvm-objdump -d --mcpu=gfx1201|gfx1100 <out>/<arch>.hsaco`；内核名 `readelf -Ws`；按函数计指令类别的脚本在 scratchpad（`mix.py`、`opdiff.py`），思路同 `closed-inspect/disassemble.py`。
