# 0.41-a可选history游戏入口与受控门

用户授权临时包给网友试；尚未验证真实房顶改善，未安装本机游戏、未改玩家配置、正式0.41 ZIP/tag不变。

最小scope为regular FFX pre-upscale。`DLSS5_TEMPORAL_HISTORY_EXPERIMENT=1`默认off；`DLSS5_TEMPORAL_MV_UNJITTERED=1`是显式试验前提，未检测context创建flag。仅MP1/AE0/graph0/skin0/overlap0与合法FFX metadata、UV几何启用。MP3、元数据缺失、MV缺失、曝光变化、frame gap等走空间/cold，日志区分requested/active/history/reset/seed。RE9/Magpie不宣称支持此实验。开启/关闭重启后同MP1/AE0对照。

Network预分配自己的有效internal-blend历史、warp scratch/half32 tap、严格NV SIG表；直接UV→prefix及raw五tap sum/reciprocal→两K16 head→gate FFMA→有效RGB RTZ/alpha1存储。原D3D旧prefix/smooth/feed history不混用。bridge构造期UV carrier固定8B/pixel，旧输入仍16B；warmup失效前史，F9 MP1→3旧Body seed0并失效，回1先cold。所有额外模块独立新增，原39行/架构保留。

GPU720及1080 core门：first/reset/hotMP3/回1cold/flagoff与独立旧primitive链的prefix/fullgate逐float-bit0，finite。实际NativeGameFrame720入口的first/reset/missingMV/下一帧cold/exposure change/frame gap/hotMP3→1全部float-bit0。输入为合法synthetic色块/zeroMV/显式元数据，不冒充真实scene源。

F64参考gate有明确代价：最短8帧GPU均720 off4.779→on7.081ms；1080 off9.146→on14.179ms，约增加5.03ms。只诊断开关成本，不作FPS或p99承诺；临时包是质量试验。

源码/六模块SHA与门日志见本目录receipt。新模块每架构temporal-history、c32-wave1-temporal、c32-wave1-temporal-fast；两新小asset为post70-history-head.f16/64B、native-temporal-sigmoid.f32/262144B，normalized-output.f32使用既有33554432B表。gfx1200仅编译/目标核验，未真机运行。

实验脚本在 `../../HIP/experiments/history-trial-041a`。9070单队列原子lock、game-check、15秒游戏看门狗与D≥100GB；试验后锁释放。首个隔离fixture漏f16 packed asset导致缺文件，补同源asset后通过，不认算法失败；Frame harness改与生产同C++17编译，避免既有u8string/C++20不兼容。成功门不继续刷轮。
