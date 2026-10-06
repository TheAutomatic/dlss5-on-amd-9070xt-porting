// CPU static typed-pair probe only, not a second production candidate.
typedef _Float16 trial_half2 __attribute__((ext_vector_type(2)));
typedef float trial_float2 __attribute__((ext_vector_type(2)));
typedef unsigned short trial_code2 __attribute__((ext_vector_type(2)));
DEV trial_code2 vit_trial_score_pair(trial_float2 score){
 trial_half2 s=__builtin_convertvector(score,trial_half2);
 trial_half2 y=__builtin_elementwise_fma(s,trial_half2{(_Float16).08953857421875f,(_Float16).08953857421875f},trial_half2{(_Float16)1.708984375f,(_Float16)1.708984375f});
 y=__builtin_elementwise_max(y,trial_half2{(_Float16)1.439453125f,(_Float16)1.439453125f});
 y=__builtin_elementwise_min(y,trial_half2{(_Float16)1.9775390625f,(_Float16)1.9775390625f});
 unsigned u=(__builtin_bit_cast(unsigned,y)&0x03ff03ffu)<<4;
 return __builtin_bit_cast(trial_code2,u);
}
