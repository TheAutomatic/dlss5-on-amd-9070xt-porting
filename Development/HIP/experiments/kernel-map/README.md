# 全网逐核地图复现

任务基线 `b99e9ef6`，现场add-on b5ab8c3a。最终结果 `Development/results/kernel-map-20260929/README.md`；当前生产代码只接受H（head grouped pool/project）与V（ViT score transpose）。没有发包。所有GPU脚本先查游戏进程，计时不并行。

## 地图数据与口径

`ours-jobs.json`、`deep1080.json`、`daniel-shallow.json`是实际计时参数/typed buffer描述。Daniel仅reference选择分支，shared head等沿该图调用；浅层native1088与我方1152、post移位和skip42/43/46独立标记。154＋169个派发完全无漏无重复，边界融合按完整组配对。900地图未跑，生成器的900描述不算实测。

`jobbench.cpp`每进程只执行一个job。输入±.25，矩阵±1/64；混合布局的half/f32尺度单独填。主缓冲区两边256B guard，检查全部buffer guard和选定输出finite/nonzero；zero初始化未写padding不能证明覆盖，也不能证明无越界读。8次warmup后同stream捕获128次串行launch，graph预热，再7轮GPU事件除128取中位。buffer初始化、拷贝、验证不在计时区。11个同类>30%异常项再各跑两独立进程，原始＋两复测共21轮取中位，不挑最快。日志留全，表只代表独立合成核中位数之和，不能代替完整网络ABBA。

Packed kernarg使用HIP extra API；END是3，非CUDA的null。定义核对官方头文件：[HIP Runtime API](https://rocmdocs.amd.com/projects/HIP/en/docs-5.0.0/doxygen/html/hip__runtime__api_8h.html)。参数前缀取ELF metadata，不自行补隐式尾字段。

## 重建工具与合成fixture

从仓库根目录运行 `bash Development/HIP/experiments/kernel-map/build-tools.sh /tmp/kernel-map-tools`，生成recorder-v2.exe/jobbench-v2.exe。recorder用固定任务commit重建隔离源码并应用recorder-host.patch；记录最终Run选择的模块/导出/grid/参数/分配大小。ReadWeights在原布局先把矩阵/bias非零项改成确定性±1/64、norm/residual/skip增益改1，再走原生产pack；只沿用必要结构零，不沿用训练值。`MAP_DIR`指定packed synthetic权重输出目录。需要原模型资产来获得尺寸/结构零，合成大buffer和hsaco不入git。

9070工作根 `D:\DLSSNR-Lab\hip-backend\kernel-map`。`snapshot.ps1`只用于测试前冻结基线，不要对已经升级的游戏重跑并称其为旧基线。`record-v2.ps1`读原捕获live-menu-before.f16，只生成fixture和参数日志。`parse-record.py LOG OUTPUT`先将UTF16/UTF8的JOB行转成ours-record.json；`make-ours.py`将解析后的ours-record.json转成typed jobs，并构造固定Gather索引；`ours-types.json`给真实输入/输出dtype，不能按C++ float*声明猜FP8/half数据。

`make-shallow.py`、`make-daniel-deep.py`从已归档Daniel调度与ELF metadata生成jobs；后者需要工作根all-metadata.json（结果目录daniel-metadata.json即该内容）。`read-meta.py`提取当前基线flat-A各模块metadata。默认工作根/tmp/kernel-map，移动环境时修改/传入相应根路径。

`make-after-jobs.py`从原head半权重row布局重排fragment，生成H/V的9个更新job（需numpy；ELF读metadata需msgpack）。

`pack-jobs.py JOBS.json OUT_DIR`生成简单二进制job描述，拒绝超出userprefix的参数。`run-jobs.ps1 -List LIST.txt -Batch NAME`逐进程运行。首批未分开尺度的169条整批作废（42条全零），见discarded-fixture.json，不得用logs-ours替代logs-ours-valid。

## 汇总与增量更新

`analyze-map.py --root RESULT_DIR`需要结果目录现有manifest/position-map/dispatch-jobs/有效logs及repeat-list.txt。它核对START导出、7轮TIME与RESULT、前后CHECK、323个位置，再生成analysis-final；任一必需日志缺失则只产pending。归档结果复制为map-before。浅层有效面积折算仅启发式，另保真实window量，不混进严格同尺寸排名。

`overlay-map.py --overlay RESULT_DIR/overlay.json --baseline RESULT_DIR/map-before --out RESULT_DIR/map-after`只刷新已接受9项：两个head旧派发替换为1、八个attention更新，其他我方159/Daniel154沿用。after-ours-092含两额外复测，共21样本。没有声称after全表重新测量。

## 生产回归与安装

候选H/V源码及说明在head/、vit-attn/；以b99e9ef6源树应用patch，H include追加multihead-fast-padded-wave-packed，V改deep_fast-packed。P在projection-unmeasured/仅编译、未GPU验证、不合入。最终生产宏默认0，配方显式开C512_HEAD_GROUP和HIP_VIT_ATTN_TRANSPOSED_SCORE；无新用户flags。

`regression.ps1`固定7用例、EXACT/AE各12帧，168候选帧逐位核对float FMA goldens。长ABBA1000帧/槽弃200，短筛200弃32，首尾RGB读回；gameflags额外12帧单列。`analyze-results.py`复算时序/逐帧golden/AE所有字段。`build-production.ps1`双架构及macro-off控制；production与候选代码段相同，gfx1200只编译、gfx1201实卡。

安装只换addon和两个模块×双架构，基于冻结b5ab8c3a核对，DIRECT_IO=3及MAKE_RESIDENT_EVERY=60保持。回滚用`install.ps1 -RestoreBackup D:\DLSSNR-Lab\hip-backend\kernel-map\backups\stellar-20260929-084855`。`verify-installed.ps1`核对全部60模块及现场SHA256SUMS。RE9 runtime只在隔离目录回放/冒烟，未装RE9；游戏画面验收由Zero本机完成。
