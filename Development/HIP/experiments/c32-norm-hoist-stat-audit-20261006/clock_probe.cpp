#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <chrono>
#include <cstdio>
#include <numeric>
#include <limits>
int main(){LARGE_INTEGER f,p,q;QueryPerformanceFrequency(&f);QueryPerformanceCounter(&p);long long qmin=LLONG_MAX,qgcd=0,nmin=LLONG_MAX,ngcd=0;unsigned qzeros=0,nzeros=0,nnegative=0;auto prev=std::chrono::steady_clock::now();for(int i=0;i<10000;i++){QueryPerformanceCounter(&q);auto d=q.QuadPart-p.QuadPart;if(d>0){if(d<qmin)qmin=d;qgcd=std::gcd(qgcd,d);}else if(!d)qzeros++;p=q;auto now=std::chrono::steady_clock::now();long long ns=std::chrono::duration_cast<std::chrono::nanoseconds>(now-prev).count();if(ns>0){if(ns<nmin)nmin=ns;ngcd=std::gcd(ngcd,ns);}else if(!ns)nzeros++;else nnegative++;prev=now;}printf("{\"QPF_hz\":%lld,\"QPC_tick_ns\":%.9g,\"QPC_min_positive_ticks\":%lld,\"QPC_diff_gcd_ticks\":%lld,\"QPC_zero_differences\":%u,\"steady_declared_period_num\":%lld,\"steady_declared_period_den\":%lld,\"steady_min_positive_ns\":%lld,\"steady_diff_gcd_ns\":%lld,\"steady_zero_differences\":%u,\"steady_negative_differences\":%u,\"samples\":10000}\n",f.QuadPart,1e9/double(f.QuadPart),qmin,qgcd,qzeros,(long long)std::chrono::steady_clock::period::num,(long long)std::chrono::steady_clock::period::den,nmin,ngcd,nzeros,nnegative);}
