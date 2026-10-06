#include "runtime_strength_config.h"
#include <cassert>
#include <initializer_list>
#include <cstdio>
int main(){using namespace runtime_strength;for(auto s:{L"",L"auto",L" auto "})assert(Parse(s).state==State::Inherit);assert(Parse(nullptr).state==State::Inherit);for(auto s:{L"0,1",L"1,0",L"0.7,0.3",L" .7 , .3 "})assert(Parse(s).state==State::Numeric);for(auto s:{L".7",L"nan,.3",L"inf,.3",L"1.1,.3",L"-.1,.3",L".7,.3junk",L".7,.3,.4"})assert(Parse(s).state==State::Invalid);float a=.4f,b=.6f;Override(Parse(L"auto"),a,b);assert(a==.4f&&b==.6f);Override(Parse(L".7,.3"),a,b);assert(a==.7f&&b==.3f);Override(Parse(L"nan,.3"),a,b);assert(a==.7f&&b==.3f);puts("PARSER priority finite bounds inheritance PASS");}
