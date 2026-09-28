# C512 FFN FP8线索：权重全精确，但已有展开算术反例

CPU扫描已完成：`amd-full`内block23..30、40..47共16份ffwd权重，合计8,388,608个float。
三个区间mix[0,262144)、expand[262144,393216)、contract[393216,524288)分别检查。
**全部原float就已在有限E4M3格点，half RNE没有改变任何一个bit；8,388,608/8,388,608可精确编码。**
逐文件SHA、每区间计数/范围在`weight-census-all16.json`；`census.py`可重算。

生产输入链也符合FP8格点条件：encoder入口Down的F输出、decoder39的F(H)输出，中间非raw C512 attention projection的F输出；shift仅搬值/补零。链尾raw用于后续pool/Up，不直接作为下一个C512 FFN输入。mixed本身为F(Hrtz)，因此expand的输入也在格点。

但是“操作数均精确”不等于“FP8 WMMA与F16 WMMA累加结果逐位相同”。本仓库已经有明确反例：

- `Development/history/DevHistory-full-20260923.md:1738-1750`：全16块×3输入共48组，block46 pattern2有10个float位差，其余47组一致。
- 当时权重是精确FP8打包，F16控制还专门从同FP8解码，排除了编码精度/输入差异。
- 阶段隔离：只换expand FP8即可复现；只换contract FP8则48组全同。这正是当前源码明确保F16 expand的来源。
- 可复现输入在`Development/HIP/test_split_ffn_fp8.cpp:4`：N32，code=(i*37+i/31)%127，按E4M3精确解码，i%3==0取负。全部输入均有限且在E4M3格点，涵盖到448。
- 该测试需配套旧`experiments/split-ffn-fp8.patch`/stage-isolation补丁才能重建当年的候选，不能直接用当前保F16展开的同名kernel冒称反例消失。

所以按“发现不能精确的反例即停止”要求，**此分支暂不输出RF8 kernel/host补丁**。权重census是新复核结果，不能覆盖旧硬件算术反例。若后续明确要求在新转置寄存器RF8上重验，应将上述block46/pattern2列为第一道单块门槛；即使该块生产默认跳过，也不能只凭真实fixture通过宣称全FP8等价。

这不影响R/RF（原F16 mix/expand＋FP8 contract）或compact路线。此轮未GPU、未改生产、未跑旧实验。

## 原日志已经找回（本轮只读，未重跑）

`release/HIP/split-ffn-fp8-validation.log:52` 原文：

```
block=46 pattern=2 bitdiff=10 invalid=0
```

`release/HIP/split-stage-isolation.log`：control EXIT=0；expand EXIT=1并重复同一行；contract EXIT=0。两份日志副本已放本目录，供归档。

这里的bitdiff=10是测试中10个float输出元素的4-byte memcmp不同，**不是只差10个bit，也不是max ULP=10**。旧测试没有打印这10个元素的索引/具体浮点值，原日志也没有，故不编造数值。旧阶段隔离采用当时激活表达式；没有宣称新RF8已经实际跑过，关闭依据是不能从格点精确推出两种WMMA严格等价。

R/RF本轮自身已通过逐位但短筛分别约慢0.2/0.3ms，主进程决定关闭，不继续打磨；compact方向已有收益。FP8展开按已知反例关闭，本目录不生成RF8补丁。

## 归档复现

`python3 census.py --root <297>/release/native-rgb-valid1080/amd-full`（需要NumPy），JSON写回脚本同目录。16份权重不重复打包，来源与SHA见JSON。附原测试cpp及两个历史patch，仅用于追溯当时反例；不能直接套到当前生产同名核。RF8本轮未构建/未运行。

日志归档时统一为LF并去行尾空白；原始字节hash另存original-log-hashes.json，数值未改。
