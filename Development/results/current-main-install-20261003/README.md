# 当前 main 编译与双游戏安装（2026-10-03 23:23）

源码：main `1311179d`，包含已批准 fast-vit / preupscale-auto。未打包 0.41、未 commit/push、未启动游戏。

- 剑星 add-on：`518e34c401b51b4cf86bf0f3b7d7ca676e6fc8b0e6df8178ed493ca7caf2f9cb`
- 鬼武者 runtime（Content + _storage_ 两份）：`2176c54484736f7f6156d525e0b1d0d7d9da9e110f27895254fe94376e9a4f3d`
- 两游戏 HIP SHA256SUMS：`9d4a20242d7d4694fb2da2b48158452d96b8f8c2ac263418f4b085a393ad8c2e`；gfx1200 / gfx1201 各 36 模块，共 72。

COMGR 全配方重编；LLVM23 五行两架构重编，供配方使用。正常重编模块文件哈希与上一版存在差异，因此实际回归确认输出，未用模块哈希推定等价。

验证：正常 7 + AE 7 + AE 决策 CSV + 票据 rollover 4 = 19 组 SAME；全 71 块 FAST=1 的 7 组对已批准 PF 全 SAME。RE9 旧/新 × 两遍：900 `6f961945261a355c` / 1080 `aaa31e2dffa3a1b5` 全 SAME，runtime-smoke errors=0。这里正常逐位基线是上一版生产链，FAST 基线是已批准 PF，不是 NVIDIA exact。安装后逐文件读回、72 模块/SUMS 双游戏一致，fast-tier exact 全模块快照同步，status 双 EXACT。

custom/native 两份配置逐文件哈希未变。新 default 为全块、FAST=1、MULTI_PASS=1、PRE_UPSCALE=auto；剑星 native PRE=1、MULTI_PASS=3（custom 也为 3）覆盖 default；鬼武者 native PRE=0、MULTI_PASS=1。剑星仍强制前置，auto 真游戏效果未验证。F9 真按键亦未验证。

备份及回滚入口（远端）：`D:\DLSSNR-Lab\current-main-20261003\backups\20261003-232258\rollback.ps1`。备份含双游戏所有涉及文件、配置、manifest（存在性 + 原哈希）和 exact 快照。回滚脚本会先原子获取 gpu.lock、查游戏和实验进程；安装异常自动回滚。未实际执行回滚，以保留此次安装。

远端工作区 `D:\DLSSNR-Lab\current-main-20261003` 保留构建产物、脚本和日志；回归帧转储已清理，自有 gpu.lock 已释放。D 盘余量约 423 GB。本地只归档日志与脚本，构建二进制移到 `/tmp/dlss5-current-main-20261003-host-build`，不入仓。


### 23:48:16 Zero 真游戏反馈

鬼武者 GPU 占用 89～92%，Zero 感觉比此前下降；此前约 95% 只是历史读数对照，本条未报 FPS，未确认本轮稳 60。剑星 1x 仍为 57～58 fps，本轮未读出帧率提高。离线省时不能直接当成游戏帧率收益，约 0.3 fps 的推算不是实测。
