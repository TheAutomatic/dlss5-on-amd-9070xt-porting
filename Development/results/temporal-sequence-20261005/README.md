# 房顶闪烁：默认关闭的 MP1 时序实验

本阶段完成受控数学与整网接口闭环，**未证明修复111.mp4、未部署、未改默认/用户配置/0.41 ZIP**。视频只有拍屏最终输出，真实连续网络输入/MV/depth尚缺。

## 原版合同

真实5090复用此前成功的core615/nvngx.dll（SHA52A68ACC…）与310.8插件；首Reset1、次Reset0的合法1920×1080两Eval全部SUCCESS。原pre seed0→1、Style1/128；history/motion首为空、次非空，pre/post同history/MV handle。post计算网格1152但valid1080；history transform74..88与motion8c..a0为[0,0,1920,1080,1/1920,1/1080]，70恒1。

首次误用不同根目录core615.dll（SHA172FAEDF…）导致Create PlatformError，已按旧成功载荷修正；该失败不是时序算法错误。5090 D余79GiB且本项目仅1.23GiB，未移非项目文件；经调度裁定本探针输出/NGXdata/cwd/TEMP/TMP/cache全C（余730GiB），D只读输入/DLL、仅共享锁极小例外。成功探针前后D数据元数据无变化。

单次在原launch回调查询标准CUDA descriptor：cuCtxGetCurrent返回SUCCESS但context=null，未切换/创建上下文；**原私有history texture实际格式/内容仍未直接确认**。外部输入colorRGBA16F、MVRG16F、depthR32F/valid1080是本harness创建事实，不能冒称内部descriptor。受控原post gold用自建half-exact FLOAT4/线性clamp纹理，scope见post-history-gate结果。

原gate row6独立恢复、两K16 HMMA半精度模型对24576受控真实posttap特征0半码差。AMD SIG原语有限half63488码中11033码不同、最大3ULP/1.1920929e-7，不能称NV逐位；严格实验使用5090生成65536码表（262144B，SHA394394a5258bad437495d68076be75d8413fa0ed5b752400e3947c332437b850）。表保在本地/tmp/post-history-gate-original与5090 C实验目录，源码可重生成。

## 软件 warp 与整网闭环

warp.hip沿既有native_temporal_sample合同保21bit UV、8bit采样权重与舍入；prefix得到normalizedRGBA，post保raw五tapΣ和reciprocal，执行原FFMA(recip,Σ,-RGB)后门控FFMA，不能先归一化再减RGB。原CUBIN16×16 closed/zeroMV/+1px/对角(+.25,+.375)四组gold，对本软件warp＋严格gate全float-bit0。

原RGB96/旧导出保留；新half32特征tap默认false，限MP1/skin0/graph0，构造期HasFn与buffer预分配。原post两个旧导出机器码同；三个prefix只有新增descriptor引起的PC相对常量地址变化，保留原始差异记录，未写全模块byte同。GPU特征驻留，不每帧拉141MB。valid历史仅存blend后有效RGB，实验明确f16RNE→f32存储政策（尚不是已查明原API格式）；prefix padding镜像，post只混valid，pad原RGB保留。

AE0/full71/FAST_NUMERIC1受控整网：小合法512×512→640×360/proc384的3路×2seed×8帧48行；合法1920×1080/proc1152三路×2seed×3帧18行。空间、prefix-only、prefix+完整gate各自独立history；first/reset/missingMV/resize失效保护。66行finite，off/first/reset对独立当前基线0字节差；history-enabled同输入/seed自重复0字节差。首批误清不存在键而继承模板AE1已隔离为diagnostic，未据它推时序质量。

平均亮度与同geometry/epoch波动分别留CSV/summary；**不普遍改善**：1080三帧计数seed背景范围空间0.000321、prefix0.001303、full0.002134（0..1工作域）。初期history反馈/合成内容与真实房顶不同，不能据少帧宣称治闪，也不把减反光当稳定。诊断wall含冷加载/读回，非性能门或FPS；F64 head仍是参考原型，未称生产高性能。

## 复跑与剩余工作

prepare_options.py从当前NativeHipNetwork初始化代码生成同源Options；prepare.py生成显式合成元数据。sequence.cpp与run_sequence.ps1完成小gold→三路→valid1080门，CPU多行命令及本任务脚本均落文件。全GPU窗口依次执行、游戏检查/原子锁/15s看门狗，实验结束锁已释放。

真实连续帧/MV与jitter/exposure/reset信息、原内部history内容/格式、遮挡拖影/真实反光稳定性仍待验证；目前只MP1，不把共享history直接用于MP3。无新用户开关或安装。下一步按计划转独立无损ViT960大tile，再小buffer晚复用。
