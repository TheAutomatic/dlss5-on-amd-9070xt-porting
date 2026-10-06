// B2 keeps B's score half RNE and half FMA. Clamp returns half operands directly;
// no half-FMA-result ->f32 ->clamp ->half round trip. max/min NUM matches B's fmax/fmin.
DEV unsigned short vit_trial_score_half(float score){
 _Float16 s=(_Float16)score;
 _Float16 y=__builtin_fmaf16(s,(_Float16)0.08953857421875f,(_Float16)1.708984375f);
 y=__builtin_elementwise_max(y,(_Float16)1.439453125f);
 y=__builtin_elementwise_min(y,(_Float16)1.9775390625f);
 unsigned short u=__builtin_bit_cast(unsigned short,y);
 return static_cast<unsigned short>((u&0x3ffu)<<4);
}
