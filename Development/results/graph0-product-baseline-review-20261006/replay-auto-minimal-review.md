# ReplayAuto最小CPU机制门（未实施/未GPU）

产品首筛6afdb3ba未过mean收益门，原Auto与ReplayOff数据不删除；本候选只研究一个ReplayAuto角色对实际EagerAuto，不扩四格/新位置。

1. **公共接口与类型**：锁定ROCm7.0.2头 `/tmp/hip-graph-abi-20261006/hip_runtime_api.h:1412` 定义EventRecord=7，`:8377`声明 `hipGraphEventRecordNodeGetEvent(node, hipEvent_t*)`。现设备DLL导出/实际节点尚未证明，缺接口即拒，不把EventRecord参数按KernelParams解码。
2. **事件身份**：`HIP/submit_pulse.h`现lease私有持有handles，仅Active/HasHandles公开。隔离版本最小暴露active/count1的只读handle，不另造事件或改变生产Record。捕获应得161 Kernel+1 EventRecord，总162；返回handle必须同实际Auto lease，kernel函数序列仍同eager161。强唯一Topo必须证明普通C256Down→事件→C512首Body顺序，不能只多重集或节点数。
3. **拥有权**：当前quiet copied `hip_d3d12_bridge.h:195–196`先CloseSubmitPulse再LabAppClose，只在图无事件时适用。组合必须owner device/drain→destroy graphExec/graph→leaseClose→imports/semaphore/Network释放。`hip_reference_network.h:875`现LabAppClose已有先同步再销exec/graph，失败终止而非放走被引用资源。
4. **每帧资格**：普通`:795` marker执行原host Scope；重放不执行这些C++检查。必须每GraphLaunch前核实际非site `PulseRejectMask`(:854)、active lease/driver/caps、固定geometry/style/seed/输入输出ptr/history/MP/AE/profile等key，变化即诊断停止。site所需orderedDown标记不能拿捕获后的stale字段默许；由冻结DAG精确边界证明，拒未知拓扑，不放宽普通NN生产条件。
5. **计数边界**：warm正常执行Record、capture的host Record录图、GraphLaunch API次数分别报告。不得套eager Record=N当图GPU执行N。原CLR GraphEventRecordNode:2162–2204存raw event并在重放提交RecordCommand，事件必须持续alive；GraphLaunch成功/rawsame不足单独证明marker实际执行，报告此限制。
6. **最小顺序**：先typed导出/拥有权/source门，再capture-only162node身份+DAG门，再一次poison输出重放/rawfinitebit0；通过后才bounded changedHDR和quiet性能源审。原Frame codec/prewait/postsignal/query/drain仍在图外，NET0/PDL0/PRED1inactive固定scope。此文不授权GPU，不支持生产长图/热配置回落，不相加pure/APP/pulse收益。
