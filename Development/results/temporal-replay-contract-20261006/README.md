# MP1 history原型修正与实际codec回放准备（2026-10-06）

生产默认、玩家配置、现装载荷、0.41发布包没有改动。本轮完成隔离原型合同修正和工具链门；没有真实房顶连续源，不能宣称闪烁已修复。生产目前没有这个完整history原型，因此RNE错误不是现装游戏闪烁的已证实原因。

## 实际发现与修正

原版history合同见 `../history-contract-20261006`：有效1920×1080 RGBA16F、alpha1，与原post内部输出surface逐half一致，和API最终解码域不同；history包含有效post blend。原post HALF4 surface受控gold明确RTZ而非RNE。

隔离 `../../HIP/experiments/temporal-sequence-20261005/warp.hip` 的temporal_store已从隐式half RNE改显式RTZ，保存internal gate-blend RGB有效区、alpha1；实验仍用widened-half f32数组作纹理读值载体，不把数组内存布局称为私有API布局。原型的只读prior＋末尾存储顺序不变；两个buffer只是隔离原型租约实现，不宣称原API双history pingpong。

9070受控GPU：closed、zeroMV、+1px、(.25,.375)四组，temporal_store对5090原CUBIN HALF4 surface gold逐float-bit0。输入为原核float输出RGB、gold为原surface half精确扩宽；不是CPU仿写NVIDIA输出。见store.log。

原型状态提取为history_state.h：first/reset/resize清ready并重置实验counter；同帧history读写分槽；GPU完成并通过检查才commit；失败不发布历史。missingMV的“存空间fallback”和“下一帧先失效”两policy仅CPU对照，默认保持已有实验policy，尚未认定原API行为。MP3不实现时序：当前MultiPassRest共享hist/seed只能说明当前代码，不能决定分遍或共享哪条质量路线。

## 实际转码与回放

replay_convert.cpp完整CPU链接并实际运行既有NativeGameCodec、NativeGameRgbInput、NativeTemporalFeed、NativeTemporalCoordinates shader。所有codec/几何/MV sign与scale参数显式配置；不把原FFX raw当encoded输入、不缺项悄填曝光1。当前color texture需等于render extent；不同需后续明确subrect adapter。

这条转换直接fit原FFX输入，未执行FSR，所以是受控replay输入因素，不冒充游戏FSR后实际网络输入。jitter/depth保留元数据但未应用，motion方向尚需核；源seed=null保留，fixed0/counter是独立实验因素。

最小GPU fixture为人为1280×720 RGBA16F色块、明确zeroMV/曝光1，重复两帧；不是新游戏抓帧。两次转换hash一致、encoded与coordinates finite、encoded alpha1、proc768底部mirror逐bit同。

发现UV转pixel位移有6.1035e-5残差（zeroMV也出现），因此prepared回放直接读取原Coordinates UV，新增temporal_warp_uv；pixel MV输出仅诊断，不做UV→pixel→UV往返。原temporal_warp位移入口继续保留。

prepared-index接入sequence.exe后，三路（空间/prefix-only/full-gate）×fixed0/counter×两帧，共12行：finite、off/first独立baseline byte0、同输入/seed重复byte0。此门证明工具链和隔离原型可运行，不证明真实闪烁改善；diagnostic wall不作性能门。

## 可运行入口与封存

- `../../HIP/experiments/temporal-sequence-20261005/build_replay.sh OUTPUT_DIR`：本地MinGW构建converter/store/sequence及同源Options。
- 同目录 `run_cpu_contract.sh`：租约状态、raw manifest、converted receipt/index的CPU合同门。
- `seal_real_sequence.py manifest.jsonl`：要求COMPLETE且无FAILED，核frame/资源extent/row/bytes/SHA；upscale[0,0]、seed缺项、未核source identity/MV/codec合同输出blocker，不造数据。
- 采集/显式recipe入口为 `../../HIP/experiments/real-sequence`（b439efc6、adbb2bf2）。只CPU完整链接与保守write/alias/thread守门验证；尚未GPU采集、未安装。Mode2 FFX-only源无同期NR闪烁最终图，copy扰动使timing_valid=false。
- `seal_converted.py receipt.json CONVERTED_DIR prepared.tsv`：绑定转换config、输出几何/finite/mirror/SHA及源seed缺项；prepared-index为实验输入，不升级source_identity_verified。
- 同目录 `run_convert_fixture.ps1`：本轮9070隔离GPU门脚本。game-check、原子gpu.lock、15秒游戏看门狗、D≥100GB；本轮D约412GB，未遇游戏、锁已释放。实验目录 `D:\DLSSNR-Lab\temporal-replay-contract-20261006`。

本结果只保小CSV、hash、receipt、日志与summary，不入大raw或二进制。原原型RNE阶段记录作为历史保留，当前修正见本文件。真实roof连续color/MV/depth/jitter/exposure/reset、生产effective flags/modules与瞬态源身份仍待；不继续追加合成案例充当场景证据。
