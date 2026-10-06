# FAST1与C256持久段的实际覆盖（CPU审计，未重跑旧负账）

当前FAST1不是全族采用同一数学。900(1600×960)和1088/1152(1920宽)使用normal swin-persistent；只有1440实际2560×1472/FAST1选择swin-persistent-fast。普通c64-wave2-fast行定义W2_FAST_NUM3；normal SP行未定义该宏，multihead_fast_padded.hip默认0。

当前真实1088 FAST1/full71日志 sparse-stage-20261006/0-kind-0/stdout.log：SP_PLAN c256 first16/layers6/tasks846/w16=1与first49同；SP_STATS runs482/fallback0/jobs407772，对应两段×241帧。因此16–21与49–54共12块实际接管，不是只看已编module。900同源selector也接管此12块，900本轮没有另造真实计数。H()保RNE半、Hrtz()保RTZ半；W2_BOUNDED_RCP1使w2_inverse先rcp再保两步Newton。sp_run_body直接调用同源swin_wave2_body，不会从普通Body的fast module继承宏。

旧fast-tier-20261001的MS负账非空：b4.ps1明确以W2_FAST_NUM3编SP，mkset将仅该module放flat-MS；all2记录单模块对比PSNR约54.5dB，证明数值发生变化。900三轮+0.0084/+0.0065/+0.0172ms，合并+0.0107ms；1080三轮+0.0161/-0.0013/-0.0135、合并约+0.0004，p99退。不能把它当未试的新优化。旧当时完整真实replacement计数未归档，不能用当前482来代替。

结论：严格/fast覆盖不均匀是真的，可能是残余数学差的一个边界；速度贡献仍未拆清，不能直接解释1.01ms。当前source/row/key与旧实验触发已核，不GPU重开该负账，也不把FAST1说成已等于mochi数学。需要新的实际机制/资源证据才安排新控制。
