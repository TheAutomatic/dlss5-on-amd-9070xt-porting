#pragma once
#include "history_state.h"
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
// Explicit controlled-replay records, not captured seed reconstruction.
struct PreparedFrame {unsigned frame{};temporal_experiment::Shape shape;bool reset{},motion_valid{};std::string encoded,coordinates;};
inline std::vector<PreparedFrame> ReadPreparedIndex(const std::string&path){
 std::ifstream f(path);if(!f)throw std::runtime_error("prepared index missing");std::vector<PreparedFrame> rows;std::string line;
 while(std::getline(f,line)){if(line.empty()||line[0]=='#')continue;std::istringstream s(line);std::vector<std::string>v;std::string value;while(std::getline(s,value,'\t')){if(!value.empty()&&value.back()=='\r')value.pop_back();v.push_back(value);}if(v.size()!=8)throw std::runtime_error("prepared index expects8 tab fields");
  PreparedFrame r;r.frame=unsigned(std::stoul(v[0]));r.shape={unsigned(std::stoul(v[1])),unsigned(std::stoul(v[2])),unsigned(std::stoul(v[3]))};r.shape.Validate();if(v[4]!="0"&&v[4]!="1")throw std::runtime_error("prepared reset");if(v[5]!="0"&&v[5]!="1")throw std::runtime_error("prepared motion validity");r.reset=v[4]=="1";r.motion_valid=v[5]=="1";r.encoded=v[6];r.coordinates=v[7];if(!rows.empty()&&r.frame<=rows.back().frame)throw std::runtime_error("prepared frame order");if(!rows.empty()&&r.frame!=rows.back().frame+1&&!r.reset)throw std::runtime_error("prepared gap without reset");if(r.encoded.empty()||(r.motion_valid&&r.coordinates.empty()))throw std::runtime_error("prepared input missing");rows.push_back(r);
 }
 if(rows.size()<2)throw std::runtime_error("prepared index needs2+ frames");return rows;
}
