# Final-store sourceword routing correction

remaining found DevHistory1248/deep-tail-20260930 VIT_QKV_TAIL_VEC: sameQKVfinalquantizedbytes, reusednormalizationLDS transpose andb128 stores, 19goldsame/three1080round merged+.005ms negative. Thus72b1841a's prior search absence is superseded; old route didnotchangephysicalVlayout, didnotaddLDS capacity, andusedwavebarrier/fence ratherthanfullWG barrier. No automaticnewperformanceclaim.

Dynamicds_bpermute sourceword trap: inputregisterselection occursat sourceinvocation beforedestination gathers. packed[j][dest_e/4] chosenusingeachsource'slocalt doesnotretrieve thedestdesiredword. Naivecorrectroute gathersbothfixedword0/1 for eachdesiredbyte thenselectsatdest:16DS per8Bword,32DS/tile, notoneDSbyteasassumed.

A smallerexactpackedbutterfly route exists: perj twou32 containing8bytes; forbitsb=0,1,2 swap lanebitb withregisterbyte-indexbitb. Atb0/1 gatherpartnerlane xor1/xor2 fromeachfixedsameword (2DS/j), byteindexxor permutation andlane-dependent byte maskselect. Atb2 foreachfixedoutputwordw gatherfixedotherword(1-w) fromlane xor4 (2DS/j); selectcross iff laneBit2!=w, otherwise ownwordw. Finallygather eachfixedwordfromlane ((lane&7)|((lane&8)<<1)|((lane&16)>>1)) exchanginghighlane3/4 (2DS/j). Total8DS/j,16DS/tile, plusbyteperm/mask operations and3serialshuffle stages. No dynamic sourcewordchoice.

Symbolic512-positionCPUproof route matches targettoken=lane%16,column=j16+(lane/16)*8+byteindex, preservingAoSvalues. This provesroutingonly, notactualmachinecode orspeed; originalLDSroute mayoutperform registershuffles. A newmechanism mustbecomparedwiththatnegativeLDSroute'sactualISA/controlsync, notrenamedwide-store gain. NoGPU/candidateimplementation.
