## 900  frames=240  dispatch=153 (his 123)  sum(step)=13158us  span: profiled 13.7265 / plain 6.865 ms (swin-off plain None); his total 5909us
| fam | ours step (in-chain, gap incl.) | ours exec | disp | his | ours-his |
|---|---:|---:|---:|---:|---:|
| C32 | 2641.6 | 2612.7 | 11 | 1971.6 | +670.1 |
| C64 | 1112.1 | 1095.9 | 8 | 694.0 | +418.0 |
| C128 | 1349.4 | 1328.1 | 12 | 704.5 | +644.9 |
| C256 | 1583.0 | 1537.9 | 15 | 843.8 | +739.3 |
| C512 | 3390.0 | 3258.5 | 55 | 844.0 | +2545.9 |
| ViT | 2934.8 | 2804.6 | 50 | 835.9 | +2098.9 |
| other | 147.6 | 142.9 | 2 | 15.5 | +132.1 |
SP (production): sp_init exec 43.2 step 49.0; sp_run256_w16 exec 346.3 step 348.3; sp_recover256_w16 exec 43.4 step 48.7; sp_init exec 43.2 step 49.0; sp_run256_w16 exec 342.9 step 344.9; sp_recover256_w16 exec 43.3 step 48.6
## 1088  frames=240  dispatch=149 (his 123)  sum(step)=15276us  span: profiled 15.892 / plain 9.1265 ms (swin-off plain None); his total 7772us
| fam | ours step (in-chain, gap incl.) | ours exec | disp | his | ours-his |
|---|---:|---:|---:|---:|---:|
| C32 | 3386.9 | 3359.4 | 11 | 2682.3 | +704.7 |
| C64 | 1348.3 | 1333.5 | 8 | 938.0 | +410.4 |
| C128 | 1617.3 | 1597.0 | 12 | 948.7 | +668.7 |
| C256 | 1642.1 | 1602.7 | 11 | 1174.0 | +468.0 |
| C512 | 3684.4 | 3536.4 | 55 | 1014.7 | +2669.7 |
| ViT | 3437.6 | 3301.0 | 50 | 996.0 | +2441.5 |
| other | 158.9 | 154.6 | 2 | 18.4 | +140.4 |
SP (production): sp_init exec 43.2 step 48.8; sp_run256_w16 exec 475.1 step 476.9; sp_recover256_w16 exec 43.4 step 49.0; sp_init exec 44.3 step 50.1; sp_run256_w16 exec 452.7 step 454.5; sp_recover256_w16 exec 43.6 step 49.1
## 1152  frames=240  dispatch=149 (his 123)  sum(step)=15641us  span: profiled 16.3345 / plain 9.5715 ms (swin-off plain None); his total 7772us
| fam | ours step (in-chain, gap incl.) | ours exec | disp | his | ours-his |
|---|---:|---:|---:|---:|---:|
| C32 | 3556.9 | 3529.3 | 11 | 2682.3 | +874.7 |
| C64 | 1400.9 | 1386.1 | 8 | 938.0 | +462.9 |
| C128 | 1673.4 | 1653.0 | 12 | 948.7 | +724.7 |
| C256 | 1711.4 | 1672.2 | 11 | 1174.0 | +537.4 |
| C512 | 3758.8 | 3605.9 | 55 | 1014.7 | +2744.1 |
| ViT | 3387.4 | 3250.2 | 50 | 996.0 | +2391.4 |
| other | 151.9 | 147.6 | 2 | 18.4 | +133.4 |
SP (production): sp_init exec 42.7 step 48.3; sp_run256_w16 exec 498.5 step 500.6; sp_recover256_w16 exec 43.2 step 48.4; sp_init exec 44.4 step 49.9; sp_run256_w16 exec 478.9 step 480.9; sp_recover256_w16 exec 44.4 step 49.5
## 900 corrected: f=41.1us/dispatch (min exec 38.8us, trivial sp_init/recover ~43); plain span 6865us vs his 5909us, diff +956us
| fam | ours in-chain (step - f) | disp | his | ours-his |
|---|---:|---:|---:|---:|
| C32 | 2189.1 | 11 | 1971.6 | +217.6 |
| C64 | 783.0 | 8 | 694.0 | +88.9 |
| C128 | 855.8 | 12 | 704.5 | +151.3 |
| C256 | 966.0 | 15 | 843.8 | +122.3 |
| C512 | 1127.6 | 55 | 844.0 | +283.6 |
| ViT | 878.1 | 50 | 835.9 | +42.2 |
| other | 65.4 | 2 | 15.5 | +49.9 |
SP corrected: sp_init 7.8; sp_run256_w16 307.2; sp_recover256_w16 7.5; sp_init 7.8; sp_run256_w16 303.7; sp_recover256_w16 7.4
## 1088 corrected: f=41.3us/dispatch (min exec 43.1us, trivial sp_init/recover ~43); plain span 9126us vs his 7772us, diff +1354us
| fam | ours in-chain (step - f) | disp | his | ours-his |
|---|---:|---:|---:|---:|
| C32 | 2933.0 | 11 | 2682.3 | +250.7 |
| C64 | 1018.1 | 8 | 938.0 | +80.2 |
| C128 | 1122.1 | 12 | 948.7 | +173.5 |
| C256 | 1188.1 | 11 | 1174.0 | +14.1 |
| C512 | 1414.6 | 55 | 1014.7 | +399.9 |
| ViT | 1374.2 | 50 | 996.0 | +378.1 |
| other | 76.3 | 2 | 18.4 | +57.9 |
SP corrected: sp_init 7.5; sp_run256_w16 435.7; sp_recover256_w16 7.7; sp_init 8.8; sp_run256_w16 413.3; sp_recover256_w16 7.8
## 1152 corrected: f=40.7us/dispatch (min exec 42.7us, trivial sp_init/recover ~43); plain span 9572us vs his 7772us, diff +1799us
| fam | ours in-chain (step - f) | disp | his | ours-his |
|---|---:|---:|---:|---:|
| C32 | 3108.9 | 11 | 2682.3 | +426.6 |
| C64 | 1075.0 | 8 | 938.0 | +137.1 |
| C128 | 1184.6 | 12 | 948.7 | +235.9 |
| C256 | 1263.4 | 11 | 1174.0 | +89.3 |
| C512 | 1518.5 | 55 | 1014.7 | +503.7 |
| ViT | 1350.8 | 50 | 996.0 | +354.7 |
| other | 70.4 | 2 | 18.4 | +51.9 |
SP corrected: sp_init 7.5; sp_run256_w16 459.9; sp_recover256_w16 7.7; sp_init 9.2; sp_run256_w16 440.2; sp_recover256_w16 8.8
