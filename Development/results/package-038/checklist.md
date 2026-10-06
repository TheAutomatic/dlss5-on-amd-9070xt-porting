# 0.38 打包清单（09-30）

脚本 `Development/tools/package-038.ps1`（9070 `D:\DLSSNR-Lab\release-038\`，日志 `package.log`），源码提交 e1b1a18c（tag 0.38）。以 0.37 三个 ZIP 为底（先逐文件校验底包）。**默认设置下与 0.37 逐位相同**；唯一有损项 `DLSS5_NETWORK_1080_ROWS=1088` 为可选、模板 1152 不开。

## 载荷

|对象|来源|SHA256|
|---|---|---|
|常规/Magpie add-on|e1b1a18c 源码 DGX 交叉编译（`scripts/build-addon-oneclick.sh --hip`）|bfba6900079677ff231bfbb210958bfbf68f24964ccf52eb52f5be9836f84976|
|RE9 runtime|e1b1a18c 源码（`scripts/build-runtime.sh`）|ade2d404c2f8d2a7e56ca947ef008a91d6afd90b085e68725e3bfefdde6bc7d7|
|RE9 dxgi 宿主|0.37 RE9 包内沿用|aa3761f2cdb0d9a4653732bd430019ff421b3ce9471fe3697b553dc6d71714a2|
|HIP 模块|剑星现装 62 份（每架构 31），与鬼武者现装逐文件全同（0 差）；清单 [HIP-SHA256SUMS](HIP-SHA256SUMS)|—|
|shader|与 0.37 同（输入 5be59a41），**新增** `native_format_convert.hlsl`|35a1973fc558d7a934cc1190c91f026734405935113568c81e4c7b19c0627b90|
|RE9 源码包|prepare-host.py + bundle-source.py 重生（`upstream.json` 已 checkout 还原），含 native_format_*/native_hot_flags|—|

相对 0.37 变化的模块（gfx1200/gfx1201）：c32-wave1 fd8fed73/8e47b814、c512-m32-deep 81183833/6fc2f5be、c512-m32-mh 3bdb80cc/0f28a38c、c64-wave2 e4f84f44/e46ea20f、deep_fast-packed 54d388a7/eec7d4a6、multihead-fast-padded-wave-packed 1acba935/23a5abb9、swin-persistent 23022d04/8911ecd3、vit-stream 72ee6081/fef8a768。其余 23 个与 0.37 同。

## 重编宿主对现装逐位（`D:\DLSSNR-Lab\release-038\hostcheck`）

现装剑星 add-on 6d059845 是在旧源码上打补丁编的，所以从 e1b1a18c 重编后先验：
- add-on 宿主：base = prefix-post lab `benchmark-P.exe`（6d059845 同源）vs 候选 = e1b1a18c 编的 benchmark（`-DHIP_SWIN_PERSISTENT=1`），同一套剑星现装 31 个 gfx1201 模块；7 用例 × EXACT/AE × 12 帧 = 168 帧逐帧 SHA **全 SAME**、AE 决策 CSV SAME、900/1080 history × EXACT/AE 强制票号回绕 SAME（`full.ps1 -Set A -Cand H -RollHost Hroll -SkipTiming`）。
- RE9 runtime：鬼武者现装 5e601d57 vs 新 ade2d404，现装模块，rt_bench 900/1080 hash 同（b2980ada643da964 / 758674a8bbd0206d）；runtime-smoke `swin_run=1/1`、SP_STATS errors=0、`lmxxf_nr_gpu: ok`。

## flags / 包内改动

- 三个模板加 `DLSS5_FORMAT_FALLBACK=1`、`DLSS5_NETWORK_1080_ROWS=1152`；常规/Magpie 加 `DLSS5_HOT_RELOAD=1`（RE9 模板注释写明不适用）。脚本逐行核对。
- `native_format_convert.hlsl` 手动加入 `native-game-tiled-assets`（037 脚本只刷新底包已有 shader；脚本先断言底包里没有它）。
- ReShade.ini（常规/Magpie `TutorialProgress=4`）照旧。package-notes 六份加 0.38 节。

## 结果（`D:\給網友打包\`）

|包|字节|SHA256|文件数|
|---|---:|---|---:|
|Magpie-DLSS5-AMD-0.38.zip|339,966,341|fcaeeffa529ab523a14775938c0947418a8fec9f636d1142c2c5be7496de6ad4|739|
|OptiScaler-DLSS5-AMD-0.38.zip|370,164,139|1aebc3301da554a1bb78530aea631700e6e747a0441d12a6f1fd1d10fec279c1|557|
|OptiScaler-REFramework-DLSS5-AMD-0.38.zip|424,714,993|3dbf7a7ebab883ee661fc21f8f11487d922666c681c1772c963ecbb654eacab8|561|

三包 44 个 shader 变体编译通过，ZIP 读回逐文件 SHA256 通过。RE9 包内 runtime smoke（900，32 帧）：`swin_run=1/1`、flags applied=18、SP_STATS runs=4 fallback=0 errors=0、`lmxxf_nr_gpu: ok`（包内冒烟，不是 RE9 游戏实测）。未改任何游戏安装目录。

## 上传

- Gofile：https://gofile.io/d/wsAqRlAI （9070 curl.exe，三包同一文件夹，服务器回报 MD5 与本地一致；记录 `D:\DLSSNR-Lab\release-038\gofile.json`）。
- 夸克：Zero 自传，README/CHANGELOG 暂写"夸克链接稍后补"。
