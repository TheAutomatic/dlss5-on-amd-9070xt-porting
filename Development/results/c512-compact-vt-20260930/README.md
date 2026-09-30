# C512 QKV-attention 的 V 在 LDS 转置存放（2026-09-30）：逐位，但两档不全正，不收；未装机

**结论**：kernel-map-v3 候选 1。`c512_qkv_attention_compact`（900 13 次 615µs、1080 约 718µs）的 P·V B 片段原来每个查询 tile 从 [token][channel] 布局逐字节取（64 条 `ds_load_u8` + 字节插入）。新宏 `C512_COMPACT_VT`（`hip/c512_qkv_attention_compact.inc`，源码默认 0，**配方不开**）让 part 2（V）写 LDS 时存 [channel][token]，读就是 8 字节连续。同字节同操作数，逐位。只动 c512-m32-mh，宿主不变。

- 静态 ISA（gfx1201）：总 1933→1867 条；`ds_load_u8` 64→0，换成 4 条 `ds_load_2addr_b64`；写端多 32 条 `ds_store_b8`。宏 0 编出的模块与剑星现装 `.note/.rodata/.text` 同（compare-modules identical 1）。
- 逐位：7 用例 × EXACT/AE × 12 帧 + AE CSV + 900/1080 票号回绕，19 组 SAME。
- 三轮 ABBA（1000 帧弃 200，base = 现装 31 模块 + deep-tail2 的 benchmark-base 宿主）：

|轮|900 avg|1080 avg|
|---|---|---|
|1|7.6655→7.6615（−0.0040）|10.4918→10.4941（+0.0023）|
|2|7.6836→7.6837（+0.0001）|10.4988→10.4973（−0.0015）|
|3|7.6871→7.6907（+0.0036）|10.5130→10.4988（−0.0142）|
|合并|7.6787→7.6786，p99 7.917→7.911|10.5012→10.4967，p99 10.814→10.814|

按新规（逐位、ABBA 为正、另一档不变差）**不收**：900 三轮符号不一、合并为零。读数：这 64 条字节读在这个核里不是瓶颈（核 VALU 占 63%，大头在 QKV 投影与 softmax 段），省下的 LDS 指令被写端 32 条 b8 抵掉。剑星/鬼武者未动（add-on 6d059845、RE9 runtime 5e601d57 不变），无新备份，不发包。

复现：`Development/HIP/experiments/c512-compact-vt/`（setup → b.ps1 → go.ps1；install/final 已改好模块名，备用）。lab `D:\DLSSNR-Lab\hip-backend\c512-compact-vt-20260930`，逐位帧转储已删。
