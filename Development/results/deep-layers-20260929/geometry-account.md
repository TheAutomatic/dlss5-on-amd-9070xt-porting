# C512 compact几何、工作量与中间buffer账

只读审计生产准备版 `compact/production/Development/HIP/hip_reference_network.h` 与 `compact/production/hip/c512_qkv_attention_compact.inc`。数学不变；下表按当前skip42/43/46后的13块，非16块名义图。机器可读计算见geometry-account.json。

## 实际移位及原工作域

encoder23..30和decoder40..47分别用0/3/1/2循环，sx=4*(shift&1)、sy=4*((shift>>1)&1)。
有效C512：900为50×30，1080为60×36。原域`ww=ceil8(w+sx),hh=ceil8(h+sy)`。

|block|shift|sx,sy|900原token|1080原token|
|---|---:|---|---:|---:|
|23|0|0,0|1792|2560|
|24|3|4,4|2240|2560|
|25|1|4,0|1792|2560|
|26|2|0,4|2240|2560|
|27|0|0,0|1792|2560|
|28|3|4,4|2240|2560|
|29|1|4,0|1792|2560|
|30|2|0,4|2240|2560|
|40|0|0,0|1792|2560|
|41|3|4,4|2240|2560|
|44|0|0,0|1792|2560|
|45|3|4,4|2240|2560|
|47|2|0,4|2240|2560|

900为6块56×32=1792、7块56×40=2240；1080全部64×40=2560。

## 点运算减少，attention工作量保持

|13块合计|900|1080|
|---|---:|---:|
|有效token|19,500|28,080|
|原点运算token|26,432|33,280|
|compact `n=ceil16(w*h)`|1,504/块，合19,552|2,160/块，合28,080|
|FFN/projection派发覆盖减少|6,880（26.029%）|5,200（15.625%）|
|M32 mix实际32token槽容量|19,552（减少26.029%）|28,288（减少15.000%）|
|attention原8×8窗口数，前后相同|413|520|
|attention组数，前后相同（×16头）|6,608|8,320|

1080 n2160不是32倍数；mix最后组第二个16token不读/不写，但源码仍执行其零输入acc1 WMMA，不能按2160说所有mix矩阵工作都降15.625%。900 n1504是32倍数。

QKV仍在原shifted窗口里做，原来的64key、bias坐标、归一化/softmax支持集合都保留，不能把上表点运算比例乘整个C512或整个网络时间。

## 每种中间buffer的逻辑容量

下表是13次调用各buffer逻辑容量的和，不是峰值VRAM、GPU allocator实际保留量或每帧DRAM流量。

|buffer/元素格式|900原→compact B|1080原→compact B|
|---|---:|---:|
|mixed float×512|54,132,736→40,042,496|68,157,440→57,507,840|
|contract float×512（仍保留旧双出口）|54,132,736→40,042,496|68,157,440→57,507,840|
|FFN feature float×512|54,132,736→40,042,496|68,157,440→57,507,840|
|contract8 byte×512|13,533,184→10,010,624|17,039,360→14,376,960|
|FFN feature8 byte×512|13,533,184→10,010,624|17,039,360→14,376,960|
|AV8分配 byte×512|13,533,184→10,010,624|17,039,360→14,376,960|

原shift-pack输出float也是54,132,736 / 68,157,440B。
compact900仍为每块分配1504×512 float的尾补齐副本（合40,042,496B）；1080直接alias原input，不再产生shift-pack副本。
最终输出仍分别每块1500×512 / 2160×512 float，13块合39,936,000 / 57,507,840B，前后不变。
compact900的AV实际只写有效1500行，合9,984,000B；分配中的每块末4行不写。其余完整点运算buffer仍按1504行写。

## 独立映射与尾部核查

- Host `CompactC512Body`：900将1500个有效像素看成一维 `(width=1500,height=1)`，用原mh_shift_pack复制/补4个零token；不是每一图像行补列。1080 valid2160已16对齐，直接使用input。
- 前三段mix/FFN/FFN projection全部在该未移位紧凑raster执行，原权重、累加顺序及量化未改。
- 新attention对每个原窗口token计算 `x=window_x*8+tok%8-sx`、`y=window_y*8+tok/8-sy`；有效时读取 `p=y*validwidth+x` 的旧16token×32channel tiled feature8，越界时送**零A片段**进QKV，没有删padding key或零扫描。
- AV只在上述坐标有效时写 `p*512+head*32+channel`；原窗口域对有效raster坐标一一覆盖，既无遗漏也无重叠写。
- 最后原 `mh_attention_project_frag_c512` 用n1504/2160、cropw=w、croph=h、workw=w、sx=sy=0；900末4个补token的AV无有效输出消费者，投影裁切不写result越界。
- 这些尾token可能仍被最后一块矩阵tile加载/计算，但各token行相互独立；不能把“未写尾AV”描述成完整buffer全初始化，也不能把其无效行算成有效画面。
- 返回result容量是valid*512 float。原skip、Stage、raw?3:0保持。尺寸gate不符回退旧Body。

## 派发预期

原每块6次：shift-pack、mix、FFN、FFN projection、融合QKV-attention、attention projection。
compact900仍6次（shift-pack变为4行尾补齐）；compact1080为5次（没有尾补齐派发）。
13块body：90078→78，108078→65；若加进入C512的pool/project一次，则C512口径90079→79、108079→66。
相对0.36整网198/182的拓扑预期为900198、1080169；以主进程实际TOPO trace最终确认，不能只凭函数源码代替现场计数。

## FP8调查归档

`../../HIP/experiments/deep-layers/fp8/`已含可带参数重跑的census.py、16权重JSON、原10个float位差日志、旧测试cpp/两份patch、SHA256SUMS.json。
全部8,388,608个权重原float就可精确FP8编码，half没有改位；旧block46/pattern2只换expand FP8复现10个float元素差异。
这不是10bits/10ULP；旧日志未列出元素索引/值。RF8本轮未构建或运行，不能因权重精确就断言FP16/FP8 WMMA逐位。
