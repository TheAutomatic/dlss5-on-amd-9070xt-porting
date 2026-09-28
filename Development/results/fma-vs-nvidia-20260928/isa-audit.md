# NVIDIA / 我们 / Daniel 算术审计（静态，2026-09-28）

结论：NVIDIA 的激活和 softmax 仿指数 affine **确实是 HFMA2（half FMA）**。我们当前 f32 mul/add 是不同精度的路径，单改 f32 FMA 不是恢复 NVIDIA。Daniel reference 激活确实更贴近 NVIDIA，但 reference 不等于逐位 NVIDIA：归一化求和树、倒数实现和矩阵累加模拟都有差别。

## 三方对照

| 段 | NVIDIA SASS | 我们当前 | Daniel 0.5.0 reference (`Lb0`) |
|---|---|---|---|
| C32/C64/C128/C256 FFN 激活 | expanded 来自 `QMMA.16832.F16.E4M3.E4M3`；half clamp；`HFMA2(abs(g),-0.055908203125,0.447265625)`；`HFMA2(g,q,0.89453125)`；`HMUL2(a,p)`；half→FP8 | expanded 为 WMMA f32；clamp f32；q/p 各 f32 mul+add/sub，最终 f32 product→FP8。C32 `wave_owned_c32.inc:239`，MH `wave_owned_mh.inc:207`。ACO ACT-c32.s:365 起可见 sub、dual_mul、dual_add | 已沿 C32/C64 Lb0 数据流确认 `v_pk_fma_f16` 两次，接 `v_pk_mul_f16`；**不是凭全核 fma_mix 条数判断**。C64 0x10CB68 clamp→0x10CB94 q→0x10CBA0 p→0x10CBB0 product |
| softmax 仿指数 affine | score/bias half 运算后 `HFMA2(score,0.044921875,1.30078125)`，half clamp，位重解释/移位形成指数近似（不是普通 exp） | score/bias、affine 是 f32 separate mul/add；显式位移构造 half exponent | C64 0x110FD8 `v_pk_fma_f16 v38,v48,s9,0x3d34`，s9 在 0x10FFE4=0x29c0，即 half 0.044921875；输出 half |
| softmax 分母 | HADD2 多级树 + shuffle/half 双分量合并；每次 half 舍入 | C32 half 输入、WMMA **f32 累加**；MH 两路 WMMA f32 sums 后 f32 相加（不等于原树） | C64 0x111510—0x1115F8 为 half 加法树，最后 high/low half 相加；比我们保留更多 half 边界，但未经全树排列等价证明 |
| softmax 倒数/归一化概率 | 分母 half→f32；`MUFU.RCP`；`F2FP.F16.F32.PACK_AB`；`HMUL2(exponent, half reciprocal)` | bounded `rcp` + 两轮 Newton FMA，保留 f32 reciprocal；f32 exponent*inv→FP8 | C64 0x11160C—0x111664 是完整 f32 division lowering：div_scale、rcp、FMA、div_fmas、div_fixup；0x11166C 转 half，0x111674 起 half multiply。**不是 NVIDIA 的直接 MUFU.RCP** |
| Q/K 平方范数 | `HMUL2(x0,x0)` 起步、`HFMA2(x1,x1,acc)` 等局部累加，HADD2+SHFL 合并；half→f32、MUFU.RSQ、转回 half、HMUL2 缩放 | C32 单项平方舍到 half，再 WMMA f32 sum；MH 32 通道串行 f32 mul/add（`w2_serial_norm`）；rsq 后保留 f32，再乘 scale/值 | C64 0x10FBB0—0x10FC28 **逐项 v_pk_mul_f16 平方**，0x10FC30—0x10FD0C half 加法树，然后 f32 rsq→half→half multiply。这里没有对应 NVIDIA 的 fused square+acc，故 reference 也非严格原指令复制 |
| 残差 | 至少 C32 输出投影明确：half 残差*scale (`HMUL2`) 作为 QMMA.F16 初始 accumulator；矩阵结果在此累加，不能概括为一个 scalar FMA | C32 attention 输出：WMMA f32 投影、f32 residual*scale、f32 add，最后 Hrtz；MH FFN 残差先 Hrtz(product) 作 WMMA f32 seed；MH attention 残差是 diagonal FP8 WMMA 三段+投影 WMMA | C64 最终投影是 f32 WMMA 分组，然后 `v_fma_mixlo/hi_f16(half accumulator,1.0,f32 partial)` 舍 half（例如 0x112438 起，s3=1.0）。此处 FMA 实际承担“累加并舍到 half”；不是普通自由融合 residual*scale+projection。尚未逐寄存器证明所有 residual 支路与 NVIDIA 的分块顺序一致 |

## NVIDIA 独立 cubin / 核入口与定位

`cuobjdump --dump-sass` 从 cubin 00/01/02/03 抽取普通 `_fp8` 核，分别写 `c32.sass`/`c64.sass`/`c128.sass`/`c256.sass`。地址均相对各 kernel：

| C | 激活 q | softmax affine | 平方 fused 累加例 | rsq | reciprocal |
|---|---|---|---|---|---|
| 32 | 0x0aa0 | 0x6090 | 0x4a80 | 0x4ef0 | 0x6db0 |
| 64 | 0x11f0 | 0x5080 | 0x3920 | 0x3d60 | 0x5d50 |
| 128 | 0x10b0 | 0x4950 | 0x3340 | 0x3af0 | 0x55c0 |
| 256 | 0x1530 | 0x54a0 | 0x3790 | 0x3ec0 | 0x6ea0 |

C32 激活另一组完整寄存器链：0x1850/0x1880 R36=clamp(R40)；0x18b0 R37=HFMA2(abs(R36),-R0.H0,0.447265625)；0x1900 R37=HFMA2(R36,R37,0.89453125)；0x1a20 R37=HMUL2(R40,R37)。这直接证明激活而非某个无关 FMA。

C32 范数链例：0x4b90 HFMA2 R0,R91,R91,R0；0x4bd0 HADD2 R2,R2,R0；邻近 SHFL.BFLY 后 HADD2；MUFU.RSQ。C32 分母末尾 0x6d00/10/20 HADD2，0x6d70/80 half→f32，0x6db0/dd0 MUFU.RCP，0x6e20 pack half。

C32 残差链：0x9b10 `HMUL2 R14,R88,R13`，0x9c00 `QMMA.16832.F16.E4M3.E4M3 R14,R4,R24,R14`。因残差已经进入 matrix accumulator，改末尾 scalar mul/add 不能复原它。

## 证据和限制

- `/tmp/fma-vs-nvidia/nvidia-00.sass` 原已有；本轮生成 01/02/03 全反汇编以及四个单核切片。
- `/tmp/fma-vs-nvidia/daniel-c32.s`、`daniel-c64.s` 是原 dis-gfx1201.s 的 Lb0 核切片，保留原绝对指令地址。
- NVIDIA C32～C256 都核实了上述激活/affine/平方FMA/rsq/rcp 指令类别；Daniel C32/C64/C128/C256均独立检查了四段局部数据流，C128/C256地址见末表；未证明全树及全残差等价。
- SASS 没打印 `.rn` 时不能写成 PTX 文本里的显式 `.rn`；本报告只引用实际 HFMA2/HMUL2 等机器指令。保留 half 边界才是候选设计必须先解决的事。
- 未跑 GPU，未改生产源/配方，未证明任一第三方实现端到端逐位 NVIDIA。

## 补审：Daniel C128/C256 reference 独立核（已实际读取，无 C64 外推）

核符号分别 `_Z13k_reg_swin_mhILi128ELi0ELb0EEv9VarParams`（入口 0x17D000）和 `_Z13k_reg_swin_mhILi256ELi0ELb0EEv9VarParams`（入口 0x1EC500）。全核切片已存 `daniel-c128.s`、`daniel-c256.s`。以下是原反汇编绝对地址。

| 实际数据流 | C128 | C256 |
|---|---|---|
| 激活系数加载 -0.055908203125=half 0xab28 | 0x17D47C s11=0xab28 | 0x1EC8FC s11=0xab28 |
| q=half FMA(abs(g),s11,half 0x3728) | 0x17DCCC `v_pk_fma_f16 v100,v100,s11,0x3728` | 0x1ECEE4 `v_pk_fma_f16 v106,v106,s11,0x3728` |
| p=half FMA(g,q,half 0x3b28) | 0x17DCD8 `v_pk_fma_f16 v99,v99,v100,0x3b28` | 0x1ECF14 `v_pk_fma_f16 v98,v98,v106,0x3b28` |
| 激活原 a × p | 0x17DCF0 `v_pk_mul_f16 v99,v126,v99` | 0x1ECF48 `v_pk_mul_f16 v17,v17,v98` |
| softmax affine 系数 half 0x29c0=0.044921875 | 0x1817E0 s11=0x29c0 | 0x1F09A4 s11=0x29c0 |
| softmax half FMA + half 0x3d34=1.30078125 | 0x181A44 `v_pk_fma_f16 v56,v82,s11,0x3d34` | 0x1F0BC8 `v_pk_fma_f16 v41,v86,s11,0x3d34` |
| 范数单项 half square（没有 fused add） | 0x180768 `v_pk_mul_f16 v17,v42,v42`；0x1807EC `v_pk_mul_f16 v34,v58,v58` | 0x1EF97C `v_pk_mul_f16 v52,v29,v29`；0x1EF984 `v_pk_mul_f16 v53,v25,v25` |
| 范数 half sum，输入为上面的 squares | 0x180814 `v_pk_add_f16 v17,v17,v34`；shuffle/树后 0x1808B0 half 高低相加 | 0x1EF9A8 `v_pk_add_f16 v52,v52,v53`；shuffle/树后 0x1EFAEC half 高低相加 |
| 范数 RSQ→half→half product | 0x1808C4 rsq v17；0x1808CC cvt half v34；0x1808D0 `v_pk_mul_f16 v17,v42,v34` | 0x1EFB10 rsq v52；0x1EFB14 cvt half v52；0x1EFB1C `v_pk_mul_f16 v28,v28,v52` |
| softmax half denominator 末端 | 0x18203C/50/5C 三次 pk_add；0x18206C 高低 half add；0x182070 转 f32 | 0x1F11C0/D4/E0 三次 pk_add；0x1F11F0 高低 half add；0x1F11F4 转 f32 |
| softmax 完整 f32 reciprocal division | 0x182080 div_scale →0x18208C rcp→FMA correction→0x1820CC div_fmas→0x1820D8 div_fixup | 0x1F1204 div_scale →0x1F1210 rcp→FMA correction→0x1F1250 div_fmas→0x1F125C div_fixup |
| reciprocal→half→probability half product | 0x1820E0 cvt half v92；0x1820E8 `v_pk_mul_f16 v106,v92,v56`（指数位构造的符号修正见 neg flags） | 0x1F1264 cvt half v94；0x1F126C `v_pk_mul_f16 v70,v94,v41`（同样 neg flags） |
| 最终投影块累加回 half | 0x182AE0 s9=1.0；0x182B90 f32 WMMA；0x182B98 `v_fma_mixlo_f16 v22,v135,s9,v31`，half×1+f32 partial→half | 0x1F1C5C s9=1.0；0x1F1D14 f32 WMMA；0x1F1D1C `v_fma_mixlo_f16 v22,v135,s9,v31`，同类数据流 |

因此 C128/C256 均独立确认了与 C64 同类的精度/指令结构。这里证明指令类别和局部链，**未证明整棵 reduction tree 或全部残差 tensor 分块与 NVIDIA 等价**。

C32 补核也一致：平方 `v_pk_mul_f16` 0x05349C/0x0534A4 后 `v_pk_add_f16` 0x0534CC；rsq 0x053720→half 0x05376C→half product 0x053790。softmax affine half FMA 0x055220（s9=0x29c0）；分母除法 rcp 0x055868→div_fixup 0x0558B4→half 0x0558BC→half product 0x0558C4。

上述补审取代前一节“Daniel 只深追 C32 激活与 C64”的覆盖范围限制；未证全树/全残差等价的限制仍保留。

## 指令语义文档

NVIDIA PTX 对half FMA的定义是乘积与加法合并、只在half目的精度舍入；HFMA2对应双half SIMD。参见 [NVIDIA PTX half FMA](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#half-precision-floating-point-instructions-fma) 与 [NVIDIA mixed precision / HFMA2](https://developer.nvidia.com/blog/mixed-precision-programming-cuda-8/)。AMD mixed FMA的输入精度由op_sel_hi指定、MIXLO写half，参见 [AMD RDNA4 ISA](https://www.amd.com/content/dam/amd/en/documents/radeon-tech-docs/instruction-set-architectures/rdna4-instruction-set-architecture.pdf)。这些定义只用于解释已找到的机器指令，不能替代本项目原DLL的数据流证据。
