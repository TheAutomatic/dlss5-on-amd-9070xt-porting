# Timed pulse完整框架真实HDR首双档

隔离复制当前NativeGameFrame/HIP network/bridge/env headers；实验键DLSS5_LAB_SUBMIT_PAIR默认0，仅C512 encoder开始处额外Record两个预分配timed events，不查询inner event、不额外同步、不改kernel/地址/codec。graph on明确拒绝。两event属于Network、创建在producer wait前，销毁在owned stream完成后。

输入D:\DLSSNR-Lab\hip-backend\live-menu-before.f16，1296×720 RGBA16F/7464960B，既有真实HDR capture（不是本轮scene源），冻结每帧恢复。当前stock FAST1/full71/MP1/AE0/history0，原codec→NN→decode/copy完整NR框架；不含游戏render/FSR/Present。900与production1080/proc1152分别none/on/on/none，160frames弃前80、edgesonly中间不扫图。两侧同一外层NET timing/CPUwall，最初全160冷加载均值另存，不用作收刀。

|档|wall平均delta ms|wall合并p99 delta ms|NET GPU平均delta ms|两B均快|
|---|---:|---:|---:|---|
|900/proc960|−0.163994|−0.232740|约−0.04334|是|
|1080/proc1152|−0.062863|−0.187400|约−0.06394|是|

所有slot输出first/last F16 SHA相同、finite。900更多收益在GPU网络span外，不能全称kernel变快；1152 wall与NET变化接近。短门支持进同batch三round/正常history兼容与资源候选比较，不是已收生产/FPS保证，更不是已追平mochi。

源码生成、runner在../../HIP/experiments/framework-submit-pair-20261006。snapshot/source SHA、CSV、NET逐frame日志同目录；调用API仍异步marker，机制未唯一锁定。未部署双游戏、未改配置/ZIP/tag；GPU原子lock/gamecheck/15s看门狗/D≥100GB，结束已释放。

## 同batch T/U与正式paired门（不收）

同一O2 caller320帧弃80，T/U/U/T：900 U相对T平均−0.008069ms但p99+0.00658ms；1152平均+0.009092ms且p99+0.04424ms。不能证明untimed更优，选择timed进入正式三roundnone/T/T/none。两档全输出first/last同SHA、finite。

正式900三轮平均delta−0.07524/−0.08558/−0.09871ms，p99均下降；1152三轮平均−0.05486/−0.03854/−0.05164ms，但第三轮p99 **+0.08934ms**。即使合并均值正，按门不收，不刷paired同variant，也未执行正常19收刀兼容门。

1152第三轮wall p99 A10.25963→B10.34897ms；同日志NET GPU p99 9.499666→9.436023ms，wall减NET差值尾扩大；B1frame206另有wall11.823/NET11.1853ms的GPU尖峰。旧logger没有timing.tag，且Poll返回最近完成记录，不能证明每条NET精确对应该frame，更不能将全部尾退步归因CPU。这里只报告分布/受限关联，详见formal/1080-round3的tail JSON。下一caller同一次原snapshot输出tag/currentframe/ready，先SetTimingTag，不加查询或同步。

下一最小机制候选是同C512起点只Record一个timed event，减少一个owned事件与一次API；独立默认off隔离工具，不改位置/数学，不用新诊断增加pulse，不宣称record必flush。实际optional helper的Create/Record失败回退、构造异常lease、owner-device/drain销毁另做可注入测试；现隔离paired和single throw-on-error不视为production安全。

bridge:52–75的tag只附带记录，不参与ring busy/next/oldest或elapsed判断，无去重。全0不阻止last_ms更新；但valid为sticky，旧NET样本存在pending时复用最近值的可能，不能声称全部fresh配对。wall/QPC与输出SHA门独立有效。
