# vit-stream / mh_fast 在 LLVM22/23 下不逐位：定位与对齐（2026-10-02，光派单）

**结论：根因找到了，是 LDS 屏障前少了一条 `s_wait_dscnt`，不是浮点、也不是循环展开。加栅栏后 LLVM23、LLVM22 都逐位（19 组 SAME），但两者都不比现配方快，不收。配方不变，next-candidate 没动。**

## 1. 定位
做法：用 LLVM21（fork，= 现装 COMGR 代码）和 LLVM23 各编一份汇编，按核把 LLVM23 的函数体、kernel descriptor 和元数据条目拼进 LLVM21 的汇编，再用 LLVM23 汇编器汇编（`splice.py` / `asm.sh`），每份只换一个模块跑 19 组（`go-bv.ps1` → `go-cv.ps1`，-PinIdle）。全部结果在 `bitwise.txt`。

先排除的：
| 试验 | 结果 | 说明 |
|---|---|---|
| LLVM21 `-fno-unroll-loops` | SAME | 展开方式不影响数值 |
| LLVM23 `-fno-unroll-loops` / 前端 `-unroll-count=4` | 不同 | 对齐展开救不回来 |
| LLVM21 前端产的 IR + LLVM23 后端 | 不同 | 问题在后端 |
| LLVM23 + f16 加宽走内联汇编（去掉 `v_fma_mix`） | 不同 | fma_mix 无关（LLVM21 同改 SAME） |
| LLVM21 代码用 LLVM23 汇编器重新汇编（未用的 src2 编码变了） | SAME | 编码无关 |
| LLVM21 把 `v_rcp_iflag_f32` 全换成 `v_rcp_f32`（LLVM23 用 `v_s_rcp_f32`） | SAME | 整数除法的 rcp 无关 |
| LLVM23 `-DHIP_LDS_FENCE=0` | 不同 | |

按核拼接二分（vit-stream 83 个核 → 半 → 四分之一 → 单核；mh_fast 派发的 7 个核逐个）：
- vit-stream：只换 **`vit_stream_qkv_frag_hin_w5`** 一个核就不同，其余单核都 SAME。
- mh_fast：只换 **`mh_ffn_fused_c256_frag_project_mapped_g128_qkv_fb_pdl`** 或 **`..._bytein_fb_pdl`**（都走 `mh_ffn_qkv_body`）就不同；attention 投影、四个 pool 核单换都 SAME。

原因：这两处源码在写 LDS 后直接 `__builtin_amdgcn_s_barrier()`，没有 `WG_FENCE`。LLVM 的内存模型里裸 barrier 不是内存栅栏。LLVM21 的 SIInsertWaitcnts 对 gfx12 的拆分屏障（`s_barrier_signal`）一律先补"所有计数器清零"，等于白送了一条 `s_wait_dscnt 0`；LLVM22/23 把这条规则收窄成只对老的 `S_BARRIER` 生效（注释："Subtargets with split barriers don't need to back off the barrier"），于是 `ds_store_2addr_b32 ×8 → s_barrier_signal` 之间没有等待，别的 wave 过了屏障读到还没落地的 LDS。ISA 对照（qkv_w5，LDS/屏障序列）：
```
LLVM21: ds_store_2addr_b32x8 s_wait_dscnt s_barrier_signal s_barrier_wait ds_load_2addr_b32x8
LLVM23: ds_store_2addr_b32x8              s_barrier_signal s_barrier_wait ds_load_2addr_b32x8
```
（§8.1 看到的 FMA/加法条数差、展开倍数差都是真的，但都不改数值。）

## 2. 对齐：源码宏 `HIP_BARRIER_FENCE`（默认 0）
`hip/deep_fast.hip`、`hip/multihead_fast_padded.hip`：宏为 1 时，本文件里每个裸 `__builtin_amdgcn_s_barrier()` 前后加 `WG_FENCE(3)` / `WG_FENCE(2)`（LDS 作用域的 release/acquire，只多出 `s_wait_dscnt`）。默认 0 时用 LLVM21 重编与改前逐条同。
- LLVM23 + 宏 1：vit-stream、mh_fast 各 **19 组 SAME**。
- LLVM22（ROCm 7.2.4）+ 宏 1：各 **19 组 SAME**（LLVM22 的 qkv_w5 同样少那条等待，加宏后补上）。

## 3. 测速（DUP，基线 = 现配方 c32/c64 LLVM23 + c512-deep max-ilp，µs，900 / 1152 行，去漂移中位）
| 候选 | vit-stream 整模块 | mh_fast 整模块 |
|---|---|---|
| LLVM23 + 宏（pass7 900 五轮、1152 四轮 / pass9 三轮） | +111 / +146，+120 / +125 | +369 / +91，+384 / +106 |
| LLVM23 不加宏（不逐位，只看代价，pass8） | +109 / +155 | +321 / +101 |
| LLVM21 + 宏（栅栏本身的代价，pass8） | 0 / +50 | +10 / +9 |
| LLVM23 + 宏 + `-unroll-threshold=1200`（pass8） | +90 / +83 | +289 / −23 |
| LLVM22 + 宏（pass9） | +7 / +29 | +3 / −20 |

- LLVM23 慢在编译器本身（不加栅栏也一样慢），栅栏只占一点。按核：ffn c256 单份 DUP 234→848µs（900），contract 191→353，project 71→210，qkv 343→425。ffn 不是展开（指令数、WMMA 数、VGPR 都差不多），没继续追。
- LLVM22 + 宏：vit-stream 两档都慢，不测；mh_fast 900 持平、1080 −20，上了完整验证（`full-CS7.txt`）：19 组 SAME，ABBA 900 +0.003/+0.021/−0.015，1080 +0.018/−0.005/−0.021ms，合并 p99 7.422→7.406、10.098→10.111。有三轮慢，**不收**。

## 4. 结论
- 不逐位的根因是源码依赖了老编译器在屏障前白送的等待；`HIP_BARRIER_FENCE=1` 能让 LLVM22/23 逐位。以后要用新编译器编这两个模块时得带上这个宏。
- 速度上两者都不赚，**配方不变（d48cdae3 起那套），next-candidate 包和 install.ps1 没动。**

## 文件
`bitwise.txt`（全部 19 组结果；注意 bv1 的 XH1 是"LLVM21 IR + LLVM23 后端"，bv8 的 XH1 是 vit 第 73–77 号核拼接，后者覆盖了前者的目录）、`pass7.log`（1152 行跑到第四轮，看出明显变慢后手动中止）/ `pass8.log` / `pass9.log` 及 `*-table.txt`、`full-CS7.txt`。
脚本：`Development/HIP/experiments/llvm23-vit/`（go-bv.ps1、go-cv.ps1、dupc.ps1、go-cs.ps1、guard.sh、cases7–9、splice.py、asm.sh、fpseq.py、allops.py、icount.py、an.py）。lab：`D:\DLSSNR-Lab\hip-backend\compiler-sweep-20261001\X*`、`L23bf`、`L22bf`、`L21bf`、`L23p`、`L23ut12`。

## 5. 续（同日）：审计 next-candidate 的 c32/c64，全仓清单
扫描器 `barrier_scan.py`：反汇编里按函数线性扫，遇到 LDS 写（ds_store 等）后、`s_wait_dscnt 0`（或合并的 storecnt_dscnt/loadcnt_dscnt）前出现 `s_barrier_signal` 就记一处。不跟分支，是近似。验证：vit-stream LLVM23 能抓到 qkv_w5，LLVM21 和 LLVM23+宏 都是 0。

**next-candidate**：c32-wave1（LLVM23，两架构）0 处。c64-wave2（LLVM23）72 个核有，**全是编进模块但不从这个模块派发的 mh_* 核**（宿主从 c64_wave2 只调 c*_wave2* 和 c256_attn_wave*，这 28 个核 0 处）。还是按"有一处就加"处理：配方行加 `l23defines = @('HIP_BARRIER_FENCE 1')`（只进 Linux 上的 LLVM23 预编，COMGR 不看这个字段，默认配方不变；compile-modules.py 认这个字段），两架构重编后 0 处，28 个派发核与加宏前逐条相同。
- 19 组 SAME；ABBA（基线 = 原包配方）900 −0.002/−0.007/+0.022，1080 +0.017/−0.003/−0.004ms，合并 p99 7.445→7.452、10.151→10.117（`full-CS8.txt`）。派发代码没变，这是 A/A 噪声。
- 没有按"不赚就退回 LLVM21"处理：这次加栅栏改的只是不派发的核，派发代码逐条相同，退回 LLVM21 会丢掉 c32/c64 那 −0.05/−0.07ms，换不来任何安全性。**包已更新**（旧包备份 `D:\DLSSNR-Lab\next-candidate-bak-20261002-prefence`，build-next 旧版 `build-next-prefence`）：c64 gfx1201 A0CAD8CB / gfx1200 B90443EE（与测过的代码逐条同，文件哈希不同是 cuid 随源码文本变），c32 不变；包 SHA256SUMS 0831EAA1，`install.ps1 -DryRun` 过；README.txt 写明原因。新预编在 lab `compiler-sweep-20261001\pre23f`。

**全仓**：31 个模块用 LLVM21 和 LLVM23 各编一遍扫（`isa-scan-llvm23.txt`）。LLVM21 全部 0 处，现装配方安全。LLVM23 下有：c512-m32-deep 5、c512-m32-mh 72、c64-wave2 72、deep_fast(-packed) 5、multihead-fast(-packed) 9、multihead-fast-padded-wave(-packed) 84、multihead-tiled 7、swin-persistent 72、vit-stream 7、vit-wide-deep 5。源码层的屏障清单（启发式分"前面有没有 WG_FENCE"）在 `source-barriers.txt`：裸的集中在 multihead_fast_padded.hip 26、deep_fast.hip 15、vit_stream.inc 7 等。技术债记进 WorkingPlan。
