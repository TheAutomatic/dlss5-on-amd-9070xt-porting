# ViT960 contraction shared-weight tile — static rejection

A single candidate preserves each output's skip multiplication/FAST_H, four independent K1024 partials, ascending K16 WMMA order, four partial additions and final production F-byte output. Two waves each own16 tokens and64 columns; they share a K512×64 FP8 weight segment in32KiB LDS. This differs from the earlier rejected960 attention constant-address experiment and does not lower resolution or alter quantization.

Canonical `vit-stream-fast` COMGR21 recipe, plus experimental `VIT_CONTRACT_T32_W2=1`, compiled for gfx1200 and gfx1201. Both targets report:

| Kernel | VGPR | Spills | Private bytes/thread | LDS bytes | Threads |
|---|---:|---:|---:|---:|---:|
| Existing byte contraction | 208 | 0 | 0 | 4096 | 32 |
| T32×N64 two-wave candidate | 256 | 171 | 688 | 32768 | 64 |

Rejected at the agreed static gate. The new shared-weight scheme introduces heavy spill/scratch traffic and greater LDS pressure; it has no credible performance case in this compiled form. No GPU execution, numeric equality claim, tuple benchmark or whole-network speed claim. This rejects this concrete candidate, not every possible larger contraction tile. No parameter/layout/compiler scan follows.

Production source unchanged. Candidate lives in `Development/HIP/experiments/vit-contract960/candidate.inc`; `prepare.py` appends it to the canonical source and reproduces the compiled source byte for byte. Target module hashes/resource metadata are in `resources.json`; source hash/recipe in `source.json`. No installation/default/release change.
