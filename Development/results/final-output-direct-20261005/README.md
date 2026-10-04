# 最终RGB直接写共享输出（已安装）

基线b687e13a、full71/FAST1；模块数学不变。RunGraph最后post、预测最终apply或skin最终blend借用bridge输出指针，Allocation owned=false不释放/不同步；仅最终一次拷贝消除，不按遍数倍乘。graph、OVERLAP与input/history地址重叠保留旧copy，中间/history/AE缓存继续私有。

| 档位 | 基线墙钟ms | 候选墙钟ms | 省ms | p99基线→候选ms |
|---|---:|---:|---:|---:|
| 900 | 7.089554 | 7.067336 | .022218 | 7.403→7.386 |
| 1080 | 9.878794 | 9.856674 | .022120 | 10.260→10.242 |
| 1440 | 16.554247 | 16.421272 | .132975 | 17.017→16.955 |

每档3轮ABBA、每槽320弃80，1440样本/侧；全部无慢轮、合并p99更低，TimingOnly只首尾检查。不代表游戏FPS。初copy1/copy9差/8约.022/.030/.140ms只缓存/调度预算，不作真实省时；shortscreen后才扩终点并正式测。

MP2、真3、1440预测+history、预测/真3+skin、单遍AE六组RAW SAME；真实OVERLAP1旧路RAW SAME。graph基线PDL+graph互斥失败，不追，候选opt.graph无条件旧copy。正常19最终normal/AE/CSV/roll全SAME；第一次误用不导出逐帧的TimingOnly runner，MissingFrames属工具失败，已换同源canonical runner。RE9 900单遍/1080预测3各4帧SAME，smoke8runs/errors0。

双游戏host-only安装：addon3c518b600dd2ec026b8654008f3632608032dae3244f784285a7ff6391c30744；runtime4b1852f93c9b70f04dc74862a7640b082ef76c76505e6f02efa36fafb66a9378根/_storage_相同。三配置及模块SUMS hash均未变，exact/host-payload.json已记录。备份D:\DLSSNR-Lab\final-output-direct-20261005\backups\20261005-070357带rollback.ps1。锁释放；666原始输出已留hash后仅清本轮帧，不删权重/输入。已上传0.41ZIP不动，未push/tag。
