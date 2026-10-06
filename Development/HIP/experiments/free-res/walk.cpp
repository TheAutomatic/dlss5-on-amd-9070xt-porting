#include "nr_native_plan.hpp"
#include <cstdio>
#include <sstream>
int main(int c,char**v){unsigned s[][2]={{1280,720},{1280,768},{1600,900},{1706,960},{1707,961},{1920,1080},{2560,1440},{1366,768},{3440,1440},{3840,2160},{1920,800},{320,240},{640,360},{5120,1440},{2560,1080}};
for(auto&p:s){auto r=nr::make_native_plan(p[0],p[1]);
 // find vit grid: rows for block 31..38 (tokens)
 std::istringstream in(r.text);std::string line;unsigned vt=0;std::string vline;while(std::getline(in,line)){std::istringstream w(line);int b;w>>b;if(b==31&&vline.empty())vline=line;}
 printf("%ux%u -> work %ux%u red %u/%u | vit row: %.60s\n",p[0],p[1],r.width,r.height,r.reductions_x,r.reductions_y,vline.c_str());}}
