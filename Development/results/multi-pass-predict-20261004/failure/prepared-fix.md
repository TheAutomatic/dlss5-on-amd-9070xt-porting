# 首帧同步上传缺陷与小修准备

撤回先前首次moduleLoad假设：RE9 PrepareFrame已经调用PrepareStagedKernels，预测模块也在暖跑时加载。明确缺陷在feed索引：

- 真3遍暖跑调用MultiPassFeed两次，slot0/1均分配，multi_next归0。
- 两遍+预测暖跑只调用一次，slot0分配、multi_next变1。
- 真实首帧使用slot1，首次分配会调用Upload；Upload明确hipStreamSynchronize。这发生在bridge已入队等待producer之后，游戏调用上下文producer尚未提交，循环等待风险具体存在。
- bench/smoke先提交producer，因而没覆盖此死锁。原真2遍也有同样潜伏路径。

小修不改公式或HSACO：ctor中准备两个feed；SetMultiPass/SetMultiPassPredict在当前frame producer wait入队之前准备；热点MultiPassFeed无Upload，未准备即报错，避免悄悄同步。预测模块与两个核符号也在初始化预加载（模块存在或启动已启预测），默认关旧模块集合缺文件时仍兼容。

静态顺序：D3D12Bridge::Create -> new Network（加载/准备）-> Share/import semaphore -> PrepareStagedKernels -> RecordInputCopy -> Enqueue（hipWaitExternalSemaphoresAsync）-> Network::Enqueue -> MultiPassFeed（只copy）。add-on ApplyHotMultiPass在当前网络Frame入队前调用安全setter。待机器空闲再做未提交producer fence的受控旧/新复现及输出回归；目前不是已完成的GPU修复验收，不覆盖正在正常的鬼武者。

CPU编译通过，产物仅留/tmp/mp-predict-prepared-products：

- addon 8a020ea68a5ddcaca83b304ef3ecbd9c2db92c13eeeff1aa3f073a0f9f156bf0
- runtime 7fec39cf0bb999124cb1db0a51e7ae791b83c489d9c1bf4c043d6744f6575e5f
- benchmark（Swin persistent，无RAW_EXPORT）a9c3ec6182ffd5c47237f58cea812e9e42037e1f3ca3eca2314ab1cbdd9bf2c1
