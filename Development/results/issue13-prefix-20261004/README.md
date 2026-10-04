# Issue13 原版block0 pre-down小块

原NVIDIA310.8/独立NGXcore615，输入/seed1/style1/无history沿此前原合同；本次仅定向追加GPU buffer复制，未改原模型数学，没有再保存API final。两帧各2遍输出相同、无NaN码。启动capture后台需有效launch self：一次暖Eval提交完成后，在Eval外初始化copy；采样hook里不CPU等待、不ContextSync。

源8×8起点顺序：(832,528)、(960,544)、(0,0)、(1912,1072)。对应down4×4起点：(416,264)、(480,272)、(0,0)、(956,536)。原processing1920×1152，down960×576×32；取自packet+f8真实GPU地址，原preblock完整结束后、下一block消费之前。原物理布局是两个C16平面；*.tiles.fp8布局[4,2,4,4,16]，*.hwc.fp8布局[4,4,4,32]，*.hwc.f32仅精确E4M3解码，不是量化前FP32。

prefix16特征和16→32投影融合在原kernel寄存器/LDS，没有独立export/输出指针，本包没有捕获它们。受控identity权重实验不能标成原未修改阶段。原mix权重在body byte8208..9231，需要重排才对应HIP首512权重。

最新test20 p95=23.315485%、每帧自身exact pre-down注入降16.327520%是作者的新报告，不套当前79cbf484。此前原post14.94%只对exact-reference结论成立；生产仍可能有前端额外偏差。目前无test20源码/commit/有效flags/模块SHA，不能交付一条已验证修复。需要该指纹及按本tile的exact/test20逐层对照，区分noise、16→32积累、首FFN/attention/pooling。单改RNE跨8对有好有坏，不能当修复。
