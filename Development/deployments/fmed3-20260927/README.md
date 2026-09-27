# fmed3-20260927 — Stellar Blade

Installed 2026-09-27 12:31: both architectures' 29 HIP modules replaced by the next production recipe (set M = pack8 + SAT3 +
FMED3, `results/fmed3-ovfl-20260927`; gfx1201 c32-wave1 5e9b3593, c64-wave2 63000f26, c512-m32-mh 0ae5641b). Add-on
(b08cd2e3, 0.33) and flags unchanged. Previous sets (0.33 pack8 ALL) backed up to
`D:\DLSSNR-Lab\fmed3-20260927\backups\stellar-20260927-123103`; restore with `install.ps1 -Restore <that dir>` (game closed).

Expected: network 900 ≈9.7 ms / 1080 ≈13.45 ms offline (0.33 ≈9.8 / 13.64), i.e. a fraction of a frame in game. Standard test:
1080P window, FSR native AA, main menu, F8 to EXACT (status line shows it); 0.33 reference main menu 49–50, common scenes 53–54.
