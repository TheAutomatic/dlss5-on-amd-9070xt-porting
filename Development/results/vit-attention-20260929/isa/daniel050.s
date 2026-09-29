
/home/lmxxf/work/vit-attention-20260929/daniel-050.hsaco:	file format elf64-amdgpu

Disassembly of section .text:

0000000000105500 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams>:
	s_load_b128 s[12:15], s[0:1], 0x20                         // 000000105500: F4004300 F8000020
	s_mov_b64 s[16:17], 0                                      // 000000105508: BE900180
	s_wait_kmcnt 0x0                                           // 00000010550C: BFC70000
	s_cmp_lg_u64 s[14:15], 0                                   // 000000105510: BF11800E
	s_cselect_b32 s20, -1, 0                                   // 000000105514: 981480C1
	s_cmp_eq_u64 s[14:15], 0                                   // 000000105518: BF10800E
	s_cbranch_scc1 1                                           // 00000010551C: BFA20001 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0x24>
	s_sendmsg_rtn_b64 s[16:17], sendmsg(MSG_RTN_GET_REALTIME)  // 000000105520: BE904D83
	v_lshrrev_b32_e32 v36, 5, v0                               // 000000105524: 32480085
	s_lshl_b32 s22, ttmp9, 6                                   // 000000105528: 84168675
	s_load_b256 s[4:11], s[0:1], 0x0                           // 00000010552C: F4006100 F8000000
	s_ashr_i32 s2, s22, 4                                      // 000000105534: 86028416
	v_dual_mov_b32 v38, 0 :: v_dual_and_b32 v27, 15, v0        // 000000105538: CA240080 261A008F
	v_or_b32_e32 v1, s2, v36                                   // 000000105540: 38024802
	v_bfe_u32 v7, v0, 4, 1                                     // 000000105544: D6100007 02050900
	s_and_b32 s21, ttmp7, 0xffff                               // 00000010554C: 8B15FF73 0000FFFF
	s_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)// 000000105554: BF870193
	v_dual_mov_b32 v30, 0 :: v_dual_lshlrev_b32 v3, 4, v27     // 000000105558: CA220080 1E023684
	v_ashrrev_i32_e32 v2, 31, v1                               // 000000105560: 3404029F
	v_dual_mov_b32 v29, 0 :: v_dual_mov_b32 v32, 0             // 000000105564: CA100080 1D200080
	v_dual_mov_b32 v31, 0 :: v_dual_mov_b32 v34, 0             // 00000010556C: CA100080 1F220080
	s_delay_alu instid0(VALU_DEP_3)                            // 000000105574: BF870003
	v_lshlrev_b64_e32 v[1:2], 14, v[1:2]                       // 000000105578: 3E02028E
	v_lshl_or_b32 v28, v7, 8, v3                               // 00000010557C: D656001C 040D1107
	v_mov_b32_e32 v35, 0                                       // 000000105584: 7E460280
	v_mov_b32_e32 v37, 0                                       // 000000105588: 7E4A0280
	v_mov_b32_e32 v33, 0                                       // 00000010558C: 7E420280
	s_lshl_b32 s18, s21, 9                                     // 000000105590: 84128915
	s_cmp_lt_i32 s12, 64                                       // 000000105594: BF04C00C
	s_mov_b32 s19, 0                                           // 000000105598: BE930080
	s_cbranch_scc1 818                                         // 00000010559C: BFA20332 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0xd68>
	s_wait_kmcnt 0x0                                           // 0000001055A0: BFC70000
	v_add_co_u32 v3, vcc_lo, s4, v1                            // 0000001055A4: D7006A03 00020204
	s_delay_alu instid0(VALU_DEP_1)                            // 0000001055AC: BF870001
	v_add_co_ci_u32_e64 v4, null, s5, v2, vcc_lo               // 0000001055B0: D5207C04 01AA0405
	s_add_nc_u64 s[4:5], s[18:19], 8                           // 0000001055B8: A9848812
	v_add_co_u32 v5, vcc_lo, v3, v28                           // 0000001055BC: D7006A05 00023903
	s_wait_alu 0xfffd                                          // 0000001055C4: BF88FFFD
	v_add_co_ci_u32_e64 v6, null, 0, v4, vcc_lo                // 0000001055C8: D5207C06 01AA0880
	s_lshl_b32 s3, s21, 5                                      // 0000001055D0: 84038515
	v_add_co_u32 v3, vcc_lo, v5, s18                           // 0000001055D4: D7006A03 00002505
	s_wait_alu 0xfffd                                          // 0000001055DC: BF88FFFD
	v_add_co_ci_u32_e64 v4, null, 0, v6, vcc_lo                // 0000001055E0: D5207C04 01AA0C80
	s_wait_alu 0xfffe                                          // 0000001055E8: BF88FFFE
	v_add_co_u32 v5, vcc_lo, s4, v5                            // 0000001055EC: D7006A05 00020A04
	s_wait_alu 0xfffd                                          // 0000001055F4: BF88FFFD
	v_add_co_ci_u32_e64 v6, null, s5, v6, vcc_lo               // 0000001055F8: D5207C06 01AA0C05
	s_clause 0x1                                               // 000000105600: BF850001
	global_load_b64 v[3:4], v[3:4], off                        // 000000105604: EE05407C 00000003 00000003
	global_load_b64 v[5:6], v[5:6], off                        // 000000105610: EE05407C 00000005 00000005
	s_or_b32 s24, s3, 16                                       // 00000010561C: 8C189003
	s_ashr_i32 s2, s12, 31                                     // 000000105620: 86029F0C
	v_dual_mov_b32 v34, 0 :: v_dual_lshlrev_b32 v7, 3, v7      // 000000105624: CA220080 22060E83
	v_or_b32_e32 v8, s3, v27                                   // 00000010562C: 38103603
	v_or_b32_e32 v9, s24, v27                                  // 000000105630: 38123618
	s_wait_alu 0xfffe                                          // 000000105634: BF88FFFE
	s_lshr_b32 s2, s2, 26                                      // 000000105638: 85029A02
	v_mbcnt_lo_u32_b32 v41, -1, 0                              // 00000010563C: D71F0029 000100C1
	s_wait_alu 0xfffe                                          // 000000105644: BF88FFFE
	s_add_co_i32 s2, s12, s2                                   // 000000105648: 8102020C
	v_dual_mov_b32 v33, 0 :: v_dual_mov_b32 v32, 0             // 00000010564C: CA100080 21200080
	s_wait_alu 0xfffe                                          // 000000105654: BF88FFFE
	s_ashr_i32 s23, s2, 6                                      // 000000105658: 86178602
	v_add_co_u32 v39, s2, s8, v7                               // 00000010565C: D7000227 00020E08
	v_mad_co_u64_u32 v[7:8], null, v8, s12, 0                  // 000000105664: D6FE7C07 02001908
	v_mad_co_u64_u32 v[9:10], null, v9, s12, 0                 // 00000010566C: D6FE7C09 02001909
	s_wait_alu 0xf1ff                                          // 000000105674: BF88F1FF
	v_add_co_ci_u32_e64 v40, null, s9, 0, s2                   // 000000105678: D5207C28 00090009
	v_xor_b32_e32 v42, 16, v41                                 // 000000105680: 3A545290
	v_dual_mov_b32 v37, 0 :: v_dual_mov_b32 v30, 0             // 000000105684: CA100080 251E0080
	v_dual_mov_b32 v35, 0 :: v_dual_mov_b32 v38, 0             // 00000010568C: CA100080 23260080
	v_mov_b32_e32 v31, 0                                       // 000000105694: 7E3E0280
	v_mov_b32_e32 v29, 0                                       // 000000105698: 7E3A0280
	s_add_nc_u64 s[2:3], s[6:7], s[18:19]                      // 00000010569C: A9821206
	s_add_nc_u64 s[4:5], s[6:7], s[4:5]                        // 0000001056A0: A9840406
	s_mov_b32 s6, 0x3fdac000                                   // 0000001056A4: BE8600FF 3FDAC000
	s_mov_b32 s7, 0x3db76000                                   // 0000001056AC: BE8700FF 3DB76000
	s_mov_b32 s8, s19                                          // 0000001056B4: BE880013
	s_wait_alu 0xfffe                                          // 0000001056B8: BF88FFFE
	v_add_co_u32 v17, s9, s2, v28                              // 0000001056BC: D7000911 00023802
	s_wait_alu 0xf1ff                                          // 0000001056C4: BF88F1FF
	v_add_co_ci_u32_e64 v18, null, s3, 0, s9                   // 0000001056C8: D5207C12 00250003
	v_add_co_u32 v25, s9, s4, v28                              // 0000001056D0: D7000919 00023804
	s_wait_alu 0xf1ff                                          // 0000001056D8: BF88F1FF
	v_add_co_ci_u32_e64 v26, null, s5, 0, s9                   // 0000001056DC: D5207C1A 00250005
	s_clause 0x3                                               // 0000001056E4: BF850003
	global_load_b64 v[11:12], v[17:18], off                    // 0000001056E8: EE05407C 0000000B 00000011
	global_load_b64 v[13:14], v[17:18], off offset:16384       // 0000001056F4: EE05407C 0000000D 00400011
	global_load_b64 v[15:16], v[17:18], off offset:32768       // 000000105700: EE05407C 0000000F 00800011
	global_load_b64 v[23:24], v[17:18], off offset:49152       // 00000010570C: EE05407C 00000017 00C00011
	s_clause 0x3                                               // 000000105718: BF850003
	global_load_b64 v[17:18], v[25:26], off                    // 00000010571C: EE05407C 00000011 00000019
	global_load_b64 v[19:20], v[25:26], off offset:16384       // 000000105728: EE05407C 00000013 00400019
	global_load_b64 v[21:22], v[25:26], off offset:32768       // 000000105734: EE05407C 00000015 00800019
	global_load_b64 v[25:26], v[25:26], off offset:49152       // 000000105740: EE05407C 00000019 00C00019
	v_add_co_u32 v43, vcc_lo, v39, s8                          // 00000010574C: D7006A2B 00001127
	s_wait_alu 0xfffd                                          // 000000105754: BF88FFFD
	v_add_co_ci_u32_e64 v44, null, 0, v40, vcc_lo              // 000000105758: D5207C2C 01AA5080
	v_cmp_gt_i32_e32 vcc_lo, 32, v42                           // 000000105760: 7C8854A0
	s_mov_b32 s9, 1.0                                          // 000000105764: BE8900F2
	s_add_co_i32 s23, s23, -1                                  // 000000105768: 8117C117
	s_add_co_i32 s8, s8, 64                                    // 00000010576C: 8108C008
	s_wait_alu 0xfffd                                          // 000000105770: BF88FFFD
	v_cndmask_b32_e32 v47, v41, v42, vcc_lo                    // 000000105774: 025E5529
	v_add_co_u32 v45, vcc_lo, v43, v7                          // 000000105778: D7006A2D 00020F2B
	s_wait_alu 0xfffd                                          // 000000105780: BF88FFFD
	v_add_co_ci_u32_e64 v46, null, v44, v8, vcc_lo             // 000000105784: D5207C2E 01AA112C
	v_add_co_u32 v43, vcc_lo, v43, v9                          // 00000010578C: D7006A2B 0002132B
	s_wait_alu 0xfffd                                          // 000000105794: BF88FFFD
	v_add_co_ci_u32_e64 v44, null, v44, v10, vcc_lo            // 000000105798: D5207C2C 01AA152C
	s_clause 0x7                                               // 0000001057A0: BF850007
	global_load_b64 v[75:76], v[45:46], off                    // 0000001057A4: EE05407C 0000004B 0000002D
	global_load_b64 v[77:78], v[45:46], off offset:16          // 0000001057B0: EE05407C 0000004D 0000102D
	global_load_b64 v[79:80], v[45:46], off offset:32          // 0000001057BC: EE05407C 0000004F 0000202D
	global_load_b64 v[81:82], v[45:46], off offset:48          // 0000001057C8: EE05407C 00000051 0000302D
	global_load_b64 v[83:84], v[43:44], off                    // 0000001057D4: EE05407C 00000053 0000002B
	global_load_b64 v[85:86], v[43:44], off offset:16          // 0000001057E0: EE05407C 00000055 0000102B
	global_load_b64 v[87:88], v[43:44], off offset:32          // 0000001057EC: EE05407C 00000057 0000202B
	global_load_b64 v[89:90], v[43:44], off offset:48          // 0000001057F8: EE05407C 00000059 0000302B
	v_lshlrev_b32_e32 v91, 2, v47                              // 000000105804: 30B65E82
	s_add_nc_u64 s[2:3], s[2:3], 0x10000                       // 000000105808: A982FF02 00010000
	s_cmp_eq_u32 s23, 0                                        // 000000105810: BF068017
	s_add_nc_u64 s[4:5], s[4:5], 0x10000                       // 000000105814: A984FF04 00010000
	s_wait_loadcnt 0xf                                         // 00000010581C: BFC0000F
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[11:12], v[3:4], 0  // 000000105820: CC46402B 1A02070B
	s_wait_loadcnt 0xe                                         // 000000105828: BFC0000E
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[13:14], v[3:4], 0  // 00000010582C: CC464033 1A02070D
	s_wait_loadcnt 0xd                                         // 000000105834: BFC0000D
	v_wmma_f32_16x16x16_fp8_fp8 v[59:66], v[15:16], v[3:4], 0  // 000000105838: CC46403B 1A02070F
	s_wait_loadcnt 0xc                                         // 000000105840: BFC0000C
	v_wmma_f32_16x16x16_fp8_fp8 v[67:74], v[23:24], v[3:4], 0  // 000000105844: CC464043 1A020717
	s_wait_loadcnt 0xb                                         // 00000010584C: BFC0000B
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[17:18], v[5:6], v[43:50]// 000000105850: CC46402B 1CAE0B11
	s_wait_loadcnt 0xa                                         // 000000105858: BFC0000A
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[19:20], v[5:6], v[51:58]// 00000010585C: CC464033 1CCE0B13
	s_wait_loadcnt 0x9                                         // 000000105864: BFC00009
	v_wmma_f32_16x16x16_fp8_fp8 v[59:66], v[21:22], v[5:6], v[59:66]// 000000105868: CC46403B 1CEE0B15
	s_wait_loadcnt 0x8                                         // 000000105870: BFC00008
	v_wmma_f32_16x16x16_fp8_fp8 v[67:74], v[25:26], v[5:6], v[67:74]// 000000105874: CC464043 1D0E0B19
	s_wait_alu 0xfffe                                          // 00000010587C: BF88FFFE
	v_fma_mixlo_f16 v11, s9, 0, v43                            // 000000105880: CC21000B 04AD0009
	v_fma_mixlo_f16 v12, s9, 0, v44                            // 000000105888: CC21000C 04B10009
	v_fma_mixlo_f16 v13, s9, 0, v45                            // 000000105890: CC21000D 04B50009
	v_fma_mixlo_f16 v14, s9, 0, v46                            // 000000105898: CC21000E 04B90009
	v_fma_mixlo_f16 v15, s9, 0, v47                            // 0000001058A0: CC21000F 04BD0009
	v_fma_mixlo_f16 v16, s9, 0, v48                            // 0000001058A8: CC210010 04C10009
	v_fma_mixlo_f16 v17, s9, 0, v49                            // 0000001058B0: CC210011 04C50009
	v_fma_mixlo_f16 v18, s9, 0, v50                            // 0000001058B8: CC210012 04C90009
	v_fma_mixlo_f16 v19, s9, 0, v51                            // 0000001058C0: CC210013 04CD0009
	v_fma_mixlo_f16 v20, s9, 0, v52                            // 0000001058C8: CC210014 04D10009
	v_fma_mixlo_f16 v21, s9, 0, v53                            // 0000001058D0: CC210015 04D50009
	v_fma_mixlo_f16 v22, s9, 0, v54                            // 0000001058D8: CC210016 04D90009
	v_fma_mixlo_f16 v23, s9, 0, v55                            // 0000001058E0: CC210017 04DD0009
	v_fma_mixlo_f16 v24, s9, 0, v56                            // 0000001058E8: CC210018 04E10009
	v_fma_mixlo_f16 v25, s9, 0, v57                            // 0000001058F0: CC210019 04E50009
	v_fma_mixlo_f16 v26, s9, 0, v58                            // 0000001058F8: CC21001A 04E90009
	v_fma_mixlo_f16 v43, s9, 0, v59                            // 000000105900: CC21002B 04ED0009
	v_fma_mixlo_f16 v44, s9, 0, v60                            // 000000105908: CC21002C 04F10009
	v_fma_mixlo_f16 v45, s9, 0, v61                            // 000000105910: CC21002D 04F50009
	v_fma_mixlo_f16 v46, s9, 0, v62                            // 000000105918: CC21002E 04F90009
	v_fma_mixlo_f16 v47, s9, 0, v63                            // 000000105920: CC21002F 04FD0009
	v_fma_mixlo_f16 v48, s9, 0, v64                            // 000000105928: CC210030 05010009
	v_fma_mixlo_f16 v49, s9, 0, v65                            // 000000105930: CC210031 05050009
	v_fma_mixlo_f16 v50, s9, 0, v66                            // 000000105938: CC210032 05090009
	v_fma_mixlo_f16 v51, s9, 0, v67                            // 000000105940: CC210033 050D0009
	v_fma_mixlo_f16 v52, s9, 0, v68                            // 000000105948: CC210034 05110009
	v_fma_mixlo_f16 v53, s9, 0, v69                            // 000000105950: CC210035 05150009
	v_fma_mixlo_f16 v54, s9, 0, v70                            // 000000105958: CC210036 05190009
	v_fma_mix_f32 v11, v11, s7, s6 op_sel_hi:[1,0,0]           // 000000105960: CC20000B 08180F0B
	v_fma_mix_f32 v12, v12, s7, s6 op_sel_hi:[1,0,0]           // 000000105968: CC20000C 08180F0C
	v_fma_mix_f32 v13, v13, s7, s6 op_sel_hi:[1,0,0]           // 000000105970: CC20000D 08180F0D
	v_fma_mix_f32 v14, v14, s7, s6 op_sel_hi:[1,0,0]           // 000000105978: CC20000E 08180F0E
	v_fma_mix_f32 v15, v15, s7, s6 op_sel_hi:[1,0,0]           // 000000105980: CC20000F 08180F0F
	v_fma_mix_f32 v16, v16, s7, s6 op_sel_hi:[1,0,0]           // 000000105988: CC200010 08180F10
	v_fma_mix_f32 v17, v17, s7, s6 op_sel_hi:[1,0,0]           // 000000105990: CC200011 08180F11
	v_fma_mix_f32 v18, v18, s7, s6 op_sel_hi:[1,0,0]           // 000000105998: CC200012 08180F12
	v_fma_mix_f32 v19, v19, s7, s6 op_sel_hi:[1,0,0]           // 0000001059A0: CC200013 08180F13
	v_fma_mix_f32 v20, v20, s7, s6 op_sel_hi:[1,0,0]           // 0000001059A8: CC200014 08180F14
	v_fma_mix_f32 v21, v21, s7, s6 op_sel_hi:[1,0,0]           // 0000001059B0: CC200015 08180F15
	v_fma_mix_f32 v22, v22, s7, s6 op_sel_hi:[1,0,0]           // 0000001059B8: CC200016 08180F16
	v_cvt_f16_f32_e32 v11, v11                                 // 0000001059C0: 7E16150B
	v_cvt_f16_f32_e32 v12, v12                                 // 0000001059C4: 7E18150C
	v_cvt_f16_f32_e32 v13, v13                                 // 0000001059C8: 7E1A150D
	v_cvt_f16_f32_e32 v14, v14                                 // 0000001059CC: 7E1C150E
	v_cvt_f16_f32_e32 v15, v15                                 // 0000001059D0: 7E1E150F
	v_cvt_f16_f32_e32 v16, v16                                 // 0000001059D4: 7E201510
	v_cvt_f16_f32_e32 v19, v19                                 // 0000001059D8: 7E261513
	v_cvt_f16_f32_e32 v20, v20                                 // 0000001059DC: 7E281514
	v_cvt_f16_f32_e32 v21, v21                                 // 0000001059E0: 7E2A1515
	v_cvt_f16_f32_e32 v22, v22                                 // 0000001059E4: 7E2C1516
	v_fma_mixlo_f16 v55, s9, 0, v71                            // 0000001059E8: CC210037 051D0009
	v_fma_mixlo_f16 v56, s9, 0, v72                            // 0000001059F0: CC210038 05210009
	v_fma_mixlo_f16 v57, s9, 0, v73                            // 0000001059F8: CC210039 05250009
	v_fma_mixlo_f16 v58, s9, 0, v74                            // 000000105A00: CC21003A 05290009
	v_fma_mix_f32 v23, v23, s7, s6 op_sel_hi:[1,0,0]           // 000000105A08: CC200017 08180F17
	v_fma_mix_f32 v24, v24, s7, s6 op_sel_hi:[1,0,0]           // 000000105A10: CC200018 08180F18
	v_fma_mix_f32 v25, v25, s7, s6 op_sel_hi:[1,0,0]           // 000000105A18: CC200019 08180F19
	v_fma_mix_f32 v26, v26, s7, s6 op_sel_hi:[1,0,0]           // 000000105A20: CC20001A 08180F1A
	v_fma_mix_f32 v43, v43, s7, s6 op_sel_hi:[1,0,0]           // 000000105A28: CC20002B 08180F2B
	v_fma_mix_f32 v44, v44, s7, s6 op_sel_hi:[1,0,0]           // 000000105A30: CC20002C 08180F2C
	v_fma_mix_f32 v45, v45, s7, s6 op_sel_hi:[1,0,0]           // 000000105A38: CC20002D 08180F2D
	v_fma_mix_f32 v46, v46, s7, s6 op_sel_hi:[1,0,0]           // 000000105A40: CC20002E 08180F2E
	v_fma_mix_f32 v47, v47, s7, s6 op_sel_hi:[1,0,0]           // 000000105A48: CC20002F 08180F2F
	v_fma_mix_f32 v48, v48, s7, s6 op_sel_hi:[1,0,0]           // 000000105A50: CC200030 08180F30
	v_fma_mix_f32 v49, v49, s7, s6 op_sel_hi:[1,0,0]           // 000000105A58: CC200031 08180F31
	v_fma_mix_f32 v50, v50, s7, s6 op_sel_hi:[1,0,0]           // 000000105A60: CC200032 08180F32
	v_fma_mix_f32 v51, v51, s7, s6 op_sel_hi:[1,0,0]           // 000000105A68: CC200033 08180F33
	v_fma_mix_f32 v52, v52, s7, s6 op_sel_hi:[1,0,0]           // 000000105A70: CC200034 08180F34
	v_fma_mix_f32 v53, v53, s7, s6 op_sel_hi:[1,0,0]           // 000000105A78: CC200035 08180F35
	v_fma_mix_f32 v54, v54, s7, s6 op_sel_hi:[1,0,0]           // 000000105A80: CC200036 08180F36
	v_cvt_f16_f32_e32 v17, v17                                 // 000000105A88: 7E221511
	v_cvt_f16_f32_e32 v18, v18                                 // 000000105A8C: 7E241512
	v_cvt_f16_f32_e32 v23, v23                                 // 000000105A90: 7E2E1517
	v_cvt_f16_f32_e32 v24, v24                                 // 000000105A94: 7E301518
	v_cvt_f16_f32_e32 v25, v25                                 // 000000105A98: 7E321519
	v_cvt_f16_f32_e32 v26, v26                                 // 000000105A9C: 7E34151A
	v_cvt_f16_f32_e32 v43, v43                                 // 000000105AA0: 7E56152B
	v_cvt_f16_f32_e32 v44, v44                                 // 000000105AA4: 7E58152C
	v_cvt_f16_f32_e32 v45, v45                                 // 000000105AA8: 7E5A152D
	v_cvt_f16_f32_e32 v46, v46                                 // 000000105AAC: 7E5C152E
	v_cvt_f16_f32_e32 v47, v47                                 // 000000105AB0: 7E5E152F
	v_cvt_f16_f32_e32 v48, v48                                 // 000000105AB4: 7E601530
	v_cvt_f16_f32_e32 v49, v49                                 // 000000105AB8: 7E621531
	v_cvt_f16_f32_e32 v50, v50                                 // 000000105ABC: 7E641532
	v_cvt_f16_f32_e32 v51, v51                                 // 000000105AC0: 7E661533
	v_cvt_f16_f32_e32 v52, v52                                 // 000000105AC4: 7E681534
	v_cvt_f16_f32_e32 v53, v53                                 // 000000105AC8: 7E6A1535
	v_cvt_f16_f32_e32 v54, v54                                 // 000000105ACC: 7E6C1536
	v_pack_b32_f16 v11, v11, v12                               // 000000105AD0: D711000B 0002190B
	v_pack_b32_f16 v12, v13, v14                               // 000000105AD8: D711000C 00021D0D
	v_pack_b32_f16 v13, v15, v16                               // 000000105AE0: D711000D 0002210F
	v_pack_b32_f16 v15, v19, v20                               // 000000105AE8: D711000F 00022913
	v_pack_b32_f16 v16, v21, v22                               // 000000105AF0: D7110010 00022D15
	v_fma_mix_f32 v55, v55, s7, s6 op_sel_hi:[1,0,0]           // 000000105AF8: CC200037 08180F37
	v_fma_mix_f32 v56, v56, s7, s6 op_sel_hi:[1,0,0]           // 000000105B00: CC200038 08180F38
	v_fma_mix_f32 v57, v57, s7, s6 op_sel_hi:[1,0,0]           // 000000105B08: CC200039 08180F39
	v_fma_mix_f32 v58, v58, s7, s6 op_sel_hi:[1,0,0]           // 000000105B10: CC20003A 08180F3A
	v_cvt_f16_f32_e32 v55, v55                                 // 000000105B18: 7E6E1537
	v_cvt_f16_f32_e32 v56, v56                                 // 000000105B1C: 7E701538
	v_cvt_f16_f32_e32 v57, v57                                 // 000000105B20: 7E721539
	v_cvt_f16_f32_e32 v58, v58                                 // 000000105B24: 7E74153A
	v_pack_b32_f16 v14, v17, v18                               // 000000105B28: D711000E 00022511
	v_pack_b32_f16 v17, v23, v24                               // 000000105B30: D7110011 00023117
	v_pack_b32_f16 v18, v25, v26                               // 000000105B38: D7110012 00023519
	v_pack_b32_f16 v19, v43, v44                               // 000000105B40: D7110013 0002592B
	v_pack_b32_f16 v20, v45, v46                               // 000000105B48: D7110014 00025D2D
	v_pack_b32_f16 v21, v47, v48                               // 000000105B50: D7110015 0002612F
	v_pack_b32_f16 v22, v49, v50                               // 000000105B58: D7110016 00026531
	v_pack_b32_f16 v23, v51, v52                               // 000000105B60: D7110017 00026933
	v_pack_b32_f16 v24, v53, v54                               // 000000105B68: D7110018 00026D35
	v_pk_max_num_f16 v11, 0x3dc2, v11 op_sel_hi:[0,1]          // 000000105B70: CC1C400B 100216FF 00003DC2
	v_pk_max_num_f16 v12, 0x3dc2, v12 op_sel_hi:[0,1]          // 000000105B7C: CC1C400C 100218FF 00003DC2
	v_pk_max_num_f16 v13, 0x3dc2, v13 op_sel_hi:[0,1]          // 000000105B88: CC1C400D 10021AFF 00003DC2
	v_pk_max_num_f16 v15, 0x3dc2, v15 op_sel_hi:[0,1]          // 000000105B94: CC1C400F 10021EFF 00003DC2
	v_pk_max_num_f16 v16, 0x3dc2, v16 op_sel_hi:[0,1]          // 000000105BA0: CC1C4010 100220FF 00003DC2
	v_pack_b32_f16 v25, v55, v56                               // 000000105BAC: D7110019 00027137
	v_pack_b32_f16 v26, v57, v58                               // 000000105BB4: D711001A 00027539
	v_pk_max_num_f16 v14, 0x3dc2, v14 op_sel_hi:[0,1]          // 000000105BBC: CC1C400E 10021CFF 00003DC2
	v_pk_max_num_f16 v17, 0x3dc2, v17 op_sel_hi:[0,1]          // 000000105BC8: CC1C4011 100222FF 00003DC2
	v_pk_max_num_f16 v18, 0x3dc2, v18 op_sel_hi:[0,1]          // 000000105BD4: CC1C4012 100224FF 00003DC2
	v_pk_max_num_f16 v19, 0x3dc2, v19 op_sel_hi:[0,1]          // 000000105BE0: CC1C4013 100226FF 00003DC2
	v_pk_max_num_f16 v20, 0x3dc2, v20 op_sel_hi:[0,1]          // 000000105BEC: CC1C4014 100228FF 00003DC2
	v_pk_max_num_f16 v21, 0x3dc2, v21 op_sel_hi:[0,1]          // 000000105BF8: CC1C4015 10022AFF 00003DC2
	v_pk_max_num_f16 v22, 0x3dc2, v22 op_sel_hi:[0,1]          // 000000105C04: CC1C4016 10022CFF 00003DC2
	v_pk_max_num_f16 v23, 0x3dc2, v23 op_sel_hi:[0,1]          // 000000105C10: CC1C4017 10022EFF 00003DC2
	v_pk_max_num_f16 v24, 0x3dc2, v24 op_sel_hi:[0,1]          // 000000105C1C: CC1C4018 100230FF 00003DC2
	v_pk_min_num_f16 v11, 0x3fe9, v11 op_sel_hi:[0,1]          // 000000105C28: CC1B400B 100216FF 00003FE9
	v_pk_min_num_f16 v12, 0x3fe9, v12 op_sel_hi:[0,1]          // 000000105C34: CC1B400C 100218FF 00003FE9
	v_pk_min_num_f16 v13, 0x3fe9, v13 op_sel_hi:[0,1]          // 000000105C40: CC1B400D 10021AFF 00003FE9
	v_pk_min_num_f16 v15, 0x3fe9, v15 op_sel_hi:[0,1]          // 000000105C4C: CC1B400F 10021EFF 00003FE9
	v_pk_min_num_f16 v16, 0x3fe9, v16 op_sel_hi:[0,1]          // 000000105C58: CC1B4010 100220FF 00003FE9
	v_pk_max_num_f16 v25, 0x3dc2, v25 op_sel_hi:[0,1]          // 000000105C64: CC1C4019 100232FF 00003DC2
	v_pk_max_num_f16 v26, 0x3dc2, v26 op_sel_hi:[0,1]          // 000000105C70: CC1C401A 100234FF 00003DC2
	v_pk_min_num_f16 v14, 0x3fe9, v14 op_sel_hi:[0,1]          // 000000105C7C: CC1B400E 10021CFF 00003FE9
	v_pk_min_num_f16 v17, 0x3fe9, v17 op_sel_hi:[0,1]          // 000000105C88: CC1B4011 100222FF 00003FE9
	v_pk_min_num_f16 v18, 0x3fe9, v18 op_sel_hi:[0,1]          // 000000105C94: CC1B4012 100224FF 00003FE9
	v_pk_min_num_f16 v19, 0x3fe9, v19 op_sel_hi:[0,1]          // 000000105CA0: CC1B4013 100226FF 00003FE9
	v_pk_min_num_f16 v20, 0x3fe9, v20 op_sel_hi:[0,1]          // 000000105CAC: CC1B4014 100228FF 00003FE9
	v_pk_min_num_f16 v21, 0x3fe9, v21 op_sel_hi:[0,1]          // 000000105CB8: CC1B4015 10022AFF 00003FE9
	v_pk_min_num_f16 v22, 0x3fe9, v22 op_sel_hi:[0,1]          // 000000105CC4: CC1B4016 10022CFF 00003FE9
	v_pk_min_num_f16 v23, 0x3fe9, v23 op_sel_hi:[0,1]          // 000000105CD0: CC1B4017 10022EFF 00003FE9
	v_pk_min_num_f16 v24, 0x3fe9, v24 op_sel_hi:[0,1]          // 000000105CDC: CC1B4018 100230FF 00003FE9
	v_pk_lshlrev_b16 v11, 4, v11 op_sel_hi:[0,1]               // 000000105CE8: CC04400B 10021684
	v_pk_lshlrev_b16 v12, 4, v12 op_sel_hi:[0,1]               // 000000105CF0: CC04400C 10021884
	v_pk_lshlrev_b16 v13, 4, v13 op_sel_hi:[0,1]               // 000000105CF8: CC04400D 10021A84
	v_pk_lshlrev_b16 v15, 4, v15 op_sel_hi:[0,1]               // 000000105D00: CC04400F 10021E84
	v_pk_lshlrev_b16 v16, 4, v16 op_sel_hi:[0,1]               // 000000105D08: CC044010 10022084
	v_pk_min_num_f16 v25, 0x3fe9, v25 op_sel_hi:[0,1]          // 000000105D10: CC1B4019 100232FF 00003FE9
	v_pk_min_num_f16 v26, 0x3fe9, v26 op_sel_hi:[0,1]          // 000000105D1C: CC1B401A 100234FF 00003FE9
	v_pk_lshlrev_b16 v14, 4, v14 op_sel_hi:[0,1]               // 000000105D28: CC04400E 10021C84
	v_pk_lshlrev_b16 v17, 4, v17 op_sel_hi:[0,1]               // 000000105D30: CC044011 10022284
	v_pk_lshlrev_b16 v18, 4, v18 op_sel_hi:[0,1]               // 000000105D38: CC044012 10022484
	v_pk_lshlrev_b16 v19, 4, v19 op_sel_hi:[0,1]               // 000000105D40: CC044013 10022684
	v_pk_lshlrev_b16 v20, 4, v20 op_sel_hi:[0,1]               // 000000105D48: CC044014 10022884
	v_pk_lshlrev_b16 v21, 4, v21 op_sel_hi:[0,1]               // 000000105D50: CC044015 10022A84
	v_pk_lshlrev_b16 v22, 4, v22 op_sel_hi:[0,1]               // 000000105D58: CC044016 10022C84
	v_pk_lshlrev_b16 v23, 4, v23 op_sel_hi:[0,1]               // 000000105D60: CC044017 10022E84
	v_pk_lshlrev_b16 v24, 4, v24 op_sel_hi:[0,1]               // 000000105D68: CC044018 10023084
	v_pk_add_u16 v51, v11, 2.0 op_sel:[0,1]                    // 000000105D70: CC0A5033 1801E90B
	v_pk_add_u16 v11, v12, 2.0 op_sel:[0,1]                    // 000000105D78: CC0A500B 1801E90C
	v_pk_add_u16 v52, v13, 2.0 op_sel:[0,1]                    // 000000105D80: CC0A5034 1801E90D
	v_pk_add_u16 v59, v15, 2.0 op_sel:[0,1]                    // 000000105D88: CC0A503B 1801E90F
	v_pk_add_u16 v13, v16, 2.0 op_sel:[0,1]                    // 000000105D90: CC0A500D 1801E910
	v_pk_lshlrev_b16 v25, 4, v25 op_sel_hi:[0,1]               // 000000105D98: CC044019 10023284
	v_pk_lshlrev_b16 v26, 4, v26 op_sel_hi:[0,1]               // 000000105DA0: CC04401A 10023484
	v_pk_add_u16 v12, v14, 2.0 op_sel:[0,1]                    // 000000105DA8: CC0A500C 1801E90E
	v_pk_add_u16 v60, v17, 2.0 op_sel:[0,1]                    // 000000105DB0: CC0A503C 1801E911
	v_pk_add_u16 v14, v18, 2.0 op_sel:[0,1]                    // 000000105DB8: CC0A500E 1801E912
	v_pk_add_u16 v61, v19, 2.0 op_sel:[0,1]                    // 000000105DC0: CC0A503D 1801E913
	v_pk_add_u16 v15, v20, 2.0 op_sel:[0,1]                    // 000000105DC8: CC0A500F 1801E914
	v_pk_add_u16 v62, v21, 2.0 op_sel:[0,1]                    // 000000105DD0: CC0A503E 1801E915
	v_pk_add_u16 v16, v22, 2.0 op_sel:[0,1]                    // 000000105DD8: CC0A5010 1801E916
	v_pk_add_u16 v63, v23, 2.0 op_sel:[0,1]                    // 000000105DE0: CC0A503F 1801E917
	v_pk_add_u16 v17, v24, 2.0 op_sel:[0,1]                    // 000000105DE8: CC0A5011 1801E918
	ds_bpermute_b32 v19, v91, v51                              // 000000105DF0: DACC0000 1300335B
	ds_bpermute_b32 v20, v91, v59                              // 000000105DF8: DACC0000 14003B5B
	ds_bpermute_b32 v23, v91, v11                              // 000000105E00: DACC0000 17000B5B
	ds_bpermute_b32 v24, v91, v13                              // 000000105E08: DACC0000 18000D5B
	v_pk_add_u16 v64, v25, 2.0 op_sel:[0,1]                    // 000000105E10: CC0A5040 1801E919
	v_pk_add_u16 v18, v26, 2.0 op_sel:[0,1]                    // 000000105E18: CC0A5012 1801E91A
	ds_bpermute_b32 v21, v91, v61                              // 000000105E20: DACC0000 15003D5B
	ds_bpermute_b32 v22, v91, v63                              // 000000105E28: DACC0000 16003F5B
	ds_bpermute_b32 v25, v91, v15                              // 000000105E30: DACC0000 19000F5B
	ds_bpermute_b32 v26, v91, v17                              // 000000105E38: DACC0000 1A00115B
	ds_bpermute_b32 v43, v91, v52                              // 000000105E40: DACC0000 2B00345B
	ds_bpermute_b32 v44, v91, v60                              // 000000105E48: DACC0000 2C003C5B
	ds_bpermute_b32 v45, v91, v62                              // 000000105E50: DACC0000 2D003E5B
	ds_bpermute_b32 v104, v91, v12                             // 000000105E58: DACC0000 68000C5B
	ds_bpermute_b32 v105, v91, v14                             // 000000105E60: DACC0000 69000E5B
	ds_bpermute_b32 v106, v91, v16                             // 000000105E68: DACC0000 6A00105B
	ds_bpermute_b32 v46, v91, v64                              // 000000105E70: DACC0000 2E00405B
	v_lshrrev_b32_e32 v48, 16, v51                             // 000000105E78: 32606690
	v_lshrrev_b32_e32 v54, 16, v52                             // 000000105E7C: 326C6890
	v_lshrrev_b32_e32 v58, 16, v59                             // 000000105E80: 32747690
	v_lshrrev_b32_e32 v68, 16, v60                             // 000000105E84: 32887890
	v_lshrrev_b32_e32 v72, 16, v61                             // 000000105E88: 32907A90
	v_lshrrev_b32_e32 v93, 16, v62                             // 000000105E8C: 32BA7C90
	ds_bpermute_b32 v91, v91, v18                              // 000000105E90: DACC0000 5B00125B
	v_cvt_f32_f16_e32 v47, v51                                 // 000000105E98: 7E5E1733
	v_cvt_f32_f16_e32 v49, v11                                 // 000000105E9C: 7E62170B
	v_lshrrev_b32_e32 v50, 16, v11                             // 000000105EA0: 32641690
	v_cvt_f32_f16_e32 v53, v52                                 // 000000105EA4: 7E6A1734
	v_lshrrev_b32_e32 v56, 16, v12                             // 000000105EA8: 32701890
	v_cvt_f32_f16_e32 v57, v59                                 // 000000105EAC: 7E72173B
	v_cvt_f32_f16_e32 v65, v13                                 // 000000105EB0: 7E82170D
	v_lshrrev_b32_e32 v66, 16, v13                             // 000000105EB4: 32841A90
	v_cvt_f32_f16_e32 v67, v60                                 // 000000105EB8: 7E86173C
	v_lshrrev_b32_e32 v70, 16, v14                             // 000000105EBC: 328C1C90
	v_cvt_f32_f16_e32 v71, v61                                 // 000000105EC0: 7E8E173D
	v_lshrrev_b32_e32 v74, 16, v15                             // 000000105EC4: 32941E90
	v_cvt_f32_f16_e32 v92, v62                                 // 000000105EC8: 7EB8173E
	v_lshrrev_b32_e32 v95, 16, v16                             // 000000105ECC: 32BE2090
	v_cvt_f32_f16_e32 v48, v48                                 // 000000105ED0: 7E601730
	v_cvt_f32_f16_e32 v54, v54                                 // 000000105ED4: 7E6C1736
	v_cvt_f32_f16_e32 v58, v58                                 // 000000105ED8: 7E74173A
	v_cvt_f32_f16_e32 v68, v68                                 // 000000105EDC: 7E881744
	v_cvt_f32_f16_e32 v72, v72                                 // 000000105EE0: 7E901748
	v_cvt_f32_f16_e32 v93, v93                                 // 000000105EE4: 7EBA175D
	s_wait_dscnt 0xf                                           // 000000105EE8: BFC6000F
	v_pk_add_f16 v19, v51, v19                                 // 000000105EEC: CC0F4013 18022733
	s_wait_dscnt 0xe                                           // 000000105EF4: BFC6000E
	v_pk_add_f16 v20, v59, v20                                 // 000000105EF8: CC0F4014 1802293B
	s_wait_dscnt 0xd                                           // 000000105F00: BFC6000D
	v_pk_add_f16 v11, v11, v23                                 // 000000105F04: CC0F400B 18022F0B
	s_wait_dscnt 0xc                                           // 000000105F0C: BFC6000C
	v_pk_add_f16 v13, v13, v24                                 // 000000105F10: CC0F400D 1802310D
	v_cvt_f32_f16_e32 v55, v12                                 // 000000105F18: 7E6E170C
	v_cvt_f32_f16_e32 v69, v14                                 // 000000105F1C: 7E8A170E
	v_cvt_f32_f16_e32 v73, v15                                 // 000000105F20: 7E92170F
	v_cvt_f32_f16_e32 v94, v16                                 // 000000105F24: 7EBC1710
	v_lshrrev_b32_e32 v97, 16, v63                             // 000000105F28: 32C27E90
	v_cvt_f32_f16_e32 v98, v17                                 // 000000105F2C: 7EC41711
	v_lshrrev_b32_e32 v99, 16, v17                             // 000000105F30: 32C62290
	v_lshrrev_b32_e32 v101, 16, v64                            // 000000105F34: 32CA8090
	v_cvt_f32_f16_e32 v50, v50                                 // 000000105F38: 7E641732
	v_cvt_f32_f16_e32 v56, v56                                 // 000000105F3C: 7E701738
	v_cvt_f32_f16_e32 v66, v66                                 // 000000105F40: 7E841742
	v_cvt_f32_f16_e32 v70, v70                                 // 000000105F44: 7E8C1746
	v_cvt_f32_f16_e32 v74, v74                                 // 000000105F48: 7E94174A
	v_cvt_f32_f16_e32 v95, v95                                 // 000000105F4C: 7EBE175F
	s_wait_dscnt 0xb                                           // 000000105F50: BFC6000B
	v_pk_add_f16 v21, v61, v21                                 // 000000105F54: CC0F4015 18022B3D
	s_wait_dscnt 0xa                                           // 000000105F5C: BFC6000A
	v_pk_add_f16 v107, v63, v22                                // 000000105F60: CC0F406B 18022D3F
	s_wait_dscnt 0x9                                           // 000000105F68: BFC60009
	v_pk_add_f16 v15, v15, v25                                 // 000000105F6C: CC0F400F 1802330F
	s_wait_dscnt 0x8                                           // 000000105F74: BFC60008
	v_pk_add_f16 v108, v17, v26                                // 000000105F78: CC0F406C 18023511
	s_wait_dscnt 0x7                                           // 000000105F80: BFC60007
	v_pk_add_f16 v17, v52, v43                                 // 000000105F84: CC0F4011 18025734
	s_wait_dscnt 0x6                                           // 000000105F8C: BFC60006
	v_pk_add_f16 v22, v60, v44                                 // 000000105F90: CC0F4016 1802593C
	s_wait_dscnt 0x5                                           // 000000105F98: BFC60005
	v_pk_add_f16 v23, v62, v45                                 // 000000105F9C: CC0F4017 18025B3E
	v_cvt_pk_fp8_f32 v51, v47, v48                             // 000000105FA4: D7690033 0002612F
	v_cvt_pk_fp8_f32 v52, v53, v54                             // 000000105FAC: D7690034 00026D35
	v_cvt_pk_fp8_f32 v59, v57, v58                             // 000000105FB4: D769003B 00027539
	v_cvt_pk_fp8_f32 v60, v67, v68                             // 000000105FBC: D769003C 00028943
	v_cvt_pk_fp8_f32 v61, v71, v72                             // 000000105FC4: D769003D 00029147
	v_cvt_pk_fp8_f32 v62, v92, v93                             // 000000105FCC: D769003E 0002BB5C
	s_wait_dscnt 0x4                                           // 000000105FD4: BFC60004
	v_pk_add_f16 v12, v12, v104                                // 000000105FD8: CC0F400C 1802D10C
	s_wait_dscnt 0x3                                           // 000000105FE0: BFC60003
	v_pk_add_f16 v14, v14, v105                                // 000000105FE4: CC0F400E 1802D30E
	s_wait_dscnt 0x2                                           // 000000105FEC: BFC60002
	v_pk_add_f16 v67, v16, v106                                // 000000105FF0: CC0F4043 1802D510
	v_pk_add_f16 v16, v19, v20                                 // 000000105FF8: CC0F4010 18022913
	v_pk_add_f16 v11, v11, v13                                 // 000000106000: CC0F400B 18021B0B
	v_cvt_f32_f16_e32 v96, v63                                 // 000000106008: 7EC0173F
	v_cvt_f32_f16_e32 v100, v64                                // 00000010600C: 7EC81740
	v_lshrrev_b32_e32 v103, 16, v18                            // 000000106010: 32CE2490
	v_cvt_f32_f16_e32 v97, v97                                 // 000000106014: 7EC21761
	v_cvt_f32_f16_e32 v101, v101                               // 000000106018: 7ECA1765
	v_pk_add_f16 v13, v17, v22                                 // 00000010601C: CC0F400D 18022D11
	v_cvt_pk_fp8_f32 v51, v49, v50 op_sel:[0,0,1]              // 000000106024: D7694033 00026531
	v_cvt_pk_fp8_f32 v52, v55, v56 op_sel:[0,0,1]              // 00000010602C: D7694034 00027137
	v_cvt_pk_fp8_f32 v59, v65, v66 op_sel:[0,0,1]              // 000000106034: D769403B 00028541
	v_cvt_pk_fp8_f32 v60, v69, v70 op_sel:[0,0,1]              // 00000010603C: D769403C 00028D45
	v_cvt_pk_fp8_f32 v61, v73, v74 op_sel:[0,0,1]              // 000000106044: D769403D 00029549
	v_cvt_pk_fp8_f32 v62, v94, v95 op_sel:[0,0,1]              // 00000010604C: D769403E 0002BF5E
	v_pk_add_f16 v65, v12, v14                                 // 000000106054: CC0F4041 18021D0C
	v_pk_add_f16 v66, v21, v16                                 // 00000010605C: CC0F4042 18022115
	v_pk_add_f16 v69, v15, v11                                 // 000000106064: CC0F4045 1802170F
	v_cvt_f32_f16_e32 v102, v18                                // 00000010606C: 7ECC1712
	v_cvt_f32_f16_e32 v99, v99                                 // 000000106070: 7EC61763
	v_cvt_f32_f16_e32 v103, v103                               // 000000106074: 7ECE1767
	s_wait_dscnt 0x1                                           // 000000106078: BFC60001
	v_pk_add_f16 v109, v64, v46                                // 00000010607C: CC0F406D 18025D40
	v_cvt_pk_fp8_f32 v63, v96, v97                             // 000000106084: D769003F 0002C360
	v_cvt_pk_fp8_f32 v64, v100, v101                           // 00000010608C: D7690040 0002CB64
	s_wait_dscnt 0x0                                           // 000000106094: BFC60000
	v_pk_add_f16 v68, v18, v91                                 // 000000106098: CC0F4044 1802B712
	v_pk_add_f16 v70, v23, v13                                 // 0000001060A0: CC0F4046 18021B17
	s_wait_loadcnt 0x7                                         // 0000001060A8: BFC00007
	v_wmma_f32_16x16x16_fp8_fp8 v[11:18], v[75:76], v[51:52], 0// 0000001060AC: CC46400B 1A02674B
	s_wait_loadcnt 0x5                                         // 0000001060B4: BFC00005
	v_wmma_f32_16x16x16_fp8_fp8 v[19:26], v[79:80], v[61:62], 0// 0000001060B8: CC464013 1A027B4F
	s_wait_loadcnt 0x3                                         // 0000001060C0: BFC00003
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[83:84], v[51:52], 0// 0000001060C4: CC46402B 1A026753
	s_wait_loadcnt 0x1                                         // 0000001060CC: BFC00001
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[87:88], v[61:62], 0// 0000001060D0: CC464033 1A027B57
	v_pk_add_f16 v61, v67, v65                                 // 0000001060D8: CC0F403D 18028343
	v_pk_add_f16 v62, v107, v66                                // 0000001060E0: CC0F403E 1802856B
	v_pk_add_f16 v65, v108, v69                                // 0000001060E8: CC0F4041 18028B6C
	v_cvt_pk_fp8_f32 v63, v98, v99 op_sel:[0,0,1]              // 0000001060F0: D769403F 0002C762
	v_cvt_pk_fp8_f32 v64, v102, v103 op_sel:[0,0,1]            // 0000001060F8: D7694040 0002CF66
	v_pk_add_f16 v66, v109, v70                                // 000000106100: CC0F4042 18028D6D
	v_wmma_f32_16x16x16_fp8_fp8 v[11:18], v[77:78], v[59:60], v[11:18]// 000000106108: CC46400B 1C2E774D
	v_wmma_f32_16x16x16_fp8_fp8 v[43:50], v[85:86], v[59:60], v[43:50]// 000000106110: CC46402B 1CAE7755
	v_pk_add_f16 v60, v62, v65                                 // 000000106118: CC0F403C 1802833E
	v_wmma_f32_16x16x16_fp8_fp8 v[19:26], v[81:82], v[63:64], v[19:26]// 000000106120: CC464013 1C4E7F51
	v_pk_add_f16 v59, v68, v61                                 // 000000106128: CC0F403B 18027B44
	v_fma_mixlo_f16 v11, v33, s9, v11 op_sel_hi:[1,0,0]        // 000000106130: CC21000B 0C2C1321
	v_fma_mixlo_f16 v49, v29, s9, v49 op_sel_hi:[1,0,0]        // 000000106138: CC210031 0CC4131D
	v_fma_mixlo_f16 v50, v29, s9, v50 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 000000106140: CC210832 0CC8131D
	v_pk_add_f16 v29, v60, v66                                 // 000000106148: CC0F401D 1802853C
	v_fma_mixlo_f16 v12, v33, s9, v12 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 000000106150: CC21080C 0C301321
	v_fma_mixlo_f16 v13, v37, s9, v13 op_sel_hi:[1,0,0]        // 000000106158: CC21000D 0C341325
	v_fma_mixlo_f16 v33, v11, s9, v19 op_sel_hi:[1,0,0]        // 000000106160: CC210021 0C4C130B
	s_wait_loadcnt 0x0                                         // 000000106168: BFC00000
	v_wmma_f32_16x16x16_fp8_fp8 v[51:58], v[89:90], v[63:64], v[51:58]// 00000010616C: CC464033 1CCE7F59
	v_pk_add_f16 v11, v29, v59                                 // 000000106174: CC0F400B 1802771D
	v_fma_mixlo_f16 v14, v37, s9, v14 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 00000010617C: CC21080E 0C381325
	v_fma_mixlo_f16 v15, v35, s9, v15 op_sel_hi:[1,0,0]        // 000000106184: CC21000F 0C3C1323
	v_fma_mixlo_f16 v17, v34, s9, v17 op_sel_hi:[1,0,0]        // 00000010618C: CC210011 0C441322
	v_fma_mixlo_f16 v43, v32, s9, v43 op_sel_hi:[1,0,0]        // 000000106194: CC21002B 0CAC1320
	v_fma_mixlo_f16 v45, v31, s9, v45 op_sel_hi:[1,0,0]        // 00000010619C: CC21002D 0CB4131F
	v_fma_mixlo_f16 v47, v30, s9, v47 op_sel_hi:[1,0,0]        // 0000001061A4: CC21002F 0CBC131E
	v_fma_mixlo_f16 v37, v13, s9, v21 op_sel_hi:[1,0,0]        // 0000001061AC: CC210025 0C54130D
	v_alignbit_b32 v13, s0, v11, 16                            // 0000001061B4: D616000D 02421600
	v_fma_mixlo_f16 v16, v35, s9, v16 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 0000001061BC: CC210810 0C401323
	v_fma_mixlo_f16 v18, v34, s9, v18 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 0000001061C4: CC210812 0C481322
	v_fma_mixlo_f16 v44, v32, s9, v44 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 0000001061CC: CC21082C 0CB01320
	v_fma_mixlo_f16 v46, v31, s9, v46 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 0000001061D4: CC21082E 0CB8131F
	v_fma_mixlo_f16 v48, v30, s9, v48 op_sel:[1,0,0] op_sel_hi:[1,0,0]// 0000001061DC: CC210830 0CC0131E
	v_fma_mixlo_f16 v35, v15, s9, v23 op_sel_hi:[1,0,0]        // 0000001061E4: CC210023 0C5C130F
	v_fma_mixlo_f16 v34, v17, s9, v25 op_sel_hi:[1,0,0]        // 0000001061EC: CC210022 0C641311
	v_fma_mixlo_f16 v32, v43, s9, v51 op_sel_hi:[1,0,0]        // 0000001061F4: CC210020 0CCC132B
	v_fma_mixlo_f16 v31, v45, s9, v53 op_sel_hi:[1,0,0]        // 0000001061FC: CC21001F 0CD4132D
	v_fma_mixlo_f16 v30, v47, s9, v55 op_sel_hi:[1,0,0]        // 000000106204: CC21001E 0CDC132F
	v_fma_mixlo_f16 v29, v49, s9, v57 op_sel_hi:[1,0,0]        // 00000010620C: CC21001D 0CE41331
	v_pk_add_f16 v11, v11, v13                                 // 000000106214: CC0F400B 18021B0B
	v_fma_mixhi_f16 v33, v12, s9, v20 op_sel_hi:[1,0,0]        // 00000010621C: CC220021 0C50130C
	v_fma_mixhi_f16 v37, v14, s9, v22 op_sel_hi:[1,0,0]        // 000000106224: CC220025 0C58130E
	v_fma_mixhi_f16 v35, v16, s9, v24 op_sel_hi:[1,0,0]        // 00000010622C: CC220023 0C601310
	v_fma_mixhi_f16 v34, v18, s9, v26 op_sel_hi:[1,0,0]        // 000000106234: CC220022 0C681312
	v_fma_mixhi_f16 v32, v44, s9, v52 op_sel_hi:[1,0,0]        // 00000010623C: CC220020 0CD0132C
	v_fma_mixhi_f16 v31, v46, s9, v54 op_sel_hi:[1,0,0]        // 000000106244: CC22001F 0CD8132E
	v_fma_mixhi_f16 v30, v48, s9, v56 op_sel_hi:[1,0,0]        // 00000010624C: CC22001E 0CE01330
	v_fma_mixhi_f16 v29, v50, s9, v58 op_sel_hi:[1,0,0]        // 000000106254: CC22001D 0CE81332
	v_pk_add_f16 v38, v38, v11 op_sel_hi:[1,0]                 // 00000010625C: CC0F4026 08021726
	s_cbranch_scc0 64788                                       // 000000106264: BFA1FD14 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0x1b8>
	s_sub_co_i32 s2, s12, s13                                  // 000000106268: 81820D0C
	s_mov_b32 s3, 0xbdac0000                                   // 00000010626C: BE8300FF BDAC0000
	s_wait_alu 0xfffe                                          // 000000106274: BF88FFFE
	s_cvt_f32_i32 s2, s2                                       // 000000106278: BE826402
	s_wait_kmcnt 0x0                                           // 00000010627C: BFC70000
	s_add_nc_u64 s[4:5], 8, s[18:19]                           // 000000106280: A9841288
	s_wait_alu 0xfffe                                          // 000000106284: BF88FFFE
	v_fma_mixlo_f16 v3, s2, s3, 0                              // 000000106288: CC210003 02000602
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 000000106290: BF870091
	v_add_f16_e32 v3, v38, v3                                  // 000000106294: 64060726
	v_cvt_f32_f16_e32 v3, v3                                   // 000000106298: 7E061703
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 00000010629C: BF870091
	v_max_num_f32_e32 v3, 0x38820000, v3                       // 0000001062A0: 2C0606FF 38820000
	v_div_scale_f32 v4, null, v3, v3, 1.0                      // 0000001062A8: D6FC7C04 03CA0703
	v_div_scale_f32 v7, vcc_lo, 1.0, v3, 1.0                   // 0000001062B0: D6FC6A07 03CA06F2
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(TRANS32_DEP_1)// 0000001062B8: BF870292
	v_rcp_f32_e32 v5, v4                                       // 0000001062BC: 7E0A5504
	v_fma_f32 v6, -v4, v5, 1.0                                 // 0000001062C0: D6130006 23CA0B04
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000001062C8: BF870091
	v_fmac_f32_e32 v5, v6, v5                                  // 0000001062CC: 560A0B06
	v_mul_f32_e32 v6, v7, v5                                   // 0000001062D0: 100C0B07
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)// 0000001062D4: BF870091
	v_fma_f32 v8, -v4, v6, v7                                  // 0000001062D8: D6130008 241E0D04
	v_fmac_f32_e32 v6, v8, v5                                  // 0000001062E0: 560C0B08
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_2) | instid1(VALU_DEP_2)// 0000001062E4: BF870131
	v_fma_f32 v4, -v4, v6, v7                                  // 0000001062E8: D6130004 241E0D04
	v_lshl_add_u32 v7, v36, 4, s22                             // 0000001062F0: D6460007 00590924
	s_wait_alu 0xfffd                                          // 0000001062F8: BF88FFFD
	v_div_fmas_f32 v4, v4, v5, v6                              // 0000001062FC: D6370004 041A0B04
	v_add_co_u32 v1, vcc_lo, s10, v1                           // 000000106304: D7006A01 0002020A
	s_wait_alu 0xfffd                                          // 00000010630C: BF88FFFD
	v_add_co_ci_u32_e64 v2, null, s11, v2, vcc_lo              // 000000106310: D5207C02 01AA040B
	v_cmp_eq_u32_e32 vcc_lo, 0, v0                             // 000000106318: 7C940080
	v_div_fixup_f32 v0, v4, v3, 1.0                            // 00000010631C: D6270000 03CA0704
	v_add_co_u32 v3, s2, v1, v28                               // 000000106324: D7000203 00023901
	v_or_b32_e32 v5, v7, v27                                   // 00000010632C: 380A3707
	s_wait_alu 0xf1ff                                          // 000000106330: BF88F1FF
	v_add_co_ci_u32_e64 v7, null, 0, v2, s2                    // 000000106334: D5207C07 000A0480
	v_cvt_f16_f32_e32 v2, v0                                   // 00000010633C: 7E041500
	v_add_co_u32 v0, s2, v3, s18                               // 000000106340: D7000200 00002503
	s_wait_alu 0xf1ff                                          // 000000106348: BF88F1FF
	v_add_co_ci_u32_e64 v1, null, 0, v7, s2                    // 00000010634C: D5207C01 000A0E80
	v_pk_mul_f16 v6, v2, v37 op_sel_hi:[0,1]                   // 000000106354: CC104006 10024B02
	v_pk_mul_f16 v8, v2, v35 op_sel_hi:[0,1]                   // 00000010635C: CC104008 10024702
	v_pk_mul_f16 v12, v2, v30 op_sel_hi:[0,1]                  // 000000106364: CC10400C 10023D02
	v_pk_mul_f16 v4, v2, v33 op_sel_hi:[0,1]                   // 00000010636C: CC104004 10024302
	v_pk_mul_f16 v9, v2, v34 op_sel_hi:[0,1]                   // 000000106374: CC104009 10024502
	v_pk_max_num_f16 v6, 0xdf00, v6 op_sel_hi:[0,1]            // 00000010637C: CC1C4006 10020CFF 0000DF00
	v_pk_max_num_f16 v8, 0xdf00, v8 op_sel_hi:[0,1]            // 000000106388: CC1C4008 100210FF 0000DF00
	v_pk_mul_f16 v10, v2, v32 op_sel_hi:[0,1]                  // 000000106394: CC10400A 10024102
	v_pk_mul_f16 v11, v2, v31 op_sel_hi:[0,1]                  // 00000010639C: CC10400B 10023F02
	v_pk_mul_f16 v2, v2, v29 op_sel_hi:[0,1]                   // 0000001063A4: CC104002 10023B02
	v_pk_max_num_f16 v12, 0xdf00, v12 op_sel_hi:[0,1]          // 0000001063AC: CC1C400C 100218FF 0000DF00
	v_pk_max_num_f16 v4, 0xdf00, v4 op_sel_hi:[0,1]            // 0000001063B8: CC1C4004 100208FF 0000DF00
	v_pk_max_num_f16 v9, 0xdf00, v9 op_sel_hi:[0,1]            // 0000001063C4: CC1C4009 100212FF 0000DF00
	v_pk_min_num_f16 v8, 0x5f00, v8 op_sel_hi:[0,1]            // 0000001063D0: CC1B4008 100210FF 00005F00
	v_pk_min_num_f16 v6, 0x5f00, v6 op_sel_hi:[0,1]            // 0000001063DC: CC1B4006 10020CFF 00005F00
	v_cmp_gt_i32_e64 s2, s13, v5                               // 0000001063E8: D4440002 00020A0D
	v_pk_max_num_f16 v10, 0xdf00, v10 op_sel_hi:[0,1]          // 0000001063F0: CC1C400A 100214FF 0000DF00
	v_pk_max_num_f16 v2, 0xdf00, v2 op_sel_hi:[0,1]            // 0000001063FC: CC1C4002 100204FF 0000DF00
	v_pk_min_num_f16 v5, 0x5f00, v12 op_sel_hi:[0,1]           // 000000106408: CC1B4005 100218FF 00005F00
	v_pk_min_num_f16 v4, 0x5f00, v4 op_sel_hi:[0,1]            // 000000106414: CC1B4004 100208FF 00005F00
	v_pk_min_num_f16 v9, 0x5f00, v9 op_sel_hi:[0,1]            // 000000106420: CC1B4009 100212FF 00005F00
	s_wait_alu 0xf1ff                                          // 00000010642C: BF88F1FF
	v_cndmask_b32_e64 v8, 0, v8, s2                            // 000000106430: D5010008 000A1080
	v_cndmask_b32_e64 v6, 0, v6, s2                            // 000000106438: D5010006 000A0C80
	v_pk_max_num_f16 v11, 0xdf00, v11 op_sel_hi:[0,1]          // 000000106440: CC1C400B 100216FF 0000DF00
	v_pk_min_num_f16 v10, 0x5f00, v10 op_sel_hi:[0,1]          // 00000010644C: CC1B400A 100214FF 00005F00
	v_pk_min_num_f16 v12, 0x5f00, v2 op_sel_hi:[0,1]           // 000000106458: CC1B400C 100204FF 00005F00
	v_cndmask_b32_e64 v5, 0, v5, s2                            // 000000106464: D5010005 000A0A80
	v_cndmask_b32_e64 v2, 0, v4, s2                            // 00000010646C: D5010002 000A0880
	v_cndmask_b32_e64 v9, 0, v9, s2                            // 000000106474: D5010009 000A1280
	v_cvt_f32_f16_e32 v14, v6                                  // 00000010647C: 7E1C1706
	v_lshrrev_b32_e32 v6, 16, v6                               // 000000106480: 320C0C90
	v_lshrrev_b32_e32 v16, 16, v8                              // 000000106484: 32201090
	v_pk_min_num_f16 v11, 0x5f00, v11 op_sel_hi:[0,1]          // 000000106488: CC1B400B 100216FF 00005F00
	v_cndmask_b32_e64 v4, 0, v10, s2                           // 000000106494: D5010004 000A1480
	v_cndmask_b32_e64 v10, 0, v12, s2                          // 00000010649C: D501000A 000A1880
	v_lshrrev_b32_e32 v22, 16, v5                              // 0000001064A4: 322C0A90
	v_lshrrev_b32_e32 v13, 16, v2                              // 0000001064A8: 321A0490
	v_cvt_f32_f16_e32 v15, v8                                  // 0000001064AC: 7E1E1708
	v_cvt_f32_f16_e32 v17, v9                                  // 0000001064B0: 7E221709
	v_lshrrev_b32_e32 v9, 16, v9                               // 0000001064B4: 32121290
	v_cvt_f32_f16_e32 v24, v6                                  // 0000001064B8: 7E301706
	v_cvt_f32_f16_e32 v6, v16                                  // 0000001064BC: 7E0C1710
	v_cndmask_b32_e64 v11, 0, v11, s2                          // 0000001064C0: D501000B 000A1680
	v_lshrrev_b32_e32 v19, 16, v4                              // 0000001064C8: 32260890
	v_cvt_f32_f16_e32 v21, v5                                  // 0000001064CC: 7E2A1705
	v_cvt_f32_f16_e32 v23, v10                                 // 0000001064D0: 7E2E170A
	v_lshrrev_b32_e32 v10, 16, v10                             // 0000001064D4: 32141490
	v_cvt_f32_f16_e32 v16, v22                                 // 0000001064D8: 7E201716
	v_cvt_f32_f16_e32 v12, v2                                  // 0000001064DC: 7E181702
	v_cvt_f32_f16_e32 v13, v13                                 // 0000001064E0: 7E1A170D
	v_cvt_f32_f16_e32 v9, v9                                   // 0000001064E4: 7E121709
	v_cvt_pk_fp8_f32 v8, v15, v6                               // 0000001064E8: D7690008 00020D0F
	v_cvt_f32_f16_e32 v18, v4                                  // 0000001064F0: 7E241704
	v_cvt_f32_f16_e32 v20, v11                                 // 0000001064F4: 7E28170B
	v_lshrrev_b32_e32 v11, 16, v11                             // 0000001064F8: 32161690
	v_cvt_f32_f16_e32 v19, v19                                 // 0000001064FC: 7E261713
	v_cvt_f32_f16_e32 v10, v10                                 // 000000106500: 7E14170A
	v_cvt_pk_fp8_f32 v5, v21, v16                              // 000000106504: D7690005 00022115
	v_cvt_pk_fp8_f32 v2, v12, v13                              // 00000010650C: D7690002 00021B0C
	v_cvt_pk_fp8_f32 v8, v17, v9 op_sel:[0,0,1]                // 000000106514: D7694008 00021311
	v_cvt_f32_f16_e32 v11, v11                                 // 00000010651C: 7E16170B
	v_cvt_pk_fp8_f32 v4, v18, v19                              // 000000106520: D7690004 00022712
	v_cvt_pk_fp8_f32 v5, v23, v10 op_sel:[0,0,1]               // 000000106528: D7694005 00021517
	v_add_co_u32 v6, s2, s4, v3                                // 000000106530: D7000206 00020604
	v_cvt_pk_fp8_f32 v2, v14, v24 op_sel:[0,0,1]               // 000000106538: D7694002 0002310E
	v_perm_b32 v3, v8, v8, 0x3020104                           // 000000106540: D6440003 03FE1108 03020104
	s_wait_alu 0xf1ff                                          // 00000010654C: BF88F1FF
	v_add_co_ci_u32_e64 v7, null, s5, v7, s2                   // 000000106550: D5207C07 000A0E05
	v_cvt_pk_fp8_f32 v4, v20, v11 op_sel:[0,0,1]               // 000000106558: D7694004 00021714
	v_perm_b32 v5, v5, v5, 0x3020104                           // 000000106560: D6440005 03FE0B05 03020104
	s_and_b32 s2, vcc_lo, s20                                  // 00000010656C: 8B02146A
	s_clause 0x1                                               // 000000106570: BF850001
	global_store_b64 v[0:1], v[2:3], off                       // 000000106574: EE06C07C 01000000 00000000
	global_store_b64 v[6:7], v[4:5], off                       // 000000106580: EE06C07C 02000000 00000006
	s_wait_alu 0xfffe                                          // 00000010658C: BF88FFFE
	s_and_saveexec_b32 s3, s2                                  // 000000106590: BE832002
	s_cbranch_execz 34                                         // 000000106594: BFA50022 <_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams+0x1120>
	s_load_b64 s[0:1], s[0:1], 0x30                            // 000000106598: F4002000 F8000030
	s_lshr_b32 s2, ttmp7, 16                                   // 0000001065A0: 85029073
	v_mov_b32_e32 v0, s16                                      // 0000001065A4: 7E000210
	v_dual_mov_b32 v2, 0 :: v_dual_mov_b32 v1, s17             // 0000001065A8: CA100080 02000011
	s_wait_kmcnt 0x0                                           // 0000001065B0: BFC70000
	s_wait_alu 0xfffe                                          // 0000001065B4: BF88FFFE
	s_mul_i32 s1, s1, s2                                       // 0000001065B8: 96010201
	s_wait_alu 0xfffe                                          // 0000001065BC: BF88FFFE
	s_add_co_i32 s1, s1, s21                                   // 0000001065C0: 81011501
	s_wait_alu 0xfffe                                          // 0000001065C4: BF88FFFE
	s_mul_i32 s0, s1, s0                                       // 0000001065C8: 96000001
	s_wait_alu 0xfffe                                          // 0000001065CC: BF88FFFE
	s_add_co_i32 s0, s0, ttmp9                                 // 0000001065D0: 81007500
	s_wait_alu 0xfffe                                          // 0000001065D4: BF88FFFE
	s_lshl_b32 s0, s0, 1                                       // 0000001065D8: 84008100
	s_wait_alu 0xfffe                                          // 0000001065DC: BF88FFFE
	s_ashr_i32 s1, s0, 31                                      // 0000001065E0: 86019F00
	s_wait_alu 0xfffe                                          // 0000001065E4: BF88FFFE
	s_lshl_b64 s[0:1], s[0:1], 3                               // 0000001065E8: 84808300
	s_wait_alu 0xfffe                                          // 0000001065EC: BF88FFFE
	s_add_nc_u64 s[0:1], s[14:15], s[0:1]                      // 0000001065F0: A980000E
	global_store_b64 v2, v[0:1], s[0:1]                        // 0000001065F4: EE06C000 00000000 00000002
	s_sendmsg_rtn_b64 s[2:3], sendmsg(MSG_RTN_GET_REALTIME)    // 000000106600: BE824D83
	s_wait_kmcnt 0x0                                           // 000000106604: BFC70000
	s_wait_alu 0xfffe                                          // 000000106608: BF88FFFE
	v_dual_mov_b32 v0, s2 :: v_dual_mov_b32 v1, s3             // 00000010660C: CA100002 00000003
	global_store_b64 v2, v[0:1], s[0:1] offset:8               // 000000106614: EE06C000 00000000 00000802
	s_nop 0                                                    // 000000106620: BF800000
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)                       // 000000106624: BFB60003
	s_endpgm                                                   // 000000106628: BFB00000
		...
