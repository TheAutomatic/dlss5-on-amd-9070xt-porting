# ViT 960 token 常量化：已有快路径，小筛不收（2026-10-04）

**不合生产、不新增宿主选择、不装游戏。** 新 960 专用核数值相同，但当前 FAST_NUMERIC=1 对应的 FAST15 小筛出现慢轮，未显示稳定收益。没有跑整网 19 组、2K 动态/history 或整帧 p99；只完成隔离 actual attention 对拍与三轮 ABBA。

## 当前原生 2K 并非缺快路径

基线 `d02b423c`：2560×1472 free geometry，ViT 网格40×24=960。宿主选名为 `vit_attention_fused_640_bytein_bout`，生产配方 `HIP_VIT_ATTN_TRANSPOSED_SCORE=1` 进入逐16 key流式转置score核。该 body 的 MAXT 模板不用于容量/循环边界，所以640只是名字；runtime tokens=960完整处理60个 key tile，没有640大小的LDS越界或拆分fallback。

ViT stream mask3、N64 projection门不限制640，现有w5f8 QKV也自动选：960/16=60 token tile，恰为5个wave一组的倍数。没把已有w5、half contract、byte AV当成新增优化。

唯一小候选是新增960 export，以常量960调用同一个 body，让输入stride、输出地址、循环上限成为编译期常数；不改QK/PV K顺序、归约树、FP8/half量化或几何。正常 VIT_FAST_NUM=0、现生产fast VIT_FAST_NUM=15分别编译，对照各自原核。

## 结果

两种精度 × 两种有限FP8 QKV输入，960×1024 输出各983040 byte全部一致。pattern0覆盖宽FP8幅度，pattern1以较小Q/K及较宽V模拟归一化输入；均为合成输入，不冒充游戏真实 norm。

每槽20次warm +150次计时调用；计时前两实现各300次交错预热。GPU event同流包住整批，end同步后读；同时记录CPU wall，两者同方向。小块运行有明显槽波动，不能选择最好轮声称提速。

| FAST15 输入 | 轮 | 原核 µs | 常量960 µs | 差 µs |
|---|---:|---:|---:|---:|
| pattern0 | 0 | 93.742 | 90.154 | −3.587 |
| pattern0 | 1 | 103.019 | 102.958 | −0.061 |
| pattern0 | 2 | 126.429 | 135.687 | +9.257 |
| pattern1 | 0 | 90.024 | 106.322 | +16.298 |
| pattern1 | 1 | 105.807 | 101.854 | −3.953 |
| pattern1 | 2 | 122.945 | 100.831 | −22.114 |

正常精度同样出现慢轮（pattern1最后一轮+41.925µs）。因此止于小筛，不继续token块数/M32/编译器扫参。这个结果只否决本轮常量化候选；不证明ViT960不存在其它优化。

ISA（gfx1201）：正常核467→453行、FAST15核371→357行；VGPR68→66，SGPR12→10，20条global load及5条WMMA静态指令不变、零spill。省的是少量地址/边界计算，没有减少注意力主要算术或访存。

## 边界和复现

- `Development/HIP/experiments/vit960/attention960.inc` 保存默认宏0的实验export，`prepare.py` 从固定d02b423c构造baseline/candidate。生产 `hip/deep_fast.hip`、配方、sharedhost没有改动。
- 官方COMGR21，正常与FAST15配方保持生产定义（包括原有half/FP8路径）；没有推广LLVM23。gfx1200/gfx1201都编译，ELF flags分别0x48/0x4e；实际GPU仅gfx1201。
- 两架构、两种精度，所有原有FUNC符号的机器码逐字节不变，只有新增960 export。见`summary.json`函数计数/目标/模块/生成源码SHA。旧900/1080代码未改，但未额外跑游戏回归。
- `probe.cpp` 是actual attention隔离对拍及计时，`build.ps1/run.ps1` 保留编译和GPU独占流程；`probe-0.log/probe-15.log`及`timing.csv`为原始槽，压缩ISA片段可直接核核名/指令。
- Windows实验根`D:\DLSSNR-Lab\vit960-20261004`；game-check、原子owner锁、15秒看门狗、D盘>100GB。GPU锁已释放给主工程；没有修改游戏、没有帧dump、没有外发/push。

主工程同批原生1440单遍wholewall约19.98ms、1080约12.19ms（另一个任务的数据，不与本表孤立event混算）。960常量化并未找到可收收益，后续应以真实2K族账定位，而非从核名640推断没有优化。
