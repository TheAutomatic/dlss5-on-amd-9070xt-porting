# 工作尺寸只读审计（2026-09-28）

结论：1080 档不能把 1152 行说成我们相对 NVIDIA 多算。原版实际调用参数已经明确给出 **1920×1152**，我们相同。Daniel 0.5.0 默认实际算法给出 **1920×1088**，其“working extent”说法与本仓库这份 NVIDIA DLL 的 1080 捕获不一致。900 档我们与 Daniel 都是 **1600×960**；原版 900 没有可靠捕获，不能认证谁忠实。未运行 GPU、未改生产或安装文件。

## 证据链

全部相对路径相对于 wechat/assets/297。

- 原 DLL `large-resources/nvidia/nvngx_dlssnr.dll` SHA256 `e16bcf15e16e13f527491cdf7845b2fe6521a738d8f7c9c721866a8496e1fc8e`。
- 1080 原始捕获 `release/native-kernel-params-25972-17399312/launch-0001.bin` SHA256 `e9418d00f4edd51c8e8f735cbc8bd6597e41538dc3abf8d804721ab16965ef95`，本轮用 Python struct 直接复读：`<ff @0x90 = (1920,1080)`；`<ii @0xd0 = (1080,1920)`；`<ii @0xf0 = (1152,1920)`。前两组是有效纹理，最后一组是网络处理 H/W，并非依据日志猜尺寸。
- 同捕获 launch-0055.bin 的 `<iiii @0x40 = (36,60,20,32)`，池化的全尺寸与 token 网格；launch-0056.bin `<ii @0x20 = (20,32)`；launch-0099.bin `<iiii @0x40 = (20,32,36,60)`。网络补齐、ViT 补零 token、屏幕有效区是三件事。
- `Development/native-runtime-parameters-1080.json:3` 记录桌面1080/无边框主菜单现场，`:1376` 附近 post 再给出 H/W=1152/1920。`Development/native-1080-geometry-summary.json` 为逐级汇总。`Development/history/native-runtime-contract.md:11-16` 已明确淘汰旧 1920×1088 猜测。
- 旧捕获 `release/native-kernel-params-24064-11278468/launch-0001.bin` 本轮复读：有效纹理 3840×2160、处理 H/W=2176/3840。旧 JSON 的 1088×1920 是 encoder block1 的半尺寸，**不是 1080 屏幕的原生处理尺寸**。所以不能把旧数据作为 1088 方案的原版凭据；4K 的2176同时是ceil64与ceil128的结果，本身不能区分两种规则；仍不能从两份捕获推广到所有输入。
- 我们当前 `src/native_network_geometry.h:12-14`：900=1600×960、1080=1920×1152。`Development/HIP/hip_reference_network.h:380,470`：1080 head 特判30×18→32×20，900=25×15→25×16；缩减1080行数还必须重新确定head网格及有效区，不能只改一个高度常量。

## Daniel 的确切静态规则

目标 `.../scratchpad/d050/x/mod.dll` SHA256 `cddfb09e019347957bf7b96c95c0e900e8d3062dfaed697a8a96b0a039aec31a`。本轮 `llvm-objdump -d --no-show-raw-insn` 导出 `/tmp/fma-vs-nvidia/daniel-host.s`，下列都是 PE VA：

- `0x1800285ff..0x18002863b`：`DLSSNR_PAD128` 存在→mode2；否则 `DLSSNR_EXTENT` 解析整数为8→mode1；其他/未设置→mode0。严格说 PAD128 检查的是 getenv 非空指针，字符串“0”也会启用。
- `0x18003cea0` 是尺寸计算函数；mode2 `0x18003ceb5..cede` 两轴 `(n+127)&~127`；mode1 `0x18003cee0..ceff` 两轴 `(n+7)&~7`。
- 默认 mode0 `0x18003cf0d..cf49` 两轴 `max(320,(n+63)&~63)`。
- `0x18003cf6d..cf88`：未设置 `DLSSNR_EXTENT_NO_W64` 且两个尺寸低8位均0时，给高度 `|=64`（此时等价+64）。不是“凡宽64对齐都多一行”；是宽高同时256整除的特例。
- 调用 `0x18003733e..37351` 传入对象 mode 与输入 W/H，返回工作 W/H。

正尺寸等价伪码：

```cpp
if (PAD128_present) return {ceil128(w), ceil128(h)};
if (EXTENT == 8) return {ceil8(w), ceil8(h)};
w = max(320, ceil64(w)); h = max(320, ceil64(h));
if (!NO_W64_present && w % 256 == 0 && h % 256 == 0) h += 64;
return {w,h};
```

| 有效输入 | NVIDIA 实捕 | 我们当前 | Daniel默认 | Daniel PAD128 |
|---|---|---|---|---|
|1920×1080|1920×1152|1920×1152|1920×1088|1920×1152|
|1600×900|未捕获/未确认|1600×960|1600×960|1664×1024|
|3840×2160|3840×2176|不适用（我们默认分档）|3840×2176|3840×2176|

注意900下PAD128还会增加宽度，不等于我们的旧900w（1600×1024）。Daniel算法恰好匹配已有4K、却不匹配1080捕获；第一轮尚未定位 NVIDIA host 决定差异的规则；第二轮已定位由逐层shape计数决定步长，见文末补充。不能把 Daniel 自称当原版证明。已导出 `/tmp/fma-vs-nvidia/nvidia-host.s`。

## 性能估算与输出范围

- **以已捕获 NVIDIA 1080 为目标：尺寸差0，尺寸对齐收益0ms。**
- 如果另立实验“仿 Daniel 把1080从1152缩到1088”：减少64行、122880处理像素，即当前处理像素的5.5556%；当前相对候选多5.8824%。按整网12.6ms线性缩放约省 **0.70ms**、剩11.90ms。这只是面积模型，不是ABBA结果或保证上限：ViT token选择/全局注意力二次项、边界窗口取整、固定dispatch均会破坏线性。不能用1080可见高度直接声称省0.79ms，因为Daniel实际也补到1088。
- 900对Daniel默认已经同尺寸，预期尺寸项收益 **0ms**。相对NVIDIA真实900未知，没有可计算的可信差额。900相对可见900行仍有60行，不代表它能直接删。
- 输出变化**可能遍布整图，不能许诺只改底边**。encoder的边界差异进入池化、ViT全局注意力，然后经decoder传全图；时序历史还能带到后续帧。
- 已有直接历史实测支持，`Development/history/DevHistory-full-20260923.md:2264-2271`：900从1024→960时HDR40帧67.5dB（峰值29.7抬高PSNR，底带36.4dB）；SDR seed123 history **31.5dB且全图均匀**，顶部0–99行31.1dB、底部800–899行31.7dB。那次ABBA省0.75ms，后续0.9–1.0ms，Zero主观看不出差别后批准为当前900档。该旧实验不是本轮1080缩高实测，不能挪用其PSNR或ms当候选结果。

当前可交付的判断是：不要以“修复 NVIDIA 尺寸偏差”为理由改1080。若要试1088，应明确是对原生1080捕获的有损几何候选；先确定head补零网格，再对整帧/时序差异与ABBA单独验收。原版900的规则仍需真实调用捕获或定位原DLL对应host分支。

## 第二轮CPU静态收窄：已找到原DLL的尺寸决策函数

`0x180039780` 本身是 `CCNetwork / hnet-vigilant-squid / crazy-cuckoo` 图配置构造函数，不是最终输入尺寸公式。实际尺寸决策在 **`0x18003c580`**，由网络构造 `0x180031dc4` 和 resize 路径 `0x18003df6e` 调用。

精确静态证据（均为 `nvidia-host.s` 的PE VA）：

1. `0x18003c5c6..3c5dd` 先保存输入两轴到对象+0x278/+0x27c，初始工作轴到+0x280/+0x284；`0x18003c5ec` 调 `0x180036300` 先构造一轮层对象。
2. `0x18003c60a..3c65e` 对最后层所含算子做 RTTI 判断；成功走下面的padding分支，否则走 `0x18003c664` 的普通shape链。这也是需要保留的适用前提。
3. `0x18003c750..3c7cd` 遍历层对象数组（object+0xf8..+0x100），每个层调用虚表+8的shape函数。返回轴0比上层小就在 `0x18003c7ad` 增计数 `r13d`，返回轴1变小就在 `0x18003c7b9` 增计数 `ebp`；它数的是**尺寸下降次数**，不能直接当作固定网络下采样级数。
4. `0x18003c7ed..3c821` 两个步长为 `a0 = 1 << count0`、`a1 = 1 << count1`，存object+0x288/+0x28c。
5. `0x18003c828..3c85f` 使用整数除余得到各自向上对齐值，最小320，写object+0x280/+0x284。
6. `0x18003c866..3c881` 若 axis0 能被 `4*a0` 整除且 axis1 能被 `4*a1` 整除，就给第二轴再加 `a1`。
7. 如果新的工作轴不同于原输入，`0x18003c888..3c8ad` 用工作尺寸重新调 `0x180036300` 构图。

```cpp
// padding分支，正尺寸；shape回调涉及具体层/算子及模式
count0 = count1 = 0;
x = input0; y = input1;
for (layer : graph) {
    (nx, ny, ...) = layer.infer_shape(x, y, ...);
    if (nx < x) ++count0;
    if (ny < y) ++count1;
    x = nx; y = ny;
}
a0 = 1 << count0; a1 = 1 << count1;
work0 = max(320, ceil_div(input0, a0) * a0);
work1 = max(320, ceil_div(input1, a1) * a1);
if (work0 % (4*a0) == 0 && work1 % (4*a1) == 0) work1 += a1;
if (work0 != input0 || work1 != input1) rebuild_graph(work0, work1);
```

**这比“原版ceil128”或“原版ceil64”都准确：原版步长由实际图的shape遍历决定，Daniel把它固定成64。** 1080实捕的1152与第二轴步长128吻合；4K的2176同时可由64或128得到，不能说已经证实4K用64。尚未逐个还原此次图的所有shape回调输出，所以不能诚实给出900的count0/count1，更不能确认它是否仍为960。

辅助定位：单层wrapper虚表 `0x1800b23a8` 的shape函数 `0x18002b7d0` 会依次调内部算子虚表+0x18；split-Swin wrapper虚表 `0x1800b2460` 的shape函数 `0x180041b70` 对末尾特定pool算子转调其shape，否则保持空间轴；ViT两个wrapper的 `0x180043210` / `0x1800446d0` 保持空间轴。剩余缺口在实际图的算子shape结果及初始模式，已缩到可定点抓取的地方，无需再全DLL扫字符串。

### 现有捕获脚本核查

`Development/preblock_live_parameters.cpp` 的hook只在RVA `0x449a0` 复制实际CPU参数blob，并在RVA `0x44830` 记内核名；`hook()`结尾原参数原样交还 `original(...)`。它**不修改尺寸**，也没有按128覆写的逻辑。`Development/decode_native_runtime_parameters.py` 只读对应blob。后来的`prepare_native_rgb_game.py`等受控caller确实可重写尺寸，但它们不产生这两份现场capture源。因此不能用“可能是我们抓取时补成1152”解释现场差异。

下一步若以后有原版现场机会，只需在 `0x18003c7ed` 读两轴计数，或构图后读对象+0x278..+0x294；若同时记录每个shape回调的入/出轴，就能说明多出来的下降发生在哪一层。此轮未增加/部署hook、未跑原版或5090。到此收窄交付。
