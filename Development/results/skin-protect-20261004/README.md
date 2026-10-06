# 肤色保留1x，其余叠层（2026-10-04，双游戏已装）

新键 `DLSS5_MULTI_PASS_SKIN_PROTECT=0/1` 默认0，仅多遍生效。保存第一遍y1，最终用原输入x算共同RGB权重m，输出 `m*y1+(1-m)*yN`，核心m=1逐位取y1、m=0逐位取多遍；支持真3与预测3，MP1不做混合。不会用原图替代y1，也不修改后续遍输入/seed/history。跨帧历史自然受最后输出影响，因此history两次独立运行的非皮肤区不能强求整体相同。

颜色合同已核：本地encode先原linear/paper-white→高光shoulder→sRGB曲线，x已经sRGB-like，不再gamma；Magpie也直传sRGB。YCbCr公开参数参考 [OptiShade SkinColourWeight](https://github.com/GamingWithGravy/OptiShade/blob/main/optiscaler/OptiScaler/shaders/dlssnr/precompile/dlssnr.hlsl)，独立实现；中心Cb/Cr=.405/.600，半轴.090/.110。核心距离≤.95且maxRGB-minRGB≥.06时m=1；距离.95–1.45、chroma .02–.06羽化，3×3均值与原权重取max保住核心。非语义分割：暖色背景可误选，彩光/阴影可漏，HDR shoulder也会影响阈值。

[最终解码脸部对照](shots/900-static-decoded-face.png)：左1x、中真3、右保护，脸明显回到1x。工作域图第四列为mask： [900](shots/900-static-face.png)、[1080运动](shots/1080-motion-face.png)、[history](shots/1080-history-face.png)。CPU/GPUmask最大误差5.4e-7，六组真/近似保护m1全部逐位等本帧y1；无history m0逐位等真3/同fixture旧未保护预测结果。每例核心约3万–4.3万像素，约93%画面m0。详细统计/原张量哈希在shots；原始帧已清理。

验证：默认normal19 SAME（含AE CSV+roll）；MP1开保护三场景SAME；900静止、1080运动/history共五模式12帧无NaN；真/预测保护900静止+1080 history两次哈希SAME。最终RE9开预测+保护smoke errors=0，日志含multi_pass=3/predict=1/skin=1。短100帧ABBA、前32帧不计，mask+保存第一遍copy+混合新增约900 .25ms、1080 .34ms；目标是观感，不是提速。

之前首帧死锁修复也已实证：给producer设置1.5秒未满足栅栏，旧runtime EnqueueHip阻塞1528.316ms，新版2.005ms即返回，解锁后都正常完成。两feed在初始化/安全热切预备，热点不Upload；预测核/符号也预加载。新增肤色资源固定预备，运行期只有copy/核，不会再首次初始化它们。内核无屏障，新核使用当前rtc，两架构日志分别ISA1200/1201。

装机readback：剑星addon `731b8daee1c8bc73551a37161df18597679b2d08203e3e4840ff72ea9743b0d3`；鬼武者根/_storage_ runtime `c38b83833b6d4757eb58003411eab2deaab9f72c8925e460e399113653cc83bf`；两架构76模块/SUMS `c7ea9ac8d1a96f0f474bad7d9fe3c8a46532eb49f8ee5bb87363cc9b98d0838b`，exact快照同步双EXACT。两游戏custom MP3、PREDICT0、SKIN1；native MP3无skin/predict覆盖，其它项/BOM/换行保留，剑星PRE1、鬼武者PRE0。因此当前是皮肤1x+整体**真3x**。剑星编辑custom skin0/1可热载，F9仅切遍数；鬼武者改配置需重启，无F9。

备份/回滚 `D:\DLSSNR-Lab\skin-protect-20261004\backups\20261004-015944\rollback.ps1`（全部旧载荷/配置/exact）。未代启动游戏，真游戏重开观感/恢复确认待Zero；GPU锁已释放。源码、脚本、结果提交，不含二进制、不打包不push。旧常规模块gfx1200编译目标疑点仍留0.41前待办，本轮只保证新核目标正确。

## 02:16 用户关闭保护

Zero反馈保护开启后整体效果几乎看不出来、剑星真3约27fps。仅将两游戏custom SKIN_PROTECT置0，实际MP3/PREDICT0及其余项原样保留。native无skin覆盖，无Machine/User环境覆盖；备份skin-off-20261004-021602，exact只同步native/custom配置快照，未动载荷未跑GPU。读取时游戏不在运行，运行中新热载未证；下一启动关闭，鬼武者必须重启。27fps不能直接归于mask .34ms，当前真3与此前预测3不同。此观感实验没有满足用户，保持关闭。

## 02:19 鬼武者再试优化3x

用户明确要求后，只鬼武者改MP3/PREDICT1/SKIN0；两处runtime已核C38B8383、76模块C7EA9AC8、gfx1201预测核2E7F1437，含双feed修复，无需重装载荷。剑星未动、未跑GPU；无相关Machine/User环境覆盖。配置备份oni-predict-on-20261004-021943，oni exact配置同步。重新启动读配置，实际两遍+预测第三遍，皮肤关；实玩待用户。可回custom MP1/PREDICT0再重启。
