## 900  frames=240  dispatch=153 (his 123)  sum(step)=13391us  span: profiled 13.9895 / plain 7.0135000000000005 ms (swin-off plain 7.163); his total 5909us
| fam | ours step (in-chain, gap incl.) | ours exec | disp | his | ours-his |
|---|---:|---:|---:|---:|---:|
| C32 | 2638.4 | 2609.6 | 11 | 1971.6 | +666.9 |
| C64 | 1159.9 | 1142.3 | 8 | 694.0 | +465.8 |
| C128 | 1422.1 | 1395.8 | 12 | 704.5 | +717.7 |
| C256 | 1610.3 | 1565.7 | 15 | 843.8 | +766.5 |
| C512 | 3468.4 | 3334.6 | 55 | 844.0 | +2624.3 |
| ViT | 2943.6 | 2813.2 | 50 | 835.9 | +2107.7 |
| other | 148.2 | 143.4 | 2 | 15.5 | +132.7 |
SP (production): sp_init-16 exec 43.7 step 49.2; sp_run256-16 exec 362.4 step 364.4; sp_recover-16 exec 43.1 step 48.5; sp_init-49 exec 43.5 step 49.2; sp_run256-49 exec 356.1 step 357.9; sp_recover-49 exec 43.3 step 48.4
## 1080  frames=240  dispatch=149 (his 123)  sum(step)=16078us  span: profiled 16.809 / plain 9.736 ms (swin-off plain 9.834); his total 7772us
| fam | ours step (in-chain, gap incl.) | ours exec | disp | his | ours-his |
|---|---:|---:|---:|---:|---:|
| C32 | 3548.9 | 3520.8 | 11 | 2682.3 | +866.6 |
| C64 | 1462.1 | 1446.0 | 8 | 938.0 | +524.1 |
| C128 | 1781.9 | 1756.5 | 12 | 948.7 | +833.3 |
| C256 | 1715.1 | 1675.8 | 11 | 1174.0 | +541.0 |
| C512 | 3847.0 | 3690.5 | 55 | 1014.7 | +2832.3 |
| ViT | 3571.0 | 3432.8 | 50 | 996.0 | +2575.0 |
| other | 151.5 | 147.2 | 2 | 18.4 | +133.1 |
SP (production): sp_init-16 exec 42.9 step 48.4; sp_run256-16 exec 494.2 step 495.9; sp_recover-16 exec 43.3 step 48.6; sp_init-49 exec 44.4 step 50.0; sp_run256-49 exec 475.1 step 477.1; sp_recover-49 exec 44.2 step 49.5
## 900 corrected: f=41.7us/dispatch (min exec 38.2us, trivial sp_init/recover ~43); plain span 7014us vs his 5909us, diff +1104us
| fam | ours in-chain (step - f) | disp | his | ours-his |
|---|---:|---:|---:|---:|
| C32 | 2179.9 | 11 | 1971.6 | +208.4 |
| C64 | 826.4 | 8 | 694.0 | +132.4 |
| C128 | 922.0 | 12 | 704.5 | +217.5 |
| C256 | 985.1 | 15 | 843.8 | +141.3 |
| C512 | 1175.9 | 55 | 844.0 | +331.8 |
| ViT | 859.4 | 50 | 835.9 | +23.5 |
| other | 64.8 | 2 | 15.5 | +49.3 |
SP corrected: sp_init-16 7.5; sp_run256-16 322.7; sp_recover-16 6.9; sp_init-49 7.5; sp_run256-49 316.3; sp_recover-49 6.7
SWIN_RUN=0 C256 dispatches (step - f): ffn_fb_pdl:61.0, c256_attn_wave_bo:23.8, ffn_bytein_fb_pdl:62.2, c256_attn_wave_bo:23.3, ffn_bytein_fb_pdl:60.6, c256_attn_wave_bo:25.1, ffn_bytein_fb_pdl:62.0, c256_attn_wave_bo:23.5, ffn_bytein_fb_pdl:60.9, c256_attn_wave_bo:25.3, ffn_bytein_fb_pdl:62.2, c256_attn_wave_bo:23.5, ffn_bytein_fb_pdl:61.2, c256_attn_wave_bo:25.2, ffn_bytein_fb_pdl:62.4, c256_attn_wave:35.3, mh_pool_project_group_c256:18.2, ffn_bytein_fb_pdl:59.1, c256_attn_wave_bo:24.5, ffn_bytein_fb_pdl:59.6, c256_attn_wave_bo:23.0, ffn_bytein_fb_pdl:58.7, c256_attn_wave_bo:25.0, ffn_bytein_fb_pdl:61.0, c256_attn_wave_bo:24.0, ffn_bytein_fb_pdl:59.9, c256_attn_wave_bo:25.8, ffn_bytein_fb_pdl:61.5, c256_attn_wave_bo:24.5, ffn_bytein_fb_pdl:60.9, c256_attn_wave_bo:26.2, ffn_bytein_fb_pdl:62.1, c256_attn_wave_bo:24.8
## 1080 corrected: f=42.6us/dispatch (min exec 42.9us, trivial sp_init/recover ~43); plain span 9736us vs his 7772us, diff +1964us
| fam | ours in-chain (step - f) | disp | his | ours-his |
|---|---:|---:|---:|---:|
| C32 | 3080.7 | 11 | 2682.3 | +398.4 |
| C64 | 1121.6 | 8 | 938.0 | +183.6 |
| C128 | 1271.2 | 12 | 948.7 | +322.5 |
| C256 | 1246.9 | 11 | 1174.0 | +72.8 |
| C512 | 1506.2 | 55 | 1014.7 | +491.5 |
| ViT | 1443.0 | 50 | 996.0 | +446.9 |
| other | 66.4 | 2 | 18.4 | +47.9 |
SP corrected: sp_init-16 5.8; sp_run256-16 453.4; sp_recover-16 6.1; sp_init-49 7.5; sp_run256-49 434.6; sp_recover-49 6.9
SWIN_RUN=0 C256 dispatches (step - f): c256_wave2_bo_w16:87.6, c256_wave2_bi_bo_w16:89.1, c256_wave2_bi_bo_w16:87.4, c256_wave2_bi_bo_w16:87.3, c256_wave2_bi_bo_w16:86.4, c256_wave2_bi_bo_w16:89.4, c256_wave2_bi_bo_w16:86.7, c256_wave2_bi_w16:101.1, mh_pool_project_group_c256:22.4, c256_wave2_bi_bo_w16:83.1, c256_wave2_bi_bo_w16:90.5, c256_wave2_bi_bo_w16:85.5, c256_wave2_bi_bo_w16:88.8, c256_wave2_bi_bo_w16:84.4, c256_wave2_bi_bo_w16:91.1, c256_wave2_bi_bo_w16:86.0, c256_wave2_bi_bo_w16:88.9
