# 小请求晚一批复用：负账

未收生产、未安装。仅实验patch：≤8MiB分配请求从原use_count1/足够capacity集合中再排除recent possible-use块（包括较大capacity）；不提前释放/复用。P标下一logical launch-batch，Run连续DUP/repeat作为一批，SP init/run/recovery作为一批；不是物理GPU完成/精确last-use，非launch P可保守多延迟。Graph全旧路、PDLkeep原样、未使用stamp0可复用；uint64到界旁路。宏0编掉字段/策略，candidate.patch保存后主生产头恢复。

同源A0/A1、相同39/gfx1201当前开发模块（78双架构产品集合的一半）、原free-res fixture，实际valid2560×1440/proc2560×1472、960tokens；full71/FAST1/MP1/PRED0/SKIN0/AE0。完整NativeGameFrame且history0不创建temporal配置，首尾读回/中间不scan。160帧/槽弃80，首短ABBA：A15.680819、B15.742244ms，慢+0.061425ms；两B槽15.743150/15.741338均慢于A15.636475/15.725163。只screen，不称正式三轮或FPS。

四槽raw45219840B/SHA完全相同。candidate确实命中：每进程logical_batches25120/recent_rejects34560/reuse32627，graph_guard0。按门立即止，不刷剩余轮、不扫阈值/布局、不跑无必要正常19/900/1080，不将上游Vulkan局部缓存案例当HIP必然收益。

CSV、stderr/geometry、source/patch/host hashes齐全；截图/完整raw只保hash后清理，未删输入、weights、游戏或用户文件。GPU锁释放，配置与已上传0.41 ZIP不变。
