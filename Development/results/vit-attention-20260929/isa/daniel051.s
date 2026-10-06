
/home/lmxxf/work/vit-attention-20260929/daniel-051.hsaco:	file format elf64-amdgpu

Disassembly of section .text:

0000000000109c00 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams>:
	s_load_b128 s[12:15], s[0:1], 0x20                         // 000000109C00: F4004300 F8000020
	s_mov_b64 s[16:17], 0                                      // 000000109C08: BE900180
	s_wait_kmcnt 0x0                                           // 000000109C0C: BFC70000
	s_cmp_lg_u64 s[14:15], 0                                   // 000000109C10: BF11800E
	s_cselect_b32 s20, -1, 0                                   // 000000109C14: 981480C1
	s_cmp_eq_u64 s[14:15], 0                                   // 000000109C18: BF10800E
	s_cbranch_scc1 1                                           // 000000109C1C: BFA20001 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0x24>
	s_sendmsg_rtn_b64 s[16:17], sendmsg(MSG_RTN_GET_REALTIME)  // 000000109C20: BE904D83
	v_lshrrev_b32_e32 v36, 5, v0                               // 000000109C24: 32480085
	s_lshl_b32 s22, ttmp9, 6                                   // 000000109C28: 84168675
	s_load_b256 s[4:11], s[0:1], 0x0                           // 000000109C2C: F4006100 F8000000
	s_ashr_i32 s2, s22, 4                                      // 000000109C34: 86028416
	v_dual_mov_b32 v38, 0 :: v_dual_and_b32 v27, 15, v0        // 000000109C38: CA240080 261A008F
	v_or_b32_e32 v1, s2, v36                                   // 000000109C40: 38024802
	v_bfe_u32 v7, v0, 4, 1                                     // 000000109C44: D6100007 02050900
	s_and_b32 s21, ttmp7, 0xffff                               // 000000109C4C: 8B15FF73 0000FFFF
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000109C54: BF870193
	v_dual_mov_b32 v30, 0 :: v_dual_lshlrev_b32 v3, 4, v27     // 000000109C58: CA220080 1E023684
	v_ashrrev_i32_e32 v2, 31, v1                               // 000000109C60: 3404029F
	v_dual_mov_b32 v29, 0 :: v_dual_mov_b32 v32, 0             // 000000109C64: CA100080 1D200080
	v_dual_mov_b32 v31, 0 :: v_dual_mov_b32 v34, 0             // 000000109C6C: CA100080 1F220080
	s_delay_alu instid0(VALU_DEP_3)                            // 000000109C74: BF870003
	v_lshlrev_b64_e32 v[1:2], 14, v[1:2]                       // 000000109C78: 3E02028E
	v_lshl_or_b32 v28, v7, 8, v3                               // 000000109C7C: D656001C 040D1107
	v_mov_b32_e32 v35, 0                                       // 000000109C84: 7E460280
	v_mov_b32_e32 v37, 0                                       // 000000109C88: 7E4A0280
	v_mov_b32_e32 v33, 0                                       // 000000109C8C: 7E420280
	s_lshl_b32 s18, s21, 9                                     // 000000109C90: 84128915
	s_cmp_lt_i32 s12, 64                                       // 000000109C94: BF04C00C
	s_mov_b32 s19, 0                                           // 000000109C98: BE930080
	s_cbranch_scc1 818                                         // 000000109C9C: BFA20332 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0xd68>
	s_wait_kmcnt 0x0                                           // 000000109CA0: BFC70000
	v_add_co_u32 v3, vcc_lo, s4, v1                            // 000000109CA4: D7006A03 00020204
	s_delay_alu instid0(VALU_DEP_1)                            // 000000109CAC: BF870001
	v_add_co_ci_u32_e64 v4, null, s5, v2, vcc_lo               // 000000109CB0: D5207C04 01AA0405
	s_add_nc_u64 s[4:5], s[18:19], 8                           // 000000109CB8: A9848812
	v_add_co_u32 v5, vcc_lo, v3, v28                           // 000000109CBC: D7006A05 00023903
	s_wait_alu 0xfffd                                          // 000000109CC4: BF88FFFD
	v_add_co_ci_u32_e64 v6, null, 0, v4, vcc_lo                // 000000109CC8: D5207C06 01AA0880
	s_lshl_b32 s3, s21, 5                                      // 000000109CD0: 84038515
	v_add_co_u32 v3, vcc_lo, v5, s18                           // 000000109CD4: D7006A03 00002505
	s_wait_alu 0xfffd                                          // 000000109CDC: BF88FFFD
	v_add_co_ci_u32_e64 v4, null, 0, v6, vcc_lo                // 000000109CE0: D5207C04 01AA0C80
	s_wait_alu 0xfffe                                          // 000000109CE8: BF88FFFE
	v_add_co_u32 v5, vcc_lo, s4, v5                            // 000000109CEC: D7006A05 00020A04
	s_wait_alu 0xfffd                                          // 000000109CF4: BF88FFFD
	v_add_co_ci_u32_e64 v6, null, s5, v6, vcc_lo               // 000000109CF8: D5207C06 01AA0C05
	s_clause 0x1                                               // 000000109D00: BF850001
	global_load_b64 v[3:4], v[3:4], off                        // 000000109D04: EE05407C 00000003 00000003
	global_load_b64 v[5:6], v[5:6], off                        // 000000109D10: EE05407C 00000005 00000005
	s_or_b32 s24, s3, 16                                       // 000000109D1C: 8C189003
	s_ashr_i32 s2, s12, 31                                     // 000000109D20: 86029F0C
	v_dual_mov_b32 v34, 0 :: v_dual_lshlrev_b32 v7, 3, v7      // 000000109D24: CA220080 22060E83
	v_or_b32_e32 v8, s3, v27                                   // 000000109D2C: 38103603
	v_or_b32_e32 v9, s24, v27                                  // 000000109D30: 38123618
	s_wait_alu 0xfffe                                          // 000000109D34: BF88FFFE
	s_lshr_b32 s2, s2, 26                                      // 000000109D38: 85029A02
	v_mbcnt_lo_u32_b32 v41, -1, 0                              // 000000109D3C: D71F0029 000100C1
	s_wait_alu 0xfffe                                          // 000000109D44: BF88FFFE
	s_add_co_i32 s2, s12, s2                                   // 000000109D48: 8102020C
	v_dual_mov_b32 v33, 0 :: v_dual_mov_b32 v32, 0             // 000000109D4C: CA100080 21200080
	s_wait_alu 0xfffe                                          // 000000109D54: BF88FFFE
	s_ashr_i32 s23, s2, 6                                      // 000000109D58: 86178602
	v_add_co_u32 v39, s2, s8, v7                               // 000000109D5C: D7000227 00020E08
	v_mad_co_u64_u32 v[7:8], null, v8, s12, 0                  // 000000109D64: D6FE7C07 02001908
	v_mad_co_u64_u32 v[9:10], null, v9, s12, 0                 // 000000109D6C: D6FE7C09 02001909
	s_wait_alu 0xf1ff                                          // 000000109D74: BF88F1FF
	v_add_co_ci_u32_e64 v40, null, s9, 0, s2                   // 000000109D78: D5207C28 00090009
	v_xor_b32_e32 v42, 16, v41                                 // 000000109D80: 3A545290
	v_dual_mov_b32 v37, 0 :: v_dual_mov_b32 v30, 0             // 000000109D84: CA100080 251E0080
	v_dual_mov_b32 v35, 0 :: v_dual_mov_b32 v38, 0             // 000000109D8C: CA100080 23260080
	v_mov_b32_e32 v31, 0                                       // 000000109D94: 7E3E0280
	v_mov_b32_e32 v29, 0                                       // 000000109D98: 7E3A0280
	s_add_nc_u64 s[2:3], s[6:7], s[18:19]                      // 000000109D9C: A9821206
	s_add_nc_u64 s[4:5], s[6:7], s[4:5]                        // 000000109DA0: A9840406
	s_mov_b32 s6, 0x3fdac000                                   // 000000109DA4: BE8600FF 3FDAC000
	s_mov_b32 s7, 0x3db76000                                   // 000000109DAC: BE8700FF 3DB76000
	s_mov_b32 s8, s19                                          // 000000109DB4: BE880013
	s_wait_alu 0xfffe                                          // 000000109DB8: BF88FFFE
	v_add_co_u32 v17, s9, s2, v28                              // 000000109DBC: D7000911 00023802
	s_wait_alu 0xf1ff                                          // 000000109DC4: BF88F1FF
	v_add_co_ci_u32_e64 v18, null, s3, 0, s9                   // 000000109DC8: D5207C12 00250003
	v_add_co_u32 v25, s9, s4, v28                              // 000000109DD0: D7000919 00023804
	s_wait_alu 0xf1ff                                          // 000000109DD8: BF88F1FF
	v_add_co_ci_u32_e64 v26, null, s5, 0, s9                   // 000000109DDC: D5207C1A 00250005
	s_clause 0x3                                               // 000000109DE4: BF850003
	global_load_b64 v[11:12], v[17:18], off                    // 000000109DE8: EE05407C 0000000B 00000011
	global_load_b64 v[13:14], v[17:18], off offset:16384       // 000000109DF4: EE05407C 0000000D 00400011
	global_load_b64 v[15:16], v[17:18], off offset:32768       // 000000109E00: EE05407C 0000000F 00800011
	global_load_b64 v[23:24], v[17:18], off offset:49152       // 000000109E0C: EE05407C 00000017 00C00011
	s_clause 0x3                                               // 000000109E18: BF850003
	global_load_b64 v[17:18], v[25:26], off                    // 000000109E1C: EE05407C 00000011 00000019
	global_load_b64 v[19:20], v[25:26], off offset:16384       // 000000109E28: EE05407C 00000013 00400019
	global_load_b64 v[21:22], v[25:26], off offset:32768       // 000000109E34: EE05407C 00000015 00800019
	global_load_b64 v[25:26], v[25:26], off offset:49152       // 000000109E40: EE05407C 00000019 00C00019
	v_add_co_u32 v43, vcc_lo, v39, s8                          // 000000109E4C: D7006A2B 00001127
	s_wait_alu 0xfffd                                          // 000000109E54: BF88FFFD
	v_add_co_ci_u32_e64 v44, null, 0, v40, vcc_lo              // 000000109E58: D5207C2C 01AA5080
	v_cmp_gt_i32_e32 vcc_lo, 32, v42                           // 000000109E60: 7C8854A0
	s_mov_b32 s9, 1.0                                          // 000000109E64: BE8900F2
	s_add_co_i32 s23, s23, -1                                  // 000000109E68: 8117C117
	s_add_co_i32 s8, s8, 64                                    // 000000109E6C: 8108C008
	s_wait_alu 0xfffd                                          // 000000109E70: BF88FFFD
	v_cndmask_b32_e32 v47, v41, v42, vcc_lo                    // 000000109E74: 025E5529
	v_add_co_u32 v45, vcc_lo, v43, v7                          // 000000109E78: D7006A2D 00020F2B
	s_wait_alu 0xfffd                                          // 000000109E80: BF88FFFD
	v_add_co_ci_u32_e64 v46, null, v44, v8, vcc_lo             // 000000109E84: D5207C2E 01AA112C
	v_add_co_u32 v43, vcc_lo, v43, v9                          // 000000109E8C: D7006A2B 0002132B
	s_wait_alu 0xfffd                                          // 000000109E94: BF88FFFD
	v_add_co_ci_u32_e64 v44, null, v44, v10, vcc_lo            // 000000109E98: D5207C2C 01AA152C
	s_clause 0x7                                               // 000000109EA0: BF850007
	global_load_b64 v[75:76], v[45:46], off                    // 000000109EA4: EE05407C 0000004B 0000002D
	global_load_b64 v[77:78], v[45:46], off offset:16          // 000000109EB0: EE05407C 0000004D 0000102D
	global_load_b64 v[79:80], v[45:46], off offset:32          // 000000109EBC: EE05407C 0000004F 0000202D
	global_load_b64 v[81:82], v[45:46], off offset:48          // 000000109EC8: EE05407C 00000051 0000302D
	global_load_b64 v[83:84], v[43:44], off                    // 000000109ED4: EE05407C 00000053 0000002B
	global_load_b64 v[85:86], v[43:44], off offset:16          // 000000109EE0: EE05407C 00000055 0000102B
	global_load_b64 v[87:88], v[43:44], off offset:32          // 000000109EEC: EE05407C 00000057 0000202B
	global_load_b64 v[89:90], v[43:44], off offset:48          // 000000109EF8: EE05407C 00000059 0000302B
	v_lshlrev_b32_e32 v91, 2, v47                              // 000000109F04: 30B65E82
	s_add_nc_u64 s[2:3], s[2:3], 0x10000                       // 000000109F08: A982FF02 00010000
	s_cmp_eq_u32 s23, 0                                        // 000000109F10: BF068017
	s_add_nc_u64 s[4:5], s[4:5], 0x10000                       // 000000109F14: A984FF04 00010000
	s_wait_loadcnt 0xf                                         // 000000109F1C: BFC0000F
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[11:12], v[3:4], 0  // 000000109F20: CC46402B 1A02070B
	s_wait_loadcnt 0xe                                         // 000000109F28: BFC0000E
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[13:14], v[3:4], 0  // 000000109F2C: CC464033 1A02070D
	s_wait_loadcnt 0xd                                         // 000000109F34: BFC0000D
	v_wmma_f32_16x16x16_fp8_fp8 v[59:66], v[15:16], v[3:4], 0  // 000000109F38: CC46403B 1A02070F
	s_wait_loadcnt 0xc                                         // 000000109F40: BFC0000C
	v_wmma_f32_16x16x16_fp8_fp8 v[67:74], v[23:24], v[3:4], 0  // 000000109F44: CC464043 1A020717
	s_wait_loadcnt 0xb                                         // 000000109F4C: BFC0000B
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[17:18], v[5:6], v[43:50]// 000000109F50: CC46402B 1CAE0B11
	s_wait_loadcnt 0xa                                         // 000000109F58: BFC0000A
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[19:20], v[5:6], v[51:58]// 000000109F5C: CC464033 1CCE0B13
	s_wait_loadcnt 0x9                                         // 000000109F64: BFC00009
	v_wmma_f32_16x16x16_fp8_fp8 v[59:66], v[21:22], v[5:6], v[59:66]// 000000109F68: CC46403B 1CEE0B15
	s_wait_loadcnt 0x8                                         // 000000109F70: BFC00008
	v_wmma_f32_16x16x16_fp8_fp8 v[67:74], v[25:26], v[5:6], v[67:74]// 000000109F74: CC464043 1D0E0B19
	s_wait_alu 0xfffe                                          // 000000109F7C: BF88FFFE
	v_fma_mixlo_f16 v11, s9, 0, v43                            // 000000109F80: CC21000B 04AD0009
	v_fma_mixlo_f16 v12, s9, 0, v44                            // 000000109F88: CC21000C 04B10009
	v_fma_mixlo_f16 v13, s9, 0, v45                            // 000000109F90: CC21000D 04B50009
	v_fma_mixlo_f16 v14, s9, 0, v46                            // 000000109F98: CC21000E 04B90009
	v_fma_mixlo_f16 v15, s9, 0, v47                            // 000000109FA0: CC21000F 04BD0009
	v_fma_mixlo_f16 v16, s9, 0, v48                            // 000000109FA8: CC210010 04C10009
	v_fma_mixlo_f16 v17, s9, 0, v49                            // 000000109FB0: CC210011 04C50009
	v_fma_mixlo_f16 v18, s9, 0, v50                            // 000000109FB8: CC210012 04C90009
	v_fma_mixlo_f16 v19, s9, 0, v51                            // 000000109FC0: CC210013 04CD0009
	v_fma_mixlo_f16 v20, s9, 0, v52                            // 000000109FC8: CC210014 04D10009
	v_fma_mixlo_f16 v21, s9, 0, v53                            // 000000109FD0: CC210015 04D50009
	v_fma_mixlo_f16 v22, s9, 0, v54                            // 000000109FD8: CC210016 04D90009
	v_fma_mixlo_f16 v23, s9, 0, v55                            // 000000109FE0: CC210017 04DD0009
	v_fma_mixlo_f16 v24, s9, 0, v56                            // 000000109FE8: CC210018 04E10009
	v_fma_mixlo_f16 v25, s9, 0, v57                            // 000000109FF0: CC210019 04E50009
	v_fma_mixlo_f16 v26, s9, 0, v58                            // 000000109FF8: CC21001A 04E90009
	v_fma_mixlo_f16 v43, s9, 0, v59                            // 00000010A000: CC21002B 04ED0009
	v_fma_mixlo_f16 v44, s9, 0, v60                            // 00000010A008: CC21002C 04F10009
	v_fma_mixlo_f16 v45, s9, 0, v61                            // 00000010A010: CC21002D 04F50009
	v_fma_mixlo_f16 v46, s9, 0, v62                            // 00000010A018: CC21002E 04F90009
	v_fma_mixlo_f16 v47, s9, 0, v63                            // 00000010A020: CC21002F 04FD0009
	v_fma_mixlo_f16 v48, s9, 0, v64                            // 00000010A028: CC210030 05010009
	v_fma_mixlo_f16 v49, s9, 0, v65                            // 00000010A030: CC210031 05050009
	v_fma_mixlo_f16 v50, s9, 0, v66                            // 00000010A038: CC210032 05090009
	v_fma_mixlo_f16 v51, s9, 0, v67                            // 00000010A040: CC210033 050D0009
	v_fma_mixlo_f16 v52, s9, 0, v68                            // 00000010A048: CC210034 05110009
	v_fma_mixlo_f16 v53, s9, 0, v69                            // 00000010A050: CC210035 05150009
	v_fma_mixlo_f16 v54, s9, 0, v70                            // 00000010A058: CC210036 05190009
	v_fma_mix_f32 v11, v11, s7, s6 op_sel_hi:[1,0,0]           // 00000010A060: CC20000B 08180F0B
	v_fma_mix_f32 v12, v12, s7, s6 op_sel_hi:[1,0,0]           // 00000010A068: CC20000C 08180F0C
	v_fma_mix_f32 v13, v13, s7, s6 op_sel_hi:[1,0,0]           // 00000010A070: CC20000D 08180F0D
	v_fma_mix_f32 v14, v14, s7, s6 op_sel_hi:[1,0,0]           // 00000010A078: CC20000E 08180F0E
	v_fma_mix_f32 v15, v15, s7, s6 op_sel_hi:[1,0,0]           // 00000010A080: CC20000F 08180F0F
	v_fma_mix_f32 v16, v16, s7, s6 op_sel_hi:[1,0,0]           // 00000010A088: CC200010 08180F10
	v_fma_mix_f32 v17, v17, s7, s6 op_sel_hi:[1,0,0]           // 00000010A090: CC200011 08180F11
	v_fma_mix_f32 v18, v18, s7, s6 op_sel_hi:[1,0,0]           // 00000010A098: CC200012 08180F12
	v_fma_mix_f32 v19, v19, s7, s6 op_sel_hi:[1,0,0]           // 00000010A0A0: CC200013 08180F13
	v_fma_mix_f32 v20, v20, s7, s6 op_sel_hi:[1,0,0]           // 00000010A0A8: CC200014 08180F14
	v_fma_mix_f32 v21, v21, s7, s6 op_sel_hi:[1,0,0]           // 00000010A0B0: CC200015 08180F15
	v_fma_mix_f32 v22, v22, s7, s6 op_sel_hi:[1,0,0]           // 00000010A0B8: CC200016 08180F16
	v_cvt_f16_f32_e32 v11, v11                                 // 00000010A0C0: 7E16150B
	v_cvt_f16_f32_e32 v12, v12                                 // 00000010A0C4: 7E18150C
	v_cvt_f16_f32_e32 v13, v13                                 // 00000010A0C8: 7E1A150D
	v_cvt_f16_f32_e32 v14, v14                                 // 00000010A0CC: 7E1C150E
	v_cvt_f16_f32_e32 v15, v15                                 // 00000010A0D0: 7E1E150F
	v_cvt_f16_f32_e32 v16, v16                                 // 00000010A0D4: 7E201510
	v_cvt_f16_f32_e32 v19, v19                                 // 00000010A0D8: 7E261513
	v_cvt_f16_f32_e32 v20, v20                                 // 00000010A0DC: 7E281514
	v_cvt_f16_f32_e32 v21, v21                                 // 00000010A0E0: 7E2A1515
	v_cvt_f16_f32_e32 v22, v22                                 // 00000010A0E4: 7E2C1516
	v_fma_mixlo_f16 v55, s9, 0, v71                            // 00000010A0E8: CC210037 051D0009
	v_fma_mixlo_f16 v56, s9, 0, v72                            // 00000010A0F0: CC210038 05210009
	v_fma_mixlo_f16 v57, s9, 0, v73                            // 00000010A0F8: CC210039 05250009
	v_fma_mixlo_f16 v58, s9, 0, v74                            // 00000010A100: CC21003A 05290009
	v_fma_mix_f32 v23, v23, s7, s6 op_sel_hi:[1,0,0]           // 00000010A108: CC200017 08180F17
	v_fma_mix_f32 v24, v24, s7, s6 op_sel_hi:[1,0,0]           // 00000010A110: CC200018 08180F18
	v_fma_mix_f32 v25, v25, s7, s6 op_sel_hi:[1,0,0]           // 00000010A118: CC200019 08180F19
	v_fma_mix_f32 v26, v26, s7, s6 op_sel_hi:[1,0,0]           // 00000010A120: CC20001A 08180F1A
	v_fma_mix_f32 v43, v43, s7, s6 op_sel_hi:[1,0,0]           // 00000010A128: CC20002B 08180F2B
	v_fma_mix_f32 v44, v44, s7, s6 op_sel_hi:[1,0,0]           // 00000010A130: CC20002C 08180F2C
	v_fma_mix_f32 v45, v45, s7, s6 op_sel_hi:[1,0,0]           // 00000010A138: CC20002D 08180F2D
	v_fma_mix_f32 v46, v46, s7, s6 op_sel_hi:[1,0,0]           // 00000010A140: CC20002E 08180F2E
	v_fma_mix_f32 v47, v47, s7, s6 op_sel_hi:[1,0,0]           // 00000010A148: CC20002F 08180F2F
	v_fma_mix_f32 v48, v48, s7, s6 op_sel_hi:[1,0,0]           // 00000010A150: CC200030 08180F30
	v_fma_mix_f32 v49, v49, s7, s6 op_sel_hi:[1,0,0]           // 00000010A158: CC200031 08180F31
	v_fma_mix_f32 v50, v50, s7, s6 op_sel_hi:[1,0,0]           // 00000010A160: CC200032 08180F32
	v_fma_mix_f32 v51, v51, s7, s6 op_sel_hi:[1,0,0]           // 00000010A168: CC200033 08180F33
	v_fma_mix_f32 v52, v52, s7, s6 op_sel_hi:[1,0,0]           // 00000010A170: CC200034 08180F34
	v_fma_mix_f32 v53, v53, s7, s6 op_sel_hi:[1,0,0]           // 00000010A178: CC200035 08180F35
	v_fma_mix_f32 v54, v54, s7, s6 op_sel_hi:[1,0,0]           // 00000010A180: CC200036 08180F36
	v_cvt_f16_f32_e32 v17, v17                                 // 00000010A188: 7E221511
	v_cvt_f16_f32_e32 v18, v18                                 // 00000010A18C: 7E241512
	v_cvt_f16_f32_e32 v23, v23                                 // 00000010A190: 7E2E1517
	v_cvt_f16_f32_e32 v24, v24                                 // 00000010A194: 7E301518
	v_cvt_f16_f32_e32 v25, v25                                 // 00000010A198: 7E321519
	v_cvt_f16_f32_e32 v26, v26                                 // 00000010A19C: 7E34151A
	v_cvt_f16_f32_e32 v43, v43                                 // 00000010A1A0: 7E56152B
	v_cvt_f16_f32_e32 v44, v44                                 // 00000010A1A4: 7E58152C
	v_cvt_f16_f32_e32 v45, v45                                 // 00000010A1A8: 7E5A152D
	v_cvt_f16_f32_e32 v46, v46                                 // 00000010A1AC: 7E5C152E
	v_cvt_f16_f32_e32 v47, v47                                 // 00000010A1B0: 7E5E152F
	v_cvt_f16_f32_e32 v48, v48                                 // 00000010A1B4: 7E601530
	v_cvt_f16_f32_e32 v49, v49                                 // 00000010A1B8: 7E621531
	v_cvt_f16_f32_e32 v50, v50                                 // 00000010A1BC: 7E641532
	v_cvt_f16_f32_e32 v51, v51                                 // 00000010A1C0: 7E661533
	v_cvt_f16_f32_e32 v52, v52                                 // 00000010A1C4: 7E681534
	v_cvt_f16_f32_e32 v53, v53                                 // 00000010A1C8: 7E6A1535
	v_cvt_f16_f32_e32 v54, v54                                 // 00000010A1CC: 7E6C1536
	v_pack_b32_f16 v11, v11, v12                               // 00000010A1D0: D711000B 0002190B
	v_pack_b32_f16 v12, v13, v14                               // 00000010A1D8: D711000C 00021D0D
	v_pack_b32_f16 v13, v15, v16                               // 00000010A1E0: D711000D 0002210F
	v_pack_b32_f16 v15, v19, v20                               // 00000010A1E8: D711000F 00022913
	v_pack_b32_f16 v16, v21, v22                               // 00000010A1F0: D7110010 00022D15
	v_fma_mix_f32 v55, v55, s7, s6 op_sel_hi:[1,0,0]           // 00000010A1F8: CC200037 08180F37
	v_fma_mix_f32 v56, v56, s7, s6 op_sel_hi:[1,0,0]           // 00000010A200: CC200038 08180F38
	v_fma_mix_f32 v57, v57, s7, s6 op_sel_hi:[1,0,0]           // 00000010A208: CC200039 08180F39
	v_fma_mix_f32 v58, v58, s7, s6 op_sel_hi:[1,0,0]           // 00000010A210: CC20003A 08180F3A
	v_cvt_f16_f32_e32 v55, v55                                 // 00000010A218: 7E6E1537
	v_cvt_f16_f32_e32 v56, v56                                 // 00000010A21C: 7E701538
	v_cvt_f16_f32_e32 v57, v57                                 // 00000010A220: 7E721539
	v_cvt_f16_f32_e32 v58, v58                                 // 00000010A224: 7E74153A
	v_pack_b32_f16 v14, v17, v18                               // 00000010A228: D711000E 00022511
	v_pack_b32_f16 v17, v23, v24                               // 00000010A230: D7110011 00023117
	v_pack_b32_f16 v18, v25, v26                               // 00000010A238: D7110012 00023519
	v_pack_b32_f16 v19, v43, v44                               // 00000010A240: D7110013 0002592B
	v_pack_b32_f16 v20, v45, v46                               // 00000010A248: D7110014 00025D2D
	v_pack_b32_f16 v21, v47, v48                               // 00000010A250: D7110015 0002612F
	v_pack_b32_f16 v22, v49, v50                               // 00000010A258: D7110016 00026531
	v_pack_b32_f16 v23, v51, v52                               // 00000010A260: D7110017 00026933
	v_pack_b32_f16 v24, v53, v54                               // 00000010A268: D7110018 00026D35
	v_pk_max_num_f16 v11, 0x3dc2, v11 op_sel_hi:[0,1]          // 00000010A270: CC1C400B 100216FF 00003DC2
	v_pk_max_num_f16 v12, 0x3dc2, v12 op_sel_hi:[0,1]          // 00000010A27C: CC1C400C 100218FF 00003DC2
	v_pk_max_num_f16 v13, 0x3dc2, v13 op_sel_hi:[0,1]          // 00000010A288: CC1C400D 10021AFF 00003DC2
	v_pk_max_num_f16 v15, 0x3dc2, v15 op_sel_hi:[0,1]          // 00000010A294: CC1C400F 10021EFF 00003DC2
	v_pk_max_num_f16 v16, 0x3dc2, v16 op_sel_hi:[0,1]          // 00000010A2A0: CC1C4010 100220FF 00003DC2
	v_pack_b32_f16 v25, v55, v56                               // 00000010A2AC: D7110019 00027137
	v_pack_b32_f16 v26, v57, v58                               // 00000010A2B4: D711001A 00027539
	v_pk_max_num_f16 v14, 0x3dc2, v14 op_sel_hi:[0,1]          // 00000010A2BC: CC1C400E 10021CFF 00003DC2
	v_pk_max_num_f16 v17, 0x3dc2, v17 op_sel_hi:[0,1]          // 00000010A2C8: CC1C4011 100222FF 00003DC2
	v_pk_max_num_f16 v18, 0x3dc2, v18 op_sel_hi:[0,1]          // 00000010A2D4: CC1C4012 100224FF 00003DC2
	v_pk_max_num_f16 v19, 0x3dc2, v19 op_sel_hi:[0,1]          // 00000010A2E0: CC1C4013 100226FF 00003DC2
	v_pk_max_num_f16 v20, 0x3dc2, v20 op_sel_hi:[0,1]          // 00000010A2EC: CC1C4014 100228FF 00003DC2
	v_pk_max_num_f16 v21, 0x3dc2, v21 op_sel_hi:[0,1]          // 00000010A2F8: CC1C4015 10022AFF 00003DC2
	v_pk_max_num_f16 v22, 0x3dc2, v22 op_sel_hi:[0,1]          // 00000010A304: CC1C4016 10022CFF 00003DC2
	v_pk_max_num_f16 v23, 0x3dc2, v23 op_sel_hi:[0,1]          // 00000010A310: CC1C4017 10022EFF 00003DC2
	v_pk_max_num_f16 v24, 0x3dc2, v24 op_sel_hi:[0,1]          // 00000010A31C: CC1C4018 100230FF 00003DC2
	v_pk_min_num_f16 v11, 0x3fe9, v11 op_sel_hi:[0,1]          // 00000010A328: CC1B400B 100216FF 00003FE9
	v_pk_min_num_f16 v12, 0x3fe9, v12 op_sel_hi:[0,1]          // 00000010A334: CC1B400C 100218FF 00003FE9
	v_pk_min_num_f16 v13, 0x3fe9, v13 op_sel_hi:[0,1]          // 00000010A340: CC1B400D 10021AFF 00003FE9
	v_pk_min_num_f16 v15, 0x3fe9, v15 op_sel_hi:[0,1]          // 00000010A34C: CC1B400F 10021EFF 00003FE9
	v_pk_min_num_f16 v16, 0x3fe9, v16 op_sel_hi:[0,1]          // 00000010A358: CC1B4010 100220FF 00003FE9
	v_pk_max_num_f16 v25, 0x3dc2, v25 op_sel_hi:[0,1]          // 00000010A364: CC1C4019 100232FF 00003DC2
	v_pk_max_num_f16 v26, 0x3dc2, v26 op_sel_hi:[0,1]          // 00000010A370: CC1C401A 100234FF 00003DC2
	v_pk_min_num_f16 v14, 0x3fe9, v14 op_sel_hi:[0,1]          // 00000010A37C: CC1B400E 10021CFF 00003FE9
	v_pk_min_num_f16 v17, 0x3fe9, v17 op_sel_hi:[0,1]          // 00000010A388: CC1B4011 100222FF 00003FE9
	v_pk_min_num_f16 v18, 0x3fe9, v18 op_sel_hi:[0,1]          // 00000010A394: CC1B4012 100224FF 00003FE9
	v_pk_min_num_f16 v19, 0x3fe9, v19 op_sel_hi:[0,1]          // 00000010A3A0: CC1B4013 100226FF 00003FE9
	v_pk_min_num_f16 v20, 0x3fe9, v20 op_sel_hi:[0,1]          // 00000010A3AC: CC1B4014 100228FF 00003FE9
	v_pk_min_num_f16 v21, 0x3fe9, v21 op_sel_hi:[0,1]          // 00000010A3B8: CC1B4015 10022AFF 00003FE9
	v_pk_min_num_f16 v22, 0x3fe9, v22 op_sel_hi:[0,1]          // 00000010A3C4: CC1B4016 10022CFF 00003FE9
	v_pk_min_num_f16 v23, 0x3fe9, v23 op_sel_hi:[0,1]          // 00000010A3D0: CC1B4017 10022EFF 00003FE9
	v_pk_min_num_f16 v24, 0x3fe9, v24 op_sel_hi:[0,1]          // 00000010A3DC: CC1B4018 100230FF 00003FE9
	v_pk_lshlrev_b16 v11, 4, v11 op_sel_hi:[0,1]               // 00000010A3E8: CC04400B 10021684
	v_pk_lshlrev_b16 v12, 4, v12 op_sel_hi:[0,1]               // 00000010A3F0: CC04400C 10021884
	v_pk_lshlrev_b16 v13, 4, v13 op_sel_hi:[0,1]               // 00000010A3F8: CC04400D 10021A84
	v_pk_lshlrev_b16 v15, 4, v15 op_sel_hi:[0,1]               // 00000010A400: CC04400F 10021E84
	v_pk_lshlrev_b16 v16, 4, v16 op_sel_hi:[0,1]               // 00000010A408: CC044010 10022084
	v_pk_min_num_f16 v25, 0x3fe9, v25 op_sel_hi:[0,1]          // 00000010A410: CC1B4019 100232FF 00003FE9
	v_pk_min_num_f16 v26, 0x3fe9, v26 op_sel_hi:[0,1]          // 00000010A41C: CC1B401A 100234FF 00003FE9
	v_pk_lshlrev_b16 v14, 4, v14 op_sel_hi:[0,1]               // 00000010A428: CC04400E 10021C84
	v_pk_lshlrev_b16 v17, 4, v17 op_sel_hi:[0,1]               // 00000010A430: CC044011 10022284
	v_pk_lshlrev_b16 v18, 4, v18 op_sel_hi:[0,1]               // 00000010A438: CC044012 10022484
	v_pk_lshlrev_b16 v19, 4, v19 op_sel_hi:[0,1]               // 00000010A440: CC044013 10022684
	v_pk_lshlrev_b16 v20, 4, v20 op_sel_hi:[0,1]               // 00000010A448: CC044014 10022884
	v_pk_lshlrev_b16 v21, 4, v21 op_sel_hi:[0,1]               // 00000010A450: CC044015 10022A84
	v_pk_lshlrev_b16 v22, 4, v22 op_sel_hi:[0,1]               // 00000010A458: CC044016 10022C84
	v_pk_lshlrev_b16 v23, 4, v23 op_sel_hi:[0,1]               // 00000010A460: CC044017 10022E84
	v_pk_lshlrev_b16 v24, 4, v24 op_sel_hi:[0,1]               // 00000010A468: CC044018 10023084
	v_pk_add_u16 v51, v11, 2.0 op_sel:[0,1]                    // 00000010A470: CC0A5033 1801E90B
	v_pk_add_u16 v11, v12, 2.0 op_sel:[0,1]                    // 00000010A478: CC0A500B 1801E90C
	v_pk_add_u16 v52, v13, 2.0 op_sel:[0,1]                    // 00000010A480: CC0A5034 1801E90D
	v_pk_add_u16 v59, v15, 2.0 op_sel:[0,1]                    // 00000010A488: CC0A503B 1801E90F
	v_pk_add_u16 v13, v16, 2.0 op_sel:[0,1]                    // 00000010A490: CC0A500D 1801E910
	v_pk_lshlrev_b16 v25, 4, v25 op_sel_hi:[0,1]               // 00000010A498: CC044019 10023284
	v_pk_lshlrev_b16 v26, 4, v26 op_sel_hi:[0,1]               // 00000010A4A0: CC04401A 10023484
	v_pk_add_u16 v12, v14, 2.0 op_sel:[0,1]                    // 00000010A4A8: CC0A500C 1801E90E
	v_pk_add_u16 v60, v17, 2.0 op_sel:[0,1]                    // 00000010A4B0: CC0A503C 1801E911
	v_pk_add_u16 v14, v18, 2.0 op_sel:[0,1]                    // 00000010A4B8: CC0A500E 1801E912
	v_pk_add_u16 v61, v19, 2.0 op_sel:[0,1]                    // 00000010A4C0: CC0A503D 1801E913
	v_pk_add_u16 v15, v20, 2.0 op_sel:[0,1]                    // 00000010A4C8: CC0A500F 1801E914
	v_pk_add_u16 v62, v21, 2.0 op_sel:[0,1]                    // 00000010A4D0: CC0A503E 1801E915
	v_pk_add_u16 v16, v22, 2.0 op_sel:[0,1]                    // 00000010A4D8: CC0A5010 1801E916
	v_pk_add_u16 v63, v23, 2.0 op_sel:[0,1]                    // 00000010A4E0: CC0A503F 1801E917
	v_pk_add_u16 v17, v24, 2.0 op_sel:[0,1]                    // 00000010A4E8: CC0A5011 1801E918
	ds_bpermute_b32 v19, v91, v51                              // 00000010A4F0: DACC0000 1300335B
	ds_bpermute_b32 v20, v91, v59                              // 00000010A4F8: DACC0000 14003B5B
	ds_bpermute_b32 v23, v91, v11                              // 00000010A500: DACC0000 17000B5B
	ds_bpermute_b32 v24, v91, v13                              // 00000010A508: DACC0000 18000D5B
	v_pk_add_u16 v64, v25, 2.0 op_sel:[0,1]                    // 00000010A510: CC0A5040 1801E919
	v_pk_add_u16 v18, v26, 2.0 op_sel:[0,1]                    // 00000010A518: CC0A5012 1801E91A
	ds_bpermute_b32 v21, v91, v61                              // 00000010A520: DACC0000 15003D5B
	ds_bpermute_b32 v22, v91, v63                              // 00000010A528: DACC0000 16003F5B
	ds_bpermute_b32 v25, v91, v15                              // 00000010A530: DACC0000 19000F5B
	ds_bpermute_b32 v26, v91, v17                              // 00000010A538: DACC0000 1A00115B
	ds_bpermute_b32 v43, v91, v52                              // 00000010A540: DACC0000 2B00345B
	ds_bpermute_b32 v44, v91, v60                              // 00000010A548: DACC0000 2C003C5B
	ds_bpermute_b32 v45, v91, v62                              // 00000010A550: DACC0000 2D003E5B
	ds_bpermute_b32 v104, v91, v12                             // 00000010A558: DACC0000 68000C5B
	ds_bpermute_b32 v105, v91, v14                             // 00000010A560: DACC0000 69000E5B
	ds_bpermute_b32 v106, v91, v16                             // 00000010A568: DACC0000 6A00105B
	ds_bpermute_b32 v46, v91, v64                              // 00000010A570: DACC0000 2E00405B
	v_lshrrev_b32_e32 v48, 16, v51                             // 00000010A578: 32606690
	v_lshrrev_b32_e32 v54, 16, v52                             // 00000010A57C: 326C6890
	v_lshrrev_b32_e32 v58, 16, v59                             // 00000010A580: 32747690
	v_lshrrev_b32_e32 v68, 16, v60                             // 00000010A584: 32887890
	v_lshrrev_b32_e32 v72, 16, v61                             // 00000010A588: 32907A90
	v_lshrrev_b32_e32 v93, 16, v62                             // 00000010A58C: 32BA7C90
	ds_bpermute_b32 v91, v91, v18                              // 00000010A590: DACC0000 5B00125B
	v_cvt_f32_f16_e32 v47, v51                                 // 00000010A598: 7E5E1733
	v_cvt_f32_f16_e32 v49, v11                                 // 00000010A59C: 7E62170B
	v_lshrrev_b32_e32 v50, 16, v11                             // 00000010A5A0: 32641690
	v_cvt_f32_f16_e32 v53, v52                                 // 00000010A5A4: 7E6A1734
	v_lshrrev_b32_e32 v56, 16, v12                             // 00000010A5A8: 32701890
	v_cvt_f32_f16_e32 v57, v59                                 // 00000010A5AC: 7E72173B
	v_cvt_f32_f16_e32 v65, v13                                 // 00000010A5B0: 7E82170D
	v_lshrrev_b32_e32 v66, 16, v13                             // 00000010A5B4: 32841A90
	v_cvt_f32_f16_e32 v67, v60                                 // 00000010A5B8: 7E86173C
	v_lshrrev_b32_e32 v70, 16, v14                             // 00000010A5BC: 328C1C90
	v_cvt_f32_f16_e32 v71, v61                                 // 00000010A5C0: 7E8E173D
	v_lshrrev_b32_e32 v74, 16, v15                             // 00000010A5C4: 32941E90
	v_cvt_f32_f16_e32 v92, v62                                 // 00000010A5C8: 7EB8173E
	v_lshrrev_b32_e32 v95, 16, v16                             // 00000010A5CC: 32BE2090
	v_cvt_f32_f16_e32 v48, v48                                 // 00000010A5D0: 7E601730
	v_cvt_f32_f16_e32 v54, v54                                 // 00000010A5D4: 7E6C1736
	v_cvt_f32_f16_e32 v58, v58                                 // 00000010A5D8: 7E74173A
	v_cvt_f32_f16_e32 v68, v68                                 // 00000010A5DC: 7E881744
	v_cvt_f32_f16_e32 v72, v72                                 // 00000010A5E0: 7E901748
	v_cvt_f32_f16_e32 v93, v93                                 // 00000010A5E4: 7EBA175D
	s_wait_dscnt 0xf                                           // 00000010A5E8: BFC6000F
	v_pk_add_f16 v19, v51, v19                                 // 00000010A5EC: CC0F4013 18022733
	s_wait_dscnt 0xe                                           // 00000010A5F4: BFC6000E
	v_pk_add_f16 v20, v59, v20                                 // 00000010A5F8: CC0F4014 1802293B
	s_wait_dscnt 0xd                                           // 00000010A600: BFC6000D
	v_pk_add_f16 v11, v11, v23                                 // 00000010A604: CC0F400B 18022F0B
	s_wait_dscnt 0xc                                           // 00000010A60C: BFC6000C
	v_pk_add_f16 v13, v13, v24                                 // 00000010A610: CC0F400D 1802310D
	v_cvt_f32_f16_e32 v55, v12                                 // 00000010A618: 7E6E170C
	v_cvt_f32_f16_e32 v69, v14                                 // 00000010A61C: 7E8A170E
	v_cvt_f32_f16_e32 v73, v15                                 // 00000010A620: 7E92170F
	v_cvt_f32_f16_e32 v94, v16                                 // 00000010A624: 7EBC1710
	v_lshrrev_b32_e32 v97, 16, v63                             // 00000010A628: 32C27E90
	v_cvt_f32_f16_e32 v98, v17                                 // 00000010A62C: 7EC41711
	v_lshrrev_b32_e32 v99, 16, v17                             // 00000010A630: 32C62290
	v_lshrrev_b32_e32 v101, 16, v64                            // 00000010A634: 32CA8090
	v_cvt_f32_f16_e32 v50, v50                                 // 00000010A638: 7E641732
	v_cvt_f32_f16_e32 v56, v56                                 // 00000010A63C: 7E701738
	v_cvt_f32_f16_e32 v66, v66                                 // 00000010A640: 7E841742
	v_cvt_f32_f16_e32 v70, v70                                 // 00000010A644: 7E8C1746
	v_cvt_f32_f16_e32 v74, v74                                 // 00000010A648: 7E94174A
	v_cvt_f32_f16_e32 v95, v95                                 // 00000010A64C: 7EBE175F
	s_wait_dscnt 0xb                                           // 00000010A650: BFC6000B
	v_pk_add_f16 v21, v61, v21                                 // 00000010A654: CC0F4015 18022B3D
	s_wait_dscnt 0xa                                           // 00000010A65C: BFC6000A
	v_pk_add_f16 v107, v63, v22                                // 00000010A660: CC0F406B 18022D3F
	s_wait_dscnt 0x9                                           // 00000010A668: BFC60009
	v_pk_add_f16 v15, v15, v25                                 // 00000010A66C: CC0F400F 1802330F
	s_wait_dscnt 0x8                                           // 00000010A674: BFC60008
	v_pk_add_f16 v108, v17, v26                                // 00000010A678: CC0F406C 18023511
	s_wait_dscnt 0x7                                           // 00000010A680: BFC60007
	v_pk_add_f16 v17, v52, v43                                 // 00000010A684: CC0F4011 18025734
	s_wait_dscnt 0x6                                           // 00000010A68C: BFC60006
	v_pk_add_f16 v22, v60, v44                                 // 00000010A690: CC0F4016 1802593C
	s_wait_dscnt 0x5                                           // 00000010A698: BFC60005
	v_pk_add_f16 v23, v62, v45                                 // 00000010A69C: CC0F4017 18025B3E
	v_cvt_pk_fp8_f32 v51, v47, v48                             // 00000010A6A4: D7690033 0002612F
	v_cvt_pk_fp8_f32 v52, v53, v54                             // 00000010A6AC: D7690034 00026D35
	v_cvt_pk_fp8_f32 v59, v57, v58                             // 00000010A6B4: D769003B 00027539
	v_cvt_pk_fp8_f32 v60, v67, v68                             // 00000010A6BC: D769003C 00028943
	v_cvt_pk_fp8_f32 v61, v71, v72                             // 00000010A6C4: D769003D 00029147
	v_cvt_pk_fp8_f32 v62, v92, v93                             // 00000010A6CC: D769003E 0002BB5C
	s_wait_dscnt 0x4                                           // 00000010A6D4: BFC60004
	v_pk_add_f16 v12, v12, v104                                // 00000010A6D8: CC0F400C 1802D10C
	s_wait_dscnt 0x3                                           // 00000010A6E0: BFC60003
	v_pk_add_f16 v14, v14, v105                                // 00000010A6E4: CC0F400E 1802D30E
	s_wait_dscnt 0x2                                           // 00000010A6EC: BFC60002
	v_pk_add_f16 v67, v16, v106                                // 00000010A6F0: CC0F4043 1802D510
	v_pk_add_f16 v16, v19, v20                                 // 00000010A6F8: CC0F4010 18022913
	v_pk_add_f16 v11, v11, v13                                 // 00000010A700: CC0F400B 18021B0B
	v_cvt_f32_f16_e32 v96, v63                                 // 00000010A708: 7EC0173F
	v_cvt_f32_f16_e32 v100, v64                                // 00000010A70C: 7EC81740
	v_lshrrev_b32_e32 v103, 16, v18                            // 00000010A710: 32CE2490
	v_cvt_f32_f16_e32 v97, v97                                 // 00000010A714: 7EC21761
	v_cvt_f32_f16_e32 v101, v101                               // 00000010A718: 7ECA1765
	v_pk_add_f16 v13, v17, v22                                 // 00000010A71C: CC0F400D 18022D11
	v_cvt_pk_fp8_f32 v51, v49, v50 op_sel:[0,0,1]              // 00000010A724: D7694033 00026531
	v_cvt_pk_fp8_f32 v52, v55, v56 op_sel:[0,0,1]              // 00000010A72C: D7694034 00027137
	v_cvt_pk_fp8_f32 v59, v65, v66 op_sel:[0,0,1]              // 00000010A734: D769403B 00028541
	v_cvt_pk_fp8_f32 v60, v69, v70 op_sel:[0,0,1]              // 00000010A73C: D769403C 00028D45
	v_cvt_pk_fp8_f32 v61, v73, v74 op_sel:[0,0,1]              // 00000010A744: D769403D 00029549
	v_cvt_pk_fp8_f32 v62, v94, v95 op_sel:[0,0,1]              // 00000010A74C: D769403E 0002BF5E
	v_pk_add_f16 v65, v12, v14                                 // 00000010A754: CC0F4041 18021D0C
	v_pk_add_f16 v66, v21, v16                                 // 00000010A75C: CC0F4042 18022115
	v_pk_add_f16 v69, v15, v11                                 // 00000010A764: CC0F4045 1802170F
	v_cvt_f32_f16_e32 v102, v18                                // 00000010A76C: 7ECC1712
	v_cvt_f32_f16_e32 v99, v99                                 // 00000010A770: 7EC61763
	v_cvt_f32_f16_e32 v103, v103                               // 00000010A774: 7ECE1767
	s_wait_dscnt 0x1                                           // 00000010A778: BFC60001
	v_pk_add_f16 v109, v64, v46                                // 00000010A77C: CC0F406D 18025D40
	v_cvt_pk_fp8_f32 v63, v96, v97                             // 00000010A784: D769003F 0002C360
	v_cvt_pk_fp8_f32 v64, v100, v101                           // 00000010A78C: D7690040 0002CB64
	s_wait_dscnt 0x0                                           // 00000010A794: BFC60000
	v_pk_add_f16 v68, v18, v91                                 // 00000010A798: CC0F4044 1802B712
	v_pk_add_f16 v70, v23, v13                                 // 00000010A7A0: CC0F4046 18021B17
	s_wait_loadcnt 0x7                                         // 00000010A7A8: BFC00007
	v_wmma_f32_16x16x16_fp8_fp8 v[11:18], v[75:76], v[51:52], 0// 00000010A7AC: CC46400B 1A02674B
	s_wait_loadcnt 0x5                                         // 00000010A7B4: BFC00005
	v_wmma_f32_16x16x16_fp8_fp8 v[19:26], v[79:80], v[61:62], 0// 00000010A7B8: CC464013 1A027B4F
	s_wait_loadcnt 0x3                                         // 00000010A7C0: BFC00003
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[83:84], v[51:52], 0// 00000010A7C4: CC46402B 1A026753
	s_wait_loadcnt 0x1                                         // 00000010A7CC: BFC00001
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[87:88], v[61:62], 0// 00000010A7D0: CC464033 1A027B57
	v_pk_add_f16 v61, v67, v65                                 // 00000010A7D8: CC0F403D 18028343
	v_pk_add_f16 v62, v107, v66                                // 00000010A7E0: CC0F403E 1802856B
	v_pk_add_f16 v65, v108, v69                                // 00000010A7E8: CC0F4041 18028B6C
	v_cvt_pk_fp8_f32 v63, v98, v99 op_sel:[0,0,1]              // 00000010A7F0: D769403F 0002C762
	v_cvt_pk_fp8_f32 v64, v102, v103 op_sel:[0,0,1]            // 00000010A7F8: D7694040 0002CF66
	v_pk_add_f16 v66, v109, v70                                // 00000010A800: CC0F4042 18028D6D
	v_wmma_f32_16x16x16_fp8_fp8 v[11:18], v[77:78], v[59:60], v[11:18]// 00000010A808: CC46400B 1C2E774D
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[85:86], v[59:60], v[43:50]// 00000010A810: CC46402B 1CAE7755
	v_pk_add_f16 v60, v62, v65                                 // 00000010A818: CC0F403C 1802833E
	v_wmma_f32_16x16x16_fp8_fp8 v[19:26], v[81:82], v[63:64], v[19:26]// 00000010A820: CC464013 1C4E7F51
	v_pk_add_f16 v59, v68, v61                                 // 00000010A828: CC0F403B 18027B44
	v_fma_mixlo_f16 v11, v33, s9, v11 op_sel_hi:[1,0,0]        // 00000010A830: CC21000B 0C2C1321
	v_fma_mixlo_f16 v49, v29, s9, v49 op_sel_hi:[1,0,0]        // 00000010A838: CC210031 0CC4131D
	v_fma_mixlo_f16 v50, v29, s9, v50 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A840: CC210832 0CC8131D
	v_pk_add_f16 v29, v60, v66                                 // 00000010A848: CC0F401D 1802853C
	v_fma_mixlo_f16 v12, v33, s9, v12 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A850: CC21080C 0C301321
	v_fma_mixlo_f16 v13, v37, s9, v13 op_sel_hi:[1,0,0]        // 00000010A858: CC21000D 0C341325
	v_fma_mixlo_f16 v33, v11, s9, v19 op_sel_hi:[1,0,0]        // 00000010A860: CC210021 0C4C130B
	s_wait_loadcnt 0x0                                         // 00000010A868: BFC00000
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[89:90], v[63:64], v[51:58]// 00000010A86C: CC464033 1CCE7F59
	v_pk_add_f16 v11, v29, v59                                 // 00000010A874: CC0F400B 1802771D
	v_fma_mixlo_f16 v14, v37, s9, v14 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A87C: CC21080E 0C381325
	v_fma_mixlo_f16 v15, v35, s9, v15 op_sel_hi:[1,0,0]        // 00000010A884: CC21000F 0C3C1323
	v_fma_mixlo_f16 v17, v34, s9, v17 op_sel_hi:[1,0,0]        // 00000010A88C: CC210011 0C441322
	v_fma_mixlo_f16 v43, v32, s9, v43 op_sel_hi:[1,0,0]        // 00000010A894: CC21002B 0CAC1320
	v_fma_mixlo_f16 v45, v31, s9, v45 op_sel_hi:[1,0,0]        // 00000010A89C: CC21002D 0CB4131F
	v_fma_mixlo_f16 v47, v30, s9, v47 op_sel_hi:[1,0,0]        // 00000010A8A4: CC21002F 0CBC131E
	v_fma_mixlo_f16 v37, v13, s9, v21 op_sel_hi:[1,0,0]        // 00000010A8AC: CC210025 0C54130D
	v_alignbit_b32 v13, s0, v11, 16                            // 00000010A8B4: D616000D 02421600
	v_fma_mixlo_f16 v16, v35, s9, v16 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A8BC: CC210810 0C401323
	v_fma_mixlo_f16 v18, v34, s9, v18 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A8C4: CC210812 0C481322
	v_fma_mixlo_f16 v44, v32, s9, v44 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A8CC: CC21082C 0CB01320
	v_fma_mixlo_f16 v46, v31, s9, v46 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A8D4: CC21082E 0CB8131F
	v_fma_mixlo_f16 v48, v30, s9, v48 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010A8DC: CC210830 0CC0131E
	v_fma_mixlo_f16 v35, v15, s9, v23 op_sel_hi:[1,0,0]        // 00000010A8E4: CC210023 0C5C130F
	v_fma_mixlo_f16 v34, v17, s9, v25 op_sel_hi:[1,0,0]        // 00000010A8EC: CC210022 0C641311
	v_fma_mixlo_f16 v32, v43, s9, v51 op_sel_hi:[1,0,0]        // 00000010A8F4: CC210020 0CCC132B
	v_fma_mixlo_f16 v31, v45, s9, v53 op_sel_hi:[1,0,0]        // 00000010A8FC: CC21001F 0CD4132D
	v_fma_mixlo_f16 v30, v47, s9, v55 op_sel_hi:[1,0,0]        // 00000010A904: CC21001E 0CDC132F
	v_fma_mixlo_f16 v29, v49, s9, v57 op_sel_hi:[1,0,0]        // 00000010A90C: CC21001D 0CE41331
	v_pk_add_f16 v11, v11, v13                                 // 00000010A914: CC0F400B 18021B0B
	v_fma_mixhi_f16 v33, v12, s9, v20 op_sel_hi:[1,0,0]        // 00000010A91C: CC220021 0C50130C
	v_fma_mixhi_f16 v37, v14, s9, v22 op_sel_hi:[1,0,0]        // 00000010A924: CC220025 0C58130E
	v_fma_mixhi_f16 v35, v16, s9, v24 op_sel_hi:[1,0,0]        // 00000010A92C: CC220023 0C601310
	v_fma_mixhi_f16 v34, v18, s9, v26 op_sel_hi:[1,0,0]        // 00000010A934: CC220022 0C681312
	v_fma_mixhi_f16 v32, v44, s9, v52 op_sel_hi:[1,0,0]        // 00000010A93C: CC220020 0CD0132C
	v_fma_mixhi_f16 v31, v46, s9, v54 op_sel_hi:[1,0,0]        // 00000010A944: CC22001F 0CD8132E
	v_fma_mixhi_f16 v30, v48, s9, v56 op_sel_hi:[1,0,0]        // 00000010A94C: CC22001E 0CE01330
	v_fma_mixhi_f16 v29, v50, s9, v58 op_sel_hi:[1,0,0]        // 00000010A954: CC22001D 0CE81332
	v_pk_add_f16 v38, v38, v11 op_sel_hi:[1,0]                 // 00000010A95C: CC0F4026 08021726
	s_cbranch_scc0 64788                                       // 00000010A964: BFA1FD14 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0x1b8>
	s_sub_co_i32 s2, s12, s13                                  // 00000010A968: 81820D0C
	s_mov_b32 s3, 0xbdac0000                                   // 00000010A96C: BE8300FF BDAC0000
	s_wait_alu 0xfffe                                          // 00000010A974: BF88FFFE
	s_cvt_f32_i32 s2, s2                                       // 00000010A978: BE826402
	s_wait_kmcnt 0x0                                           // 00000010A97C: BFC70000
	s_add_nc_u64 s[4:5], 8, s[18:19]                           // 00000010A980: A9841288
	s_wait_alu 0xfffe                                          // 00000010A984: BF88FFFE
	v_fma_mixlo_f16 v3, s2, s3, 0                              // 00000010A988: CC210003 02000602
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000010A990: BF870091
	v_add_f16_e32 v3, v38, v3                                  // 00000010A994: 64060726
	v_cvt_f32_f16_e32 v3, v3                                   // 00000010A998: 7E061703
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000010A99C: BF870091
	v_max_num_f32_e32 v3, 0x38820000, v3                       // 00000010A9A0: 2C0606FF 38820000
	v_div_scale_f32 v4, null, v3, v3, 1.0                      // 00000010A9A8: D6FC7C04 03CA0703
	v_div_scale_f32 v7, vcc_lo, 1.0, v3, 1.0                   // 00000010A9B0: D6FC6A07 03CA06F2
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)// 00000010A9B8: BF870292
	v_rcp_f32_e32 v5, v4                                       // 00000010A9BC: 7E0A5504
	v_fma_f32 v6, -v4, v5, 1.0                                 // 00000010A9C0: D6130006 23CA0B04
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000010A9C8: BF870091
	v_fmac_f32_e32 v5, v6, v5                                  // 00000010A9CC: 560A0B06
	v_mul_f32_e32 v6, v7, v5                                   // 00000010A9D0: 100C0B07
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000010A9D4: BF870091
	v_fma_f32 v8, -v4, v6, v7                                  // 00000010A9D8: D6130008 241E0D04
	v_fmac_f32_e32 v6, v8, v5                                  // 00000010A9E0: 560C0B08
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 00000010A9E4: BF870131
	v_fma_f32 v4, -v4, v6, v7                                  // 00000010A9E8: D6130004 241E0D04
	v_lshl_add_u32 v7, v36, 4, s22                             // 00000010A9F0: D6460007 00590924
	s_wait_alu 0xfffd                                          // 00000010A9F8: BF88FFFD
	v_div_fmas_f32 v4, v4, v5, v6                              // 00000010A9FC: D6370004 041A0B04
	v_add_co_u32 v1, vcc_lo, s10, v1                           // 00000010AA04: D7006A01 0002020A
	s_wait_alu 0xfffd                                          // 00000010AA0C: BF88FFFD
	v_add_co_ci_u32_e64 v2, null, s11, v2, vcc_lo              // 00000010AA10: D5207C02 01AA040B
	v_cmp_eq_u32_e32 vcc_lo, 0, v0                             // 00000010AA18: 7C940080
	v_div_fixup_f32 v0, v4, v3, 1.0                            // 00000010AA1C: D6270000 03CA0704
	v_add_co_u32 v3, s2, v1, v28                               // 00000010AA24: D7000203 00023901
	v_or_b32_e32 v5, v7, v27                                   // 00000010AA2C: 380A3707
	s_wait_alu 0xf1ff                                          // 00000010AA30: BF88F1FF
	v_add_co_ci_u32_e64 v7, null, 0, v2, s2                    // 00000010AA34: D5207C07 000A0480
	v_cvt_f16_f32_e32 v2, v0                                   // 00000010AA3C: 7E041500
	v_add_co_u32 v0, s2, v3, s18                               // 00000010AA40: D7000200 00002503
	s_wait_alu 0xf1ff                                          // 00000010AA48: BF88F1FF
	v_add_co_ci_u32_e64 v1, null, 0, v7, s2                    // 00000010AA4C: D5207C01 000A0E80
	v_pk_mul_f16 v6, v2, v37 op_sel_hi:[0,1]                   // 00000010AA54: CC104006 10024B02
	v_pk_mul_f16 v8, v2, v35 op_sel_hi:[0,1]                   // 00000010AA5C: CC104008 10024702
	v_pk_mul_f16 v12, v2, v30 op_sel_hi:[0,1]                  // 00000010AA64: CC10400C 10023D02
	v_pk_mul_f16 v4, v2, v33 op_sel_hi:[0,1]                   // 00000010AA6C: CC104004 10024302
	v_pk_mul_f16 v9, v2, v34 op_sel_hi:[0,1]                   // 00000010AA74: CC104009 10024502
	v_pk_max_num_f16 v6, 0xdf00, v6 op_sel_hi:[0,1]            // 00000010AA7C: CC1C4006 10020CFF 0000DF00
	v_pk_max_num_f16 v8, 0xdf00, v8 op_sel_hi:[0,1]            // 00000010AA88: CC1C4008 100210FF 0000DF00
	v_pk_mul_f16 v10, v2, v32 op_sel_hi:[0,1]                  // 00000010AA94: CC10400A 10024102
	v_pk_mul_f16 v11, v2, v31 op_sel_hi:[0,1]                  // 00000010AA9C: CC10400B 10023F02
	v_pk_mul_f16 v2, v2, v29 op_sel_hi:[0,1]                   // 00000010AAA4: CC104002 10023B02
	v_pk_max_num_f16 v12, 0xdf00, v12 op_sel_hi:[0,1]          // 00000010AAAC: CC1C400C 100218FF 0000DF00
	v_pk_max_num_f16 v4, 0xdf00, v4 op_sel_hi:[0,1]            // 00000010AAB8: CC1C4004 100208FF 0000DF00
	v_pk_max_num_f16 v9, 0xdf00, v9 op_sel_hi:[0,1]            // 00000010AAC4: CC1C4009 100212FF 0000DF00
	v_pk_min_num_f16 v8, 0x5f00, v8 op_sel_hi:[0,1]            // 00000010AAD0: CC1B4008 100210FF 00005F00
	v_pk_min_num_f16 v6, 0x5f00, v6 op_sel_hi:[0,1]            // 00000010AADC: CC1B4006 10020CFF 00005F00
	v_cmp_gt_i32_e64 s2, s13, v5                               // 00000010AAE8: D4440002 00020A0D
	v_pk_max_num_f16 v10, 0xdf00, v10 op_sel_hi:[0,1]          // 00000010AAF0: CC1C400A 100214FF 0000DF00
	v_pk_max_num_f16 v2, 0xdf00, v2 op_sel_hi:[0,1]            // 00000010AAFC: CC1C4002 100204FF 0000DF00
	v_pk_min_num_f16 v5, 0x5f00, v12 op_sel_hi:[0,1]           // 00000010AB08: CC1B4005 100218FF 00005F00
	v_pk_min_num_f16 v4, 0x5f00, v4 op_sel_hi:[0,1]            // 00000010AB14: CC1B4004 100208FF 00005F00
	v_pk_min_num_f16 v9, 0x5f00, v9 op_sel_hi:[0,1]            // 00000010AB20: CC1B4009 100212FF 00005F00
	s_wait_alu 0xf1ff                                          // 00000010AB2C: BF88F1FF
	v_cndmask_b32_e64 v8, 0, v8, s2                            // 00000010AB30: D5010008 000A1080
	v_cndmask_b32_e64 v6, 0, v6, s2                            // 00000010AB38: D5010006 000A0C80
	v_pk_max_num_f16 v11, 0xdf00, v11 op_sel_hi:[0,1]          // 00000010AB40: CC1C400B 100216FF 0000DF00
	v_pk_min_num_f16 v10, 0x5f00, v10 op_sel_hi:[0,1]          // 00000010AB4C: CC1B400A 100214FF 00005F00
	v_pk_min_num_f16 v12, 0x5f00, v2 op_sel_hi:[0,1]           // 00000010AB58: CC1B400C 100204FF 00005F00
	v_cndmask_b32_e64 v5, 0, v5, s2                            // 00000010AB64: D5010005 000A0A80
	v_cndmask_b32_e64 v2, 0, v4, s2                            // 00000010AB6C: D5010002 000A0880
	v_cndmask_b32_e64 v9, 0, v9, s2                            // 00000010AB74: D5010009 000A1280
	v_cvt_f32_f16_e32 v14, v6                                  // 00000010AB7C: 7E1C1706
	v_lshrrev_b32_e32 v6, 16, v6                               // 00000010AB80: 320C0C90
	v_lshrrev_b32_e32 v16, 16, v8                              // 00000010AB84: 32201090
	v_pk_min_num_f16 v11, 0x5f00, v11 op_sel_hi:[0,1]          // 00000010AB88: CC1B400B 100216FF 00005F00
	v_cndmask_b32_e64 v4, 0, v10, s2                           // 00000010AB94: D5010004 000A1480
	v_cndmask_b32_e64 v10, 0, v12, s2                          // 00000010AB9C: D501000A 000A1880
	v_lshrrev_b32_e32 v22, 16, v5                              // 00000010ABA4: 322C0A90
	v_lshrrev_b32_e32 v13, 16, v2                              // 00000010ABA8: 321A0490
	v_cvt_f32_f16_e32 v15, v8                                  // 00000010ABAC: 7E1E1708
	v_cvt_f32_f16_e32 v17, v9                                  // 00000010ABB0: 7E221709
	v_lshrrev_b32_e32 v9, 16, v9                               // 00000010ABB4: 32121290
	v_cvt_f32_f16_e32 v24, v6                                  // 00000010ABB8: 7E301706
	v_cvt_f32_f16_e32 v6, v16                                  // 00000010ABBC: 7E0C1710
	v_cndmask_b32_e64 v11, 0, v11, s2                          // 00000010ABC0: D501000B 000A1680
	v_lshrrev_b32_e32 v19, 16, v4                              // 00000010ABC8: 32260890
	v_cvt_f32_f16_e32 v21, v5                                  // 00000010ABCC: 7E2A1705
	v_cvt_f32_f16_e32 v23, v10                                 // 00000010ABD0: 7E2E170A
	v_lshrrev_b32_e32 v10, 16, v10                             // 00000010ABD4: 32141490
	v_cvt_f32_f16_e32 v16, v22                                 // 00000010ABD8: 7E201716
	v_cvt_f32_f16_e32 v12, v2                                  // 00000010ABDC: 7E181702
	v_cvt_f32_f16_e32 v13, v13                                 // 00000010ABE0: 7E1A170D
	v_cvt_f32_f16_e32 v9, v9                                   // 00000010ABE4: 7E121709
	v_cvt_pk_fp8_f32 v8, v15, v6                               // 00000010ABE8: D7690008 00020D0F
	v_cvt_f32_f16_e32 v18, v4                                  // 00000010ABF0: 7E241704
	v_cvt_f32_f16_e32 v20, v11                                 // 00000010ABF4: 7E28170B
	v_lshrrev_b32_e32 v11, 16, v11                             // 00000010ABF8: 32161690
	v_cvt_f32_f16_e32 v19, v19                                 // 00000010ABFC: 7E261713
	v_cvt_f32_f16_e32 v10, v10                                 // 00000010AC00: 7E14170A
	v_cvt_pk_fp8_f32 v5, v21, v16                              // 00000010AC04: D7690005 00022115
	v_cvt_pk_fp8_f32 v2, v12, v13                              // 00000010AC0C: D7690002 00021B0C
	v_cvt_pk_fp8_f32 v8, v17, v9 op_sel:[0,0,1]                // 00000010AC14: D7694008 00021311
	v_cvt_f32_f16_e32 v11, v11                                 // 00000010AC1C: 7E16170B
	v_cvt_pk_fp8_f32 v4, v18, v19                              // 00000010AC20: D7690004 00022712
	v_cvt_pk_fp8_f32 v5, v23, v10 op_sel:[0,0,1]               // 00000010AC28: D7694005 00021517
	v_add_co_u32 v6, s2, s4, v3                                // 00000010AC30: D7000206 00020604
	v_cvt_pk_fp8_f32 v2, v14, v24 op_sel:[0,0,1]               // 00000010AC38: D7694002 0002310E
	v_perm_b32 v3, v8, v8, 0x3020104                           // 00000010AC40: D6440003 03FE1108 03020104
	s_wait_alu 0xf1ff                                          // 00000010AC4C: BF88F1FF
	v_add_co_ci_u32_e64 v7, null, s5, v7, s2                   // 00000010AC50: D5207C07 000A0E05
	v_cvt_pk_fp8_f32 v4, v20, v11 op_sel:[0,0,1]               // 00000010AC58: D7694004 00021714
	v_perm_b32 v5, v5, v5, 0x3020104                           // 00000010AC60: D6440005 03FE0B05 03020104
	s_and_b32 s2, vcc_lo, s20                                  // 00000010AC6C: 8B02146A
	s_clause 0x1                                               // 00000010AC70: BF850001
	global_store_b64 v[0:1], v[2:3], off                       // 00000010AC74: EE06C07C 01000000 00000000
	global_store_b64 v[6:7], v[4:5], off                       // 00000010AC80: EE06C07C 02000000 00000006
	s_wait_alu 0xfffe                                          // 00000010AC8C: BF88FFFE
	s_and_saveexec_b32 s3, s2                                  // 00000010AC90: BE832002
	s_cbranch_execz 34                                         // 00000010AC94: BFA50022 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0x1120>
	s_load_b64 s[0:1], s[0:1], 0x30                            // 00000010AC98: F4002000 F8000030
	s_lshr_b32 s2, ttmp7, 16                                   // 00000010ACA0: 85029073
	v_mov_b32_e32 v0, s16                                      // 00000010ACA4: 7E000210
	v_dual_mov_b32 v2, 0 :: v_dual_mov_b32 v1, s17             // 00000010ACA8: CA100080 02000011
	s_wait_kmcnt 0x0                                           // 00000010ACB0: BFC70000
	s_wait_alu 0xfffe                                          // 00000010ACB4: BF88FFFE
	s_mul_i32 s1, s1, s2                                       // 00000010ACB8: 96010201
	s_wait_alu 0xfffe                                          // 00000010ACBC: BF88FFFE
	s_add_co_i32 s1, s1, s21                                   // 00000010ACC0: 81011501
	s_wait_alu 0xfffe                                          // 00000010ACC4: BF88FFFE
	s_mul_i32 s0, s1, s0                                       // 00000010ACC8: 96000001
	s_wait_alu 0xfffe                                          // 00000010ACCC: BF88FFFE
	s_add_co_i32 s0, s0, ttmp9                                 // 00000010ACD0: 81007500
	s_wait_alu 0xfffe                                          // 00000010ACD4: BF88FFFE
	s_lshl_b32 s0, s0, 1                                       // 00000010ACD8: 84008100
	s_wait_alu 0xfffe                                          // 00000010ACDC: BF88FFFE
	s_ashr_i32 s1, s0, 31                                      // 00000010ACE0: 86019F00
	s_wait_alu 0xfffe                                          // 00000010ACE4: BF88FFFE
	s_lshl_b64 s[0:1], s[0:1], 3                               // 00000010ACE8: 84808300
	s_wait_alu 0xfffe                                          // 00000010ACEC: BF88FFFE
	s_add_nc_u64 s[0:1], s[14:15], s[0:1]                      // 00000010ACF0: A980000E
	global_store_b64 v2, v[0:1], s[0:1]                        // 00000010ACF4: EE06C000 00000000 00000002
	s_sendmsg_rtn_b64 s[2:3], sendmsg(MSG_RTN_GET_REALTIME)    // 00000010AD00: BE824D83
	s_wait_kmcnt 0x0                                           // 00000010AD04: BFC70000
	s_wait_alu 0xfffe                                          // 00000010AD08: BF88FFFE
	v_dual_mov_b32 v0, s2 :: v_dual_mov_b32 v1, s3             // 00000010AD0C: CA100002 00000003
	global_store_b64 v2, v[0:1], s[0:1] offset:8               // 00000010AD14: EE06C000 00000000 00000802
	s_nop 0                                                    // 00000010AD20: BF800000
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)                       // 00000010AD24: BFB60003
	s_endpgm                                                   // 00000010AD28: BFB00000
		...
