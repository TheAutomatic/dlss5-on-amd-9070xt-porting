# 默认配置换成"全 71 块 + FAST_NUMERIC=1"并装机（2026-10-03，Zero 拍板）

**结论先行**：三个模板改成 `DLSS5_SKIP_BLOCKS=`（空）+ `DLSS5_FAST_NUMERIC=1`；剑星、鬼武者的 flags 文件做同样两处改动。RE9 runtime 必须一起改：flags 文件里的空值会经 `_putenv` 把变量删掉，旧 runtime 这时退回源码内置的 `42,43,46`，空值关不掉跳块。新 runtime 源码默认改为不跳块（838A8B97），其余代码不动。验证：add-on 回放与 C 组逐位相同、fast 模块确实被打开；RE9 回放 skip=0，跳块路径与旧 runtime 逐位相同；ABBA 900 +0.098 / 1080 +0.168ms，与 default-swap 的 C 组一致。

## 空值语义

| 读取方 | 读取方式 | `DLSS5_SKIP_BLOCKS=`（空） | 不写这一行 |
|---|---|---|---|
| add-on（`native_game_oneshot.h`） | 每个 `DLSS5_` 行都 `_putenv`，空值等于删变量 | `native_hip_network.h` 拿不到变量，`Options::skip_blocks` 默认为空集，所以全 71 块都算 | 同左 |
| RE9 runtime 旧版（DBAB5E88） | 白名单认这个键，也走 `_putenv`，空值同样删变量 | `LmxxfProductionOptions` 拿不到变量，用内置的 `ParseSkipBlocks("42,43,46")`，**仍然跳块** | 跳块 |
| RE9 runtime 新版（838A8B97） | 同上 | 去掉内置值，全 71 块 | 全 71 块 |

`ParseSkipBlocks` 遇到空段（比如 `,`）会抛异常，所以只改 flags 文件绕不过去，只能改 runtime 的源码默认值。`DLSS5_FAST_NUMERIC` 白名单早就认（10-03 fast-numeric 那次加的），源码默认仍是 0，靠模板里那一行打开。

## 装机（`Development/deployments/default-c-20261003/install.ps1`，先 DryRun）

两个 flags 文件各自只改两处，其余行、行尾（剑星 CRLF、鬼武者 LF）和编码都不动：

```
-DLSS5_SKIP_BLOCKS=42,43,46
+DLSS5_SKIP_BLOCKS=
+DLSS5_FAST_NUMERIC=1
```

剑星 flags 2E308EC0（第 103 行），鬼武者 flags 92B97FFB（第 100 行）。鬼武者 runtime 和 `_storage_` 里那份都换成 838A8B97（旧的 DBAB5E88 就是 main 源码编出来的，可复现）。add-on 9D1FA493、模块、SUMS F3EFDC16 都没动。备份在 `D:\DLSSNR-Lab\default-c-backups\20261003-082157`（两个 flags、两份 runtime，以及 fast-tier 的 exact 快照、switch、README），还原用 `install.ps1 -RestoreBackup 20261003-082157`。

fast-tier：`exact\stellar-flags.txt` / `oni-flags.txt` 换成新装的 flags。`switch.ps1` 判断档位不看 flags，所以 `to-exact` 的动作没变（换回正式模块并删掉旧 fast 档加的 1088 行配置）；但"EXACT"现在只表示"装的是正式模块"，不再表示输出逐位。`status` 和切换后的提示都加了这句话，`README-Zero.txt` 开头写了新默认、怎么改回跳块、怎么回逐位。

## 验证（`Development/HIP/experiments/default-c/verify.ps1`，GPU 锁 + guard 每 15 秒查游戏）

**add-on 回放**（benchmark-F = 现装 add-on 的宿主，flags = 现装剑星文件 + bench 行，模块 = 现装 gfx1201，20 帧）：

| 档 | 现装 | + `SKIP=` + `FAST=1`（C 组） | + `SKIP=42,43,46` | + `FAST=0` | 换成假的 `-fast` 文件 |
|---|---|---|---|---|---|
| 900 | B8C0AE76 | B8C0AE76 | 361B0D8B | 40D5A92E | 退出 1：`c64-wave2-fast.hsaco: hipErrorInvalidImage` |
| 1080 | D63608E4 | D63608E4 | 14659EE0 | 71F2CAD7 | 同上 |

现装配置的输出和 C 组逐位相同，跳块或关 fast 后都会变；假 `-fast` 文件直接加载失败，说明 fast 模块确实在用。

**RE9 runtime 回放**（rt_bench 1707×961，模块 = 鬼武者现装）：

| 档 | 旧 runtime、无 flags | 新 runtime + 文件 `42,43,46` | 新 runtime + 鬼武者现装 flags | 新 runtime、无文件、环境变量 FAST=1 | 新 runtime + `SKIP=` `FAST=0` |
|---|---|---|---|---|---|
| 900 | b2980ada skip=3 | b2980ada skip=3 | ab6b7731 skip=0（applied=14） | ab6b7731 skip=0 | 6f961945 skip=0 |
| 1080 | 758674a8 skip=3 | 758674a8 skip=3 | 45d9905f skip=0 | 45d9905f skip=0 | aaa31e2d skip=0 |

写明 `42,43,46` 时新旧 runtime 逐位相同，说明只改了默认值。旧 runtime 的哈希也和 fast-numeric 那次的 old 一致。现装 flags 文件 = 默认不跳块 + fast 数值。runtime-smoke exit 0（`re9-smoke.log`）。

**ABBA**（1 轮，1000 帧取 200 以后，静止序列；基准 = 发布默认 A，候选 = 从现装剑星文件里读出的两行，模块用从游戏目录新拷的那份；`abba-INST.txt`）：

| 档 | A → 现装 | 差 | default-swap C 组三轮 |
|---|---|---|---|
| 900 | 6.983 → 7.082 | **+0.098 ms**（p99 7.225→7.294） | +0.120 / +0.096 / +0.138 |
| 1080 | 9.758 → 9.925 | **+0.168 ms**（p99 10.009→10.184） | +0.184 / +0.190 / +0.186 |

900 落在 C 组三轮范围内；1080 比三轮最低值少 0.016ms，在单轮噪声以内。

## 没改的

`scripts/package-notes/*` 和 `package-README*.txt` 是各版本的包内说明，里面"默认 42,43,46"描述的是已发布的包，下次打包写新说明时再改。
