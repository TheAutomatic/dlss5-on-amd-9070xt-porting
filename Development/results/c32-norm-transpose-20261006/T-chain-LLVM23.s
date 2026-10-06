c32_wave1_mapped_b8:                    ; @c32_wave1_mapped_b8
	.cfi_startproc
; %bb.0:
	.cfi_escape 0x0f, 0x04, 0x30, 0x36, 0xe9, 0x02 ; CFA is 0 in private_wave aspace
	.cfi_undefined 16
	s_load_b32 s2, s[0:1], 0x20
	s_wait_kmcnt 0x0
	s_cmp_ge_u32 ttmp9, s2
	s_cbranch_scc1 .LBB19_11
; %bb.1:
	s_clause 0x1
	s_load_b256 s[4:11], s[0:1], 0x0
	s_load_b128 s[12:15], s[0:1], 0x2c
	v_and_b32_e32 v77, 15, v0
	v_lshrrev_b32_e32 v1, 4, v0
	s_mov_b32 s3, 0
	v_and_b32_e32 v48, 7, v0
	v_mov_b32_e32 v78, 0
	v_lshlrev_b32_e32 v76, 4, v0
	s_mov_b32 s20, 0xc3e00000
	s_mov_b32 s21, 0xbd650000
	s_mov_b32 s16, 0x3c003c00
	v_mov_b32_e32 v0, 0
	v_mov_b32_e32 v16, 0
	v_mov_b32_e32 v32, 0
	s_mov_b32 s17, s16
	s_mov_b32 s18, s16
	v_lshlrev_b32_e32 v79, 3, v1
	v_lshlrev_b32_e32 v80, 5, v77
	v_or_b32_e32 v49, 0x1000, v77
	v_lshlrev_b32_e32 v50, 8, v1
	v_lshlrev_b32_e32 v51, 5, v1
	v_dual_mov_b32 v1, v78 :: v_dual_mov_b32 v2, v78
	v_dual_mov_b32 v3, v78 :: v_dual_mov_b32 v4, v78
	v_dual_mov_b32 v5, v78 :: v_dual_mov_b32 v6, v78
	v_dual_mov_b32 v7, v78 :: v_dual_mov_b32 v8, v78
	v_dual_mov_b32 v9, v78 :: v_dual_mov_b32 v10, v78
	v_dual_mov_b32 v11, v78 :: v_dual_mov_b32 v12, v78
	v_dual_mov_b32 v13, v78 :: v_dual_mov_b32 v14, v78
	v_mov_b32_e32 v15, v78
	v_dual_mov_b32 v17, v78 :: v_dual_mov_b32 v18, v78
	v_dual_mov_b32 v19, v78 :: v_dual_mov_b32 v20, v78
	v_dual_mov_b32 v21, v78 :: v_dual_mov_b32 v22, v78
	v_dual_mov_b32 v23, v78 :: v_dual_mov_b32 v24, v78
	v_dual_mov_b32 v25, v78 :: v_dual_mov_b32 v26, v78
	v_dual_mov_b32 v27, v78 :: v_dual_mov_b32 v28, v78
	v_dual_mov_b32 v29, v78 :: v_dual_mov_b32 v30, v78
	v_mov_b32_e32 v31, v78
	s_wait_kmcnt 0x0
	s_lshl1_add_u32 s0, s14, s12
	v_mov_b32_e32 v33, v78
	s_lshr_b32 s0, s0, 3
	v_mov_b32_e32 v34, v78
	s_cvt_f32_u32 s1, s0
	v_dual_mov_b32 v35, v78 :: v_dual_mov_b32 v36, v78
	v_mov_b32_e32 v37, v78
	s_delay_alu instid0(SALU_CYCLE_1) | instskip(SKIP_4) | instid1(TRANS32_DEP_1)
	v_s_rcp_f32 s1, s1
	v_dual_mov_b32 v38, v78 :: v_dual_mov_b32 v39, v78
	v_dual_mov_b32 v40, v78 :: v_dual_mov_b32 v41, v78
	v_dual_mov_b32 v42, v78 :: v_dual_mov_b32 v43, v78
	v_mov_b32_e32 v44, v78
	s_mul_f32 s1, s1, 0x4f7ffffe
	v_dual_mov_b32 v45, v78 :: v_dual_mov_b32 v46, v78
	v_mov_b32_e32 v47, v78
	s_wait_alu depctr_sa_sdst(0)
	s_cvt_u32_f32 s1, s1
	v_or_b32_e32 v81, v79, v80
	s_sub_co_i32 s2, 0, s0
	v_or_b32_e32 v52, 0x1000, v80
	s_wait_alu depctr_sa_sdst(0)
	s_mul_i32 s2, s2, s1
	v_add_nc_u32_e32 v82, v49, v50
	s_mul_hi_u32 s2, s1, s2
	v_mad_u32_u24 v83, 0x60, v77, v81
	s_add_co_i32 s1, s1, s2
	v_add_nc_u32_e32 v84, v52, v79
	s_wait_alu depctr_sa_sdst(0)
	s_mul_hi_u32 s1, ttmp9, s1
	v_subrev_nc_u32_e32 v48, s14, v48
	s_wait_alu depctr_sa_sdst(0)
	s_mul_i32 s2, s1, s0
	v_add_co_u32 v64, s14, s8, v81
	s_sub_co_i32 s2, ttmp9, s2
	s_add_co_i32 s19, s1, 1
	s_sub_co_i32 s22, s2, s0
	s_cmp_ge_u32 s2, s0
	v_add_co_u32 v66, s23, s6, v51
	s_cselect_b32 s1, s19, s1
	s_cselect_b32 s2, s22, s2
	s_wait_alu depctr_sa_sdst(0)
	s_add_co_i32 s19, s1, 1
	s_cmp_ge_u32 s2, s0
	v_add_co_u32 v49, s2, s6, v81
	s_cselect_b32 s1, s19, s1
	v_add_co_ci_u32_e64 v65, null, s9, 0, s14
	s_wait_alu depctr_sa_sdst(0)
	s_mul_i32 s0, s1, s0
	v_add_co_ci_u32_e64 v67, null, s7, 0, s23
	s_wait_alu depctr_sa_sdst(0)
	s_sub_co_i32 s0, ttmp9, s0
	v_add_co_ci_u32_e64 v50, null, s7, 0, s2
	s_wait_alu depctr_sa_sdst(0)
	v_lshl_add_u32 v85, s0, 3, v48
	v_add_co_u32 v68, vcc_lo, 0x800, v49
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_add_co_ci_u32_e64 v69, null, 0, v50, vcc_lo
	v_cmp_lt_i32_e32 vcc_lo, -1, v85
	v_cmp_gt_i32_e64 s0, s12, v85
	s_lshl_b32 s1, s1, 3
	s_mov_b32 s19, s16
	s_wait_alu depctr_sa_sdst(0)
	s_sub_co_i32 s14, s1, s15
.LBB19_2:                               ; =>This Loop Header: Depth=1
                                        ;     Child Loop BB19_7 Depth 2
	v_lshl_or_b32 v48, s3, 4, v77
	s_delay_alu instid0(VALU_DEP_1) | instskip(SKIP_1) | instid1(VALU_DEP_1)
	v_lshrrev_b32_e32 v48, 3, v48
	s_wait_alu depctr_sa_sdst(0)
	v_add_nc_u32_e32 v48, s14, v48
	v_mov_b32_e32 v56, 0
	s_delay_alu instid0(VALU_DEP_2)
	v_mul_lo_u32 v49, v48, s12
	v_dual_mov_b32 v57, 0 :: v_dual_mov_b32 v58, 0
	v_dual_mov_b32 v59, 0 :: v_dual_mov_b32 v60, 0
	v_mov_b32_e32 v61, 0
	v_cmp_lt_i32_e64 s1, -1, v48
	v_mov_b32_e32 v62, 0
	v_add_lshl_u32 v49, v49, v85, 5
	v_mov_b32_e32 v63, 0
	v_cmp_gt_i32_e64 s2, s13, v48
	s_and_b32 s1, vcc_lo, s1
	v_add_co_u32 v72, s15, s4, v49
	s_wait_alu depctr_va_sdst(0)
	v_add_co_ci_u32_e64 v73, null, s5, 0, s15
	s_wait_alu depctr_sa_sdst(0)
	s_and_b32 s1, s0, s1
	s_wait_alu depctr_sa_sdst(0)
	s_and_b32 s2, s1, s2
	s_wait_alu depctr_sa_sdst(0)
	s_and_saveexec_b32 s15, s2
	s_cbranch_execz .LBB19_4
; %bb.3:                                ;   in Loop: Header=BB19_2 Depth=1
	v_add_co_u32 v48, s1, v72, v79
	s_wait_alu depctr_va_sdst(0)
	v_add_co_ci_u32_e64 v49, null, 0, v73, s1
	global_load_b64 v[48:49], v[48:49], off
	s_wait_loadcnt 0x0
	v_and_b32_e32 v50, 0xff, v48
	v_bfe_u32 v51, v48, 8, 8
	v_bfe_u32 v52, v48, 16, 8
	v_lshrrev_b32_e32 v48, 24, v48
	v_and_b32_e32 v53, 0xff, v49
	v_bfe_u32 v54, v49, 8, 8
	v_bfe_u32 v55, v49, 16, 8
	v_lshrrev_b32_e32 v49, 24, v49
	v_cvt_f32_fp8_e32 v56, v50
	v_cvt_f32_fp8_e32 v57, v51
	v_cvt_f32_fp8_e32 v58, v52
	v_cvt_f32_fp8_e32 v59, v48
	v_cvt_f32_fp8_e32 v60, v53
	v_cvt_f32_fp8_e32 v61, v54
	v_cvt_f32_fp8_e32 v62, v55
	v_cvt_f32_fp8_e32 v63, v49
.LBB19_4:                               ;   in Loop: Header=BB19_2 Depth=1
	s_wait_alu depctr_sa_sdst(0)
	s_or_b32 exec_lo, exec_lo, s15
	s_clause 0x1
	global_load_b128 v[48:51], v[66:67], off offset:34832
	global_load_b128 v[52:55], v[66:67], off offset:34816
	v_dual_mov_b32 v87, 0 :: v_dual_mov_b32 v88, 0
	v_dual_mov_b32 v89, 0 :: v_dual_mov_b32 v90, 0
	v_dual_mov_b32 v91, 0 :: v_dual_mov_b32 v92, 0
	v_dual_mov_b32 v93, 0 :: v_dual_mov_b32 v94, 0
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v70, v56, v57
	v_cvt_pk_fp8_f32 v71, v60, v61
	v_cvt_pk_fp8_f32 v70, v58, v59 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v71, v62, v63 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_and_saveexec_b32 s15, s2
	s_cbranch_execz .LBB19_6
; %bb.5:                                ;   in Loop: Header=BB19_2 Depth=1
	v_add_co_u32 v72, s1, v72, v79
	s_wait_alu depctr_va_sdst(0)
	v_add_co_ci_u32_e64 v73, null, 0, v73, s1
	global_load_b64 v[72:73], v[72:73], off offset:16
	s_wait_loadcnt 0x0
	v_and_b32_e32 v74, 0xff, v72
	v_bfe_u32 v75, v72, 8, 8
	v_bfe_u32 v86, v72, 16, 8
	v_lshrrev_b32_e32 v72, 24, v72
	v_and_b32_e32 v91, 0xff, v73
	v_bfe_u32 v92, v73, 8, 8
	v_bfe_u32 v93, v73, 16, 8
	v_lshrrev_b32_e32 v73, 24, v73
	v_cvt_f32_fp8_e32 v87, v74
	v_cvt_f32_fp8_e32 v88, v75
	v_cvt_f32_fp8_e32 v89, v86
	v_cvt_f32_fp8_e32 v90, v72
	v_cvt_f32_fp8_e32 v91, v91
	v_cvt_f32_fp8_e32 v92, v92
	v_cvt_f32_fp8_e32 v93, v93
	v_cvt_f32_fp8_e32 v94, v73
.LBB19_6:                               ;   in Loop: Header=BB19_2 Depth=1
	s_wait_alu depctr_sa_sdst(0)
	s_or_b32 exec_lo, exec_lo, s15
	s_clause 0x1
	global_load_b128 v[95:98], v[66:67], off offset:34880
	global_load_b128 v[99:102], v[66:67], off offset:34896
	v_dual_max_num_f32 v56, v56, v56 :: v_dual_max_num_f32 v57, v57, v57
	v_dual_max_num_f32 v58, v58, v58 :: v_dual_max_num_f32 v59, v59, v59
	v_dual_max_num_f32 v60, v60, v60 :: v_dual_max_num_f32 v61, v61, v61
	v_dual_max_num_f32 v62, v62, v62 :: v_dual_max_num_f32 v63, v63, v63
	v_dual_max_num_f32 v74, v87, v87 :: v_dual_max_num_f32 v75, v88, v88
	v_dual_max_num_f32 v103, v89, v89 :: v_dual_max_num_f32 v104, v90, v90
	v_dual_max_num_f32 v105, v91, v91 :: v_dual_max_num_f32 v106, v92, v92
	v_dual_max_num_f32 v107, v93, v93 :: v_dual_max_num_f32 v108, v94, v94
	s_mov_b32 s2, 8
	v_dual_mov_b32 v73, v69 :: v_dual_mov_b32 v72, v68
	v_mov_b32_e32 v86, v83
	v_med3_num_f32 v56, v56, s20, 0x43e00000
	v_med3_num_f32 v57, v57, s20, 0x43e00000
	v_med3_num_f32 v58, v58, s20, 0x43e00000
	v_med3_num_f32 v59, v59, s20, 0x43e00000
	v_med3_num_f32 v60, v60, s20, 0x43e00000
	v_med3_num_f32 v61, v61, s20, 0x43e00000
	v_med3_num_f32 v62, v62, s20, 0x43e00000
	v_med3_num_f32 v63, v63, s20, 0x43e00000
	v_med3_num_f32 v74, v74, s20, 0x43e00000
	v_med3_num_f32 v75, v75, s20, 0x43e00000
	v_med3_num_f32 v103, v103, s20, 0x43e00000
	v_med3_num_f32 v104, v104, s20, 0x43e00000
	v_med3_num_f32 v105, v105, s20, 0x43e00000
	v_med3_num_f32 v106, v106, s20, 0x43e00000
	v_med3_num_f32 v107, v107, s20, 0x43e00000
	v_med3_num_f32 v108, v108, s20, 0x43e00000
	s_wait_loadcnt 0x2
	v_dual_mul_f32 v56, v56, v52 :: v_dual_mul_f32 v57, v57, v53
	v_dual_mul_f32 v58, v58, v54 :: v_dual_mul_f32 v59, v59, v55
	v_dual_mul_f32 v60, v60, v48 :: v_dual_mul_f32 v61, v61, v49
	v_dual_mul_f32 v62, v62, v50 :: v_dual_mul_f32 v63, v63, v51
	s_wait_loadcnt 0x1
	v_dual_mul_f32 v48, v74, v95 :: v_dual_mul_f32 v49, v75, v96
	v_dual_mul_f32 v50, v103, v97 :: v_dual_mul_f32 v51, v104, v98
	s_wait_loadcnt 0x0
	v_dual_mul_f32 v52, v105, v99 :: v_dual_mul_f32 v53, v106, v100
	v_dual_mul_f32 v54, v107, v101 :: v_dual_mul_f32 v55, v108, v102
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v74, v87, v88
	v_cvt_pk_fp8_f32 v75, v91, v92
	v_cvt_pk_fp8_f32 v74, v89, v90 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v75, v93, v94 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
.LBB19_7:                               ;   Parent Loop BB19_2 Depth=1
                                        ; =>  This Inner Loop Header: Depth=2
	s_clause 0x1
	global_load_b64 v[95:96], v[72:73], off
	global_load_b64 v[97:98], v[72:73], off offset:16
	s_wait_loadcnt 0x1
	v_wmma_f32_16x16x16_fp8_fp8 v[87:94], v[95:96], v[70:71], 0
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_wmma_f32_16x16x16_fp8_fp8 v[87:94], v[97:98], v[74:75], v[87:94]
	v_med3_num_f32 v95, v87, -4.0, 4.0
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_med3_num_f32 v96, v88, -4.0, 4.0
	v_med3_num_f32 v97, v89, -4.0, 4.0
	s_delay_alu instid0(VALU_DEP_4)
	v_med3_num_f32 v98, v90, -4.0, 4.0
	v_med3_num_f32 v99, v91, -4.0, 4.0
	v_med3_num_f32 v100, v92, -4.0, 4.0
	v_med3_num_f32 v101, v93, -4.0, 4.0
	v_med3_num_f32 v102, v94, -4.0, 4.0
	v_fma_f32 v103, |v95|, s21, 0x3ee50000
	v_fma_f32 v104, |v96|, s21, 0x3ee50000
	v_fma_f32 v105, |v97|, s21, 0x3ee50000
	v_fma_f32 v106, |v98|, s21, 0x3ee50000
	v_fma_f32 v107, |v99|, s21, 0x3ee50000
	v_fma_f32 v108, |v100|, s21, 0x3ee50000
	v_fma_f32 v109, |v101|, s21, 0x3ee50000
	v_fma_f32 v110, |v102|, s21, 0x3ee50000
	v_dual_fmaak_f32 v95, v95, v103, 0x3f650000 :: v_dual_fmaak_f32 v96, v96, v104, 0x3f650000
	v_dual_fmaak_f32 v97, v97, v105, 0x3f650000 :: v_dual_fmaak_f32 v98, v98, v106, 0x3f650000
	v_dual_fmaak_f32 v99, v99, v107, 0x3f650000 :: v_dual_fmaak_f32 v100, v100, v108, 0x3f650000
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_fmaak_f32 v101, v101, v109, 0x3f650000 :: v_dual_fmaak_f32 v102, v102, v110, 0x3f650000
	v_dual_mul_f32 v95, v87, v95 :: v_dual_mul_f32 v96, v88, v96
	s_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)
	v_dual_mul_f32 v89, v89, v97 :: v_dual_mul_f32 v90, v90, v98
	v_dual_mul_f32 v91, v91, v99 :: v_dual_mul_f32 v92, v92, v100
	s_delay_alu instid0(VALU_DEP_4)
	v_dual_mul_f32 v93, v93, v101 :: v_dual_mul_f32 v94, v94, v102
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v87, v95, v96
	v_cvt_pk_fp8_f32 v88, v91, v92
	v_cvt_pk_fp8_f32 v87, v89, v90 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v88, v93, v94 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_clause 0x1
	global_load_b64 v[89:90], v86, s[6:7] offset:18432
	global_load_b64 v[91:92], v86, s[6:7] offset:20480
	s_wait_alu depctr_sa_sdst(0)
	s_add_co_i32 s2, s2, -1
	v_add_co_u32 v72, s1, 0x200, v72
	s_wait_alu depctr_va_sdst(0)
	v_add_co_ci_u32_e64 v73, null, 0, v73, s1
	v_add_nc_u32_e32 v86, 16, v86
	s_wait_loadcnt 0x1
	v_wmma_f32_16x16x16_fp8_fp8 v[56:63], v[89:90], v[87:88], v[56:63]
	s_wait_loadcnt 0x0
	v_wmma_f32_16x16x16_fp8_fp8 v[48:55], v[91:92], v[87:88], v[48:55]
	s_wait_alu depctr_sa_sdst(0)
	s_cmp_lg_u32 s2, 0
	s_cbranch_scc1 .LBB19_7
; %bb.8:                                ;   in Loop: Header=BB19_2 Depth=1
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v56, v56, v57
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v57, v58, v59
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v58, v60, v61
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v59, v62, v63
	;;#ASMEND
	v_lshl_or_b32 v60, s3, 10, v76
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v48, v48, v49
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v49, v50, v51
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v50, v52, v53
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v51, v54, v55
	;;#ASMEND
	v_cvt_f32_f16_e32 v52, v56.l
	v_cvt_f32_f16_e32 v53, v56.h
	v_cvt_f32_f16_e32 v54, v57.l
	v_cvt_f32_f16_e32 v55, v57.h
	v_cvt_f32_f16_e32 v61, v58.l
	v_cvt_f32_f16_e32 v62, v58.h
	v_cvt_f32_f16_e32 v63, v59.l
	v_cvt_f32_f16_e32 v70, v59.h
	v_cvt_f32_f16_e32 v71, v48.l
	v_cvt_f32_f16_e32 v72, v48.h
	v_cvt_f32_f16_e32 v73, v49.l
	v_cvt_f32_f16_e32 v86, v49.h
	v_cvt_f32_f16_e32 v87, v50.l
	v_cvt_f32_f16_e32 v88, v50.h
	v_cvt_f32_f16_e32 v89, v51.l
	v_cvt_f32_f16_e32 v90, v51.h
	ds_store_b128 v60, v[56:59]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v74, v52, v53
	v_cvt_pk_fp8_f32 v75, v61, v62
	v_cvt_pk_fp8_f32 v74, v54, v55 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v75, v63, v70 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	ds_store_b128 v60, v[48:51] offset:512
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v102, v71, v72
	v_cvt_pk_fp8_f32 v103, v87, v88
	v_cvt_pk_fp8_f32 v102, v73, v86 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v103, v89, v90 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_clause 0x4
	global_load_b64 v[56:57], v[64:65], off
	global_load_b64 v[70:71], v[64:65], off offset:512
	global_load_b64 v[72:73], v[64:65], off offset:16
	global_load_b64 v[86:87], v[64:65], off offset:528
	global_load_b32 v104, v78, s[8:9] offset:32768
	s_wait_loadcnt 0x4
	v_wmma_f32_16x16x16_fp8_fp8 v[48:55], v[74:75], v[56:57], 0
	s_wait_loadcnt 0x3
	v_wmma_f32_16x16x16_fp8_fp8 v[56:63], v[74:75], v[70:71], 0
	s_wait_loadcnt 0x2
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x16_fp8_fp8 v[48:55], v[102:103], v[72:73], v[48:55]
	v_dual_mov_b32 v73, s19 :: v_dual_mov_b32 v72, s18
	v_dual_mov_b32 v71, s17 :: v_dual_mov_b32 v70, s16
	s_wait_loadcnt 0x1
	v_wmma_f32_16x16x16_fp8_fp8 v[56:63], v[102:103], v[86:87], v[56:63]
	v_fma_mixlo_f16 v94, v48, v48, 0
	v_fma_mixhi_f16 v94, v49, v49, 0
	v_fma_mixlo_f16 v95, v50, v50, 0
	v_fma_mixhi_f16 v95, v51, v51, 0
	v_fma_mixlo_f16 v96, v52, v52, 0
	v_fma_mixhi_f16 v96, v53, v53, 0
	v_fma_mixlo_f16 v97, v54, v54, 0
	v_fma_mixhi_f16 v97, v55, v55, 0
	v_fma_mixlo_f16 v98, v56, v56, 0
	v_fma_mixhi_f16 v98, v57, v57, 0
	v_fma_mixlo_f16 v99, v58, v58, 0
	v_fma_mixhi_f16 v99, v59, v59, 0
	v_fma_mixlo_f16 v100, v60, v60, 0
	v_fma_mixhi_f16 v100, v61, v61, 0
	v_fma_mixlo_f16 v101, v62, v62, 0
	v_fma_mixhi_f16 v101, v63, v63, 0
	v_wmma_f32_16x16x16_f16 v[86:93], v[94:97], v[70:73], 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_wmma_f32_16x16x16_f16 v[86:93], v[98:101], v[70:73], v[86:93]
	v_max_num_f32_e32 v86, v86, v86
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v86, 0x38820000, v86
	v_rsq_f32_e32 v86, v86
	s_wait_loadcnt 0x0
	s_delay_alu instid0(TRANS32_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_mul_f32_e32 v86, v86, v104
	v_dual_mul_f32 v87, v86, v48 :: v_dual_mul_f32 v88, v86, v49
	v_dual_mul_f32 v50, v86, v50 :: v_dual_mul_f32 v51, v86, v51
	v_dual_mul_f32 v52, v86, v52 :: v_dual_mul_f32 v53, v86, v53
	v_dual_mul_f32 v54, v86, v54 :: v_dual_mul_f32 v55, v86, v55
	v_dual_mul_f32 v56, v86, v56 :: v_dual_mul_f32 v57, v86, v57
	v_dual_mul_f32 v58, v86, v58 :: v_dual_mul_f32 v59, v86, v59
	v_dual_mul_f32 v60, v86, v60 :: v_dual_mul_f32 v61, v86, v61
	v_dual_mul_f32 v62, v86, v62 :: v_dual_mul_f32 v63, v86, v63
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v48, v87, v88
	v_cvt_pk_fp8_f32 v49, v52, v53
	v_cvt_pk_fp8_f32 v48, v50, v51 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v49, v54, v55 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	ds_store_b64 v84, v[48:49]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v48, v56, v57
	v_cvt_pk_fp8_f32 v49, v60, v61
	v_cvt_pk_fp8_f32 v48, v58, v59 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v49, v62, v63 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_lshl_b32 m0, s3, 2
	ds_store_b64 v84, v[48:49] offset:16
	; sched_barrier mask(0x00000000)
	ds_load_u8 v48, v82 offset:96
	ds_load_u8 v49, v82 offset:64
	ds_load_u8 v50, v82
	ds_load_u8 v51, v82 offset:32
	ds_load_u8 v52, v82 offset:160
	ds_load_u8 v53, v82 offset:128
	ds_load_u8 v54, v82 offset:224
	ds_load_u8 v55, v82 offset:192
	s_wait_dscnt 0x6
	v_perm_b32 v48, v49, v48, 0xc0c0004
	s_wait_dscnt 0x4
	v_perm_b32 v49, v50, v51, 0xc0c0004
	s_wait_dscnt 0x2
	v_perm_b32 v50, v53, v52, 0xc0c0004
	s_wait_dscnt 0x0
	v_perm_b32 v51, v55, v54, 0xc0c0004
	v_lshl_or_b32 v48, v48, 16, v49
	ds_load_u8 v49, v82 offset:16
	ds_load_u8 v52, v82 offset:48
	v_lshl_or_b32 v50, v51, 16, v50
	v_movreld_b32_e32 v0, v48
	s_delay_alu instid0(VALU_DEP_2)
	v_movreld_b32_e32 v1, v50
	ds_load_u8 v48, v82 offset:112
	ds_load_u8 v50, v82 offset:80
	ds_load_u8 v51, v82 offset:176
	ds_load_u8 v53, v82 offset:144
	ds_load_u8 v54, v82 offset:240
	ds_load_u8 v55, v82 offset:208
	s_wait_dscnt 0x6
	v_perm_b32 v49, v49, v52, 0xc0c0004
	s_wait_dscnt 0x4
	v_perm_b32 v48, v50, v48, 0xc0c0004
	s_wait_dscnt 0x2
	v_perm_b32 v50, v53, v51, 0xc0c0004
	s_wait_dscnt 0x0
	v_perm_b32 v51, v55, v54, 0xc0c0004
	v_lshl_or_b32 v48, v48, 16, v49
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v49, v51, 16, v50
	v_movreld_b32_e32 v2, v48
	s_delay_alu instid0(VALU_DEP_2)
	v_movreld_b32_e32 v3, v49
	s_clause 0x3
	global_load_b64 v[56:57], v[64:65], off offset:1024
	global_load_b64 v[86:87], v[64:65], off offset:1536
	global_load_b64 v[88:89], v[64:65], off offset:1040
	global_load_b64 v[90:91], v[64:65], off offset:1552
	s_wait_loadcnt 0x3
	v_wmma_f32_16x16x16_fp8_fp8 v[48:55], v[74:75], v[56:57], 0
	s_wait_loadcnt 0x2
	v_wmma_f32_16x16x16_fp8_fp8 v[56:63], v[74:75], v[86:87], 0
	s_wait_loadcnt 0x1
	s_delay_alu instid0(VALU_DEP_2) | instskip(SKIP_1) | instid1(VALU_DEP_2)
	v_wmma_f32_16x16x16_fp8_fp8 v[48:55], v[102:103], v[88:89], v[48:55]
	s_wait_loadcnt 0x0
	v_wmma_f32_16x16x16_fp8_fp8 v[56:63], v[102:103], v[90:91], v[56:63]
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_3)
	v_fma_mixlo_f16 v94, v48, v48, 0
	v_fma_mixhi_f16 v94, v49, v49, 0
	v_fma_mixlo_f16 v95, v50, v50, 0
	v_fma_mixhi_f16 v95, v51, v51, 0
	v_fma_mixlo_f16 v96, v52, v52, 0
	v_fma_mixhi_f16 v96, v53, v53, 0
	v_fma_mixlo_f16 v97, v54, v54, 0
	v_fma_mixhi_f16 v97, v55, v55, 0
	v_fma_mixlo_f16 v98, v56, v56, 0
	v_fma_mixhi_f16 v98, v57, v57, 0
	v_fma_mixlo_f16 v99, v58, v58, 0
	v_fma_mixhi_f16 v99, v59, v59, 0
	v_fma_mixlo_f16 v100, v60, v60, 0
	v_fma_mixhi_f16 v100, v61, v61, 0
	v_fma_mixlo_f16 v101, v62, v62, 0
	v_fma_mixhi_f16 v101, v63, v63, 0
	v_wmma_f32_16x16x16_f16 v[86:93], v[94:97], v[70:73], 0
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_wmma_f32_16x16x16_f16 v[86:93], v[98:101], v[70:73], v[86:93]
	v_max_num_f32_e32 v70, v86, v86
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_max_num_f32_e32 v70, 0x38820000, v70
	v_rsq_f32_e32 v70, v70
	s_delay_alu instid0(TRANS32_DEP_1)
	v_dual_mul_f32 v71, v70, v48 :: v_dual_mul_f32 v72, v70, v49
	v_dual_mul_f32 v50, v70, v50 :: v_dual_mul_f32 v51, v70, v51
	v_dual_mul_f32 v52, v70, v52 :: v_dual_mul_f32 v53, v70, v53
	v_dual_mul_f32 v54, v70, v54 :: v_dual_mul_f32 v55, v70, v55
	v_dual_mul_f32 v56, v70, v56 :: v_dual_mul_f32 v57, v70, v57
	v_dual_mul_f32 v58, v70, v58 :: v_dual_mul_f32 v59, v70, v59
	v_dual_mul_f32 v60, v70, v60 :: v_dual_mul_f32 v61, v70, v61
	v_dual_mul_f32 v62, v70, v62 :: v_dual_mul_f32 v63, v70, v63
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v48, v71, v72
	v_cvt_pk_fp8_f32 v49, v52, v53
	v_cvt_pk_fp8_f32 v48, v50, v51 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v49, v54, v55 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	ds_store_b64 v84, v[48:49]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v48, v56, v57
	v_cvt_pk_fp8_f32 v49, v60, v61
	v_cvt_pk_fp8_f32 v48, v58, v59 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v49, v62, v63 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	ds_store_b64 v84, v[48:49] offset:16
	; sched_barrier mask(0x00000000)
	ds_load_u8 v48, v82 offset:96
	ds_load_u8 v49, v82 offset:64
	ds_load_u8 v50, v82
	ds_load_u8 v51, v82 offset:32
	ds_load_u8 v52, v82 offset:160
	ds_load_u8 v53, v82 offset:128
	ds_load_u8 v54, v82 offset:224
	ds_load_u8 v55, v82 offset:192
	s_wait_dscnt 0x6
	v_perm_b32 v48, v49, v48, 0xc0c0004
	s_wait_dscnt 0x4
	v_perm_b32 v49, v50, v51, 0xc0c0004
	s_wait_dscnt 0x2
	v_perm_b32 v50, v53, v52, 0xc0c0004
	s_wait_dscnt 0x0
	v_perm_b32 v51, v55, v54, 0xc0c0004
	v_lshl_or_b32 v48, v48, 16, v49
	ds_load_u8 v49, v82 offset:16
	ds_load_u8 v52, v82 offset:48
	v_lshl_or_b32 v50, v51, 16, v50
	v_movreld_b32_e32 v32, v48
	s_delay_alu instid0(VALU_DEP_2)
	v_movreld_b32_e32 v33, v50
	ds_load_u8 v48, v82 offset:112
	ds_load_u8 v50, v82 offset:80
	ds_load_u8 v51, v82 offset:176
	ds_load_u8 v53, v82 offset:144
	ds_load_u8 v54, v82 offset:240
	ds_load_u8 v55, v82 offset:208
	s_wait_dscnt 0x6
	v_perm_b32 v49, v49, v52, 0xc0c0004
	s_wait_dscnt 0x4
	v_perm_b32 v48, v50, v48, 0xc0c0004
	s_wait_dscnt 0x2
	v_perm_b32 v50, v53, v51, 0xc0c0004
	s_wait_dscnt 0x0
	v_perm_b32 v51, v55, v54, 0xc0c0004
	v_lshl_or_b32 v48, v48, 16, v49
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_lshl_or_b32 v49, v51, 16, v50
	v_movreld_b32_e32 v34, v48
	s_delay_alu instid0(VALU_DEP_2)
	v_movreld_b32_e32 v35, v49
	s_clause 0x3
	global_load_b64 v[56:57], v[64:65], off offset:2048
	global_load_b64 v[58:59], v[64:65], off offset:2064
	global_load_b64 v[70:71], v[64:65], off offset:2560
	global_load_b64 v[72:73], v[64:65], off offset:2576
	s_wait_loadcnt 0x3
	v_wmma_f32_16x16x16_fp8_fp8 v[48:55], v[74:75], v[56:57], 0
	s_wait_loadcnt 0x2
	s_delay_alu instid0(VALU_DEP_1)
	v_wmma_f32_16x16x16_fp8_fp8 v[48:55], v[102:103], v[58:59], v[48:55]
	s_wait_loadcnt 0x1
	v_wmma_f32_16x16x16_fp8_fp8 v[56:63], v[74:75], v[70:71], 0
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v70, v48, v49
	v_cvt_pk_fp8_f32 v71, v52, v53
	v_cvt_pk_fp8_f32 v70, v50, v51 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v71, v54, v55 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	v_movreld_b32_e32 v16, v70
	s_wait_loadcnt 0x0
	s_delay_alu instid0(VALU_DEP_2)
	v_wmma_f32_16x16x16_fp8_fp8 v[56:63], v[102:103], v[72:73], v[56:63]
	v_movreld_b32_e32 v17, v71
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v48, v56, v57
	v_cvt_pk_fp8_f32 v49, v60, v61
	v_cvt_pk_fp8_f32 v48, v58, v59 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v49, v62, v63 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	v_movreld_b32_e32 v18, v48
	v_movreld_b32_e32 v19, v49
	; sched_barrier mask(0x00000000)
	s_add_co_i32 s3, s3, 1
	s_wait_alu depctr_sa_sdst(0)
	s_cmp_eq_u32 s3, 4
	s_cbranch_scc0 .LBB19_2
; %bb.9:
	v_lshlrev_b32_e32 v48, 2, v79
	v_lshl_or_b32 v49, ttmp9, 11, v80
	v_add_lshl_u32 v50, v81, v80, 2
	s_mov_b32 s31, 0
	s_mov_b64 s[34:35], 0
	s_mov_b32 s36, 0x3c003c00
	v_add_co_u32 v48, s0, s8, v48
	v_add_co_u32 v51, s1, v79, v49
	v_add_co_u32 v52, s2, s8, v50
	s_wait_alu depctr_va_sdst(0)
	v_add_co_ci_u32_e64 v50, null, 0, 0, s1
	v_add_co_ci_u32_e64 v49, null, s9, 0, s0
	v_add_co_u32 v51, vcc_lo, s10, v51
	s_wait_alu depctr_va_vcc(0)
	s_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)
	v_add_co_ci_u32_e64 v54, null, s11, v50, vcc_lo
	v_add_co_ci_u32_e64 v53, null, s9, 0, s2
	v_add_co_u32 v50, vcc_lo, v51, 16
	s_wait_alu depctr_va_vcc(0)
	s_delay_alu instid0(VALU_DEP_3)
	v_add_co_ci_u32_e64 v51, null, 0, v54, vcc_lo
	s_mov_b32 s37, s36
	s_mov_b32 s38, s36
	s_mov_b32 s39, s36
.LBB19_10:                              ; =>This Inner Loop Header: Depth=1
	s_mov_b32 m0, s31
	v_add_co_u32 v54, vcc_lo, v52, s34
	s_wait_alu depctr_va_vcc(0)
	v_add_co_ci_u32_e64 v55, null, s35, v53, vcc_lo
	s_clause 0x7
	global_load_b128 v[93:96], v[54:55], off offset:16384
	global_load_b128 v[97:100], v[54:55], off offset:16400
	global_load_b128 v[101:104], v[54:55], off offset:16448
	global_load_b128 v[105:108], v[54:55], off offset:16464
	global_load_b128 v[109:112], v[54:55], off offset:16512
	global_load_b128 v[113:116], v[54:55], off offset:16528
	global_load_b128 v[117:120], v[54:55], off offset:16576
	global_load_b128 v[121:124], v[54:55], off offset:16592
	v_movrels_b32_e32 v62, v0
	s_add_co_i32 m0, s31, 1
	v_movrels_b32_e32 v63, v0
	s_add_co_i32 m0, s31, 2
	v_movrels_b32_e32 v74, v0
	s_add_co_i32 m0, s31, 3
	v_movrels_b32_e32 v75, v0
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[32:33], v[62:63], 0
	v_wmma_f32_16x16x16_fp8_fp8 v[66:73], v[36:37], v[62:63], 0
	v_wmma_f32_16x16x16_fp8_fp8 v[77:84], v[40:41], v[62:63], 0
	v_wmma_f32_16x16x16_fp8_fp8 v[85:92], v[44:45], v[62:63], 0
	s_delay_alu instid0(VALU_DEP_4)
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[34:35], v[74:75], v[54:61]
	v_dual_mov_b32 v128, s39 :: v_dual_mov_b32 v127, s38
	v_dual_mov_b32 v126, s37 :: v_dual_mov_b32 v125, s36
	v_wmma_f32_16x16x16_fp8_fp8 v[66:73], v[38:39], v[74:75], v[66:73]
	v_wmma_f32_16x16x16_fp8_fp8 v[77:84], v[42:43], v[74:75], v[77:84]
	v_wmma_f32_16x16x16_fp8_fp8 v[85:92], v[46:47], v[74:75], v[85:92]
	s_wait_loadcnt 0x7
	v_dual_add_f32 v54, v54, v93 :: v_dual_add_f32 v55, v55, v94
	v_dual_add_f32 v56, v56, v95 :: v_dual_add_f32 v57, v57, v96
	s_wait_loadcnt 0x6
	v_dual_add_f32 v58, v58, v97 :: v_dual_add_f32 v59, v59, v98
	v_dual_add_f32 v60, v60, v99 :: v_dual_add_f32 v61, v61, v100
	s_wait_loadcnt 0x5
	v_dual_add_f32 v62, v66, v101 :: v_dual_add_f32 v63, v67, v102
	v_dual_add_f32 v66, v68, v103 :: v_dual_add_f32 v67, v69, v104
	s_wait_loadcnt 0x4
	v_dual_add_f32 v68, v70, v105 :: v_dual_add_f32 v69, v71, v106
	v_dual_add_f32 v70, v72, v107 :: v_dual_add_f32 v71, v73, v108
	s_wait_loadcnt 0x3
	v_dual_add_f32 v72, v77, v109 :: v_dual_add_f32 v73, v78, v110
	v_dual_add_f32 v74, v79, v111 :: v_dual_add_f32 v75, v80, v112
	s_wait_loadcnt 0x2
	v_dual_add_f32 v77, v81, v113 :: v_dual_add_f32 v78, v82, v114
	v_dual_add_f32 v79, v83, v115 :: v_dual_add_f32 v80, v84, v116
	s_wait_loadcnt 0x1
	v_dual_add_f32 v81, v85, v117 :: v_dual_add_f32 v82, v86, v118
	v_dual_add_f32 v83, v87, v119 :: v_dual_add_f32 v84, v88, v120
	s_wait_loadcnt 0x0
	v_dual_add_f32 v85, v89, v121 :: v_dual_add_f32 v86, v90, v122
	v_dual_add_f32 v87, v91, v123 :: v_dual_add_f32 v88, v92, v124
	v_dual_mul_f32 v54, 0x3d380000, v54 :: v_dual_mul_f32 v55, 0x3d380000, v55
	v_dual_mul_f32 v56, 0x3d380000, v56 :: v_dual_mul_f32 v57, 0x3d380000, v57
	v_dual_mul_f32 v58, 0x3d380000, v58 :: v_dual_mul_f32 v59, 0x3d380000, v59
	v_dual_mul_f32 v60, 0x3d380000, v60 :: v_dual_mul_f32 v61, 0x3d380000, v61
	v_dual_mul_f32 v62, 0x3d380000, v62 :: v_dual_mul_f32 v63, 0x3d380000, v63
	v_dual_mul_f32 v66, 0x3d380000, v66 :: v_dual_mul_f32 v67, 0x3d380000, v67
	v_dual_mul_f32 v68, 0x3d380000, v68 :: v_dual_mul_f32 v69, 0x3d380000, v69
	v_dual_mul_f32 v70, 0x3d380000, v70 :: v_dual_mul_f32 v71, 0x3d380000, v71
	v_dual_mul_f32 v72, 0x3d380000, v72 :: v_dual_mul_f32 v73, 0x3d380000, v73
	v_dual_mul_f32 v74, 0x3d380000, v74 :: v_dual_mul_f32 v75, 0x3d380000, v75
	v_dual_mul_f32 v77, 0x3d380000, v77 :: v_dual_mul_f32 v78, 0x3d380000, v78
	v_dual_mul_f32 v79, 0x3d380000, v79 :: v_dual_mul_f32 v80, 0x3d380000, v80
	v_dual_mul_f32 v81, 0x3d380000, v81 :: v_dual_mul_f32 v82, 0x3d380000, v82
	v_dual_mul_f32 v83, 0x3d380000, v83 :: v_dual_mul_f32 v84, 0x3d380000, v84
	v_dual_mul_f32 v85, 0x3d380000, v85 :: v_dual_mul_f32 v86, 0x3d380000, v86
	v_dual_mul_f32 v87, 0x3d380000, v87 :: v_dual_mul_f32 v88, 0x3d380000, v88
	v_dual_add_f32 v54, 0x3fa68000, v54 :: v_dual_add_f32 v55, 0x3fa68000, v55
	v_dual_add_f32 v56, 0x3fa68000, v56 :: v_dual_add_f32 v57, 0x3fa68000, v57
	v_dual_add_f32 v58, 0x3fa68000, v58 :: v_dual_add_f32 v59, 0x3fa68000, v59
	v_dual_add_f32 v60, 0x3fa68000, v60 :: v_dual_add_f32 v61, 0x3fa68000, v61
	v_dual_add_f32 v62, 0x3fa68000, v62 :: v_dual_add_f32 v63, 0x3fa68000, v63
	v_dual_add_f32 v66, 0x3fa68000, v66 :: v_dual_add_f32 v67, 0x3fa68000, v67
	v_dual_add_f32 v68, 0x3fa68000, v68 :: v_dual_add_f32 v69, 0x3fa68000, v69
	v_dual_add_f32 v70, 0x3fa68000, v70 :: v_dual_add_f32 v71, 0x3fa68000, v71
	v_dual_add_f32 v72, 0x3fa68000, v72 :: v_dual_add_f32 v73, 0x3fa68000, v73
	v_dual_add_f32 v74, 0x3fa68000, v74 :: v_dual_add_f32 v75, 0x3fa68000, v75
	v_dual_add_f32 v77, 0x3fa68000, v77 :: v_dual_add_f32 v78, 0x3fa68000, v78
	v_dual_add_f32 v79, 0x3fa68000, v79 :: v_dual_add_f32 v80, 0x3fa68000, v80
	v_dual_add_f32 v81, 0x3fa68000, v81 :: v_dual_add_f32 v82, 0x3fa68000, v82
	v_dual_add_f32 v83, 0x3fa68000, v83 :: v_dual_add_f32 v84, 0x3fa68000, v84
	v_dual_add_f32 v85, 0x3fa68000, v85 :: v_dual_add_f32 v86, 0x3fa68000, v86
	v_dual_add_f32 v87, 0x3fa68000, v87 :: v_dual_add_f32 v88, 0x3fa68000, v88
	v_dual_max_num_f32 v54, 0x3f840000, v54 :: v_dual_max_num_f32 v55, 0x3f840000, v55
	v_dual_max_num_f32 v56, 0x3f840000, v56 :: v_dual_max_num_f32 v57, 0x3f840000, v57
	v_dual_max_num_f32 v58, 0x3f840000, v58 :: v_dual_max_num_f32 v59, 0x3f840000, v59
	v_dual_max_num_f32 v60, 0x3f840000, v60 :: v_dual_max_num_f32 v61, 0x3f840000, v61
	v_dual_max_num_f32 v62, 0x3f840000, v62 :: v_dual_max_num_f32 v63, 0x3f840000, v63
	v_dual_max_num_f32 v66, 0x3f840000, v66 :: v_dual_max_num_f32 v67, 0x3f840000, v67
	v_dual_max_num_f32 v68, 0x3f840000, v68 :: v_dual_max_num_f32 v69, 0x3f840000, v69
	v_dual_max_num_f32 v70, 0x3f840000, v70 :: v_dual_max_num_f32 v71, 0x3f840000, v71
	v_dual_max_num_f32 v72, 0x3f840000, v72 :: v_dual_max_num_f32 v73, 0x3f840000, v73
	v_dual_max_num_f32 v74, 0x3f840000, v74 :: v_dual_max_num_f32 v75, 0x3f840000, v75
	v_dual_max_num_f32 v77, 0x3f840000, v77 :: v_dual_max_num_f32 v78, 0x3f840000, v78
	v_dual_max_num_f32 v79, 0x3f840000, v79 :: v_dual_max_num_f32 v80, 0x3f840000, v80
	v_dual_max_num_f32 v81, 0x3f840000, v81 :: v_dual_max_num_f32 v82, 0x3f840000, v82
	v_dual_max_num_f32 v83, 0x3f840000, v83 :: v_dual_max_num_f32 v84, 0x3f840000, v84
	v_dual_max_num_f32 v85, 0x3f840000, v85 :: v_dual_max_num_f32 v86, 0x3f840000, v86
	v_dual_max_num_f32 v87, 0x3f840000, v87 :: v_dual_max_num_f32 v88, 0x3f840000, v88
	v_cmp_gt_f32_e32 vcc_lo, 0x3fc8e000, v54
	v_lshrrev_b32_e32 v54, 8, v54
	v_cmp_gt_f32_e64 s0, 0x3fc8e000, v55
	v_lshrrev_b32_e32 v55, 8, v55
	v_cmp_gt_f32_e64 s1, 0x3fc8e000, v56
	v_lshrrev_b32_e32 v56, 8, v56
	v_cmp_gt_f32_e64 s2, 0x3fc8e000, v57
	v_lshrrev_b32_e32 v57, 8, v57
	v_cmp_gt_f32_e64 s3, 0x3fc8e000, v58
	v_lshrrev_b32_e32 v58, 8, v58
	v_cmp_gt_f32_e64 s4, 0x3fc8e000, v59
	v_lshrrev_b32_e32 v59, 8, v59
	v_cmp_gt_f32_e64 s5, 0x3fc8e000, v60
	v_lshrrev_b32_e32 v60, 8, v60
	v_cmp_gt_f32_e64 s6, 0x3fc8e000, v61
	v_lshrrev_b32_e32 v61, 8, v61
	v_cmp_gt_f32_e64 s7, 0x3fc8e000, v62
	v_lshrrev_b32_e32 v62, 8, v62
	v_cmp_gt_f32_e64 s8, 0x3fc8e000, v63
	v_lshrrev_b32_e32 v63, 8, v63
	v_cmp_gt_f32_e64 s9, 0x3fc8e000, v66
	v_lshrrev_b32_e32 v66, 8, v66
	v_cmp_gt_f32_e64 s10, 0x3fc8e000, v67
	v_lshrrev_b32_e32 v67, 8, v67
	v_cmp_gt_f32_e64 s11, 0x3fc8e000, v68
	v_lshrrev_b32_e32 v68, 8, v68
	v_cmp_gt_f32_e64 s12, 0x3fc8e000, v69
	v_lshrrev_b32_e32 v69, 8, v69
	v_cmp_gt_f32_e64 s13, 0x3fc8e000, v70
	v_lshrrev_b32_e32 v70, 8, v70
	v_cmp_gt_f32_e64 s14, 0x3fc8e000, v71
	v_lshrrev_b32_e32 v71, 8, v71
	v_cmp_gt_f32_e64 s15, 0x3fc8e000, v72
	v_lshrrev_b32_e32 v72, 8, v72
	v_cmp_gt_f32_e64 s16, 0x3fc8e000, v73
	v_lshrrev_b32_e32 v73, 8, v73
	v_cmp_gt_f32_e64 s17, 0x3fc8e000, v74
	v_lshrrev_b32_e32 v74, 8, v74
	v_cmp_gt_f32_e64 s18, 0x3fc8e000, v75
	v_lshrrev_b32_e32 v75, 8, v75
	v_cmp_gt_f32_e64 s19, 0x3fc8e000, v77
	v_lshrrev_b32_e32 v77, 8, v77
	v_cmp_gt_f32_e64 s20, 0x3fc8e000, v78
	v_lshrrev_b32_e32 v78, 8, v78
	v_cmp_gt_f32_e64 s21, 0x3fc8e000, v79
	v_lshrrev_b32_e32 v79, 8, v79
	v_cmp_gt_f32_e64 s22, 0x3fc8e000, v80
	v_lshrrev_b32_e32 v80, 8, v80
	v_cmp_gt_f32_e64 s23, 0x3fc8e000, v81
	v_lshrrev_b32_e32 v81, 8, v81
	v_cmp_gt_f32_e64 s24, 0x3fc8e000, v82
	v_lshrrev_b32_e32 v82, 8, v82
	v_cmp_gt_f32_e64 s25, 0x3fc8e000, v83
	v_lshrrev_b32_e32 v83, 8, v83
	v_cmp_gt_f32_e64 s26, 0x3fc8e000, v84
	v_lshrrev_b32_e32 v84, 8, v84
	v_cmp_gt_f32_e64 s27, 0x3fc8e000, v85
	v_lshrrev_b32_e32 v85, 8, v85
	v_cmp_gt_f32_e64 s28, 0x3fc8e000, v86
	v_lshrrev_b32_e32 v86, 8, v86
	v_cmp_gt_f32_e64 s29, 0x3fc8e000, v87
	v_lshrrev_b32_e32 v87, 8, v87
	v_cmp_gt_f32_e64 s30, 0x3fc8e000, v88
	v_lshrrev_b32_e32 v88, 8, v88
	v_and_b16 v54.l, 0xffe0, v54.l
	v_and_b16 v54.h, 0xffe0, v55.l
	v_and_b16 v55.l, 0xffe0, v56.l
	v_and_b16 v55.h, 0xffe0, v57.l
	v_and_b16 v56.l, 0xffe0, v58.l
	v_and_b16 v56.h, 0xffe0, v59.l
	v_and_b16 v57.l, 0xffe0, v60.l
	v_and_b16 v57.h, 0xffe0, v61.l
	v_and_b16 v58.l, 0xffe0, v62.l
	v_and_b16 v58.h, 0xffe0, v63.l
	v_and_b16 v59.l, 0xffe0, v66.l
	v_and_b16 v59.h, 0xffe0, v67.l
	v_and_b16 v60.l, 0xffe0, v68.l
	v_and_b16 v60.h, 0xffe0, v69.l
	v_and_b16 v61.l, 0xffe0, v70.l
	v_and_b16 v61.h, 0xffe0, v71.l
	v_and_b16 v62.l, 0xffe0, v72.l
	v_and_b16 v62.h, 0xffe0, v73.l
	v_and_b16 v63.l, 0xffe0, v74.l
	v_and_b16 v63.h, 0xffe0, v75.l
	v_and_b16 v66.l, 0xffe0, v77.l
	v_and_b16 v66.h, 0xffe0, v78.l
	v_and_b16 v67.l, 0xffe0, v79.l
	v_and_b16 v67.h, 0xffe0, v80.l
	v_and_b16 v68.l, 0xffe0, v81.l
	v_and_b16 v68.h, 0xffe0, v82.l
	v_and_b16 v69.l, 0xffe0, v83.l
	v_and_b16 v69.h, 0xffe0, v84.l
	v_and_b16 v70.l, 0xffe0, v85.l
	v_and_b16 v70.h, 0xffe0, v86.l
	v_and_b16 v71.l, 0xffe0, v87.l
	v_and_b16 v71.h, 0xffe0, v88.l
	s_wait_alu depctr_va_vcc(0)
	v_cndmask_b16 v74.l, 0xc8e0, v54.l, vcc_lo
	s_wait_alu depctr_va_sdst(0)
	v_cndmask_b16 v75.l, 0xc8e0, v54.h, s0
	v_cndmask_b16 v77.l, 0xc8e0, v55.l, s1
	v_cndmask_b16 v78.l, 0xc8e0, v55.h, s2
	v_cndmask_b16 v79.l, 0xc8e0, v56.l, s3
	v_cndmask_b16 v80.l, 0xc8e0, v56.h, s4
	v_cndmask_b16 v81.l, 0xc8e0, v57.l, s5
	v_cndmask_b16 v82.l, 0xc8e0, v57.h, s6
	v_cndmask_b16 v83.l, 0xc8e0, v58.l, s7
	v_cndmask_b16 v84.l, 0xc8e0, v58.h, s8
	v_cndmask_b16 v85.l, 0xc8e0, v59.l, s9
	v_cndmask_b16 v86.l, 0xc8e0, v59.h, s10
	v_cndmask_b16 v87.l, 0xc8e0, v60.l, s11
	v_cndmask_b16 v88.l, 0xc8e0, v60.h, s12
	v_cndmask_b16 v89.l, 0xc8e0, v61.l, s13
	v_cndmask_b16 v90.l, 0xc8e0, v61.h, s14
	v_cndmask_b16 v62.l, 0xc8e0, v62.l, s15
	v_cndmask_b16 v91.l, 0xc8e0, v62.h, s16
	v_cndmask_b16 v63.l, 0xc8e0, v63.l, s17
	v_cndmask_b16 v92.l, 0xc8e0, v63.h, s18
	v_cndmask_b16 v93.l, 0xc8e0, v66.l, s19
	v_cndmask_b16 v94.l, 0xc8e0, v66.h, s20
	v_cndmask_b16 v95.l, 0xc8e0, v67.l, s21
	v_cndmask_b16 v96.l, 0xc8e0, v67.h, s22
	v_cndmask_b16 v97.l, 0xc8e0, v68.l, s23
	v_cndmask_b16 v98.l, 0xc8e0, v68.h, s24
	v_cndmask_b16 v99.l, 0xc8e0, v69.l, s25
	v_cndmask_b16 v100.l, 0xc8e0, v69.h, s26
	v_cndmask_b16 v101.l, 0xc8e0, v70.l, s27
	v_cndmask_b16 v102.l, 0xc8e0, v70.h, s28
	v_cndmask_b16 v103.l, 0xc8e0, v71.l, s29
	v_cndmask_b16 v104.l, 0xc8e0, v71.h, s30
	v_perm_b32 v69, v82, v81, 0x5040100
	v_perm_b32 v68, v80, v79, 0x5040100
	v_perm_b32 v67, v78, v77, 0x5040100
	v_perm_b32 v66, v75, v74, 0x5040100
	v_perm_b32 v73, v90, v89, 0x5040100
	v_perm_b32 v72, v88, v87, 0x5040100
	v_perm_b32 v71, v86, v85, 0x5040100
	v_perm_b32 v70, v84, v83, 0x5040100
	v_wmma_f32_16x16x16_f16 v[54:61], v[125:128], v[66:69], 0 neg_lo:[0,1,0] neg_hi:[0,1,0]
	v_perm_b32 v69, v96, v95, 0x5040100
	v_perm_b32 v68, v94, v93, 0x5040100
	v_perm_b32 v67, v92, v63, 0x5040100
	v_perm_b32 v66, v91, v62, 0x5040100
	v_wmma_f32_16x16x16_f16 v[54:61], v[125:128], v[70:73], v[54:61] neg_lo:[0,1,0] neg_hi:[0,1,0]
	v_perm_b32 v73, v104, v103, 0x5040100
	v_perm_b32 v72, v102, v101, 0x5040100
	v_perm_b32 v71, v100, v99, 0x5040100
	v_perm_b32 v70, v98, v97, 0x5040100
	v_wmma_f32_16x16x16_f16 v[54:61], v[125:128], v[66:69], v[54:61] neg_lo:[0,1,0] neg_hi:[0,1,0]
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_wmma_f32_16x16x16_f16 v[54:61], v[125:128], v[70:73], v[54:61] neg_lo:[0,1,0] neg_hi:[0,1,0]
	v_rcp_f32_e32 v54, v54
	s_delay_alu instid0(VALU_DEP_1) | instskip(NEXT) | instid1(VALU_DEP_1)
	v_rcp_f32_e32 v55, v55
	v_rcp_f32_e32 v56, v56
	s_delay_alu instid0(VALU_DEP_1)
	v_rcp_f32_e32 v57, v57
	v_rcp_f32_e32 v58, v58
	v_rcp_f32_e32 v59, v59
	v_rcp_f32_e32 v60, v60
	v_rcp_f32_e32 v61, v61
	v_fma_mix_f32 v66, -v74, v54, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v67, -v75, v55, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v68, -v77, v56, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v69, -v78, v57, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v70, -v79, v58, neg(0) op_sel_hi:[1,0,0]
	s_delay_alu instid0(TRANS32_DEP_3) | instskip(NEXT) | instid1(TRANS32_DEP_2)
	v_fma_mix_f32 v71, -v80, v59, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v72, -v81, v60, neg(0) op_sel_hi:[1,0,0]
	s_delay_alu instid0(TRANS32_DEP_1)
	v_fma_mix_f32 v73, -v82, v61, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v74, -v83, v54, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v75, -v84, v55, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v77, -v85, v56, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v78, -v86, v57, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v79, -v87, v58, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v80, -v88, v59, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v81, -v89, v60, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v82, -v90, v61, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v83, -v62, v54, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v84, -v91, v55, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v85, -v63, v56, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v86, -v92, v57, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v87, -v93, v58, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v88, -v94, v59, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v89, -v95, v60, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v90, -v96, v61, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v91, -v97, v54, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v92, -v98, v55, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v93, -v99, v56, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v94, -v100, v57, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v95, -v101, v58, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v96, -v102, v59, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v97, -v103, v60, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v98, -v104, v61, neg(0) op_sel_hi:[1,0,0]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v62, v66, v67
	v_cvt_pk_fp8_f32 v63, v70, v71
	v_cvt_pk_fp8_f32 v62, v68, v69 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v63, v72, v73 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[16:17], v[62:63], 0
	v_wmma_f32_16x16x16_fp8_fp8 v[66:73], v[18:19], v[62:63], 0
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v62, v74, v75
	v_cvt_pk_fp8_f32 v63, v79, v80
	v_cvt_pk_fp8_f32 v62, v77, v78 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v63, v81, v82 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[20:21], v[62:63], v[54:61]
	v_wmma_f32_16x16x16_fp8_fp8 v[66:73], v[22:23], v[62:63], v[66:73]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v62, v83, v84
	v_cvt_pk_fp8_f32 v63, v87, v88
	v_cvt_pk_fp8_f32 v62, v85, v86 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v63, v89, v90 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[24:25], v[62:63], v[54:61]
	v_wmma_f32_16x16x16_fp8_fp8 v[66:73], v[26:27], v[62:63], v[66:73]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v62, v91, v92
	v_cvt_pk_fp8_f32 v63, v95, v96
	v_cvt_pk_fp8_f32 v62, v93, v94 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v63, v97, v98 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_delay_alu instid0(VALU_DEP_2) | instskip(NEXT) | instid1(VALU_DEP_2)
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[28:29], v[62:63], v[54:61]
	v_wmma_f32_16x16x16_fp8_fp8 v[66:73], v[30:31], v[62:63], v[66:73]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v62, v54, v55
	v_cvt_pk_fp8_f32 v63, v58, v59
	v_cvt_pk_fp8_f32 v62, v56, v57 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v63, v60, v61 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v74, v66, v67
	v_cvt_pk_fp8_f32 v75, v70, v71
	v_cvt_pk_fp8_f32 v74, v68, v69 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v75, v72, v73 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	s_clause 0x3
	global_load_b64 v[81:82], v[64:65], off offset:3072
	global_load_b128 v[66:69], v[48:49], off offset:32772
	global_load_b64 v[83:84], v[64:65], off offset:3088
	global_load_b128 v[70:73], v[48:49], off offset:32788
	ds_load_b128 v[77:80], v76
	s_wait_loadcnt 0x3
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[81:82], v[62:63], 0
	s_wait_loadcnt_dscnt 0x200
	v_fma_mix_f32 v66, v77, v66, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v67, v77, v67, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_fma_mix_f32 v68, v78, v68, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v69, v78, v69, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	s_wait_loadcnt 0x1
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[83:84], v[74:75], v[54:61]
	s_wait_loadcnt 0x0
	v_fma_mix_f32 v70, v79, v70, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v71, v79, v71, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_fma_mix_f32 v72, v80, v72, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v73, v80, v73, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_dual_add_f32 v54, v54, v66 :: v_dual_add_f32 v55, v55, v67
	v_dual_add_f32 v56, v56, v68 :: v_dual_add_f32 v57, v57, v69
	v_dual_add_f32 v58, v58, v70 :: v_dual_add_f32 v59, v59, v71
	s_delay_alu instid0(VALU_DEP_4)
	v_dual_add_f32 v60, v60, v72 :: v_dual_add_f32 v61, v61, v73
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v54, v54, v55
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v55, v56, v57
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v56, v58, v59
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v57, v60, v61
	;;#ASMEND
	v_fma_mix_f32 v58, v54, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v59, v54, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_fma_mix_f32 v60, v55, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v61, v55, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_fma_mix_f32 v66, v56, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v56, v56, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_fma_mix_f32 v67, v57, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v57, v57, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v54, v58, v59
	v_cvt_pk_fp8_f32 v55, v66, v56
	v_cvt_pk_fp8_f32 v54, v60, v61 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v55, v67, v57 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	global_store_b64 v[50:51], v[54:55], off offset:-16
	s_clause 0x3
	global_load_b64 v[81:82], v[64:65], off offset:3584
	global_load_b128 v[66:69], v[48:49], off offset:32836
	global_load_b64 v[83:84], v[64:65], off offset:3600
	global_load_b128 v[70:73], v[48:49], off offset:32852
	ds_load_b128 v[77:80], v76 offset:512
	s_wait_loadcnt 0x3
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[81:82], v[62:63], 0
	s_wait_loadcnt_dscnt 0x200
	v_fma_mix_f32 v62, v77, v66, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v63, v77, v67, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_fma_mix_f32 v66, v78, v68, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v67, v78, v69, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	s_wait_loadcnt 0x1
	v_wmma_f32_16x16x16_fp8_fp8 v[54:61], v[83:84], v[74:75], v[54:61]
	s_wait_loadcnt 0x0
	v_fma_mix_f32 v68, v79, v70, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v69, v79, v71, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_fma_mix_f32 v70, v80, v72, neg(0) op_sel_hi:[1,0,0]
	v_fma_mix_f32 v71, v80, v73, neg(0) op_sel:[1,0,0] op_sel_hi:[1,0,0]
	v_dual_add_f32 v54, v54, v62 :: v_dual_add_f32 v55, v55, v63
	v_dual_add_f32 v56, v56, v66 :: v_dual_add_f32 v57, v57, v67
	v_dual_add_f32 v58, v58, v68 :: v_dual_add_f32 v59, v59, v69
	s_delay_alu instid0(VALU_DEP_4)
	v_dual_add_f32 v60, v60, v70 :: v_dual_add_f32 v61, v61, v71
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v54, v54, v55
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v55, v56, v57
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v56, v58, v59
	;;#ASMEND
	;;#ASMSTART
	v_cvt_pkrtz_f16_f32 v57, v60, v61
	;;#ASMEND
	v_fma_mix_f32 v58, v54, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v59, v54, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_fma_mix_f32 v60, v55, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v61, v55, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_fma_mix_f32 v62, v56, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v56, v56, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	v_fma_mix_f32 v63, v57, 1.0, 0 op_sel_hi:[1,1,0]
	v_fma_mix_f32 v57, v57, 1.0, 0 op_sel:[1,0,0] op_sel_hi:[1,1,0]
	;;#ASMSTART
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1
	v_cvt_pk_fp8_f32 v54, v58, v59
	v_cvt_pk_fp8_f32 v55, v62, v56
	v_cvt_pk_fp8_f32 v54, v60, v61 op_sel:[0,0,1]
	v_cvt_pk_fp8_f32 v55, v63, v57 op_sel:[0,0,1]
	s_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 0
	;;#ASMEND
	global_store_b64 v[50:51], v[54:55], off
	; sched_barrier mask(0x00000000)
	v_add_co_u32 v50, vcc_lo, 0x200, v50
	s_add_nc_u64 s[34:35], s[34:35], 0x1000
	v_add_nc_u32_e32 v76, 0x400, v76
	s_wait_alu depctr_va_vcc(0)
	v_add_co_ci_u32_e64 v51, null, 0, v51, vcc_lo
	s_add_co_i32 s31, s31, 4
	s_wait_alu depctr_sa_sdst(0)
	s_cmp_lg_u32 s34, 0x4000
	s_cbranch_scc1 .LBB19_10
.LBB19_11:
	s_nop 0
	s_sendmsg sendmsg(MSG_DEALLOC_VGPRS)
	s_endpgm
