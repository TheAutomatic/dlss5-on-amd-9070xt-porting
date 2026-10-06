# 0.37 打包清单（09-29）

脚本 `Development/tools/package-037.ps1`（9070 `D:\DLSSNR-Lab\release-037\`，日志 `package.log`），源码提交 dc52056f。以 0.36 三个 ZIP 为底（先逐文件校验底包）。**与 0.36 逐位相同**。未上传、未打 tag。

## 载荷（以现装为准）

|对象|来源|SHA256|
|---|---|---|
|常规/Magpie add-on|`hip-backend\vit-qkv-20260929\dlss5-amd.addon64`，与剑星现装逐字节同|b77bbc3cf196742f8989d08fe7e63720cb9cedf7061e3a06cd89c01c984ff2e8|
|RE9 runtime|`hip-backend\vit-qkv-20260929\LmxxfNrRuntime.dll`，与鬼武者 Content/_storage_ 两份同|2c103f6ef7741e9cfc1ecf0581b582fa487ccfa45905005e776962657b388018|
|RE9 dxgi 宿主|0.36 RE9 包内沿用|aa3761f2cdb0d9a4653732bd430019ff421b3ce9471fe3697b553dc6d71714a2|
|HIP 模块|剑星现装 62 份（每架构 31），与现装 `SHA256SUMS`、鬼武者现装全同；清单 [HIP-SHA256SUMS](HIP-SHA256SUMS)|—|
|shader|与 0.36 同（git 自 tag 0.36 无改动；`fusion-round3\shaders`），44 变体编译通过|输入 5be59a41|

相对 0.36 变化的模块（与各 results README 记录一致）：c512-m32-mh（ec9e8d92/4bb9b847，深层紧凑）、multihead-fast-padded-wave-packed（71fcc576/8c386562，head 融合）、deep_fast-packed（1d816dc1/1750899d，ViT attention）、vit-stream（9d31ab5f/e727a883，QKV W5）、新增 swin-persistent（0fee8a96/48c71bff）。顺序 gfx1200/gfx1201。
注：剑星现装 `native_text_overlay.hlsl` 是 09-12 旧文件，包内用仓库/0.36 版本，不以游戏为准。

## flags / 包内改动

- 三个模板 `DLSS5_HIP_SWIN_RUN=1`（源码默认 0）；常规/Magpie `DIRECT_IO=1`、`MAKE_RESIDENT_EVERY=60`，RE9 不写 DIRECT_IO。`scripts/CONFIGURATION.md` 已写明。
- 常规 OptiScaler 包补 `ReShade.ini`（`[OVERLAY] TutorialProgress=4`），同 Magpie（WorkingPlan B6）。
- RE9 源码包重生（prepare-host + bundle-source，`upstream.json` 已 checkout 还原）；`bundle-source.py` 补收 `hip/*.inc` 与 `.txt`（此前漏了 12 个 .inc 配方，0.36 源码包同样缺）。

## 结果（`D:\給網友打包\`）

|包|字节|SHA256|文件数|
|---|---:|---|---:|
|Magpie-DLSS5-AMD-0.37.zip|339,740,509|14a8b29e703d9cc3f9e76516151964736452495b790d2d59cc4e5c5e79a947ff|738|
|OptiScaler-DLSS5-AMD-0.37.zip|369,938,358|ea0b9aa8099386392bb9c09b61aa3e630288c410bc024c0e9850ac2a60e4f868|556|
|OptiScaler-REFramework-DLSS5-AMD-0.37.zip|424,464,636|f42abcef5d5e15b048bbfa82773d119a9e684a0ba36d4b174a2c56aa94e58681|560|

三包 ZIP 读回逐文件 SHA256 通过。RE9 包内 runtime smoke（`runtime-smoke.exe`，900，32 帧）：`swin_run=1/1`，SP_STATS runs=4 fallback=0 errors=0，`lmxxf_nr_gpu: ok`。这是包内冒烟，不是 RE9 游戏实测。未改任何游戏安装目录。
