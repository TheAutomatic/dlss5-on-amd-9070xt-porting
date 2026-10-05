// Locked old mochi score math only. QK/AV remain f32 accumulation; denominator unchanged.
DEV unsigned short vit_trial_score_half(float score){
 _Float16 s=(_Float16)score;
 _Float16 y=__builtin_fmaf16(s,(_Float16)0.08953857421875f,(_Float16)1.708984375f);
 float v=__builtin_fminf(__builtin_fmaxf(float(y),1.439453125f),1.9775390625f);
 union{_Float16 h;unsigned short u;}bits;bits.h=(_Float16)v;
 return static_cast<unsigned short>((bits.u&0x3ffu)<<4);
}
