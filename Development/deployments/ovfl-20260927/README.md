# ovfl-20260927 — Stellar Blade

Installed 2026-09-27 13:17: c64-wave2 of both architectures replaced by set P (production recipe M + `W2_PACK8 4`, segmented
MODE.FP16_OVFL, `results/ovfl-census-20260927`; gfx1201 fc2d2a59, gfx1200 464c99b9). All other modules stay set M
(`deployments/fmed3-20260927`), add-on b08cd2e3 and flags unchanged. Previous c64-wave2 (set M: gfx1201 63000f26) backed up to
`D:\DLSSNR-Lab\ovfl-20260927\backups\stellar-20260927-131752`; restore with `install.ps1 -Restore <that dir>` (game closed).

Expected: network ≈ −0.05 ms (900) / −0.09 ms (1080) vs set M — below the fps reading resolution. Standard test: 1080P window,
FSR native AA, EXACT (F8), main menu; set M reference 50–51 / simple scene 54–55. What to look for is rather that nothing
breaks: no black blocks or flicker in motion.
