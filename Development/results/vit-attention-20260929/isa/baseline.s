
/home/lmxxf/work/vit-attention-20260929/baseline/gfx1201/deep_fast-packed.hsaco:	file format elf64-amdgpu

Disassembly of section .text:

0000000000019d00 <vit_attention_fused_640_bytein_bout>:
	s_load_b64 s[2:3], s[0:1], 0x18                            // 000000019D00: F4002080 F8000018
	s_wait_kmcnt 0x0                                           // 000000019D08: BFC70000
	s_cmp_eq_u64 s[2:3], 0                                     // 000000019D0C: BF108002
	s_cselect_b32 s4, -1, 0                                    // 000000019D10: 980480C1
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000019D14: BF870009
	s_and_b32 vcc_lo, exec_lo, s4                              // 000000019D18: 8B6A047E
	s_cbranch_vccnz 5                                          // 000000019D1C: BFA40005 <vit_attention_fused_640_bytein_bout+0x34>
	s_load_b32 s2, s[2:3], 0x0                                 // 000000019D20: F4000081 F8000000
	s_wait_kmcnt 0x0                                           // 000000019D28: BFC70000
	s_cmp_eq_u32 s2, 0                                         // 000000019D2C: BF068002
	s_cselect_b32 s4, -1, 0                                    // 000000019D30: 980480C1
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000019D34: BF870009
	s_and_not1_b32 vcc_lo, exec_lo, s4                         // 000000019D38: 916A047E
	s_cbranch_vccnz 1383                                       // 000000019D3C: BFA40567 <vit_attention_fused_640_bytein_bout+0x15dc>
	s_load_b32 s2, s[0:1], 0x10                                // 000000019D40: F4000080 F8000010
	s_lshr_b32 s3, ttmp9, 1                                    // 000000019D48: 85038175
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000019D4C: BF870009
	s_and_b32 s10, s3, 0x7ffffff0                              // 000000019D50: 8B0AFF03 7FFFFFF0
	s_wait_kmcnt 0x0                                           // 000000019D58: BFC70000
	s_cmp_ge_u32 s10, s2                                       // 000000019D5C: BF09020A
	s_cbranch_scc1 1374                                        // 000000019D60: BFA2055E <vit_attention_fused_640_bytein_bout+0x15dc>
	s_load_b128 s[4:7], s[0:1], 0x0                            // 000000019D64: F4004100 F8000000
	v_lshrrev_b32_e32 v1, 1, v0                                // 000000019D6C: 32020081
	s_lshl_b32 s0, ttmp9, 5                                    // 000000019D70: 84008575
	s_mov_b32 s9, 0                                            // 000000019D74: BE890080
	s_and_b32 s8, s0, 0x3e0                                    // 000000019D78: 8B08FF00 000003E0
	v_mov_b32_e32 v16, 0                                       // 000000019D80: 7E200280
	v_and_b32_e32 v40, 15, v0                                  // 000000019D84: 3650008F
	v_and_b32_e32 v41, 8, v1                                   // 000000019D88: 36520288
	v_lshlrev_b32_e32 v0, 9, v0                                // 000000019D8C: 30000089
	s_mov_b32 s3, s9                                           // 000000019D90: BE830009
	v_mov_b32_e32 v19, v16                                     // 000000019D94: 7E260310
	v_mov_b32_e32 v17, v16                                     // 000000019D98: 7E220310
	v_or_b32_e32 v2, s10, v40                                  // 000000019D9C: 3804500A
	v_dual_mov_b32 v21, v16 :: v_dual_and_b32 v0, 0x2000, v0   // 000000019DA0: CA240110 150000FF 00002000
	v_mov_b32_e32 v32, 0x3c003c00                              // 000000019DAC: 7E4002FF 3C003C00
	v_dual_mov_b32 v20, v16 :: v_dual_mov_b32 v23, v16         // 000000019DB4: CA100110 14160110
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)// 000000019DBC: BF870214
	v_lshlrev_b32_e32 v1, 10, v2                               // 000000019DC0: 3002048A
	v_lshl_add_u32 v0, s2, 11, v0                              // 000000019DC4: D6460000 04011602
	s_wait_kmcnt 0x0                                           // 000000019DCC: BFC70000
	s_add_nc_u64 s[0:1], s[4:5], s[8:9]                        // 000000019DD0: A9800804
	v_dual_mov_b32 v22, v16 :: v_dual_mov_b32 v9, v16          // 000000019DD4: CA100110 16080110
	v_add_co_u32 v42, s0, s0, v41                              // 000000019DDC: D700002A 00025200
	s_wait_alu 0xf1ff                                          // 000000019DE4: BF88F1FF
	v_add_co_ci_u32_e64 v43, null, s1, 0, s0                   // 000000019DE8: D5207C2B 00010001
	v_or3_b32 v44, v0, s8, v40                                 // 000000019DF0: D658002C 04A01100
	v_add_co_u32 v1, vcc_lo, v42, v1                           // 000000019DF8: D7006A01 0002032A
	s_delay_alu instid0(VALU_DEP_1)                            // 000000019E00: BF870001
	v_add_co_ci_u32_e64 v2, null, 0, v43, vcc_lo               // 000000019E04: D5207C02 01AA5680
	v_dual_mov_b32 v8, v16 :: v_dual_mov_b32 v11, v16          // 000000019E0C: CA100110 080A0110
	s_clause 0x1                                               // 000000019E14: BF850001
	global_load_b64 v[36:37], v[1:2], off                      // 000000019E18: EE05407C 00000024 00000001
	global_load_b64 v[38:39], v[1:2], off offset:16            // 000000019E24: EE05407C 00000026 00001001
	v_dual_mov_b32 v18, v16 :: v_dual_lshlrev_b32 v1, 10, v40  // 000000019E30: CA220110 1200508A
	v_dual_mov_b32 v10, v16 :: v_dual_mov_b32 v13, v16         // 000000019E38: CA100110 0A0C0110
	v_dual_mov_b32 v12, v16 :: v_dual_mov_b32 v15, v16         // 000000019E40: CA100110 0C0E0110
	s_delay_alu instid0(VALU_DEP_3)                            // 000000019E48: BF870003
	v_lshl_add_u32 v45, s2, 10, v1                             // 000000019E4C: D646002D 04051402
	v_dual_mov_b32 v14, v16 :: v_dual_mov_b32 v1, v16          // 000000019E54: CA100110 0E000110
	v_dual_mov_b32 v0, v16 :: v_dual_mov_b32 v3, v16           // 000000019E5C: CA100110 00020110
	v_dual_mov_b32 v2, v16 :: v_dual_mov_b32 v5, v16           // 000000019E64: CA100110 02040110
	v_dual_mov_b32 v4, v16 :: v_dual_mov_b32 v7, v16           // 000000019E6C: CA100110 04060110
	v_mov_b32_e32 v6, v16                                      // 000000019E74: 7E0C0310
	s_mov_b32 s0, 0x3fb84000                                   // 000000019E78: BE8000FF 3FB84000
	s_mov_b32 s1, 0xc3e00000                                   // 000000019E80: BE8100FF C3E00000
	s_branch 205                                               // 000000019E88: BFA000CD <vit_attention_fused_640_bytein_bout+0x4c0>
	s_and_not1_saveexec_b32 s13, s13                           // 000000019E8C: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000019E90: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 000000019E94: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 000000019E98: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 000000019E9C: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 000000019EA0: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 000000019EA4: 8C7E0B7E
	v_dual_mov_b32 v68, 0 :: v_dual_add_nc_u32 v51, s9, v44    // 000000019EA8: CA200080 44325809
	v_perm_b32 v29, v29, v28, 0x5040100                        // 000000019EB0: D644001D 03FE391D 05040100
	v_perm_b32 v28, v27, v26, 0x5040100                        // 000000019EBC: D644001C 03FE351B 05040100
	v_perm_b32 v27, v25, v24, 0x5040100                        // 000000019EC8: D644001B 03FE3119 05040100
	s_delay_alu instid0(VALU_DEP_4)                            // 000000019ED4: BF870004
	v_dual_max_num_f32 v48, v48, v48 :: v_dual_add_nc_u32 v53, 0x400, v51// 000000019ED8: CAA06130 303466FF 00000400
	v_dual_max_num_f32 v24, v33, v33 :: v_dual_add_nc_u32 v55, 0xc00, v51// 000000019EE4: CAA04321 183666FF 00000C00
	v_dual_mov_b32 v67, 0 :: v_dual_add_nc_u32 v54, 0x800, v51 // 000000019EF0: CA200080 433666FF 00000800
	v_dual_max_num_f32 v49, v49, v49 :: v_dual_add_nc_u32 v56, 0x1000, v51// 000000019EFC: CAA06331 313866FF 00001000
	v_dual_max_num_f32 v26, v34, v34 :: v_dual_add_nc_u32 v57, 0x1400, v51// 000000019F08: CAA04522 1A3866FF 00001400
	v_dual_mov_b32 v69, 0 :: v_dual_add_nc_u32 v58, 0x1800, v51// 000000019F14: CA200080 453A66FF 00001800
	v_dual_mov_b32 v25, 0 :: v_dual_add_nc_u32 v64, 0x1c00, v51// 000000019F20: CA200080 194066FF 00001C00
	s_clause 0xf                                               // 000000019F2C: BF85000F
	global_load_u8 v52, v51, s[4:5]                            // 000000019F30: EE040004 00000034 00000033
	global_load_u8 v59, v53, s[4:5]                            // 000000019F3C: EE040004 0000003B 00000035
	global_load_u8 v60, v54, s[4:5]                            // 000000019F48: EE040004 0000003C 00000036
	global_load_u8 v61, v56, s[4:5]                            // 000000019F54: EE040004 0000003D 00000038
	global_load_u8 v62, v57, s[4:5]                            // 000000019F60: EE040004 0000003E 00000039
	global_load_u8 v63, v58, s[4:5]                            // 000000019F6C: EE040004 0000003F 0000003A
	global_load_u8 v65, v55, s[4:5] offset:16                  // 000000019F78: EE040004 00000041 00001037
	global_load_u8 v55, v55, s[4:5]                            // 000000019F84: EE040004 00000037 00000037
	global_load_u8 v54, v54, s[4:5] offset:16                  // 000000019F90: EE040004 00000036 00001036
	global_load_u8 v53, v53, s[4:5] offset:16                  // 000000019F9C: EE040004 00000035 00001035
	global_load_u8 v51, v51, s[4:5] offset:16                  // 000000019FA8: EE040004 00000033 00001033
	global_load_u8 v66, v64, s[4:5]                            // 000000019FB4: EE040004 00000042 00000040
	global_load_u8 v64, v64, s[4:5] offset:16                  // 000000019FC0: EE040004 00000040 00001040
	global_load_u8 v58, v58, s[4:5] offset:16                  // 000000019FCC: EE040004 0000003A 0000103A
	global_load_u8 v57, v57, s[4:5] offset:16                  // 000000019FD8: EE040004 00000039 00001039
	global_load_u8 v56, v56, s[4:5] offset:16                  // 000000019FE4: EE040004 00000038 00001038
	v_dual_max_num_f32 v47, v47, v47 :: v_dual_mov_b32 v34, 0  // 000000019FF0: CA905F2F 2F220080
	v_max_num_f32_e32 v35, v35, v35                            // 000000019FF8: 2C464723
	v_med3_num_f32 v26, v26, s1, 0x43e00000                    // 000000019FFC: D631001A 03FC031A 43E00000
	v_perm_b32 v30, v50, v30, 0x5040100                        // 00000001A008: D644001E 03FE3D32 05040100
	v_mov_b32_e32 v50, 0                                       // 00000001A014: 7E640280
	v_med3_num_f32 v48, v48, s1, 0x43e00000                    // 00000001A018: D6310030 03FC0330 43E00000
	v_med3_num_f32 v24, v24, s1, 0x43e00000                    // 00000001A024: D6310018 03FC0318 43E00000
	v_med3_num_f32 v35, v35, s1, 0x43e00000                    // 00000001A030: D6310023 03FC0323 43E00000
	v_cvt_pk_fp8_f32 v34, v26, 0                               // 00000001A03C: D7690022 0001011A
	v_dual_max_num_f32 v46, v46, v46 :: v_dual_max_num_f32 v31, v31, v31// 00000001A044: CA945D2E 2E1E3F1F
	v_mov_b32_e32 v33, v32                                     // 00000001A04C: 7E420320
	v_med3_num_f32 v47, v47, s1, 0x43e00000                    // 00000001A050: D631002F 03FC032F 43E00000
	v_med3_num_f32 v49, v49, s1, 0x43e00000                    // 00000001A05C: D6310031 03FC0331 43E00000
	v_cvt_pk_fp8_f32 v68, v48, 0                               // 00000001A068: D7690044 00010130
	v_cvt_pk_fp8_f32 v25, v24, 0                               // 00000001A070: D7690019 00010118
	v_lshlrev_b32_e32 v24, 8, v34                              // 00000001A078: 30304488
	v_cvt_pk_fp8_f32 v50, v35, 0                               // 00000001A07C: D7690032 00010123
	v_dual_mov_b32 v70, 0 :: v_dual_mov_b32 v71, 0             // 00000001A084: CA100080 46460080
	v_med3_num_f32 v26, v46, s1, 0x43e00000                    // 00000001A08C: D631001A 03FC032E 43E00000
	v_cvt_pk_fp8_f32 v67, v47, 0                               // 00000001A098: D7690043 0001012F
	v_cvt_pk_fp8_f32 v69, v49, 0                               // 00000001A0A0: D7690045 00010131
	v_lshlrev_b32_e32 v34, 8, v68                              // 00000001A0A8: 30448888
	v_lshlrev_b32_e32 v35, 16, v50                             // 00000001A0AC: 30466490
	v_perm_b32 v24, v24, v25, 0xc0c0500                        // 00000001A0B0: D6440018 03FE3318 0C0C0500
	v_med3_num_f32 v25, v31, s1, 0x43e00000                    // 00000001A0BC: D6310019 03FC031F 43E00000
	v_cvt_pk_fp8_f32 v70, v26, 0                               // 00000001A0C8: D7690046 0001011A
	v_lshlrev_b32_e32 v26, 16, v69                             // 00000001A0D0: 30348A90
	s_add_co_i32 s3, s3, 16                                    // 00000001A0D4: 81039003
	v_and_or_b32 v24, 0xff0000, v35, v24                       // 00000001A0D8: D6570018 046246FF 00FF0000
	v_mov_b32_e32 v35, v32                                     // 00000001A0E4: 7E460320
	v_perm_b32 v31, v34, v67, 0xc0c0500                        // 00000001A0E8: D644001F 03FE8722 0C0C0500
	v_mov_b32_e32 v34, v32                                     // 00000001A0F4: 7E440320
	v_cvt_pk_fp8_f32 v71, v25, 0                               // 00000001A0F8: D7690047 00010119
	v_lshl_or_b32 v24, v70, 24, v24                            // 00000001A100: D6560018 04613146
	s_addk_co_i32 s9, 0x4000                                   // 00000001A108: B7894000
	v_and_or_b32 v25, 0xff0000, v26, v31                       // 00000001A10C: D6570019 047E34FF 00FF0000
	v_wmma_f32_16x16x16_f16 v[16:23], v[27:30], v[32:35], v[16:23]// 00000001A118: CC404010 1C42411B
	s_wait_alu 0xfffe                                          // 00000001A120: BF88FFFE
	s_cmp_ge_u32 s3, s2                                        // 00000001A124: BF090203
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A128: BF870002
	v_lshl_or_b32 v25, v71, 24, v25                            // 00000001A12C: D6560019 04653147
	s_wait_loadcnt 0x8                                         // 00000001A134: BFC00008
	v_lshlrev_b32_e32 v46, 24, v55                             // 00000001A138: 305C6E98
	s_wait_loadcnt 0x5                                         // 00000001A13C: BFC00005
	v_lshl_or_b32 v50, v53, 8, v51                             // 00000001A140: D6560032 04CD1135
	v_lshlrev_b32_e32 v31, 16, v60                             // 00000001A148: 303E7890
	s_wait_loadcnt 0x4                                         // 00000001A14C: BFC00004
	v_lshlrev_b32_e32 v49, 24, v66                             // 00000001A150: 30628498
	v_lshl_or_b32 v26, v59, 8, v52                             // 00000001A154: D656001A 04D1113B
	v_lshl_or_b32 v47, v62, 8, v61                             // 00000001A15C: D656002F 04F5113E
	v_lshlrev_b32_e32 v48, 16, v63                             // 00000001A164: 30607E90
	v_lshlrev_b32_e32 v51, 16, v54                             // 00000001A168: 30666C90
	v_lshlrev_b32_e32 v52, 24, v65                             // 00000001A16C: 30688298
	s_wait_loadcnt 0x0                                         // 00000001A170: BFC00000
	v_lshl_or_b32 v53, v57, 8, v56                             // 00000001A174: D6560035 04E11139
	v_lshlrev_b32_e32 v54, 16, v58                             // 00000001A17C: 306C7490
	v_lshlrev_b32_e32 v55, 24, v64                             // 00000001A180: 306E8098
	v_or3_b32 v46, v26, v31, v46                               // 00000001A184: D658002E 04BA3F1A
	v_or3_b32 v47, v47, v48, v49                               // 00000001A18C: D658002F 04C6612F
	v_or3_b32 v48, v50, v51, v52                               // 00000001A194: D6580030 04D26732
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000001A19C: BF870194
	v_or3_b32 v49, v53, v54, v55                               // 00000001A1A0: D6580031 04DE6D35
	v_wmma_f32_16x16x16_fp8_fp8 v[8:15], v[24:25], v[46:47], v[8:15]// 00000001A1A8: CC464008 1C225D18
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A1B0: BF870002
	v_wmma_f32_16x16x16_fp8_fp8 v[0:7], v[24:25], v[48:49], v[0:7]// 00000001A1B4: CC464000 1C026118
	s_cbranch_scc1 577                                         // 00000001A1BC: BFA20241 <vit_attention_fused_640_bytein_bout+0xdc4>
	s_wait_alu 0xfffe                                          // 00000001A1C0: BF88FFFE
	v_add_nc_u32_e32 v24, s9, v45                              // 00000001A1C4: 4A305A09
	s_mov_b32 s11, exec_lo                                     // 00000001A1C8: BE8B007E
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A1CC: BF870001
	v_add_co_u32 v24, vcc_lo, v42, v24                         // 00000001A1D0: D7006A18 0002312A
	s_wait_alu 0xfffd                                          // 00000001A1D8: BF88FFFD
	v_add_co_ci_u32_e64 v25, null, 0, v43, vcc_lo              // 00000001A1DC: D5207C19 01AA5680
	s_clause 0x1                                               // 00000001A1E4: BF850001
	global_load_b64 v[33:34], v[24:25], off                    // 00000001A1E8: EE05407C 00000021 00000018
	global_load_b64 v[46:47], v[24:25], off offset:16          // 00000001A1F4: EE05407C 0000002E 00001018
	s_wait_loadcnt 0x1                                         // 00000001A200: BFC00001
	v_wmma_f32_16x16x16_fp8_fp8 v[24:31], v[33:34], v[36:37], 0// 00000001A204: CC464018 1A024921
	s_wait_loadcnt 0x0                                         // 00000001A20C: BFC00000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A210: BF870091
	v_wmma_f32_16x16x16_fp8_fp8 v[24:31], v[46:47], v[38:39], v[24:31]// 00000001A214: CC464018 1C624D2E
	v_mul_f32_e32 v24, 0x3db76000, v24                         // 00000001A21C: 103030FF 3DB76000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A224: BF870091
	v_add_f32_e32 v24, 0x3fdac000, v24                         // 00000001A228: 063030FF 3FDAC000
	v_maxmin_num_f32 v24, v24, s0, 0x3ffd2000                  // 00000001A230: D6690018 03FC0118 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A23C: BF870091
	v_lshrrev_b32_e32 v24, 9, v24                              // 00000001A240: 32303089
	v_and_b32_e32 v24, -16, v24                                // 00000001A244: 363030D0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A248: BF870091
	v_add_nc_u16 v24, 0x4000, v24                              // 00000001A24C: D7030018 000230FF 00004000
	v_and_b32_e32 v34, 0xffff, v24                             // 00000001A258: 364430FF 0000FFFF
	v_bfe_i32 v33, v24, 0, 16                                  // 00000001A260: D6110021 02410118
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001A268: BF870112
	v_bfe_u32 v35, v34, 10, 5                                  // 00000001A26C: D6100023 02151522
	v_and_b32_e32 v33, 0x80000000, v33                         // 00000001A274: 364242FF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A27C: BF870002
	v_cmpx_lt_i32_e32 30, v35                                  // 00000001A280: 7D82469E
	s_wait_alu 0xfffe                                          // 00000001A284: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001A288: 8D0B0B7E
	v_lshlrev_b32_e32 v34, 13, v34                             // 00000001A28C: 3044448D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A290: BF870001
	v_or3_b32 v33, v33, v34, 0x7f800000                        // 00000001A294: D6580021 03FE4521 7F800000
	s_wait_alu 0xfffe                                          // 00000001A2A0: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001A2A4: BE8B300B
	s_cbranch_execz 31                                         // 00000001A2A8: BFA5001F <vit_attention_fused_640_bytein_bout+0x628>
	v_and_b32_e32 v46, 0x3f0, v34                              // 00000001A2AC: 365C44FF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001A2B4: BE8C007E
	v_cmpx_ne_u32_e32 0, v35                                   // 00000001A2B8: 7D9A4680
	s_xor_b32 s12, exec_lo, s12                                // 00000001A2BC: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A2C0: BF870092
	v_lshlrev_b32_e32 v34, 13, v46                             // 00000001A2C4: 30445C8D
	v_lshl_or_b32 v34, v35, 23, v34                            // 00000001A2C8: D6560022 04892F23
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A2D0: BF870001
	v_add3_u32 v33, v34, v33, 0x38000000                       // 00000001A2D4: D6550021 03FE4322 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001A2E0: BE8C300C
	s_cbranch_execz 14                                         // 00000001A2E4: BFA5000E <vit_attention_fused_640_bytein_bout+0x620>
	s_mov_b32 s13, exec_lo                                     // 00000001A2E8: BE8D007E
	v_cmpx_ne_u32_e32 0, v46                                   // 00000001A2EC: 7D9A5C80
	s_xor_b32 s13, exec_lo, s13                                // 00000001A2F0: 8D0D0D7E
	v_cvt_f32_u32_e32 v33, v46                                 // 00000001A2F4: 7E420D2E
	v_cmp_gt_i16_e32 vcc_lo, 0, v34                            // 00000001A2F8: 7C684480
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001A2FC: BF8700A2
	v_mul_f32_e32 v33, 0x33800000, v33                         // 00000001A300: 104242FF 33800000
	s_wait_alu 0xfffd                                          // 00000001A308: BF88FFFD
	v_cndmask_b32_e64 v33, v33, -v33, vcc_lo                   // 00000001A30C: D5010021 41AA4321
	s_and_not1_saveexec_b32 s13, s13                           // 00000001A314: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A318: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 00000001A31C: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A320: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 00000001A324: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 00000001A328: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 00000001A32C: 8C7E0B7E
	v_mul_f32_e32 v25, 0x3db76000, v25                         // 00000001A330: 103232FF 3DB76000
	s_mov_b32 s11, exec_lo                                     // 00000001A338: BE8B007E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A33C: BF870091
	v_add_f32_e32 v25, 0x3fdac000, v25                         // 00000001A340: 063232FF 3FDAC000
	v_maxmin_num_f32 v25, v25, s0, 0x3ffd2000                  // 00000001A348: D6690019 03FC0119 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A354: BF870091
	v_lshrrev_b32_e32 v25, 9, v25                              // 00000001A358: 32323289
	v_and_b32_e32 v25, -16, v25                                // 00000001A35C: 363232D0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A360: BF870091
	v_add_nc_u16 v25, 0x4000, v25                              // 00000001A364: D7030019 000232FF 00004000
	v_and_b32_e32 v35, 0xffff, v25                             // 00000001A370: 364632FF 0000FFFF
	v_bfe_i32 v34, v25, 0, 16                                  // 00000001A378: D6110022 02410119
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001A380: BF870112
	v_bfe_u32 v46, v35, 10, 5                                  // 00000001A384: D610002E 02151523
	v_and_b32_e32 v34, 0x80000000, v34                         // 00000001A38C: 364444FF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A394: BF870002
	v_cmpx_lt_i32_e32 30, v46                                  // 00000001A398: 7D825C9E
	s_wait_alu 0xfffe                                          // 00000001A39C: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001A3A0: 8D0B0B7E
	v_lshlrev_b32_e32 v35, 13, v35                             // 00000001A3A4: 3046468D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A3A8: BF870001
	v_or3_b32 v34, v34, v35, 0x7f800000                        // 00000001A3AC: D6580022 03FE4722 7F800000
	s_wait_alu 0xfffe                                          // 00000001A3B8: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001A3BC: BE8B300B
	s_cbranch_execz 31                                         // 00000001A3C0: BFA5001F <vit_attention_fused_640_bytein_bout+0x740>
	v_and_b32_e32 v47, 0x3f0, v35                              // 00000001A3C4: 365E46FF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001A3CC: BE8C007E
	v_cmpx_ne_u32_e32 0, v46                                   // 00000001A3D0: 7D9A5C80
	s_xor_b32 s12, exec_lo, s12                                // 00000001A3D4: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A3D8: BF870092
	v_lshlrev_b32_e32 v35, 13, v47                             // 00000001A3DC: 30465E8D
	v_lshl_or_b32 v35, v46, 23, v35                            // 00000001A3E0: D6560023 048D2F2E
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A3E8: BF870001
	v_add3_u32 v34, v35, v34, 0x38000000                       // 00000001A3EC: D6550022 03FE4523 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001A3F8: BE8C300C
	s_cbranch_execz 14                                         // 00000001A3FC: BFA5000E <vit_attention_fused_640_bytein_bout+0x738>
	s_mov_b32 s13, exec_lo                                     // 00000001A400: BE8D007E
	v_cmpx_ne_u32_e32 0, v47                                   // 00000001A404: 7D9A5E80
	s_xor_b32 s13, exec_lo, s13                                // 00000001A408: 8D0D0D7E
	v_cvt_f32_u32_e32 v34, v47                                 // 00000001A40C: 7E440D2F
	v_cmp_gt_i16_e32 vcc_lo, 0, v35                            // 00000001A410: 7C684680
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001A414: BF8700A2
	v_mul_f32_e32 v34, 0x33800000, v34                         // 00000001A418: 104444FF 33800000
	s_wait_alu 0xfffd                                          // 00000001A420: BF88FFFD
	v_cndmask_b32_e64 v34, v34, -v34, vcc_lo                   // 00000001A424: D5010022 41AA4522
	s_and_not1_saveexec_b32 s13, s13                           // 00000001A42C: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A430: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 00000001A434: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A438: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 00000001A43C: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 00000001A440: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 00000001A444: 8C7E0B7E
	v_mul_f32_e32 v26, 0x3db76000, v26                         // 00000001A448: 103434FF 3DB76000
	s_mov_b32 s11, exec_lo                                     // 00000001A450: BE8B007E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A454: BF870091
	v_add_f32_e32 v26, 0x3fdac000, v26                         // 00000001A458: 063434FF 3FDAC000
	v_maxmin_num_f32 v26, v26, s0, 0x3ffd2000                  // 00000001A460: D669001A 03FC011A 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A46C: BF870091
	v_lshrrev_b32_e32 v26, 9, v26                              // 00000001A470: 32343489
	v_and_b32_e32 v26, -16, v26                                // 00000001A474: 363434D0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A478: BF870091
	v_add_nc_u16 v26, 0x4000, v26                              // 00000001A47C: D703001A 000234FF 00004000
	v_and_b32_e32 v46, 0xffff, v26                             // 00000001A488: 365C34FF 0000FFFF
	v_bfe_i32 v35, v26, 0, 16                                  // 00000001A490: D6110023 0241011A
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001A498: BF870112
	v_bfe_u32 v47, v46, 10, 5                                  // 00000001A49C: D610002F 0215152E
	v_and_b32_e32 v35, 0x80000000, v35                         // 00000001A4A4: 364646FF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A4AC: BF870002
	v_cmpx_lt_i32_e32 30, v47                                  // 00000001A4B0: 7D825E9E
	s_wait_alu 0xfffe                                          // 00000001A4B4: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001A4B8: 8D0B0B7E
	v_lshlrev_b32_e32 v46, 13, v46                             // 00000001A4BC: 305C5C8D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A4C0: BF870001
	v_or3_b32 v35, v35, v46, 0x7f800000                        // 00000001A4C4: D6580023 03FE5D23 7F800000
	s_wait_alu 0xfffe                                          // 00000001A4D0: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001A4D4: BE8B300B
	s_cbranch_execz 31                                         // 00000001A4D8: BFA5001F <vit_attention_fused_640_bytein_bout+0x858>
	v_and_b32_e32 v48, 0x3f0, v46                              // 00000001A4DC: 36605CFF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001A4E4: BE8C007E
	v_cmpx_ne_u32_e32 0, v47                                   // 00000001A4E8: 7D9A5E80
	s_xor_b32 s12, exec_lo, s12                                // 00000001A4EC: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A4F0: BF870092
	v_lshlrev_b32_e32 v46, 13, v48                             // 00000001A4F4: 305C608D
	v_lshl_or_b32 v46, v47, 23, v46                            // 00000001A4F8: D656002E 04B92F2F
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A500: BF870001
	v_add3_u32 v35, v46, v35, 0x38000000                       // 00000001A504: D6550023 03FE472E 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001A510: BE8C300C
	s_cbranch_execz 14                                         // 00000001A514: BFA5000E <vit_attention_fused_640_bytein_bout+0x850>
	s_mov_b32 s13, exec_lo                                     // 00000001A518: BE8D007E
	v_cmpx_ne_u32_e32 0, v48                                   // 00000001A51C: 7D9A6080
	s_xor_b32 s13, exec_lo, s13                                // 00000001A520: 8D0D0D7E
	v_cvt_f32_u32_e32 v35, v48                                 // 00000001A524: 7E460D30
	v_cmp_gt_i16_e32 vcc_lo, 0, v46                            // 00000001A528: 7C685C80
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001A52C: BF8700A2
	v_mul_f32_e32 v35, 0x33800000, v35                         // 00000001A530: 104646FF 33800000
	s_wait_alu 0xfffd                                          // 00000001A538: BF88FFFD
	v_cndmask_b32_e64 v35, v35, -v35, vcc_lo                   // 00000001A53C: D5010023 41AA4723
	s_and_not1_saveexec_b32 s13, s13                           // 00000001A544: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A548: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 00000001A54C: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A550: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 00000001A554: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 00000001A558: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 00000001A55C: 8C7E0B7E
	v_mul_f32_e32 v27, 0x3db76000, v27                         // 00000001A560: 103636FF 3DB76000
	s_mov_b32 s11, exec_lo                                     // 00000001A568: BE8B007E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A56C: BF870091
	v_add_f32_e32 v27, 0x3fdac000, v27                         // 00000001A570: 063636FF 3FDAC000
	v_maxmin_num_f32 v27, v27, s0, 0x3ffd2000                  // 00000001A578: D669001B 03FC011B 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A584: BF870091
	v_lshrrev_b32_e32 v27, 9, v27                              // 00000001A588: 32363689
	v_and_b32_e32 v27, -16, v27                                // 00000001A58C: 363636D0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A590: BF870091
	v_add_nc_u16 v27, 0x4000, v27                              // 00000001A594: D703001B 000236FF 00004000
	v_and_b32_e32 v47, 0xffff, v27                             // 00000001A5A0: 365E36FF 0000FFFF
	v_bfe_i32 v46, v27, 0, 16                                  // 00000001A5A8: D611002E 0241011B
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001A5B0: BF870112
	v_bfe_u32 v48, v47, 10, 5                                  // 00000001A5B4: D6100030 0215152F
	v_and_b32_e32 v46, 0x80000000, v46                         // 00000001A5BC: 365C5CFF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A5C4: BF870002
	v_cmpx_lt_i32_e32 30, v48                                  // 00000001A5C8: 7D82609E
	s_wait_alu 0xfffe                                          // 00000001A5CC: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001A5D0: 8D0B0B7E
	v_lshlrev_b32_e32 v47, 13, v47                             // 00000001A5D4: 305E5E8D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A5D8: BF870001
	v_or3_b32 v46, v46, v47, 0x7f800000                        // 00000001A5DC: D658002E 03FE5F2E 7F800000
	s_wait_alu 0xfffe                                          // 00000001A5E8: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001A5EC: BE8B300B
	s_cbranch_execz 31                                         // 00000001A5F0: BFA5001F <vit_attention_fused_640_bytein_bout+0x970>
	v_and_b32_e32 v49, 0x3f0, v47                              // 00000001A5F4: 36625EFF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001A5FC: BE8C007E
	v_cmpx_ne_u32_e32 0, v48                                   // 00000001A600: 7D9A6080
	s_xor_b32 s12, exec_lo, s12                                // 00000001A604: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A608: BF870092
	v_lshlrev_b32_e32 v47, 13, v49                             // 00000001A60C: 305E628D
	v_lshl_or_b32 v47, v48, 23, v47                            // 00000001A610: D656002F 04BD2F30
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A618: BF870001
	v_add3_u32 v46, v47, v46, 0x38000000                       // 00000001A61C: D655002E 03FE5D2F 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001A628: BE8C300C
	s_cbranch_execz 14                                         // 00000001A62C: BFA5000E <vit_attention_fused_640_bytein_bout+0x968>
	s_mov_b32 s13, exec_lo                                     // 00000001A630: BE8D007E
	v_cmpx_ne_u32_e32 0, v49                                   // 00000001A634: 7D9A6280
	s_xor_b32 s13, exec_lo, s13                                // 00000001A638: 8D0D0D7E
	v_cvt_f32_u32_e32 v46, v49                                 // 00000001A63C: 7E5C0D31
	v_cmp_gt_i16_e32 vcc_lo, 0, v47                            // 00000001A640: 7C685E80
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001A644: BF8700A2
	v_mul_f32_e32 v46, 0x33800000, v46                         // 00000001A648: 105C5CFF 33800000
	s_wait_alu 0xfffd                                          // 00000001A650: BF88FFFD
	v_cndmask_b32_e64 v46, v46, -v46, vcc_lo                   // 00000001A654: D501002E 41AA5D2E
	s_and_not1_saveexec_b32 s13, s13                           // 00000001A65C: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A660: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 00000001A664: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A668: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 00000001A66C: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 00000001A670: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 00000001A674: 8C7E0B7E
	v_mul_f32_e32 v28, 0x3db76000, v28                         // 00000001A678: 103838FF 3DB76000
	s_mov_b32 s11, exec_lo                                     // 00000001A680: BE8B007E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A684: BF870091
	v_add_f32_e32 v28, 0x3fdac000, v28                         // 00000001A688: 063838FF 3FDAC000
	v_maxmin_num_f32 v28, v28, s0, 0x3ffd2000                  // 00000001A690: D669001C 03FC011C 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A69C: BF870091
	v_lshrrev_b32_e32 v28, 9, v28                              // 00000001A6A0: 32383889
	v_and_b32_e32 v28, -16, v28                                // 00000001A6A4: 363838D0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A6A8: BF870091
	v_add_nc_u16 v28, 0x4000, v28                              // 00000001A6AC: D703001C 000238FF 00004000
	v_and_b32_e32 v48, 0xffff, v28                             // 00000001A6B8: 366038FF 0000FFFF
	v_bfe_i32 v47, v28, 0, 16                                  // 00000001A6C0: D611002F 0241011C
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001A6C8: BF870112
	v_bfe_u32 v49, v48, 10, 5                                  // 00000001A6CC: D6100031 02151530
	v_and_b32_e32 v47, 0x80000000, v47                         // 00000001A6D4: 365E5EFF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A6DC: BF870002
	v_cmpx_lt_i32_e32 30, v49                                  // 00000001A6E0: 7D82629E
	s_wait_alu 0xfffe                                          // 00000001A6E4: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001A6E8: 8D0B0B7E
	v_lshlrev_b32_e32 v48, 13, v48                             // 00000001A6EC: 3060608D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A6F0: BF870001
	v_or3_b32 v47, v47, v48, 0x7f800000                        // 00000001A6F4: D658002F 03FE612F 7F800000
	s_wait_alu 0xfffe                                          // 00000001A700: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001A704: BE8B300B
	s_cbranch_execz 31                                         // 00000001A708: BFA5001F <vit_attention_fused_640_bytein_bout+0xa88>
	v_and_b32_e32 v50, 0x3f0, v48                              // 00000001A70C: 366460FF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001A714: BE8C007E
	v_cmpx_ne_u32_e32 0, v49                                   // 00000001A718: 7D9A6280
	s_xor_b32 s12, exec_lo, s12                                // 00000001A71C: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A720: BF870092
	v_lshlrev_b32_e32 v48, 13, v50                             // 00000001A724: 3060648D
	v_lshl_or_b32 v48, v49, 23, v48                            // 00000001A728: D6560030 04C12F31
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A730: BF870001
	v_add3_u32 v47, v48, v47, 0x38000000                       // 00000001A734: D655002F 03FE5F30 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001A740: BE8C300C
	s_cbranch_execz 14                                         // 00000001A744: BFA5000E <vit_attention_fused_640_bytein_bout+0xa80>
	s_mov_b32 s13, exec_lo                                     // 00000001A748: BE8D007E
	v_cmpx_ne_u32_e32 0, v50                                   // 00000001A74C: 7D9A6480
	s_xor_b32 s13, exec_lo, s13                                // 00000001A750: 8D0D0D7E
	v_cvt_f32_u32_e32 v47, v50                                 // 00000001A754: 7E5E0D32
	v_cmp_gt_i16_e32 vcc_lo, 0, v48                            // 00000001A758: 7C686080
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001A75C: BF8700A2
	v_mul_f32_e32 v47, 0x33800000, v47                         // 00000001A760: 105E5EFF 33800000
	s_wait_alu 0xfffd                                          // 00000001A768: BF88FFFD
	v_cndmask_b32_e64 v47, v47, -v47, vcc_lo                   // 00000001A76C: D501002F 41AA5F2F
	s_and_not1_saveexec_b32 s13, s13                           // 00000001A774: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A778: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 00000001A77C: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A780: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 00000001A784: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 00000001A788: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 00000001A78C: 8C7E0B7E
	v_mul_f32_e32 v29, 0x3db76000, v29                         // 00000001A790: 103A3AFF 3DB76000
	s_mov_b32 s11, exec_lo                                     // 00000001A798: BE8B007E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A79C: BF870091
	v_add_f32_e32 v29, 0x3fdac000, v29                         // 00000001A7A0: 063A3AFF 3FDAC000
	v_maxmin_num_f32 v29, v29, s0, 0x3ffd2000                  // 00000001A7A8: D669001D 03FC011D 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A7B4: BF870091
	v_lshrrev_b32_e32 v29, 9, v29                              // 00000001A7B8: 323A3A89
	v_and_b32_e32 v29, -16, v29                                // 00000001A7BC: 363A3AD0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A7C0: BF870091
	v_add_nc_u16 v29, 0x4000, v29                              // 00000001A7C4: D703001D 00023AFF 00004000
	v_and_b32_e32 v49, 0xffff, v29                             // 00000001A7D0: 36623AFF 0000FFFF
	v_bfe_i32 v48, v29, 0, 16                                  // 00000001A7D8: D6110030 0241011D
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001A7E0: BF870112
	v_bfe_u32 v50, v49, 10, 5                                  // 00000001A7E4: D6100032 02151531
	v_and_b32_e32 v48, 0x80000000, v48                         // 00000001A7EC: 366060FF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A7F4: BF870002
	v_cmpx_lt_i32_e32 30, v50                                  // 00000001A7F8: 7D82649E
	s_wait_alu 0xfffe                                          // 00000001A7FC: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001A800: 8D0B0B7E
	v_lshlrev_b32_e32 v49, 13, v49                             // 00000001A804: 3062628D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A808: BF870001
	v_or3_b32 v48, v48, v49, 0x7f800000                        // 00000001A80C: D6580030 03FE6330 7F800000
	s_wait_alu 0xfffe                                          // 00000001A818: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001A81C: BE8B300B
	s_cbranch_execz 31                                         // 00000001A820: BFA5001F <vit_attention_fused_640_bytein_bout+0xba0>
	v_and_b32_e32 v51, 0x3f0, v49                              // 00000001A824: 366662FF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001A82C: BE8C007E
	v_cmpx_ne_u32_e32 0, v50                                   // 00000001A830: 7D9A6480
	s_xor_b32 s12, exec_lo, s12                                // 00000001A834: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A838: BF870092
	v_lshlrev_b32_e32 v49, 13, v51                             // 00000001A83C: 3062668D
	v_lshl_or_b32 v49, v50, 23, v49                            // 00000001A840: D6560031 04C52F32
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A848: BF870001
	v_add3_u32 v48, v49, v48, 0x38000000                       // 00000001A84C: D6550030 03FE6131 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001A858: BE8C300C
	s_cbranch_execz 14                                         // 00000001A85C: BFA5000E <vit_attention_fused_640_bytein_bout+0xb98>
	s_mov_b32 s13, exec_lo                                     // 00000001A860: BE8D007E
	v_cmpx_ne_u32_e32 0, v51                                   // 00000001A864: 7D9A6680
	s_xor_b32 s13, exec_lo, s13                                // 00000001A868: 8D0D0D7E
	v_cvt_f32_u32_e32 v48, v51                                 // 00000001A86C: 7E600D33
	v_cmp_gt_i16_e32 vcc_lo, 0, v49                            // 00000001A870: 7C686280
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001A874: BF8700A2
	v_mul_f32_e32 v48, 0x33800000, v48                         // 00000001A878: 106060FF 33800000
	s_wait_alu 0xfffd                                          // 00000001A880: BF88FFFD
	v_cndmask_b32_e64 v48, v48, -v48, vcc_lo                   // 00000001A884: D5010030 41AA6130
	s_and_not1_saveexec_b32 s13, s13                           // 00000001A88C: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A890: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 00000001A894: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A898: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 00000001A89C: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 00000001A8A0: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 00000001A8A4: 8C7E0B7E
	v_mul_f32_e32 v30, 0x3db76000, v30                         // 00000001A8A8: 103C3CFF 3DB76000
	s_mov_b32 s11, exec_lo                                     // 00000001A8B0: BE8B007E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A8B4: BF870091
	v_add_f32_e32 v30, 0x3fdac000, v30                         // 00000001A8B8: 063C3CFF 3FDAC000
	v_maxmin_num_f32 v30, v30, s0, 0x3ffd2000                  // 00000001A8C0: D669001E 03FC011E 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A8CC: BF870091
	v_lshrrev_b32_e32 v30, 9, v30                              // 00000001A8D0: 323C3C89
	v_and_b32_e32 v30, -16, v30                                // 00000001A8D4: 363C3CD0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A8D8: BF870091
	v_add_nc_u16 v30, 0x4000, v30                              // 00000001A8DC: D703001E 00023CFF 00004000
	v_and_b32_e32 v50, 0xffff, v30                             // 00000001A8E8: 36643CFF 0000FFFF
	v_bfe_i32 v49, v30, 0, 16                                  // 00000001A8F0: D6110031 0241011E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001A8F8: BF870112
	v_bfe_u32 v51, v50, 10, 5                                  // 00000001A8FC: D6100033 02151532
	v_and_b32_e32 v49, 0x80000000, v49                         // 00000001A904: 366262FF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001A90C: BF870002
	v_cmpx_lt_i32_e32 30, v51                                  // 00000001A910: 7D82669E
	s_wait_alu 0xfffe                                          // 00000001A914: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001A918: 8D0B0B7E
	v_lshlrev_b32_e32 v50, 13, v50                             // 00000001A91C: 3064648D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A920: BF870001
	v_or3_b32 v49, v49, v50, 0x7f800000                        // 00000001A924: D6580031 03FE6531 7F800000
	s_wait_alu 0xfffe                                          // 00000001A930: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001A934: BE8B300B
	s_cbranch_execz 31                                         // 00000001A938: BFA5001F <vit_attention_fused_640_bytein_bout+0xcb8>
	v_and_b32_e32 v52, 0x3f0, v50                              // 00000001A93C: 366864FF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001A944: BE8C007E
	v_cmpx_ne_u32_e32 0, v51                                   // 00000001A948: 7D9A6680
	s_xor_b32 s12, exec_lo, s12                                // 00000001A94C: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A950: BF870092
	v_lshlrev_b32_e32 v50, 13, v52                             // 00000001A954: 3064688D
	v_lshl_or_b32 v50, v51, 23, v50                            // 00000001A958: D6560032 04C92F33
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001A960: BF870001
	v_add3_u32 v49, v50, v49, 0x38000000                       // 00000001A964: D6550031 03FE6332 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001A970: BE8C300C
	s_cbranch_execz 14                                         // 00000001A974: BFA5000E <vit_attention_fused_640_bytein_bout+0xcb0>
	s_mov_b32 s13, exec_lo                                     // 00000001A978: BE8D007E
	v_cmpx_ne_u32_e32 0, v52                                   // 00000001A97C: 7D9A6880
	s_xor_b32 s13, exec_lo, s13                                // 00000001A980: 8D0D0D7E
	v_cvt_f32_u32_e32 v49, v52                                 // 00000001A984: 7E620D34
	v_cmp_gt_i16_e32 vcc_lo, 0, v50                            // 00000001A988: 7C686480
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001A98C: BF8700A2
	v_mul_f32_e32 v49, 0x33800000, v49                         // 00000001A990: 106262FF 33800000
	s_wait_alu 0xfffd                                          // 00000001A998: BF88FFFD
	v_cndmask_b32_e64 v49, v49, -v49, vcc_lo                   // 00000001A99C: D5010031 41AA6331
	s_and_not1_saveexec_b32 s13, s13                           // 00000001A9A4: BE8D300D
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A9A8: BF870009
	s_or_b32 exec_lo, exec_lo, s13                             // 00000001A9AC: 8C7E0D7E
	s_delay_alu instid0(SALU_CYCLE_1)                          // 00000001A9B0: BF870009
	s_or_b32 exec_lo, exec_lo, s12                             // 00000001A9B4: 8C7E0C7E
	s_wait_alu 0xfffe                                          // 00000001A9B8: BF88FFFE
	s_or_b32 exec_lo, exec_lo, s11                             // 00000001A9BC: 8C7E0B7E
	v_mul_f32_e32 v31, 0x3db76000, v31                         // 00000001A9C0: 103E3EFF 3DB76000
	s_mov_b32 s11, exec_lo                                     // 00000001A9C8: BE8B007E
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A9CC: BF870091
	v_add_f32_e32 v31, 0x3fdac000, v31                         // 00000001A9D0: 063E3EFF 3FDAC000
	v_maxmin_num_f32 v31, v31, s0, 0x3ffd2000                  // 00000001A9D8: D669001F 03FC011F 3FFD2000
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A9E4: BF870091
	v_lshrrev_b32_e32 v31, 9, v31                              // 00000001A9E8: 323E3E89
	v_and_b32_e32 v31, -16, v31                                // 00000001A9EC: 363E3ED0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001A9F0: BF870091
	v_add_nc_u16 v50, 0x4000, v31                              // 00000001A9F4: D7030032 00023EFF 00004000
	v_and_b32_e32 v51, 0xffff, v50                             // 00000001AA00: 366664FF 0000FFFF
	v_bfe_i32 v31, v50, 0, 16                                  // 00000001AA08: D611001F 02410132
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001AA10: BF870112
	v_bfe_u32 v52, v51, 10, 5                                  // 00000001AA14: D6100034 02151533
	v_and_b32_e32 v31, 0x80000000, v31                         // 00000001AA1C: 363E3EFF 80000000
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001AA24: BF870002
	v_cmpx_lt_i32_e32 30, v52                                  // 00000001AA28: 7D82689E
	s_wait_alu 0xfffe                                          // 00000001AA2C: BF88FFFE
	s_xor_b32 s11, exec_lo, s11                                // 00000001AA30: 8D0B0B7E
	v_lshlrev_b32_e32 v51, 13, v51                             // 00000001AA34: 3066668D
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001AA38: BF870001
	v_or3_b32 v31, v31, v51, 0x7f800000                        // 00000001AA3C: D658001F 03FE671F 7F800000
	s_wait_alu 0xfffe                                          // 00000001AA48: BF88FFFE
	s_and_not1_saveexec_b32 s11, s11                           // 00000001AA4C: BE8B300B
	s_cbranch_execz 64787                                      // 00000001AA50: BFA5FD13 <vit_attention_fused_640_bytein_bout+0x1a0>
	v_and_b32_e32 v53, 0x3f0, v51                              // 00000001AA54: 366A66FF 000003F0
	s_mov_b32 s12, exec_lo                                     // 00000001AA5C: BE8C007E
	v_cmpx_ne_u32_e32 0, v52                                   // 00000001AA60: 7D9A6880
	s_xor_b32 s12, exec_lo, s12                                // 00000001AA64: 8D0C0C7E
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001AA68: BF870092
	v_lshlrev_b32_e32 v51, 13, v53                             // 00000001AA6C: 30666A8D
	v_lshl_or_b32 v51, v52, 23, v51                            // 00000001AA70: D6560033 04CD2F34
	s_delay_alu instid0(VALU_DEP_1)                            // 00000001AA78: BF870001
	v_add3_u32 v31, v51, v31, 0x38000000                       // 00000001AA7C: D655001F 03FE3F33 38000000
	s_and_not1_saveexec_b32 s12, s12                           // 00000001AA88: BE8C300C
	s_cbranch_execz 64770                                      // 00000001AA8C: BFA5FD02 <vit_attention_fused_640_bytein_bout+0x198>
	s_mov_b32 s13, exec_lo                                     // 00000001AA90: BE8D007E
	v_cmpx_ne_u32_e32 0, v53                                   // 00000001AA94: 7D9A6A80
	s_xor_b32 s13, exec_lo, s13                                // 00000001AA98: 8D0D0D7E
	s_cbranch_execz 64763                                      // 00000001AA9C: BFA5FCFB <vit_attention_fused_640_bytein_bout+0x18c>
	v_cvt_f32_u32_e32 v31, v53                                 // 00000001AAA0: 7E3E0D35
	v_cmp_gt_i16_e32 vcc_lo, 0, v51                            // 00000001AAA4: 7C686680
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001AAA8: BF8700A2
	v_mul_f32_e32 v31, 0x33800000, v31                         // 00000001AAAC: 103E3EFF 33800000
	s_wait_alu 0xfffd                                          // 00000001AAB4: BF88FFFD
	v_cndmask_b32_e64 v31, v31, -v31, vcc_lo                   // 00000001AAB8: D501001F 41AA3F1F
	s_branch 64754                                             // 00000001AAC0: BFA0FCF2 <vit_attention_fused_640_bytein_bout+0x18c>
	v_div_scale_f32 v24, null, v16, v16, 1.0                   // 00000001AAC4: D6FC7C18 03CA2110
	v_div_scale_f32 v25, null, v17, v17, 1.0                   // 00000001AACC: D6FC7C19 03CA2311
	v_div_scale_f32 v26, null, v18, v18, 1.0                   // 00000001AAD4: D6FC7C1A 03CA2512
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001AADC: BF870113
	v_rcp_f32_e32 v27, v24                                     // 00000001AAE0: 7E365518
	v_rcp_f32_e32 v28, v25                                     // 00000001AAE4: 7E385519
	v_div_scale_f32 v30, vcc_lo, 1.0, v16, 1.0                 // 00000001AAE8: D6FC6A1E 03CA20F2
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_3) | instid1(TRANS32_DEP_3)// 00000001AAF0: BF8703C2
	v_rcp_f32_e32 v29, v26                                     // 00000001AAF4: 7E3A551A
	v_div_scale_f32 v36, null, v19, v19, 1.0                   // 00000001AAF8: D6FC7C24 03CA2713
	v_div_scale_f32 v32, s1, 1.0, v18, 1.0                     // 00000001AB00: D6FC0120 03CA24F2
	v_div_scale_f32 v31, s0, 1.0, v17, 1.0                     // 00000001AB08: D6FC001F 03CA22F2
	v_fma_f32 v33, -v24, v27, 1.0                              // 00000001AB10: D6130021 23CA3718
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(SKIP_1) | instid1(TRANS32_DEP_1)// 00000001AB18: BF8702A6
	v_fma_f32 v34, -v25, v28, 1.0                              // 00000001AB1C: D6130022 23CA3919
	v_div_scale_f32 v38, null, v20, v20, 1.0                   // 00000001AB24: D6FC7C26 03CA2914
	v_fma_f32 v35, -v26, v29, 1.0                              // 00000001AB2C: D6130023 23CA3B1A
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 00000001AB34: BF8701A3
	v_dual_fmac_f32 v27, v33, v27 :: v_dual_fmac_f32 v28, v34, v28// 00000001AB38: C8003721 1B1C3922
	v_rcp_f32_e32 v33, v36                                     // 00000001AB40: 7E425524
	v_rcp_f32_e32 v44, v38                                     // 00000001AB44: 7E585526
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000001AB48: BF870091
	v_dual_fmac_f32 v29, v35, v29 :: v_dual_mul_f32 v34, v30, v27// 00000001AB4C: C8063B23 1D22371E
	v_fma_f32 v39, -v24, v34, v30                              // 00000001AB54: D6130027 247A4518
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_2)// 00000001AB5C: BF870312
	v_mul_f32_e32 v37, v32, v29                                // 00000001AB60: 104A3B20
	v_fma_f32 v45, -v36, v33, 1.0                              // 00000001AB64: D613002D 23CA4324
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000001AB6C: BF870193
	v_fmac_f32_e32 v34, v39, v27                               // 00000001AB70: 56443727
	v_fma_f32 v43, -v26, v37, v32                              // 00000001AB74: D613002B 24824B1A
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000001AB7C: BF870193
	v_fmac_f32_e32 v33, v45, v33                               // 00000001AB80: 5642432D
	v_fma_f32 v24, -v24, v34, v30                              // 00000001AB84: D6130018 247A4518
	v_div_scale_f32 v30, s2, 1.0, v19, 1.0                     // 00000001AB8C: D6FC021E 03CA26F2
	v_mul_f32_e32 v35, v31, v28                                // 00000001AB94: 1046391F
	s_wait_alu 0xfffd                                          // 00000001AB98: BF88FFFD
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 00000001AB9C: BF870133
	v_div_fmas_f32 v24, v24, v27, v34                          // 00000001ABA0: D6370018 048A3718
	s_mov_b32 vcc_lo, s0                                       // 00000001ABA8: BEEA0000
	v_div_scale_f32 v27, null, v21, v21, 1.0                   // 00000001ABAC: D6FC7C1B 03CA2B15
	v_div_fixup_f32 v16, v24, v16, 1.0                         // 00000001ABB4: D6270010 03CA2118
	v_mul_f32_e32 v24, v30, v33                                // 00000001ABBC: 1030431E
	v_fma_f32 v42, -v25, v35, v31                              // 00000001ABC0: D613002A 247E4719
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)// 00000001ABC8: BF8701A3
	v_mul_f32_e32 v0, v0, v16                                  // 00000001ABCC: 10002100
	v_mul_f32_e32 v8, v8, v16                                  // 00000001ABD0: 10102108
	v_fmac_f32_e32 v35, v42, v28                               // 00000001ABD4: 5646392A
	v_cvt_pk_rtz_f16_f32_e32 v8, v8, v8                        // 00000001ABD8: 5E101108
	v_cvt_f32_f16_e32 v8, v8                                   // 00000001ABDC: 7E101708
	v_mov_b32_e32 v16, 0                                       // 00000001ABE0: 7E200280
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 00000001ABE4: BF870132
	v_fma_f32 v25, -v25, v35, v31                              // 00000001ABE8: D6130019 247E4719
	v_fma_f32 v31, -v38, v44, 1.0                              // 00000001ABF0: D613001F 23CA5926
	s_wait_alu 0xfffe                                          // 00000001ABF8: BF88FFFE
	v_div_fmas_f32 v25, v25, v28, v35                          // 00000001ABFC: D6370019 048E3919
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_3)// 00000001AC04: BF8701B2
	v_fmac_f32_e32 v44, v31, v44                               // 00000001AC08: 5658591F
	v_div_scale_f32 v31, s0, 1.0, v20, 1.0                     // 00000001AC0C: D6FC001F 03CA28F2
	v_rcp_f32_e32 v28, v27                                     // 00000001AC14: 7E38551B
	v_div_fixup_f32 v17, v25, v17, 1.0                         // 00000001AC18: D6270011 03CA2319
	s_mov_b32 vcc_lo, s1                                       // 00000001AC20: BEEA0001
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)// 00000001AC24: BF8700A1
	v_dual_mul_f32 v34, v31, v44 :: v_dual_mul_f32 v9, v9, v17 // 00000001AC28: C8C6591F 22082309
	v_cvt_pk_rtz_f16_f32_e32 v9, v9, v9                        // 00000001AC30: 5E121309
	v_fma_f32 v25, -v38, v34, v31                              // 00000001AC34: D6130019 247E4526
	v_fmac_f32_e32 v37, v43, v29                               // 00000001AC3C: 564A3B2B
	s_delay_alu instid0(TRANS32_DEP_1)                         // 00000001AC40: BF870005
	v_fma_f32 v35, -v27, v28, 1.0                              // 00000001AC44: D6130023 23CA391B
	v_cvt_f32_f16_e32 v9, v9                                   // 00000001AC4C: 7E121709
	v_mul_f32_e32 v1, v1, v17                                  // 00000001AC50: 10022301
	v_fmac_f32_e32 v34, v25, v44                               // 00000001AC54: 56445919
	v_fma_f32 v26, -v26, v37, v32                              // 00000001AC58: D613001A 24824B1A
	v_div_scale_f32 v32, null, v22, v22, 1.0                   // 00000001AC60: D6FC7C20 03CA2D16
	v_dual_fmac_f32 v28, v35, v28 :: v_dual_mov_b32 v17, 0     // 00000001AC68: C8103923 1C100080
	s_wait_alu 0xfffe                                          // 00000001AC70: BF88FFFE
	s_delay_alu instid0(VALU_DEP_3)                            // 00000001AC74: BF870003
	v_div_fmas_f32 v26, v26, v29, v37                          // 00000001AC78: D637001A 04963B1A
	v_fma_f32 v29, -v36, v24, v30                              // 00000001AC80: D613001D 247A3124
	v_rcp_f32_e32 v37, v32                                     // 00000001AC88: 7E4A5520
	s_mov_b32 vcc_lo, s2                                       // 00000001AC8C: BEEA0002
	v_cvt_pk_rtz_f16_f32_e32 v1, v1, v1                        // 00000001AC90: 5E020301
	v_div_fixup_f32 v18, v26, v18, 1.0                         // 00000001AC94: D6270012 03CA251A
	v_fmac_f32_e32 v24, v29, v33                               // 00000001AC9C: 5630431D
	v_div_scale_f32 v29, null, v23, v23, 1.0                   // 00000001ACA0: D6FC7C1D 03CA2F17
	v_div_scale_f32 v26, s1, 1.0, v21, 1.0                     // 00000001ACA8: D6FC011A 03CA2AF2
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000001ACB0: BF870193
	v_fma_f32 v30, -v36, v24, v30                              // 00000001ACB4: D613001E 247A3124
	v_rcp_f32_e32 v36, v29                                     // 00000001ACBC: 7E48551D
	s_delay_alu instid0(TRANS32_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000001ACC0: BF870196
	v_fma_f32 v35, -v32, v37, 1.0                              // 00000001ACC4: D6130023 23CA4B20
	v_mul_f32_e32 v25, v26, v28                                // 00000001ACCC: 1032391A
	v_mul_f32_e32 v2, v2, v18                                  // 00000001ACD0: 10042502
	s_wait_alu 0xfffe                                          // 00000001ACD4: BF88FFFE
	v_div_fmas_f32 v24, v30, v33, v24                          // 00000001ACD8: D6370018 0462431E
	v_fma_f32 v30, -v38, v34, v31                              // 00000001ACE0: D613001E 247E4526
	s_mov_b32 vcc_lo, s0                                       // 00000001ACE8: BEEA0000
	v_fma_f32 v31, -v27, v25, v26                              // 00000001ACEC: D613001F 246A331B
	v_cvt_pk_rtz_f16_f32_e32 v2, v2, v2                        // 00000001ACF4: 5E040502
	v_div_fixup_f32 v19, v24, v19, 1.0                         // 00000001ACF8: D6270013 03CA2718
	v_fma_f32 v38, -v29, v36, 1.0                              // 00000001AD00: D6130026 23CA491D
	v_fmac_f32_e32 v37, v35, v37                               // 00000001AD08: 564A4B23
	v_div_scale_f32 v35, s3, 1.0, v22, 1.0                     // 00000001AD0C: D6FC0323 03CA2CF2
	s_wait_alu 0xfffe                                          // 00000001AD14: BF88FFFE
	v_div_fmas_f32 v30, v30, v44, v34                          // 00000001AD18: D637001E 048A591E
	v_fmac_f32_e32 v36, v38, v36                               // 00000001AD20: 56484926
	v_fmac_f32_e32 v25, v31, v28                               // 00000001AD24: 5632391F
	v_div_scale_f32 v34, s0, 1.0, v23, 1.0                     // 00000001AD28: D6FC0022 03CA2EF2
	v_mul_f32_e32 v33, v35, v37                                // 00000001AD30: 10424B23
	s_mov_b32 vcc_lo, s1                                       // 00000001AD34: BEEA0001
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000001AD38: BF870193
	v_fma_f32 v24, -v27, v25, v26                              // 00000001AD3C: D6130018 246A331B
	v_mul_f32_e32 v26, v34, v36                                // 00000001AD44: 10344922
	s_mov_b32 s1, 0xc3e00000                                   // 00000001AD48: BE8100FF C3E00000
	v_fma_f32 v31, -v32, v33, v35                              // 00000001AD50: D613001F 248E4320
	v_mul_f32_e32 v11, v11, v19                                // 00000001AD58: 1016270B
	s_wait_alu 0xfffe                                          // 00000001AD5C: BF88FFFE
	v_div_fmas_f32 v24, v24, v28, v25                          // 00000001AD60: D6370018 04663918
	v_fma_f32 v27, -v29, v26, v34                              // 00000001AD68: D613001B 248A351D
	s_mov_b32 vcc_lo, s3                                       // 00000001AD70: BEEA0003
	v_dual_fmac_f32 v33, v31, v37 :: v_dual_mov_b32 v28, 0     // 00000001AD74: C8104B1F 211C0080
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 00000001AD7C: BF870193
	v_div_fixup_f32 v21, v24, v21, 1.0                         // 00000001AD80: D6270015 03CA2B18
	v_fmac_f32_e32 v26, v27, v36                               // 00000001AD88: 5634491B
	v_max_num_f32_e32 v27, v8, v8                              // 00000001AD8C: 2C361108
	s_delay_alu instid0(VALU_DEP_4)                            // 00000001AD90: BF870004
	v_fma_f32 v25, -v32, v33, v35                              // 00000001AD94: D6130019 248E4320
	v_cvt_pk_rtz_f16_f32_e32 v11, v11, v11                     // 00000001AD9C: 5E16170B
	v_cvt_f32_f16_e32 v11, v11                                 // 00000001ADA0: 7E16170B
	v_div_fixup_f32 v20, v30, v20, 1.0                         // 00000001ADA4: D6270014 03CA291E
	v_mul_f32_e32 v13, v13, v21                                // 00000001ADAC: 101A2B0D
	s_wait_alu 0xfffe                                          // 00000001ADB0: BF88FFFE
	v_div_fmas_f32 v25, v25, v37, v33                          // 00000001ADB4: D6370019 04864B19
	s_mov_b32 vcc_lo, s0                                       // 00000001ADBC: BEEA0000
	v_cvt_f32_f16_e32 v2, v2                                   // 00000001ADC0: 7E041702
	v_mul_f32_e32 v12, v12, v20                                // 00000001ADC4: 1018290C
	v_mul_f32_e32 v4, v4, v20                                  // 00000001ADC8: 10082904
	v_div_fixup_f32 v22, v25, v22, 1.0                         // 00000001ADCC: D6270016 03CA2D19
	v_med3_num_f32 v25, v27, s1, 0x43e00000                    // 00000001ADD4: D6310019 03FC031B 43E00000
	v_mov_b32_e32 v27, 0                                       // 00000001ADE0: 7E360280
	v_cvt_pk_rtz_f16_f32_e32 v4, v4, v4                        // 00000001ADE4: 5E080904
	v_cvt_f32_f16_e32 v4, v4                                   // 00000001ADE8: 7E081704
	v_mov_b32_e32 v20, 0                                       // 00000001ADEC: 7E280280
	v_mul_f32_e32 v14, v14, v22                                // 00000001ADF0: 101C2D0E
	v_cvt_pk_fp8_f32 v27, v25, 0                               // 00000001ADF4: D769001B 00010119
	v_max_num_f32_e32 v25, v9, v9                              // 00000001ADFC: 2C321309
	v_fma_f32 v24, -v29, v26, v34                              // 00000001AE00: D6130018 248A351D
	v_mov_b32_e32 v29, 0                                       // 00000001AE08: 7E3A0280
	v_cvt_pk_rtz_f16_f32_e32 v14, v14, v14                     // 00000001AE0C: 5E1C1D0E
	v_cvt_f32_fp8_e32 v27, v27                                 // 00000001AE10: 7E36D91B
	v_med3_num_f32 v25, v25, s1, 0x43e00000                    // 00000001AE14: D6310019 03FC0319 43E00000
	s_wait_alu 0xfffe                                          // 00000001AE20: BF88FFFE
	v_div_fmas_f32 v24, v24, v36, v26                          // 00000001AE24: D6370018 046A4918
	v_cmp_neq_f32_e32 vcc_lo, 0, v8                            // 00000001AE2C: 7C3A1080
	v_cvt_f32_f16_e32 v14, v14                                 // 00000001AE30: 7E1C170E
	v_mov_b32_e32 v26, 0                                       // 00000001AE34: 7E340280
	v_cvt_pk_fp8_f32 v28, v25, 0                               // 00000001AE38: D769001C 00010119
	v_div_fixup_f32 v23, v24, v23, 1.0                         // 00000001AE40: D6270017 03CA2F18
	v_or_b32_e32 v24, s10, v41                                 // 00000001AE48: 3830520A
	s_wait_alu 0xfffd                                          // 00000001AE4C: BF88FFFD
	v_dual_cndmask_b32 v8, 0, v27 :: v_dual_mov_b32 v27, 0     // 00000001AE50: CA503680 081A0080
	v_cvt_pk_rtz_f16_f32_e32 v0, v0, v0                        // 00000001AE58: 5E000100
	v_cvt_f32_f16_e32 v0, v0                                   // 00000001AE5C: 7E001700
	v_max_num_f32_e32 v25, v0, v0                              // 00000001AE60: 2C320100
	v_lshlrev_b32_e32 v24, 10, v24                             // 00000001AE64: 3030308A
	v_cvt_pk_fp8_f32 v16, v8, 0                                // 00000001AE68: D7690010 00010108
	v_cmp_neq_f32_e32 vcc_lo, 0, v9                            // 00000001AE70: 7C3A1280
	v_mul_f32_e32 v8, v10, v18                                 // 00000001AE74: 1010250A
	v_med3_num_f32 v25, v25, s1, 0x43e00000                    // 00000001AE78: D6310019 03FC0319 43E00000
	v_or3_b32 v10, v24, s8, v40                                // 00000001AE84: D658000A 04A01118
	v_cvt_f32_fp8_e32 v24, v28                                 // 00000001AE8C: 7E30D91C
	v_mov_b32_e32 v18, 0                                       // 00000001AE90: 7E240280
	v_cvt_f32_f16_e32 v1, v1                                   // 00000001AE94: 7E021701
	v_cvt_pk_fp8_f32 v27, v25, 0                               // 00000001AE98: D769001B 00010119
	v_mov_b32_e32 v25, 0                                       // 00000001AEA0: 7E320280
	s_wait_alu 0xfffd                                          // 00000001AEA4: BF88FFFD
	v_cndmask_b32_e32 v9, 0, v24, vcc_lo                       // 00000001AEA8: 02123080
	v_cvt_pk_rtz_f16_f32_e32 v8, v8, v8                        // 00000001AEAC: 5E101108
	v_cvt_f32_f16_e32 v8, v8                                   // 00000001AEB0: 7E101708
	v_max_num_f32_e32 v28, v8, v8                              // 00000001AEB4: 2C381108
	v_cvt_f32_fp8_e32 v27, v27                                 // 00000001AEB8: 7E36D91B
	v_cmp_neq_f32_e32 vcc_lo, 0, v0                            // 00000001AEBC: 7C3A0080
	v_cvt_pk_fp8_f32 v29, v9, 0                                // 00000001AEC0: D769001D 00010109
	v_cvt_pk_rtz_f16_f32_e32 v9, v12, v12                      // 00000001AEC8: 5E12190C
	v_med3_num_f32 v24, v28, s1, 0x43e00000                    // 00000001AECC: D6310018 03FC031C 43E00000
	v_max_num_f32_e32 v28, v11, v11                            // 00000001AED8: 2C38170B
	s_wait_alu 0xfffd                                          // 00000001AEDC: BF88FFFD
	v_dual_cndmask_b32 v0, 0, v27 :: v_dual_mov_b32 v27, 0     // 00000001AEE0: CA503680 001A0080
	v_cmp_neq_f32_e32 vcc_lo, 0, v8                            // 00000001AEE8: 7C3A1080
	v_cvt_pk_fp8_f32 v25, v24, 0                               // 00000001AEEC: D7690019 00010118
	v_med3_num_f32 v24, v28, s1, 0x43e00000                    // 00000001AEF4: D6310018 03FC031C 43E00000
	v_mov_b32_e32 v28, 0                                       // 00000001AF00: 7E380280
	v_cvt_pk_fp8_f32 v27, v0, 0                                // 00000001AF04: D769001B 00010100
	v_cvt_f32_f16_e32 v9, v9                                   // 00000001AF0C: 7E121709
	v_cvt_f32_fp8_e32 v0, v25                                  // 00000001AF10: 7E00D919
	v_max_num_f32_e32 v12, v9, v9                              // 00000001AF14: 2C181309
	global_store_b8 v10, v16, s[6:7]                           // 00000001AF18: EE060006 08000000 0000000A
	v_dual_mov_b32 v16, 0 :: v_dual_mul_f32 v5, v5, v21        // 00000001AF24: CA060080 10042B05
	s_wait_alu 0xfffd                                          // 00000001AF2C: BF88FFFD
	v_cndmask_b32_e32 v0, 0, v0, vcc_lo                        // 00000001AF30: 02000080
	v_cmp_neq_f32_e32 vcc_lo, 0, v11                           // 00000001AF34: 7C3A1680
	v_mov_b32_e32 v11, 0                                       // 00000001AF38: 7E160280
	v_cvt_pk_fp8_f32 v28, v24, 0                               // 00000001AF3C: D769001C 00010118
	v_med3_num_f32 v12, v12, s1, 0x43e00000                    // 00000001AF44: D631000C 03FC030C 43E00000
	v_mov_b32_e32 v24, 0                                       // 00000001AF50: 7E300280
	v_cvt_pk_fp8_f32 v16, v0, 0                                // 00000001AF54: D7690010 00010100
	v_cvt_pk_rtz_f16_f32_e32 v0, v13, v13                      // 00000001AF5C: 5E001B0D
	v_cvt_f32_fp8_e32 v8, v28                                  // 00000001AF60: 7E10D91C
	v_cvt_f32_f16_e32 v0, v0                                   // 00000001AF64: 7E001700
	v_cvt_pk_fp8_f32 v24, v12, 0                               // 00000001AF68: D7690018 0001010C
	v_dual_max_num_f32 v12, v0, v0 :: v_dual_mul_f32 v7, v7, v23// 00000001AF70: CA860100 0C062F07
	s_wait_alu 0xfffd                                          // 00000001AF78: BF88FFFD
	v_cndmask_b32_e32 v8, 0, v8, vcc_lo                        // 00000001AF7C: 02101080
	v_cmp_neq_f32_e32 vcc_lo, 0, v9                            // 00000001AF80: 7C3A1280
	v_cvt_f32_fp8_e32 v13, v24                                 // 00000001AF84: 7E1AD918
	v_med3_num_f32 v12, v12, s1, 0x43e00000                    // 00000001AF88: D631000C 03FC030C 43E00000
	v_mov_b32_e32 v24, 0                                       // 00000001AF94: 7E300280
	v_cvt_pk_fp8_f32 v11, v8, 0                                // 00000001AF98: D769000B 00010108
	s_wait_alu 0xfffd                                          // 00000001AFA0: BF88FFFD
	v_dual_max_num_f32 v8, v4, v4 :: v_dual_cndmask_b32 v9, 0, v13// 00000001AFA4: CA920904 08081A80
	v_mov_b32_e32 v13, 0                                       // 00000001AFAC: 7E1A0280
	v_cvt_pk_fp8_f32 v24, v12, 0                               // 00000001AFB0: D7690018 0001010C
	v_cmp_neq_f32_e32 vcc_lo, 0, v4                            // 00000001AFB8: 7C3A0880
	s_delay_alu instid0(VALU_DEP_4)                            // 00000001AFBC: BF870004
	v_med3_num_f32 v8, v8, s1, 0x43e00000                      // 00000001AFC0: D6310008 03FC0308 43E00000
	v_mov_b32_e32 v12, 0                                       // 00000001AFCC: 7E180280
	v_cvt_pk_fp8_f32 v13, v9, 0                                // 00000001AFD0: D769000D 00010109
	v_cvt_f32_fp8_e32 v9, v24                                  // 00000001AFD8: 7E12D918
	v_cvt_pk_rtz_f16_f32_e32 v7, v7, v7                        // 00000001AFDC: 5E0E0F07
	v_cvt_pk_fp8_f32 v20, v8, 0                                // 00000001AFE0: D7690014 00010108
	v_max_num_f32_e32 v8, v14, v14                             // 00000001AFE8: 2C101D0E
	global_store_b8 v10, v13, s[6:7] offset:4096               // 00000001AFEC: EE060006 06800000 0010000A
	v_mov_b32_e32 v13, 0                                       // 00000001AFF8: 7E1A0280
	s_clause 0x1                                               // 00000001AFFC: BF850001
	global_store_b8 v10, v29, s[6:7] offset:1024               // 00000001B000: EE060006 0E800000 0004000A
	global_store_b8 v10, v27, s[6:7] offset:16                 // 00000001B00C: EE060006 0D800000 0000100A
	v_cvt_f32_fp8_e32 v20, v20                                 // 00000001B018: 7E28D914
	v_med3_num_f32 v8, v8, s1, 0x43e00000                      // 00000001B01C: D6310008 03FC0308 43E00000
	v_cvt_f32_f16_e32 v7, v7                                   // 00000001B028: 7E0E1707
	s_wait_alu 0xfffd                                          // 00000001B02C: BF88FFFD
	s_delay_alu instid0(VALU_DEP_2)                            // 00000001B030: BF870002
	v_cndmask_b32_e32 v4, 0, v20, vcc_lo                       // 00000001B034: 02082880
	v_cmp_neq_f32_e32 vcc_lo, 0, v0                            // 00000001B038: 7C3A0080
	v_cvt_pk_fp8_f32 v12, v8, 0                                // 00000001B03C: D769000C 00010108
	v_mul_f32_e32 v8, v15, v23                                 // 00000001B044: 10102F0F
	v_cvt_pk_rtz_f16_f32_e32 v8, v8, v8                        // 00000001B048: 5E101108
	v_cvt_f32_f16_e32 v8, v8                                   // 00000001B04C: 7E101708
	s_wait_alu 0xfffd                                          // 00000001B050: BF88FFFD
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_3) | instid1(VALU_DEP_4)// 00000001B054: BF870241
	v_dual_cndmask_b32 v0, 0, v9 :: v_dual_max_num_f32 v9, v8, v8// 00000001B058: CA541280 00081108
	v_mov_b32_e32 v20, 0                                       // 00000001B060: 7E280280
	v_cmp_neq_f32_e32 vcc_lo, 0, v14                           // 00000001B064: 7C3A1C80
	v_dual_max_num_f32 v14, v1, v1 :: v_dual_mov_b32 v15, 0    // 00000001B068: CA900301 0E0E0080
	v_med3_num_f32 v9, v9, s1, 0x43e00000                      // 00000001B070: D6310009 03FC0309 43E00000
	s_delay_alu instid0(VALU_DEP_4) | instskip(SKIP_1) | instid1(VALU_DEP_4)// 00000001B07C: BF870224
	v_cvt_pk_fp8_f32 v20, v4, 0                                // 00000001B080: D7690014 00010104
	v_cvt_f32_fp8_e32 v4, v12                                  // 00000001B088: 7E08D90C
	v_med3_num_f32 v14, v14, s1, 0x43e00000                    // 00000001B08C: D631000E 03FC030E 43E00000
	v_mov_b32_e32 v12, 0                                       // 00000001B098: 7E180280
	v_cvt_pk_fp8_f32 v13, v9, 0                                // 00000001B09C: D769000D 00010109
	s_wait_alu 0xfffd                                          // 00000001B0A4: BF88FFFD
	v_dual_max_num_f32 v9, v2, v2 :: v_dual_cndmask_b32 v4, 0, v4// 00000001B0A8: CA920502 09040880
	v_cvt_pk_fp8_f32 v15, v14, 0                               // 00000001B0B0: D769000F 0001010E
	v_cmp_neq_f32_e32 vcc_lo, 0, v8                            // 00000001B0B8: 7C3A1080
	v_cvt_f32_fp8_e32 v13, v13                                 // 00000001B0BC: 7E1AD90D
	s_delay_alu instid0(VALU_DEP_4)                            // 00000001B0C0: BF870004
	v_med3_num_f32 v9, v9, s1, 0x43e00000                      // 00000001B0C4: D6310009 03FC0309 43E00000
	v_cvt_pk_fp8_f32 v12, v0, 0                                // 00000001B0D0: D769000C 00010100
	v_cvt_f32_fp8_e32 v0, v15                                  // 00000001B0D8: 7E00D90F
	v_cvt_pk_fp8_f32 v17, v4, 0                                // 00000001B0DC: D7690011 00010104
	s_wait_alu 0xfffd                                          // 00000001B0E4: BF88FFFD
	v_cndmask_b32_e32 v8, 0, v13, vcc_lo                       // 00000001B0E8: 02101A80
	v_cvt_pk_fp8_f32 v18, v9, 0                                // 00000001B0EC: D7690012 00010109
	v_cmp_neq_f32_e32 vcc_lo, 0, v1                            // 00000001B0F4: 7C3A0280
	v_mov_b32_e32 v13, 0                                       // 00000001B0F8: 7E1A0280
	v_mul_f32_e32 v1, v3, v19                                  // 00000001B0FC: 10022703
	v_cvt_pk_rtz_f16_f32_e32 v1, v1, v1                        // 00000001B100: 5E020301
	v_cvt_f32_fp8_e32 v4, v18                                  // 00000001B104: 7E08D912
	s_wait_alu 0xfffd                                          // 00000001B108: BF88FFFD
	v_cndmask_b32_e32 v0, 0, v0, vcc_lo                        // 00000001B10C: 02000080
	v_cmp_neq_f32_e32 vcc_lo, 0, v2                            // 00000001B110: 7C3A0480
	v_cvt_pk_fp8_f32 v13, v8, 0                                // 00000001B114: D769000D 00010108
	v_mov_b32_e32 v3, 0                                        // 00000001B11C: 7E060280
	v_cvt_f32_f16_e32 v1, v1                                   // 00000001B120: 7E021701
	v_max_num_f32_e32 v8, v1, v1                               // 00000001B124: 2C100301
	s_wait_alu 0xfffd                                          // 00000001B128: BF88FFFD
	v_cndmask_b32_e32 v2, 0, v4, vcc_lo                        // 00000001B12C: 02040880
	v_mov_b32_e32 v4, 0                                        // 00000001B130: 7E080280
	v_cvt_pk_fp8_f32 v3, v0, 0                                 // 00000001B134: D7690003 00010100
	s_clause 0x1                                               // 00000001B13C: BF850001
	global_store_b8 v10, v16, s[6:7] offset:2048               // 00000001B140: EE060006 08000000 0008000A
	global_store_b8 v10, v3, s[6:7] offset:1040                // 00000001B14C: EE060006 01800000 0004100A
	v_cvt_pk_fp8_f32 v4, v2, 0                                 // 00000001B158: D7690004 00010102
	v_med3_num_f32 v0, v8, s1, 0x43e00000                      // 00000001B160: D6310000 03FC0308 43E00000
	v_dual_mov_b32 v2, 0 :: v_dual_mul_f32 v3, v6, v22         // 00000001B16C: CA060080 02022D06
	v_cvt_pk_rtz_f16_f32_e32 v3, v3, v3                        // 00000001B174: 5E060703
	v_cvt_f32_f16_e32 v3, v3                                   // 00000001B178: 7E061703
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_2)// 00000001B17C: BF870111
	v_max_num_f32_e32 v6, v3, v3                               // 00000001B180: 2C0C0703
	v_cvt_pk_fp8_f32 v2, v0, 0                                 // 00000001B184: D7690002 00010100
	v_cvt_pk_rtz_f16_f32_e32 v0, v5, v5                        // 00000001B18C: 5E000B05
	v_cvt_f32_f16_e32 v0, v0                                   // 00000001B190: 7E001700
	v_dual_max_num_f32 v5, v0, v0 :: v_dual_mov_b32 v8, 0      // 00000001B194: CA900100 05080080
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_2) | instid1(VALU_DEP_4)// 00000001B19C: BF870232
	v_cvt_f32_fp8_e32 v2, v2                                   // 00000001B1A0: 7E04D902
	v_med3_num_f32 v6, v6, s1, 0x43e00000                      // 00000001B1A4: D6310006 03FC0306 43E00000
	v_mov_b32_e32 v9, 0                                        // 00000001B1B0: 7E120280
	v_med3_num_f32 v5, v5, s1, 0x43e00000                      // 00000001B1B4: D6310005 03FC0305 43E00000
	v_max_num_f32_e32 v14, v7, v7                              // 00000001B1C0: 2C1C0F07
	v_cmp_neq_f32_e32 vcc_lo, 0, v1                            // 00000001B1C4: 7C3A0280
	global_store_b8 v10, v4, s[6:7] offset:2064                // 00000001B1C8: EE060006 02000000 0008100A
	v_cvt_pk_fp8_f32 v9, v6, 0                                 // 00000001B1D4: D7690009 00010106
	v_cvt_pk_fp8_f32 v8, v5, 0                                 // 00000001B1DC: D7690008 00010105
	v_med3_num_f32 v5, v14, s1, 0x43e00000                     // 00000001B1E4: D6310005 03FC030E 43E00000
	s_wait_alu 0xfffd                                          // 00000001B1F0: BF88FFFD
	v_dual_cndmask_b32 v1, 0, v2 :: v_dual_mov_b32 v2, 0       // 00000001B1F4: CA500480 01020080
	v_mov_b32_e32 v6, 0                                        // 00000001B1FC: 7E0C0280
	v_cvt_f32_fp8_e32 v4, v8                                   // 00000001B200: 7E08D908
	v_cmp_neq_f32_e32 vcc_lo, 0, v0                            // 00000001B204: 7C3A0080
	s_delay_alu instid0(VALU_DEP_4)                            // 00000001B208: BF870004
	v_cvt_pk_fp8_f32 v2, v1, 0                                 // 00000001B20C: D7690002 00010101
	v_cvt_f32_fp8_e32 v1, v9                                   // 00000001B214: 7E02D909
	v_cvt_pk_fp8_f32 v6, v5, 0                                 // 00000001B218: D7690006 00010105
	s_wait_alu 0xfffd                                          // 00000001B220: BF88FFFD
	v_dual_mov_b32 v5, 0 :: v_dual_cndmask_b32 v0, 0, v4       // 00000001B224: CA120080 05000880
	v_cmp_neq_f32_e32 vcc_lo, 0, v3                            // 00000001B22C: 7C3A0680
	v_mov_b32_e32 v4, 0                                        // 00000001B230: 7E080280
	v_cvt_f32_fp8_e32 v3, v6                                   // 00000001B234: 7E06D906
	s_clause 0x3                                               // 00000001B238: BF850003
	global_store_b8 v10, v11, s[6:7] offset:3072               // 00000001B23C: EE060006 05800000 000C000A
	global_store_b8 v10, v2, s[6:7] offset:3088                // 00000001B248: EE060006 01000000 000C100A
	global_store_b8 v10, v12, s[6:7] offset:5120               // 00000001B254: EE060006 06000000 0014000A
	global_store_b8 v10, v20, s[6:7] offset:4112               // 00000001B260: EE060006 0A000000 0010100A
	s_wait_alu 0xfffd                                          // 00000001B26C: BF88FFFD
	v_cndmask_b32_e32 v1, 0, v1, vcc_lo                        // 00000001B270: 02020280
	v_cmp_neq_f32_e32 vcc_lo, 0, v7                            // 00000001B274: 7C3A0E80
	v_cvt_pk_fp8_f32 v4, v0, 0                                 // 00000001B278: D7690004 00010100
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_2) | instid1(VALU_DEP_1)// 00000001B280: BF8700B3
	v_cvt_pk_fp8_f32 v5, v1, 0                                 // 00000001B284: D7690005 00010101
	s_wait_alu 0xfffd                                          // 00000001B28C: BF88FFFD
	v_cndmask_b32_e32 v2, 0, v3, vcc_lo                        // 00000001B290: 02040680
	v_cvt_pk_fp8_f32 v26, v2, 0                                // 00000001B294: D769001A 00010102
	s_clause 0x4                                               // 00000001B29C: BF850004
	global_store_b8 v10, v17, s[6:7] offset:6144               // 00000001B2A0: EE060006 08800000 0018000A
	global_store_b8 v10, v4, s[6:7] offset:5136                // 00000001B2AC: EE060006 02000000 0014100A
	global_store_b8 v10, v5, s[6:7] offset:6160                // 00000001B2B8: EE060006 02800000 0018100A
	global_store_b8 v10, v13, s[6:7] offset:7168               // 00000001B2C4: EE060006 06800000 001C000A
	global_store_b8 v10, v26, s[6:7] offset:7184               // 00000001B2D0: EE060006 0D000000 001C100A
	s_endpgm                                                   // 00000001B2DC: BFB00000
	s_nop 0                                                    // 00000001B2E0: BF800000
	s_nop 0                                                    // 00000001B2E4: BF800000
	s_nop 0                                                    // 00000001B2E8: BF800000
	s_nop 0                                                    // 00000001B2EC: BF800000
	s_nop 0                                                    // 00000001B2F0: BF800000
	s_nop 0                                                    // 00000001B2F4: BF800000
	s_nop 0                                                    // 00000001B2F8: BF800000
	s_nop 0                                                    // 00000001B2FC: BF800000
