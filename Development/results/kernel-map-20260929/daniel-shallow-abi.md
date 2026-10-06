# Daniel浅层46派发synthetic jobs

make-shallow.py从既有host schedule生成daniel-shallow.json。每种几何46派发（C32含prefix/post），两个几何分别native1920×1088和matched1920×1152。position/flags/shift/grid逐个保留，可和完整地图按position+geometry连接；不把同symbol不同shape合并。

## VarParams 192字节

所有实际选中reg_swin32与reg_swin_mh<64/128/256>使用一个by-value192B参数，metadata无用户参数拆分。未设置字段为0。普通host构建器0403a0，参数底址rsp+88。

|偏移|类型/作用|证据|
|---|---|---|
|0|input ptr|0403f0 r9入+88|
|8|output ptr|0403e8/3f8 stack output/weights成对复制|
|16|weights ptr|同上|
|24/28|width/height i32|040400/040408|
|32/36|shiftX/Y i32|040417..040428查表|
|40|flags i32|040430|
|48|upsample low ptr|040437；decoder03b39c传前级low|
|56|downsample output ptr|04043f；encoder03b649传边界输出|
|176/180|down width/height i32|0404c1..4c5；不是指针|
|184/188|up low width/height i32|0404dd..4e1；不是指针|

flags0/1/2普通，flags4启用down输出及其尺寸；flags8启用low输入及尺寸。input/output是片段数据，jobs预留4倍byte面积作保守容量，**容量不是流量**。有限FP8±.25输入，weights至少4MiB有限FP8±1/64；重复解释为half/f32亦有限，但它不是实际模型混合精度权重。

## prefix20/post32

prefix host0377e3..0378d8：input0原路径不使用；output8、weights16、down56；raw RGB float在64，辅助RGB float在72；80..100六个float校准量；104seed；112可选history保持null。raw输入ISA A5B1C使用stride12，不是RGBAhalf。job选择校准80=1、其余0，seed123，aux非零synthetic。此选择必须保留在计时备注，不冒充真实曝光/历史配置。

post host03b979..03ba55：120输出、128原RGB float、136可选history（null），144float scale=1、148额外量0、152模式1、160low feature。ISA BD0E0/BD11C确认128以stride12读f32；BD388..BD39C确认120写出。原生post shift=(0,0)，与我们(-4,-4)不同，matched尺寸也不抹掉这一语义差别。

## 运行边界

buffers有check/check_bytes：输出作fp8或f32有限性扫描，输入不作输出扫描；generic harness还需独立guard前后检查。输出zero初始化，有限不证明每字节都被写，边界/保守余量本来允许未覆盖。所有job独立进程smoke后再图计时；fault必须定位args，不以放大buffer无限掩盖。

没有GPU执行；JSON是可启动候选描述，最终成功/finite/guard由主进程运行日志证明。入口/出口指网络prefix/post，不包含import/export/frame reprojection；head/decup/repack由deep jobs覆盖。

## 混合权重初始化修订（避免全零退化）

初版全FP8填充造成half/f32尺度接近零，block1虽guard/finite通过但输出全零，因此不能作均衡负载。现JSON权重segments已修：主FP8矩阵±1/64；half残差尺度幅度1；half位置bias±1/64；每head归一化scale f32常量1。

|C|普通FFN尺度区起点|普通norm f32起点|up flags8 norm起点|
|---|---:|---:|---:|
|32|8192|19552|21664|
|64|28672|57504|65792|
|128|98304|180512|213504|
|256|360448|623136|754688|

每个norm前8192×heads字节为half位置bias；其前3C²为FP8 QKV。普通half尺度区直到QKV开始。up在尺度区前插入2C² FP8矩阵，half尺度区相应顺延。C32 prefix有额外1024B half prefix矩阵（±1/64），norm20576；post额外尺度段，norm19664。

证据样例C32 flags1：5C89C..5C8C0读取8208/8224/8240/8256并经half乘法消费；60550..6058C读取11904..12432后以fma_mix_f16解释位置bias；5E1B0 scalar global_load_b32读取19552。更宽核相同消费模式。C64 up不照普通偏移覆盖FP8上采样矩阵。

修订仅影响synthetic输入，不是实际模型权重映射保证；每项需重新smoke检查nonzero/finite/guard，旧全零输入时序不可混进新分布时序。
