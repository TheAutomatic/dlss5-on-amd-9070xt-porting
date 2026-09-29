
/home/lmxxf/work/vit-attention-20260929/production/production-1/gfx1201/deep_fast-packed.hsaco:	file format elf64-amdgpu

Disassembly of section .text:

0000000000019300 <vit_attention_fused_640_bytein_bout>:
	s_load_b64 s[2:3], s[0:1], 0x18                            // 000000019300: F4002080 F8000018
	s_wait_kmcnt 0x0                                           // 000000019308: BFC70000
	s_cmp_eq_u64 s[2:3], 0                                     // 00000001930C: BF108002
	s_cselect_b32 s4, -1, 0                                    // 000000019310: 980480C1
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000019314: BF870009
	s_and_b32 vcc_lo, exec_lo, s4                              // 000000019318: 8B6A047E
	s_cbranch_vccnz 5                                          // 00000001931C: BFA40005 <vit_attention_fused_640_bytein_bout+0x34>
	s_load_b32 s2, s[2:3], 0x0                                 // 000000019320: F4000081 F8000000
	s_wait_kmcnt 0x0                                           // 000000019328: BFC70000
	s_cmp_eq_u32 s2, 0                                         // 00000001932C: BF068002
	s_cselect_b32 s4, -1, 0                                    // 000000019330: 980480C1
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000019334: BF870009
	s_and_not1_b32 vcc_lo, exec_lo, s4                         // 000000019338: 916A047E
	s_cbranch_vccnz 719                                        // 00000001933C: BFA402CF <vit_attention_fused_640_bytein_bout+0xb7c>
	s_load_b32 s6, s[0:1], 0x10                                // 000000019340: F4000180 F8000010
	s_lshr_b32 s2, ttmp9, 1                                    // 000000019348: 85028175
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001934C: BF870009
	s_and_b32 s4, s2, 0x7ffffff0                               // 000000019350: 8B04FF02 7FFFFFF0
	s_wait_kmcnt 0x0                                           // 000000019358: BFC70000
	s_cmp_ge_u32 s4, s6                                        // 00000001935C: BF090604
	s_cbranch_scc1 710                                         // 000000019360: BFA202C6 <vit_attention_fused_640_bytein_bout+0xb7c>
	s_load_b128 s[0:3], s[0:1], 0x0                            // 000000019364: F4004000 F8000000
	v_dual_mov_b32 v24, 0x3c003c00 :: v_dual_and_b32 v3, 15, v0// 00000001936C: CA2400FF 1802008F 3C003C00
	v_lshrrev_b32_e32 v1, 1, v0                                // 000000019378: 32020081
	s_mov_b32 s5, 0                                            // 00000001937C: BE850080
	v_lshlrev_b32_e32 v0, 9, v0                                // 000000019380: 30000089
	s_delay_alu instid0(VALU_DEP_3)                            // 000000019384: BF870003
	v_or_b32_e32 v2, s4, v3                                    // 000000019388: 38040604
	v_mov_b32_e32 v27, v24                                     // 00000001938C: 7E360318
	s_lshl_b32 s4, ttmp9, 5                                    // 000000019390: 84048575
	v_dual_mov_b32 v25, v24 :: v_dual_and_b32 v32, 8, v1       // 000000019394: CA240118 19200288
	s_wait_alu 0xfffe                                          // 00000001939C: BF88FFFE
	s_and_b32 s4, s4, 0x3e0                                    // 0000000193A0: 8B04FF04 000003E0
	v_dual_mov_b32 v16, 0 :: v_dual_lshlrev_b32 v33, 10, v2    // 0000000193A8: CA220080 1020048A
	v_and_b32_e32 v0, 0x2000, v0                               // 0000000193B0: 360000FF 00002000
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 0000000193B8: BF870112
	v_dual_mov_b32 v26, v24 :: v_dual_mov_b32 v17, v16         // 0000000193BC: CA100118 1A100110
	v_lshl_add_u32 v0, s6, 11, v0                              // 0000000193C4: D6460000 04011606
	s_wait_kmcnt 0x0                                           // 0000000193CC: BFC70000
	s_wait_alu 0xfffe                                          // 0000000193D0: BF88FFFE
	s_add_nc_u64 s[8:9], s[0:1], s[4:5]                        // 0000000193D4: A9880400
	v_dual_mov_b32 v18, v16 :: v_dual_mov_b32 v19, v16         // 0000000193D8: CA100110 12120110
	v_add_co_u32 v34, s7, s8, v32                              // 0000000193E0: D7000722 00024008
	s_wait_alu 0xf1ff                                          // 0000000193E8: BF88F1FF
	v_add_co_ci_u32_e64 v35, null, s9, 0, s7                   // 0000000193EC: D5207C23 001D0009
	v_or3_b32 v36, v0, s4, v3                                  // 0000000193F4: D6580024 040C0900
	v_add_co_u32 v1, vcc_lo, v34, v33                          // 0000000193FC: D7006A01 00024322
	s_delay_alu instid0(VALU_DEP_1)                            // 000000019404: BF870001
	v_add_co_ci_u32_e64 v2, null, 0, v35, vcc_lo               // 000000019408: D5207C02 01AA4680
	s_clause 0x1                                               // 000000019410: BF850001
	global_load_b64 v[28:29], v[1:2], off                      // 000000019414: EE05407C 0000001C 00000001
	global_load_b64 v[30:31], v[1:2], off offset:16            // 000000019420: EE05407C 0000001E 00001001
	v_dual_mov_b32 v20, v16 :: v_dual_lshlrev_b32 v1, 10, v3   // 00000001942C: CA220110 1400068A
	v_dual_mov_b32 v21, v16 :: v_dual_mov_b32 v22, v16         // 000000019434: CA100110 15160110
	v_mov_b32_e32 v23, v16                                     // 00000001943C: 7E2E0310
	s_delay_alu instid0(VALU_DEP_3)                            // 000000019440: BF870003
	v_lshl_add_u32 v37, s6, 10, v1                             // 000000019444: D6460025 04051406
	v_dual_mov_b32 v8, v16 :: v_dual_mov_b32 v9, v16           // 00000001944C: CA100110 08080110
	v_dual_mov_b32 v10, v16 :: v_dual_mov_b32 v11, v16         // 000000019454: CA100110 0A0A0110
	v_dual_mov_b32 v12, v16 :: v_dual_mov_b32 v13, v16         // 00000001945C: CA100110 0C0C0110
	v_dual_mov_b32 v14, v16 :: v_dual_mov_b32 v15, v16         // 000000019464: CA100110 0E0E0110
	v_dual_mov_b32 v0, v16 :: v_dual_mov_b32 v1, v16           // 00000001946C: CA100110 00000110
	v_dual_mov_b32 v2, v16 :: v_dual_mov_b32 v3, v16           // 000000019474: CA100110 02020110
	v_dual_mov_b32 v4, v16 :: v_dual_mov_b32 v5, v16           // 00000001947C: CA100110 04040110
	v_dual_mov_b32 v6, v16 :: v_dual_mov_b32 v7, v16           // 000000019484: CA100110 06060110
	s_mov_b32 s7, 0x3fb84000                                   // 00000001948C: BE8700FF 3FB84000
	s_mov_b32 s8, s5                                           // 000000019494: BE880005
	v_add_nc_u32_e32 v40, s5, v36                              // 000000019498: 4A504805
	v_add_nc_u32_e32 v38, s5, v37                              // 00000001949C: 4A4C4A05
	s_wait_alu 0xfffe                                          // 0000000194A0: BF88FFFE
	s_add_co_i32 s8, s8, 16                                    // 0000000194A4: 81089008
	s_addk_co_i32 s5, 0x4000                                   // 0000000194A8: B7854000
	s_wait_alu 0xfffe                                          // 0000000194AC: BF88FFFE
	s_cmp_lt_u32 s8, s6                                        // 0000000194B0: BF0A0608
	v_add_nc_u32_e32 v41, 0x400, v40                           // 0000000194B4: 4A5250FF 00000400
	v_add_nc_u32_e32 v42, 0x800, v40                           // 0000000194BC: 4A5450FF 00000800
	v_add_nc_u32_e32 v43, 0xc00, v40                           // 0000000194C4: 4A5650FF 00000C00
	v_add_co_u32 v38, vcc_lo, v34, v38                         // 0000000194CC: D7006A26 00024D22
	v_add_nc_u32_e32 v45, 0x1400, v40                          // 0000000194D4: 4A5A50FF 00001400
	v_add_nc_u32_e32 v50, 0x1800, v40                          // 0000000194DC: 4A6450FF 00001800
	s_wait_alu 0xfffd                                          // 0000000194E4: BF88FFFD
	v_add_co_ci_u32_e64 v39, null, 0, v35, vcc_lo              // 0000000194E8: D5207C27 01AA4680
	v_add_nc_u32_e32 v44, 0x1000, v40                          // 0000000194F0: 4A5850FF 00001000
	v_add_nc_u32_e32 v51, 0x1c00, v40                          // 0000000194F8: 4A6650FF 00001C00
	s_clause 0x11                                              // 000000019500: BF850011
	global_load_u8 v52, v41, s[0:1]                            // 000000019504: EE040000 00000034 00000029
	global_load_u8 v53, v42, s[0:1]                            // 000000019510: EE040000 00000035 0000002A
	global_load_u8 v54, v43, s[0:1]                            // 00000001951C: EE040000 00000036 0000002B
	global_load_u8 v55, v45, s[0:1]                            // 000000019528: EE040000 00000037 0000002D
	global_load_u8 v56, v50, s[0:1]                            // 000000019534: EE040000 00000038 00000032
	global_load_u8 v57, v51, s[0:1]                            // 000000019540: EE040000 00000039 00000033
	global_load_b64 v[46:47], v[38:39], off                    // 00000001954C: EE05407C 0000002E 00000026
	global_load_b64 v[48:49], v[38:39], off offset:16          // 000000019558: EE05407C 00000030 00001026
	global_load_u8 v58, v40, s[0:1]                            // 000000019564: EE040000 0000003A 00000028
	global_load_u8 v59, v40, s[0:1] offset:16                  // 000000019570: EE040000 0000003B 00001028
	global_load_u8 v60, v44, s[0:1] offset:16                  // 00000001957C: EE040000 0000003C 0000102C
	global_load_u8 v61, v44, s[0:1]                            // 000000019588: EE040000 0000003D 0000002C
	global_load_u8 v62, v43, s[0:1] offset:16                  // 000000019594: EE040000 0000003E 0000102B
	global_load_u8 v63, v42, s[0:1] offset:16                  // 0000000195A0: EE040000 0000003F 0000102A
	global_load_u8 v64, v41, s[0:1] offset:16                  // 0000000195AC: EE040000 00000040 00001029
	global_load_u8 v65, v51, s[0:1] offset:16                  // 0000000195B8: EE040000 00000041 00001033
	global_load_u8 v66, v50, s[0:1] offset:16                  // 0000000195C4: EE040000 00000042 00001032
	global_load_u8 v67, v45, s[0:1] offset:16                  // 0000000195D0: EE040000 00000043 0000102D
	v_dual_mov_b32 v50, 0 :: v_dual_mov_b32 v51, 0             // 0000000195DC: CA100080 32320080
	s_wait_loadcnt 0xb                                         // 0000000195E4: BFC0000B
	v_wmma_f32_16x16x16_fp8_fp8 v[38:45], v[46:47], v[28:29], 0// 0000000195E8: CC464026 1A02392E
	s_wait_loadcnt 0x9                                         // 0000000195F0: BFC00009
	v_lshl_or_b32 v46, v52, 8, v58                             // 0000000195F4: D656002E 04E91134
	s_delay_alu instid0(VALU_DEP_2)                            // 0000000195FC: BF870002
	v_wmma_f32_16x16x16_fp8_fp8 v[38:45], v[48:49], v[30:31], v[38:45]// 000000019600: CC464026 1C9A3D30
	v_lshlrev_b32_e32 v47, 16, v53                             // 000000019608: 305E6A90
	v_lshlrev_b32_e32 v52, 24, v54                             // 00000001960C: 30686C98
	s_wait_loadcnt 0x6                                         // 000000019610: BFC00006
	v_lshl_or_b32 v53, v55, 8, v61                             // 000000019614: D6560035 04F51137
	v_dual_mul_f32 v43, 0x3db76000, v43 :: v_dual_lshlrev_b32 v54, 16, v56// 00000001961C: C8E256FF 2B367090 3DB76000
	v_mul_f32_e32 v39, 0x3db76000, v39                         // 000000019628: 104E4EFF 3DB76000
	v_dual_mul_f32 v40, 0x3db76000, v40 :: v_dual_lshlrev_b32 v55, 24, v57// 000000019630: C8E250FF 28367298 3DB76000
	s_wait_loadcnt 0x3                                         // 00000001963C: BFC00003
	v_lshl_or_b32 v56, v64, 8, v59                             // 000000019640: D6560038 04ED1140
	v_dual_mul_f32 v42, 0x3db76000, v42 :: v_dual_lshlrev_b32 v57, 16, v63// 000000019648: C8E254FF 2A387E90 3DB76000
	s_wait_loadcnt 0x0                                         // 000000019654: BFC00000
	v_lshl_or_b32 v59, v67, 8, v60                             // 000000019658: D656003B 04F11143
	v_dual_add_f32 v39, 0x3fdac000, v39 :: v_dual_lshlrev_b32 v60, 16, v66// 000000019660: C9224EFF 273C8490 3FDAC000
	v_mul_f32_e32 v38, 0x3db76000, v38                         // 00000001966C: 104C4CFF 3DB76000
	v_dual_mul_f32 v45, 0x3db76000, v45 :: v_dual_lshlrev_b32 v58, 24, v62// 000000019674: C8E25AFF 2D3A7C98 3DB76000
	v_dual_mul_f32 v44, 0x3db76000, v44 :: v_dual_lshlrev_b32 v61, 24, v65// 000000019680: C8E258FF 2C3C8298 3DB76000
	v_mul_f32_e32 v41, 0x3db76000, v41                         // 00000001968C: 105252FF 3DB76000
	s_delay_alu instid0(VALU_DEP_4)                            // 000000019694: BF870004
	v_add_f32_e32 v38, 0x3fdac000, v38                         // 000000019698: 064C4CFF 3FDAC000
	v_dual_add_f32 v40, 0x3fdac000, v40 :: v_dual_add_f32 v43, 0x3fdac000, v43// 0000000196A0: C90850FF 282A56FF 3FDAC000
	v_dual_add_f32 v42, 0x3fdac000, v42 :: v_dual_add_f32 v45, 0x3fdac000, v45// 0000000196AC: C90854FF 2A2C5AFF 3FDAC000
	v_med3_num_f32 v39, v39, s7, 0x3ffd2000                    // 0000000196B8: D6310027 03FC0F27 3FFD2000
	v_add_f32_e32 v41, 0x3fdac000, v41                         // 0000000196C4: 065252FF 3FDAC000
	v_med3_num_f32 v38, v38, s7, 0x3ffd2000                    // 0000000196CC: D6310026 03FC0F26 3FFD2000
	v_med3_num_f32 v40, v40, s7, 0x3ffd2000                    // 0000000196D8: D6310028 03FC0F28 3FFD2000
	v_med3_num_f32 v42, v42, s7, 0x3ffd2000                    // 0000000196E4: D631002A 03FC0F2A 3FFD2000
	v_med3_num_f32 v43, v43, s7, 0x3ffd2000                    // 0000000196F0: D631002B 03FC0F2B 3FFD2000
	v_lshrrev_b32_e32 v39, 9, v39                              // 0000000196FC: 324E4E89
	v_add_f32_e32 v44, 0x3fdac000, v44                         // 000000019700: 065858FF 3FDAC000
	v_med3_num_f32 v41, v41, s7, 0x3ffd2000                    // 000000019708: D6310029 03FC0F29 3FFD2000
	v_med3_num_f32 v45, v45, s7, 0x3ffd2000                    // 000000019714: D631002D 03FC0F2D 3FFD2000
	v_lshrrev_b32_e32 v38, 9, v38                              // 000000019720: 324C4C89
	v_and_b32_e32 v39, -16, v39                                // 000000019724: 364E4ED0
	v_med3_num_f32 v44, v44, s7, 0x3ffd2000                    // 000000019728: D631002C 03FC0F2C 3FFD2000
	v_lshrrev_b32_e32 v40, 9, v40                              // 000000019734: 32505089
	v_lshrrev_b32_e32 v42, 9, v42                              // 000000019738: 32545489
	v_lshrrev_b32_e32 v43, 9, v43                              // 00000001973C: 32565689
	v_lshrrev_b32_e32 v41, 9, v41                              // 000000019740: 32525289
	v_lshrrev_b32_e32 v44, 9, v44                              // 000000019744: 32585889
	v_lshrrev_b32_e32 v45, 9, v45                              // 000000019748: 325A5A89
	v_and_b32_e32 v38, -16, v38                                // 00000001974C: 364C4CD0
	v_and_b32_e32 v40, -16, v40                                // 000000019750: 365050D0
	v_and_b32_e32 v42, -16, v42                                // 000000019754: 365454D0
	v_and_b32_e32 v43, -16, v43                                // 000000019758: 365656D0
	v_or3_b32 v46, v46, v47, v52                               // 00000001975C: D658002E 04D25F2E
	v_and_b32_e32 v41, -16, v41                                // 000000019764: 365252D0
	v_and_b32_e32 v44, -16, v44                                // 000000019768: 365858D0
	v_and_b32_e32 v45, -16, v45                                // 00000001976C: 365A5AD0
	v_add_nc_u16 v38, 0x4000, v38                              // 000000019770: D7030026 00024CFF 00004000
	v_add_nc_u16 v52, 0x4000, v39                              // 00000001977C: D7030034 00024EFF 00004000
	v_add_nc_u16 v39, 0x4000, v40                              // 000000019788: D7030027 000250FF 00004000
	v_add_nc_u16 v40, 0x4000, v42                              // 000000019794: D7030028 000254FF 00004000
	v_add_nc_u16 v42, 0x4000, v43                              // 0000000197A0: D703002A 000256FF 00004000
	v_or3_b32 v47, v53, v54, v55                               // 0000000197AC: D658002F 04DE6D35
	v_or3_b32 v48, v56, v57, v58                               // 0000000197B4: D6580030 04EA7338
	v_add_nc_u16 v53, 0x4000, v41                              // 0000000197BC: D7030035 000252FF 00004000
	v_add_nc_u16 v41, 0x4000, v44                              // 0000000197C8: D7030029 000258FF 00004000
	v_add_nc_u16 v43, 0x4000, v45                              // 0000000197D4: D703002B 00025AFF 00004000
	v_cvt_f32_f16_e32 v44, v38                                 // 0000000197E0: 7E581726
	v_cvt_f32_f16_e32 v45, v52                                 // 0000000197E4: 7E5A1734
	v_cvt_f32_f16_e32 v56, v40                                 // 0000000197E8: 7E701728
	v_cvt_f32_f16_e32 v57, v42                                 // 0000000197EC: 7E72172A
	v_or3_b32 v49, v59, v60, v61                               // 0000000197F0: D6580031 04F6793B
	v_cvt_f32_f16_e32 v54, v39                                 // 0000000197F8: 7E6C1727
	v_cvt_f32_f16_e32 v55, v53                                 // 0000000197FC: 7E6E1735
	v_cvt_f32_f16_e32 v58, v41                                 // 000000019800: 7E741729
	v_cvt_f32_f16_e32 v59, v43                                 // 000000019804: 7E76172B
	v_cvt_pk_fp8_f32 v50, v44, v45                             // 000000019808: D7690032 00025B2C
	v_cvt_pk_fp8_f32 v51, v56, v57                             // 000000019810: D7690033 00027338
	v_perm_b32 v41, v43, v41, 0x5040100                        // 000000019818: D6440029 03FE532B 05040100
	v_perm_b32 v40, v42, v40, 0x5040100                        // 000000019824: D6440028 03FE512A 05040100
	v_perm_b32 v39, v53, v39, 0x5040100                        // 000000019830: D6440027 03FE4F35 05040100
	v_perm_b32 v38, v52, v38, 0x5040100                        // 00000001983C: D6440026 03FE4D34 05040100
	v_cvt_pk_fp8_f32 v50, v54, v55 op_sel:[0,0,1]              // 000000019848: D7694032 00026F36
	v_cvt_pk_fp8_f32 v51, v58, v59 op_sel:[0,0,1]              // 000000019850: D7694033 0002773A
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000019858: BF870113
	v_wmma_f32_16x16x16_f16 v[16:23], v[24:27], v[38:41], v[16:23]// 00000001985C: CC404010 1C424D18
	v_wmma_f32_16x16x16_fp8_fp8 v[8:15], v[46:47], v[50:51], v[8:15]// 000000019864: CC464008 1C22652E
	v_wmma_f32_16x16x16_fp8_fp8 v[0:7], v[48:49], v[50:51], v[0:7]// 00000001986C: CC464000 1C026530
	s_cbranch_scc1 65288                                       // 000000019874: BFA2FF08 <vit_attention_fused_640_bytein_bout+0x198>
	s_delay_alu instid0(VALU_DEP_3)                            // 000000019878: BF870003
	v_div_scale_f32 v17, null, v16, v16, 1.0                   // 00000001987C: D6FC7C11 03CA2110
	v_div_scale_f32 v20, vcc_lo, 1.0, v16, 1.0                 // 000000019884: D6FC6A14 03CA20F2
	s_mov_b32 s0, 0xc3e00000                                   // 00000001988C: BE8000FF C3E00000
	v_rcp_f32_e32 v18, v17                                     // 000000019894: 7E245511
	v_dual_mov_b32 v25, 0 :: v_dual_mov_b32 v26, 0             // 000000019898: CA100080 191A0080
	v_dual_mov_b32 v23, 0 :: v_dual_mov_b32 v24, 0             // 0000000198A0: CA100080 17180080
	v_mov_b32_e32 v22, 0                                       // 0000000198A8: 7E2C0280
	v_mov_b32_e32 v28, 0                                       // 0000000198AC: 7E380280
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000198B0: BF870095
	v_fma_f32 v19, -v17, v18, 1.0                              // 0000000198B4: D6130013 23CA2511
	v_fmac_f32_e32 v18, v19, v18                               // 0000000198BC: 56242513
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000000198C0: BF870091
	v_mul_f32_e32 v19, v20, v18                                // 0000000198C4: 10262514
	v_fma_f32 v21, -v17, v19, v20                              // 0000000198C8: D6130015 24522711
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000198D0: BF870121
	v_fmac_f32_e32 v19, v21, v18                               // 0000000198D4: 56262515
	v_mov_b32_e32 v21, 0                                       // 0000000198D8: 7E2A0280
	v_fma_f32 v17, -v17, v19, v20                              // 0000000198DC: D6130011 24522711
	v_mov_b32_e32 v20, 0                                       // 0000000198E4: 7E280280
	s_wait_alu 0xfffd                                          // 0000000198E8: BF88FFFD
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 0000000198EC: BF870122
	v_div_fmas_f32 v17, v17, v18, v19                          // 0000000198F0: D6370011 044E2511
	v_dual_mov_b32 v18, 0 :: v_dual_mov_b32 v19, 0             // 0000000198F8: CA100080 12120080
	v_div_fixup_f32 v16, v17, v16, 1.0                         // 000000019900: D6270010 03CA2111
	v_mov_b32_e32 v27, 0                                       // 000000019908: 7E360280
	v_mov_b32_e32 v29, 0                                       // 00000001990C: 7E3A0280
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000019910: BF8700B3
	v_dual_mov_b32 v17, 0 :: v_dual_mul_f32 v8, v8, v16        // 000000019914: CA060080 11082108
	v_cvt_pk_rtz_f16_f32_e32 v8, v8, v8                        // 00000001991C: 5E101108
	v_cvt_f32_f16_e32 v8, v8                                   // 000000019920: 7E101708
	v_max_num_f32_e32 v30, v8, v8                              // 000000019924: 2C3C1108
	v_mul_f32_e32 v10, v10, v16                                // 000000019928: 1014210A
	v_cvt_pk_rtz_f16_f32_e32 v10, v10, v10                     // 00000001992C: 5E14150A
	v_cvt_f32_f16_e32 v10, v10                                 // 000000019930: 7E14170A
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000019934: BF8700B1
	v_dual_mul_f32 v9, v9, v16 :: v_dual_max_num_f32 v34, v10, v10// 000000019938: C8D42109 0922150A
	v_cvt_pk_rtz_f16_f32_e32 v9, v9, v9                        // 000000019940: 5E121309
	v_cvt_f32_f16_e32 v9, v9                                   // 000000019944: 7E121709
	v_dual_mul_f32 v12, v12, v16 :: v_dual_max_num_f32 v31, v9, v9// 000000019948: C8D4210C 0C1E1309
	v_med3_num_f32 v30, v30, s0, 0x43e00000                    // 000000019950: D631001E 03FC011E 43E00000
	v_mul_f32_e32 v14, v14, v16                                // 00000001995C: 101C210E
	v_cvt_pk_rtz_f16_f32_e32 v14, v14, v14                     // 000000019960: 5E1C1D0E
	v_cvt_f32_f16_e32 v14, v14                                 // 000000019964: 7E1C170E
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 000000019968: BF8700B1
	v_dual_mul_f32 v11, v11, v16 :: v_dual_max_num_f32 v38, v14, v14// 00000001996C: C8D4210B 0B261D0E
	v_cvt_pk_rtz_f16_f32_e32 v11, v11, v11                     // 000000019974: 5E16170B
	v_cvt_f32_f16_e32 v11, v11                                 // 000000019978: 7E16170B
	v_max_num_f32_e32 v35, v11, v11                            // 00000001997C: 2C46170B
	v_med3_num_f32 v31, v31, s0, 0x43e00000                    // 000000019980: D631001F 03FC011F 43E00000
	v_cvt_pk_fp8_f32 v22, v30, 0                               // 00000001998C: D7690016 0001011E
	v_cmp_neq_f32_e32 vcc_lo, 0, v8                            // 000000019994: 7C3A1080
	v_med3_num_f32 v34, v34, s0, 0x43e00000                    // 000000019998: D6310022 03FC0122 43E00000
	v_med3_num_f32 v35, v35, s0, 0x43e00000                    // 0000000199A4: D6310023 03FC0123 43E00000
	v_cvt_pk_fp8_f32 v20, v31, 0                               // 0000000199B0: D7690014 0001011F
	v_cvt_f32_fp8_e32 v22, v22                                 // 0000000199B8: 7E2CD916
	v_mul_f32_e32 v13, v13, v16                                // 0000000199BC: 101A210D
	v_cvt_pk_fp8_f32 v18, v34, 0                               // 0000000199C0: D7690012 00010122
	v_cvt_pk_fp8_f32 v25, v35, 0                               // 0000000199C8: D7690019 00010123
	v_cvt_f32_fp8_e32 v20, v20                                 // 0000000199D0: 7E28D914
	s_wait_alu 0xfffd                                          // 0000000199D4: BF88FFFD
	v_cndmask_b32_e32 v8, 0, v22, vcc_lo                       // 0000000199D8: 02102C80
	v_cmp_neq_f32_e32 vcc_lo, 0, v9                            // 0000000199DC: 7C3A1280
	v_cvt_f32_fp8_e32 v18, v18                                 // 0000000199E0: 7E24D912
	v_cvt_f32_fp8_e32 v25, v25                                 // 0000000199E4: 7E32D919
	v_cvt_pk_rtz_f16_f32_e32 v12, v12, v12                     // 0000000199E8: 5E18190C
	v_cvt_pk_fp8_f32 v23, v8, 0                                // 0000000199EC: D7690017 00010108
	s_wait_alu 0xfffd                                          // 0000000199F4: BF88FFFD
	v_cndmask_b32_e32 v9, 0, v20, vcc_lo                       // 0000000199F8: 02122880
	v_cmp_neq_f32_e32 vcc_lo, 0, v11                           // 0000000199FC: 7C3A1680
	v_cvt_f32_f16_e32 v12, v12                                 // 000000019A00: 7E18170C
	v_cvt_pk_rtz_f16_f32_e32 v13, v13, v13                     // 000000019A04: 5E1A1B0D
	v_cvt_f32_f16_e32 v13, v13                                 // 000000019A08: 7E1A170D
	v_max_num_f32_e32 v37, v13, v13                            // 000000019A0C: 2C4A1B0D
	s_wait_alu 0xfffd                                          // 000000019A10: BF88FFFD
	v_cndmask_b32_e32 v11, 0, v25, vcc_lo                      // 000000019A14: 02163280
	v_cmp_neq_f32_e32 vcc_lo, 0, v10                           // 000000019A18: 7C3A1480
	v_mul_f32_e32 v15, v15, v16                                // 000000019A1C: 101E210F
	v_med3_num_f32 v30, v38, s0, 0x43e00000                    // 000000019A20: D631001E 03FC0126 43E00000
	v_med3_num_f32 v37, v37, s0, 0x43e00000                    // 000000019A2C: D6310025 03FC0125 43E00000
	v_mul_f32_e32 v2, v2, v16                                  // 000000019A38: 10042102
	s_wait_alu 0xfffd                                          // 000000019A3C: BF88FFFD
	v_cndmask_b32_e32 v10, 0, v18, vcc_lo                      // 000000019A40: 02142480
	v_cvt_pk_rtz_f16_f32_e32 v15, v15, v15                     // 000000019A44: 5E1E1F0F
	v_cvt_f32_f16_e32 v15, v15                                 // 000000019A48: 7E1E170F
	v_dual_max_num_f32 v36, v12, v12 :: v_dual_max_num_f32 v39, v15, v15// 000000019A4C: CA94190C 24261F0F
	v_cmp_neq_f32_e32 vcc_lo, 0, v12                           // 000000019A54: 7C3A1880
	v_cvt_pk_fp8_f32 v19, v10, 0                               // 000000019A58: D7690013 0001010A
	v_and_b32_e32 v10, 0xff, v23                               // 000000019A60: 36142EFF 000000FF
	s_delay_alu instid0(VALU_DEP_4)                            // 000000019A68: BF870004
	v_med3_num_f32 v36, v36, s0, 0x43e00000                    // 000000019A6C: D6310024 03FC0124 43E00000
	v_cvt_pk_fp8_f32 v24, v9, 0                                // 000000019A78: D7690018 00010109
	v_cvt_pk_fp8_f32 v28, v37, 0                               // 000000019A80: D769001C 00010125
	v_cvt_pk_fp8_f32 v29, v30, 0                               // 000000019A88: D769001D 0001011E
	v_mul_f32_e32 v0, v0, v16                                  // 000000019A90: 10002100
	v_cvt_pk_fp8_f32 v17, v36, 0                               // 000000019A94: D7690011 00010124
	v_lshlrev_b16 v9, 8, v24                                   // 000000019A9C: D7380009 00023088
	v_cvt_pk_rtz_f16_f32_e32 v0, v0, v0                        // 000000019AA4: 5E000100
	v_cvt_f32_fp8_e32 v12, v29                                 // 000000019AA8: 7E18D91D
	v_cvt_f32_f16_e32 v0, v0                                   // 000000019AAC: 7E001700
	v_cvt_f32_fp8_e32 v8, v17                                  // 000000019AB0: 7E10D911
	v_and_b32_e32 v17, 0xff, v19                               // 000000019AB4: 362226FF 000000FF
	v_or_b32_e32 v9, v10, v9                                   // 000000019ABC: 3812130A
	v_dual_mov_b32 v18, 0 :: v_dual_mul_f32 v3, v3, v16        // 000000019AC0: CA060080 12022103
	s_wait_alu 0xfffd                                          // 000000019AC8: BF88FFFD
	v_cndmask_b32_e32 v8, 0, v8, vcc_lo                        // 000000019ACC: 02101080
	v_cvt_pk_fp8_f32 v26, v11, 0                               // 000000019AD0: D769001A 0001010B
	v_cmp_neq_f32_e32 vcc_lo, 0, v13                           // 000000019AD8: 7C3A1A80
	v_med3_num_f32 v13, v39, s0, 0x43e00000                    // 000000019ADC: D631000D 03FC0127 43E00000
	v_cvt_pk_rtz_f16_f32_e32 v3, v3, v3                        // 000000019AE8: 5E060703
	v_cvt_pk_fp8_f32 v27, v8, 0                                // 000000019AEC: D769001B 00010108
	v_lshlrev_b16 v11, 8, v26                                  // 000000019AF4: D738000B 00023488
	v_and_b32_e32 v8, 0xffff, v9                               // 000000019AFC: 361012FF 0000FFFF
	v_cvt_f32_f16_e32 v3, v3                                   // 000000019B04: 7E061703
	v_dual_mov_b32 v19, 0 :: v_dual_mul_f32 v6, v6, v16        // 000000019B08: CA060080 13062106
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_4) | instid1(VALU_DEP_1)// 000000019B10: BF8700D3
	v_or_b32_e32 v10, v17, v11                                 // 000000019B14: 38141711
	v_cvt_f32_fp8_e32 v11, v28                                 // 000000019B18: 7E16D91C
	v_cvt_pk_rtz_f16_f32_e32 v6, v6, v6                        // 000000019B1C: 5E0C0D06
	v_cvt_f32_f16_e32 v6, v6                                   // 000000019B20: 7E0C1706
	s_wait_alu 0xfffd                                          // 000000019B24: BF88FFFD
	v_dual_cndmask_b32 v10, 0, v11 :: v_dual_lshlrev_b32 v9, 16, v10// 000000019B28: CA621680 0A081490
	v_mov_b32_e32 v11, 0                                       // 000000019B30: 7E160280
	v_cmp_neq_f32_e32 vcc_lo, 0, v14                           // 000000019B34: 7C3A1C80
	v_mov_b32_e32 v17, 0                                       // 000000019B38: 7E220280
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000019B3C: BF8701B3
	v_cvt_pk_fp8_f32 v11, v10, 0                               // 000000019B40: D769000B 0001010A
	s_wait_alu 0xfffd                                          // 000000019B48: BF88FFFD
	v_cndmask_b32_e32 v10, 0, v12, vcc_lo                      // 000000019B4C: 02141880
	v_cvt_pk_fp8_f32 v17, v13, 0                               // 000000019B50: D7690011 0001010D
	v_dual_max_num_f32 v12, v0, v0 :: v_dual_mov_b32 v13, 0    // 000000019B58: CA900100 0C0C0080
	v_lshlrev_b16 v11, 8, v11                                  // 000000019B60: D738000B 00021688
	v_cmp_neq_f32_e32 vcc_lo, 0, v15                           // 000000019B68: 7C3A1E80
	s_delay_alu instid0(VALU_DEP_4)                            // 000000019B6C: BF870004
	v_cvt_f32_fp8_e32 v14, v17                                 // 000000019B70: 7E1CD911
	v_and_b32_e32 v17, 0xff, v27                               // 000000019B74: 362236FF 000000FF
	v_med3_num_f32 v12, v12, s0, 0x43e00000                    // 000000019B7C: D631000C 03FC010C 43E00000
	v_mov_b32_e32 v15, 0                                       // 000000019B88: 7E1E0280
	v_cvt_pk_fp8_f32 v13, v10, 0                               // 000000019B8C: D769000D 0001010A
	s_wait_alu 0xfffd                                          // 000000019B94: BF88FFFD
	v_cndmask_b32_e32 v14, 0, v14, vcc_lo                      // 000000019B98: 021C1C80
	v_or_b32_e32 v11, v17, v11                                 // 000000019B9C: 38161711
	v_cvt_pk_fp8_f32 v18, v12, 0                               // 000000019BA0: D7690012 0001010C
	v_mul_f32_e32 v1, v1, v16                                  // 000000019BA8: 10022101
	v_cmp_neq_f32_e32 vcc_lo, 0, v0                            // 000000019BAC: 7C3A0080
	v_cvt_pk_fp8_f32 v15, v14, 0                               // 000000019BB0: D769000F 0001010E
	v_and_b32_e32 v10, 0xffff, v11                             // 000000019BB8: 361416FF 0000FFFF
	v_cvt_pk_rtz_f16_f32_e32 v1, v1, v1                        // 000000019BC0: 5E020301
	v_cvt_f32_fp8_e32 v11, v18                                 // 000000019BC4: 7E16D912
	v_cvt_f32_f16_e32 v1, v1                                   // 000000019BC8: 7E021701
	v_max_num_f32_e32 v12, v1, v1                              // 000000019BCC: 2C180301
	v_lshlrev_b16 v14, 8, v15                                  // 000000019BD0: D738000E 00021E88
	v_mov_b32_e32 v15, 0                                       // 000000019BD8: 7E1E0280
	v_cvt_pk_rtz_f16_f32_e32 v2, v2, v2                        // 000000019BDC: 5E040502
	s_wait_alu 0xfffd                                          // 000000019BE0: BF88FFFD
	v_cndmask_b32_e32 v0, 0, v11, vcc_lo                       // 000000019BE4: 02001680
	v_med3_num_f32 v11, v12, s0, 0x43e00000                    // 000000019BE8: D631000B 03FC010C 43E00000
	v_cvt_f32_f16_e32 v2, v2                                   // 000000019BF4: 7E041702
	v_dual_max_num_f32 v12, v2, v2 :: v_dual_max_num_f32 v17, v3, v3// 000000019BF8: CA940502 0C100703
	v_mov_b32_e32 v18, 0                                       // 000000019C00: 7E240280
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 000000019C04: BF870223
	v_cvt_pk_fp8_f32 v15, v11, 0                               // 000000019C08: D769000F 0001010B
	v_cmp_neq_f32_e32 vcc_lo, 0, v1                            // 000000019C10: 7C3A0280
	v_med3_num_f32 v12, v12, s0, 0x43e00000                    // 000000019C14: D631000C 03FC010C 43E00000
	v_med3_num_f32 v11, v17, s0, 0x43e00000                    // 000000019C20: D631000B 03FC0111 43E00000
	v_mov_b32_e32 v17, 0                                       // 000000019C2C: 7E220280
	v_cvt_pk_fp8_f32 v19, v0, 0                                // 000000019C30: D7690013 00010100
	s_delay_alu instid0(VALU_DEP_4)                            // 000000019C38: BF870004
	v_cvt_pk_fp8_f32 v18, v12, 0                               // 000000019C3C: D7690012 0001010C
	v_and_b32_e32 v12, 0xff, v13                               // 000000019C44: 36181AFF 000000FF
	v_cvt_f32_fp8_e32 v13, v15                                 // 000000019C4C: 7E1AD90F
	v_cvt_pk_fp8_f32 v17, v11, 0                               // 000000019C50: D7690011 0001010B
	v_mov_b32_e32 v11, 0                                       // 000000019C58: 7E160280
	v_cvt_f32_fp8_e32 v0, v18                                  // 000000019C5C: 7E00D912
	s_wait_alu 0xfffd                                          // 000000019C60: BF88FFFD
	v_dual_mov_b32 v18, 0 :: v_dual_cndmask_b32 v1, 0, v13     // 000000019C64: CA120080 12001A80
	v_cmp_neq_f32_e32 vcc_lo, 0, v2                            // 000000019C6C: 7C3A0480
	v_cvt_f32_fp8_e32 v13, v17                                 // 000000019C70: 7E1AD911
	s_wait_alu 0xfffd                                          // 000000019C74: BF88FFFD
	v_cndmask_b32_e32 v0, 0, v0, vcc_lo                        // 000000019C78: 02000080
	v_cmp_neq_f32_e32 vcc_lo, 0, v3                            // 000000019C7C: 7C3A0680
	v_mul_f32_e32 v2, v4, v16                                  // 000000019C80: 10042104
	v_mov_b32_e32 v4, 0                                        // 000000019C84: 7E080280
	v_cvt_pk_fp8_f32 v11, v1, 0                                // 000000019C88: D769000B 00010101
	v_mul_f32_e32 v1, v5, v16                                  // 000000019C90: 10022105
	s_wait_alu 0xfffd                                          // 000000019C94: BF88FFFD
	v_cndmask_b32_e32 v3, 0, v13, vcc_lo                       // 000000019C98: 02061A80
	v_cvt_pk_rtz_f16_f32_e32 v2, v2, v2                        // 000000019C9C: 5E040502
	v_mov_b32_e32 v13, 0                                       // 000000019CA0: 7E1A0280
	v_cvt_f32_f16_e32 v2, v2                                   // 000000019CA4: 7E041702
	v_max_num_f32_e32 v15, v2, v2                              // 000000019CA8: 2C1E0502
	v_cvt_pk_fp8_f32 v4, v0, 0                                 // 000000019CAC: D7690004 00010100
	v_cvt_pk_rtz_f16_f32_e32 v1, v1, v1                        // 000000019CB4: 5E020301
	v_cvt_pk_fp8_f32 v13, v3, 0                                // 000000019CB8: D769000D 00010103
	v_mov_b32_e32 v3, 0                                        // 000000019CC0: 7E060280
	v_med3_num_f32 v0, v15, s0, 0x43e00000                     // 000000019CC4: D6310000 03FC010F 43E00000
	v_cvt_f32_f16_e32 v1, v1                                   // 000000019CD0: 7E021701
	v_cmp_neq_f32_e32 vcc_lo, 0, v2                            // 000000019CD4: 7C3A0480
	v_and_b32_e32 v15, 0xff, v19                               // 000000019CD8: 361E26FF 000000FF
	v_lshlrev_b16 v11, 8, v11                                  // 000000019CE0: D738000B 00021688
	v_cvt_pk_fp8_f32 v3, v0, 0                                 // 000000019CE8: D7690003 00010100
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 000000019CF0: BF8700A1
	v_cvt_f32_fp8_e32 v3, v3                                   // 000000019CF4: 7E06D903
	s_wait_alu 0xfffd                                          // 000000019CF8: BF88FFFD
	v_dual_max_num_f32 v5, v1, v1 :: v_dual_cndmask_b32 v2, 0, v3// 000000019CFC: CA920301 05020680
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 000000019D04: BF870131
	v_med3_num_f32 v0, v5, s0, 0x43e00000                      // 000000019D08: D6310000 03FC0105 43E00000
	v_dual_mul_f32 v5, v7, v16 :: v_dual_mov_b32 v16, 0        // 000000019D14: C8D02107 05100080
	v_cmp_neq_f32_e32 vcc_lo, 0, v1                            // 000000019D1C: 7C3A0280
	v_cvt_pk_fp8_f32 v16, v0, 0                                // 000000019D20: D7690010 00010100
	s_delay_alu instid0(VALU_DEP_1)                            // 000000019D28: BF870001
	v_cvt_f32_fp8_e32 v3, v16                                  // 000000019D2C: 7E06D910
	v_mov_b32_e32 v16, 0                                       // 000000019D30: 7E200280
	v_cvt_pk_rtz_f16_f32_e32 v5, v5, v5                        // 000000019D34: 5E0A0B05
	v_cvt_f32_f16_e32 v5, v5                                   // 000000019D38: 7E0A1705
	s_wait_alu 0xfffd                                          // 000000019D3C: BF88FFFD
	v_cndmask_b32_e32 v1, 0, v3, vcc_lo                        // 000000019D40: 02020680
	v_cmp_neq_f32_e32 vcc_lo, 0, v6                            // 000000019D44: 7C3A0C80
	v_max_num_f32_e32 v17, v5, v5                              // 000000019D48: 2C220B05
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 000000019D4C: BF8701A3
	v_cvt_pk_fp8_f32 v16, v1, 0                                // 000000019D50: D7690010 00010101
	v_and_b32_e32 v1, 0xff, v4                                 // 000000019D58: 360208FF 000000FF
	v_med3_num_f32 v0, v17, s0, 0x43e00000                     // 000000019D60: D6310000 03FC0111 43E00000
	v_mov_b32_e32 v17, 0                                       // 000000019D6C: 7E220280
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_2)// 000000019D70: BF870121
	v_cvt_pk_fp8_f32 v17, v0, 0                                // 000000019D74: D7690011 00010100
	v_mov_b32_e32 v0, 0                                        // 000000019D7C: 7E000280
	v_cvt_f32_fp8_e32 v3, v17                                  // 000000019D80: 7E06D911
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 000000019D84: BF8701B2
	v_cvt_pk_fp8_f32 v0, v2, 0                                 // 000000019D88: D7690000 00010102
	v_max_num_f32_e32 v7, v6, v6                               // 000000019D90: 2C0E0D06
	v_lshlrev_b16 v2, 8, v16                                   // 000000019D94: D7380002 00022088
	v_and_b32_e32 v0, 0xff, v0                                 // 000000019D9C: 360000FF 000000FF
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 000000019DA4: BF870113
	v_med3_num_f32 v7, v7, s0, 0x43e00000                      // 000000019DA8: D6310007 03FC0107 43E00000
	v_or_b32_e32 v0, v0, v2                                    // 000000019DB4: 38000500
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000019DB8: BF870092
	v_cvt_pk_fp8_f32 v18, v7, 0                                // 000000019DBC: D7690012 00010107
	v_cvt_f32_fp8_e32 v7, v18                                  // 000000019DC4: 7E0ED912
	s_wait_alu 0xfffd                                          // 000000019DC8: BF88FFFD
	s_delay_alu instid0(VALU_DEP_1)                            // 000000019DCC: BF870001
	v_cndmask_b32_e32 v6, 0, v7, vcc_lo                        // 000000019DD0: 020C0E80
	v_cmp_neq_f32_e32 vcc_lo, 0, v5                            // 000000019DD4: 7C3A0A80
	v_mov_b32_e32 v5, 0                                        // 000000019DD8: 7E0A0280
	v_lshlrev_b16 v7, 8, v13                                   // 000000019DDC: D7380007 00021A88
	s_wait_alu 0xfffd                                          // 000000019DE4: BF88FFFD
	v_cndmask_b32_e32 v3, 0, v3, vcc_lo                        // 000000019DE8: 02060680
	s_delay_alu instid0(VALU_DEP_3)                            // 000000019DEC: BF870003
	v_cvt_pk_fp8_f32 v5, v6, 0                                 // 000000019DF0: D7690005 00010106
	v_or_b32_e32 v6, v15, v11                                  // 000000019DF8: 380C170F
	v_or_b32_e32 v1, v1, v7                                    // 000000019DFC: 38020F01
	v_or3_b32 v11, v32, s4, v33                                // 000000019E00: D658000B 04840920
	v_cvt_pk_fp8_f32 v21, v3, 0                                // 000000019E08: D7690015 00010103
	v_and_b32_e32 v4, 0xff, v5                                 // 000000019E10: 36080AFF 000000FF
	v_or_b32_e32 v5, v12, v14                                  // 000000019E18: 380A1D0C
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000019E1C: BF870093
	v_lshlrev_b16 v3, 8, v21                                   // 000000019E20: D7380003 00022A88
	v_or_b32_e32 v2, v4, v3                                    // 000000019E28: 38040704
	s_delay_alu instid0(VALU_DEP_3)                            // 000000019E2C: BF870003
	v_lshlrev_b32_e32 v3, 16, v5                               // 000000019E30: 30060A90
	v_and_b32_e32 v4, 0xffff, v6                               // 000000019E34: 36080CFF 0000FFFF
	v_and_b32_e32 v6, 0xffff, v0                               // 000000019E3C: 360C00FF 0000FFFF
	v_lshlrev_b32_e32 v5, 16, v1                               // 000000019E44: 300A0290
	v_lshlrev_b32_e32 v7, 16, v2                               // 000000019E48: 300E0490
	v_or_b32_e32 v0, v8, v9                                    // 000000019E4C: 38001308
	v_or_b32_e32 v1, v10, v3                                   // 000000019E50: 3802070A
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000019E54: BF870214
	v_or_b32_e32 v2, v4, v5                                    // 000000019E58: 38040B04
	v_or_b32_e32 v3, v6, v7                                    // 000000019E5C: 38060F06
	s_clause 0x1                                               // 000000019E60: BF850001
	global_store_b64 v11, v[0:1], s[2:3]                       // 000000019E64: EE06C002 00000000 0000000B
	global_store_b64 v11, v[2:3], s[2:3] offset:16             // 000000019E70: EE06C002 01000000 0000100B
	s_endpgm                                                   // 000000019E7C: BFB00000
	s_nop 0                                                    // 000000019E80: BF800000
	s_nop 0                                                    // 000000019E84: BF800000
	s_nop 0                                                    // 000000019E88: BF800000
	s_nop 0                                                    // 000000019E8C: BF800000
	s_nop 0                                                    // 000000019E90: BF800000
	s_nop 0                                                    // 000000019E94: BF800000
	s_nop 0                                                    // 000000019E98: BF800000
	s_nop 0                                                    // 000000019E9C: BF800000
	s_nop 0                                                    // 000000019EA0: BF800000
	s_nop 0                                                    // 000000019EA4: BF800000
	s_nop 0                                                    // 000000019EA8: BF800000
	s_nop 0                                                    // 000000019EAC: BF800000
	s_nop 0                                                    // 000000019EB0: BF800000
	s_nop 0                                                    // 000000019EB4: BF800000
	s_nop 0                                                    // 000000019EB8: BF800000
	s_nop 0                                                    // 000000019EBC: BF800000
	s_nop 0                                                    // 000000019EC0: BF800000
	s_nop 0                                                    // 000000019EC4: BF800000
	s_nop 0                                                    // 000000019EC8: BF800000
	s_nop 0                                                    // 000000019ECC: BF800000
	s_nop 0                                                    // 000000019ED0: BF800000
	s_nop 0                                                    // 000000019ED4: BF800000
	s_nop 0                                                    // 000000019ED8: BF800000
	s_nop 0                                                    // 000000019EDC: BF800000
	s_nop 0                                                    // 000000019EE0: BF800000
	s_nop 0                                                    // 000000019EE4: BF800000
	s_nop 0                                                    // 000000019EE8: BF800000
	s_nop 0                                                    // 000000019EEC: BF800000
	s_nop 0                                                    // 000000019EF0: BF800000
	s_nop 0                                                    // 000000019EF4: BF800000
	s_nop 0                                                    // 000000019EF8: BF800000
	s_nop 0                                                    // 000000019EFC: BF800000
