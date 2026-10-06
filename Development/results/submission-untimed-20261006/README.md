# 同C512起点 untimed pair：两档首门正，未跨批选优

API hipEventDisableTiming=0x2只限制profiling/timing能力，不承诺flush/省timestamp。公开clr rocm7.0 recordCommand与develop EventMarker仍启用markerTS/profiling，不能将其当实际Windows二进制证明。当前DLL静态PE明确CreateWithFlags出口存在，后续GPUCtor flags2也成功；Windowsbackend提交/batch机制未因果锁定。

候选only beforeC512 encoder23..30原位置，2events每Network预分配，ownedstream同步后Destroy，无inner ElapsedTime/query/sync/DisableSystemFence/位置扫。Destroy返回码未逐个记录，不假称额外API压力全通过。完整NativeGameFrame clone保当前codec/bridge/NN/decode、真实冻结HDR1296×720、FAST1/full71/MP1/historyoff/AE0/graph0/DIRECT_IO3/NET timing。事件只有API能力改变，raw不写，外层NET GPU及整个Frame wall口径分别保留。

|首ABBA，160帧弃80|wall变化ms|合并p99变化ms|NET GPU变化ms|
|---|---:|---:|---:|
|900 untimed vs无pulse|-0.132144|-0.175080|-0.032898|
|900同exe timed正控 vs无pulse|-0.073150|-0.056080|-0.068777|
|1152 untimed vs无pulse|-0.059881|-0.057870|-0.051247|

三组均首次4槽、raw首尾同SHA/finite；没有刷失败轮、源/exe未改，machine/game/100GiB/atomiclock/15swatchdog门通过。1152单B槽p99高于早A而低于晚A，合并改善，不只选好槽。各组自己的基线不同，禁止比较跨组绝对wall或宣称untimed优于timed；wall增益也不全归为GPU算术。现象支持单位置marker可改变完整框架成本，但因果机制仍未定。

权威handles38114、34241、6002均exit0/LOCK_RELEASED，未安装/改玩家配置/0.41-a ZIP/正式包；队列已归root/integrator。后续同batch T↔U或formal必要三档门择稳定route，timed已有两档正不为untimed否定它。

Primary API/docs来源与CPU候选代码见experiments/submission-untimed-20261006/README.md；精确clone/source/exeSHA与compiler命令在framework-untimed-source.json，原CSV/log均在本目录。
