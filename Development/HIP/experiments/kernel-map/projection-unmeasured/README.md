本轮已编译但未执行GPU计时/逐位，不进入配方。完整地图后只选head与ViT attention两项，此候选留作后续。以下为设计阶段记录。

# Final C512 attention projection: two token tiles share weights

Independent base b99e9ef6. No production mutation, compilation or GPU use.

Append `c512_projection_m32.inc` to **c512-m32-mh** and define `C512_PROJECTION_M32=1`; default0. Host patch uses default0 `C512_PROJECTION_M32_HOST`; when active M32 is supported it remaps only the old `mh_fast:mh_attention_project_frag_c512` dispatch to the new export. Existing flags/fallbacks/crop calls remain. Grid `ceil(tokens/32)*8`,32threads; no ABI change. Both compact and diagnostic padded layouts use original argument values. Tail16 handled by per-token guards.

Mechanism: old wave16tokens×64outputs,32accumulator floats. New wave32tokens×64outputs,64accumulator floats; each K16 weightfragment is read once for two independent token tiles. WeightB requests ideally halve per output area, AV bytes and output math are unchanged. No LDS. Also read each residual scale once per output column, sharing across both token tiles. This is **M32 plus scale-load hoisting**, not only a dispatch-count change. Actual compiler VGPR/spill/rematerialization must be inspected.

Mathematics preserved: initialize each accumulator with the same Hrtz(feature*scale); K advances32 and h0/1 in identical order; WMMA operand orientation unchanged; post3Hrtz,post4F,otherwiseF(Hrtz) and crop mapping are copied literally. No half-scale conversion, no residual FMA, no consumer layout change. Block30's raw output and900 compact1504/valid1500 tail remain covered by unchangedpost/crop arguments.

Daniel evidence: ordinary `reg_vit_conv<2,0,false>` uses group_x*2 at0xCFF1C and tests both tiles againstP; Bweight fragments loaded0xD0624..D0678 feed separate token accumulators e.g0xD06DC/D06E4 reusev63:64 with two A fragments. Its residual scales are packedhalf loaded at262144tail and used by packedhalf multiplication. We copy **only weight reuse**, not its half residual arithmetic. Current kernel'sfloat residualscale/Hrtz order is retained.

This differs from previously failed C512 FFN M32: no expanded4096hidden tensor, no doubledhiddenLDS, no FFN activation; it changes only the final512→512 projection. All13 active C512 blocks are eligible. If register pressure erases weight-bandwidth gain, reject after short screen; don't force based solely on observed12us vs23us independent synthetic timing.
