# Issue4：HIP序列入口恢复选定device（2026-10-04）

最新[报告](https://github.com/lmxxf/dlss5-on-amd-9070xt-porting/issues/4#issuecomment-5979173007)/[PR15](https://github.com/lmxxf/dlss5-on-amd-9070xt-porting/pull/15)是明确新证据：AMD iGPU+9070XT，LUID始终匹配device1/gfx1201/HIP70260201，init ready后首prefix报400。提交者同机/42字段同/模块同，仅换addon，0.40与旧main各9次400；Enqueue开头重绑device后600+帧无错误。这是提交者受控A/B/C，不是本机双GPU复测。

采纳PR15同一行，放既有try内：hipSetDevice(hip_device)失败仍failed=true封闭退出，不退回0、不改LUID选卡/共享格式/kernel。初始化线程选择过卡，不保证后续HIP入口当前device正确。[AMD官方](https://rocm.docs.amd.com/projects/HIP/en/latest/reference/hip_runtime_api/modules/device_management.html)说明current device是线程本地状态，SetDevice不做同步且开销低。没记录实际线程ID，因此不声称该机器跨线程已直接实测；报错kernel标签还可能来自lazy hipModuleGetFunction，不一定已到带显式stream的Launch。

本机Intel核显不进入HIP，实际只有device0。跨线程模块创建/查询前后均device0成功，不能代替双HIP复现。候选对fresh同HEAD基线900/1080各8帧逐位同。候选addon已编：/tmp/issue4-products/dlss5-amd.addon64，SHA a810cd5194f565be68198b1f86a5777cc62e446995fa49d355c2f5661aa37444。未安装Magpie/两游戏、未改配置/BIOS/驱动、未回复或关闭issue、无push。

旧日志Magpie0.25/ReShade6.8选9070已正确；最新600帧没有线程ID/完整系统显示器接线，不靠禁核显当修复。Create/constructor已绑定；Enqueue现绑定覆盖wait/lazyFn/launch/signal。其它第三线程timing/cleanup入口暂未扩改，WaitForSubmittedWork错误仍保留资源，未把这些未复现方向作为当前修复前置阻断。
