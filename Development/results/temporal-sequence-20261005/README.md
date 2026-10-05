# 房顶闪烁：受控时序准备

本阶段只有 CPU 合同/生命周期检查，尚无完整时序网络结果，未改生产默认或游戏载荷。

111.mp4 为拍屏最终合成，不能恢复原输入/MV/depth。prepare.py 明确生成合成输入：固定背景、右移物体、已知 current→previous 位移和人工深度，含静止、运动、显式 reset、缺失 motion、resize。小尺寸 CPU 版不作为可运行整网 shape；`--full` 可生成1920×1080/proc1152和2560×1440/proc1472样本，仍不是该游戏复现。

CPU 检查：三路（空间、prefix history、完整时序的生命周期占位）×两种 seed 策略×8帧通过。验证 first/reset/resize/missing-MV 不读历史、读写槽分离、跨队列未完成禁止发布、底镜像与运动符号。这里没有用固定 blend 假装原版 gate，也没有证明 native warp 数学一致。

当前源码事实：pre-upscale 强制 reset=true；已有 NativeGameFrame 在同队列按 input/warp→NN→history 发布顺序工作，但完整原 post gate 未接。post-head96仅RGB，原row6门控被 unpack 丢弃；原gate是两段HMMA.F16后原生EX2/RCP及blend，而非随意f32点积。门控原语与采样合同由独立原版oracle对拍后，才接 MP1 三路网络测试。OUTPUT_SMOOTH不作为该实现。

待完成：原gate特征独立出口、原语/warp对拍、三路相同帧与seed的真实网络回放、亮度波动和平均反光强度分别评估、遮挡/拖影与时延。MP3各遍历史独立性另规划；本阶段不触碰用户MP3配置。
