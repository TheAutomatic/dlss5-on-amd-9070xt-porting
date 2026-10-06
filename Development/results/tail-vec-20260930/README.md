# 向量化字节写出尾巴推广（2026-09-30）：C32 finish_b8 / finish_dcrop_b8d，逐位，两档三轮全正，已装

**结论**：全网扫下来，"每 lane 一个通道、逐字节写"的形态只剩 C32 的两个 finish 核（block4 `c32_wave1_finish_dcrop_b8d`、block69 `c32_wave1_finish_b8`，900 每帧各 1 次、约 6100 窗口，prefix 已在上一刀改掉）。改成和 `CW_PREFIX_TAIL_VEC` 一样的"每 lane 8 个连续通道"：一次 ds_load_b128、cw_pack8、一次 8 字节写，逐像素边界判断保留（这两个核有边缘窗口，比 prefix 多一条非整窗路径）。新宏 `CW_FINISH_TAIL_VEC`（源码默认 0，c32-wave1 配方写 1），只换 c32-wave1，宿主不动。逐位 19 组 SAME；三轮 ABBA **900 −0.038～−0.046ms（0.49～0.60%），1080 −0.043～−0.055ms（0.41～0.52%），p99 六个全变好**。已装剑星、鬼武者，没发包。

## 1. 扫描（哪些输出尾巴还是逐通道）

| 核 / 出口 | 每帧次数（900） | 现形态 | 判定 |
|---|---|---|---|
| c32_wave1_prefix_b8d | 1×24000 窗 | 已向量化（上一刀） | — |
| **c32_wave1_finish_dcrop_b8d**（block4 main+down 字节） | 1×6100 窗，156µs | 每 lane 一通道：64 次 store_b8 + 16 次 down store_b8，ds_load_u16 逐值 | **本刀** |
| **c32_wave1_finish_b8**（block69 main 字节） | 1×6100 窗，142µs | 同上（只 main） | **本刀** |
| c32 chain / mapped / up 输出 | — | 已是每 lane 8 通道一次 8 字节写 | 不用改 |
| c32 post | RGB f32 头 | 另一类（HEAD_VEC 09-27 已试，1080 反慢） | 不做 |
| C64～C256 `swin_wave2_body` ByteOut / f32 out | — | lane 持 8 连续通道，8 字节写（f32 连续 8 个） | 已是宽写 |
| multihead_fast_padded 旧 FFN/norm 字节出口（`out[(first+group*8+e)*C+wave*16+rc]` 类） | 走旧路径/小核 | WMMA D 布局：lane 持一列 8 行，宽写需先 LDS 转置，不是同类尾巴 | 不在本轮 |
| deep_fast `out8` 字节（C512/ViT 旁路） | 小 | 同上，列布局 | 不在本轮 |

## 2. 做法与逐位依据

lane c → (像素槽 sl=c>>2，通道组 cg=c&3)；main 8 次（t=i*8+sl），DownCrop down 2 次（k=j*8+sl）；每次读 8 个连续 half（与 `load()` 同索引），main `q=v+0`、down `q=Hrtz(Hrtz(top+bottom)*.25)+0`，`cw_pack8<0>`（MODE 饱和，配方 MASK 127 含 bit0）。原值 main `fp8(F(v))`、down `fp8(F(...))`：v 为 RTZ 产出的有限 half，F 只在 ±0 处不同且都给 0x00，其余 F(x) 是 x 的 E4M3 精确值 → 与 prefix 同一论证。边界：整窗分支与原 `emit(full)` 同条件（含 DownCrop 偶位移）；非整窗逐像素判断 main 与 down 各自原条件。非 DownCrop 且 down 非空（生产不走）保留原逐通道 down 循环；`finish_dcrop_b8`（down f32）不改。

**指令账（gfx1201 静态，整核）**：finish_b8 VALU 1548→1462、LDS 140→86、访存 84→78、等待 311→254；finish_dcrop_b8d 静态 VALU 1172→1728（整窗/边缘两路都完全展开，静态变多），LDS 80→38、等待 213→175；尾部由 64+16 次 store_b8 变 8+2 次 b64、ds_load_u16 逐值变 ds_load_b128。chain/prefix 其余核 ISA 不变。动态以实测为准。

## 3. 验证与计时

- 配方旧默认（宏 0）编出与现装 3F9CDD24 `.text/.rodata/.note` 逐字节同；配方直编 final 与实测 F 两架构三段逐字节同。
- 7 用例 × EXACT/AE × 12 帧、AE CSV、900/1080 history 票号回绕：**19 组 SAME**。
- ABBA（1000 帧弃 200，base = benchmark-P + 现装 31 模块）：

| 轮 | 900 avg（p99） | 1080 avg（p99） |
|---|---|---|
| 1 | 7.7075→7.6616，−0.046（7.947→7.895） | 10.5719→10.5287，−0.043（10.867→10.814） |
| 2 | 7.7332→7.6956，−0.038（7.945→7.912） | 10.5660→10.5222，−0.044（10.845→10.810） |
| 3 | 7.7289→7.6851，−0.044（7.954→7.926） | 10.5875→10.5326，−0.055（10.920→10.828） |

单刀即全部候选，无需合并再确认。

## 4. 装机

- c32-wave1：gfx1201 **8E47B814**（`8E47B814D2FAC7B2524607167346A73B10320AC4DE8C37296A7AC35F2E8A30C0`）/ gfx1200 **FD8FED73**（`FD8FED733909C5662F0EF140D1DCA69303A8D289155DEB86A41B31EEBB81C682`）。
- 剑星：只换两架构 c32-wave1、重建 SHA256SUMS（62），add-on 6d059845 不变，三个 flags 核过未动。备份 `D:\DLSSNR-Lab\hip-backend\tail-vec-20260930\backups\stellar-20260930-124532-tailvec`。
- 鬼武者：模块与剑星对齐，runtime（含 `_storage_`）5e601d57 未换，备份 `D:\DLSSNR-Lab\onimusha-backups\20260930-124532-tailvec`。
- RE9 runtime 5e601d57 不变（导出名不变），未重编。没发包。回滚 `install.ps1 -RestoreStellar/-RestoreOni <备份>`。

复现：`Development/HIP/experiments/tail-vec/`（setup → build → run.ps1 -Name F → final → install）。lab `D:\DLSSNR-Lab\hip-backend\tail-vec-20260930`。
