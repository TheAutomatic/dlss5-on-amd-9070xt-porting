#include "nr_native_plan.hpp"
#include <cstdio>
#include <cstdlib>
int main(int c,char**v){auto p=nr::make_native_plan(atoi(v[1]),atoi(v[2]));fprintf(stderr,"work %ux%u red %u %u model %s\n",p.width,p.height,p.reductions_x,p.reductions_y,p.model.c_str());fputs(p.text.c_str(),stdout);}
