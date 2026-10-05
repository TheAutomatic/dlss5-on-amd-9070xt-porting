// Experimental MP1 software sampler. Port of native_temporal_sample.hlsl;
// reference is controlled original-CUBIN post, not claimed real API format parity.
typedef unsigned int uint;typedef unsigned long long u64;
#define DEV __attribute__((device,always_inline)) inline
#define KERNEL extern "C" __attribute__((global))
struct V2{float x,y;};struct V3{float x,y,z;};struct V4{float x,y,z,w;};
DEV float clampv(float x,float a,float b){return __builtin_fminf(__builtin_fmaxf(x,a),b);}
DEV float native_rcp(float x,const uint*table){
 if(table&&x>0&&__builtin_isfinite(x)){uint b=__builtin_bit_cast(uint,x);int shift=127-int((b>>23)&255);return __builtin_bit_cast(float,uint(int(table[b&0x7fffff])+shift*8388608));}return 1.f/x;
}
DEV float texround(double x){float r=float(x);if(x>0&&double(r)<x){float n=__builtin_bit_cast(float,__builtin_bit_cast(uint,r)+1);if(x==(double(r)+double(n))*.5)return n;}return r;}
DEV V3 fetch(const V4*history,float x,float y,uint w,uint h){
 float ix=1.f/float(w),iy=1.f/float(h);
 float nx=x*ix,ny=y*iy;
 float px=float(__builtin_fma(double(nx),double(w),0.)),py=float(__builtin_fma(double(ny),double(h),0.));
 float ux=px*ix,uy=py*iy;
 uint fx=uint(clampv(__builtin_floorf(ux*2097152.f),0.f,2097152.f));
 uint fy=uint(clampv(__builtin_floorf(uy*2097152.f),0.f,2097152.f));
 uint sx=(fx>>13)*w+(((fx&8191)*w+4096)>>13),sy=(fy>>13)*h+(((fy&8191)*h+4096)>>13);
 float qx=clampv(float((sx<128?128:sx)-128)/256.f,0.f,float(w-1)),qy=clampv(float((sy<128?128:sy)-128)/256.f,0.f,float(h-1));
 uint ax=uint(__builtin_floorf(qx)),ay=uint(__builtin_floorf(qy)),bx=ax+1<w?ax+1:ax,by=ay+1<h?ay+1:ay;
 float tx=__builtin_floorf((qx-float(ax))*256.f+.5f)/256.f,ty=__builtin_floorf((qy-float(ay))*256.f+.5f)/256.f;
 float corner=__builtin_floorf(((1.f-tx)*(1.f-ty))*256.f+.5f)/256.f;
 float adjx=(1.f-ty)-corner,adjy=(1.f-tx)-corner,opposite=tx-adjx;
 V4 a=history[ay*w+ax],b=history[ay*w+bx],c=history[by*w+ax],d=history[by*w+bx];
 #define SUM(CH) texround(((double(a.CH)*double(corner)+double(b.CH)*double(adjx))+double(c.CH)*double(adjy))+double(d.CH)*double(opposite))
 V3 result{SUM(x),SUM(y),SUM(z)};
 #undef SUM
 return result;
}
DEV void axis(float uv,uint extent,const uint*table,float*pos,float*weight){
 float center=__builtin_floorf(__builtin_fmaf(uv,float(extent),-.5f))+.5f;
 float t=clampv(float(__builtin_fma(double(uv),double(extent),-double(center))),0.f,1.f);
 float t2=t*t,t3=t2*t,sum=t+t3,left=__builtin_fmaf(sum,-.5f,t2),scaled=t2*2.5f;
 float product=t3*1.5f,error=(t3-product)+t3*.5f,s=product-scaled,vb=s-product;
 float se=(product-(s-vb))+(-scaled-vb),inner=s+(se+error);inner=inner+1.f;
 float right=(t3-t2)*.5f,other=1.f-left;other=other-inner;other=other-right;
 float middle=inner+other,p=float(__builtin_fma(double(other),double(native_rcp(middle,table)),double(center)));
 pos[0]=clampv(center-1.f,.5f,float(extent)-.5f);pos[1]=clampv(p,.5f,float(extent)-.5f);pos[2]=clampv(center+2.f,.5f,float(extent)-.5f);
 weight[0]=left;weight[1]=middle;weight[2]=right;
}
KERNEL void temporal_warp(const V4*history,const V2*motion,V4*prefix,V4*raw,const uint*rcptable,uint width,uint valid_h,uint proc_h){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i>=width*proc_h)return;
 uint x=i%width,y=i/width;uint vy=y<valid_h?y:2*valid_h-y-2;
 V2 mv=motion[vy*width+x];float ux=(float(x)+.5f)*(1.f/float(width)),uy=(float(vy)+.5f)*(1.f/float(valid_h));
 ux=float(__builtin_fma(double(mv.x),double(1.f/float(width)),double(ux)));
 uy=float(__builtin_fma(double(mv.y),double(1.f/float(valid_h)),double(uy)));
 float px[3],py[3],wx[3],wy[3];axis(ux,width,rcptable,px,wx);axis(uy,valid_h,rcptable,py,wy);
 float weights[5]={wx[1]*wy[0],wx[0]*wy[1],wx[1]*wy[1],wx[1]*wy[2],wx[2]*wy[1]};
 V3 values[5]={fetch(history,px[1],py[0],width,valid_h),fetch(history,px[0],py[1],width,valid_h),fetch(history,px[1],py[1],width,valid_h),fetch(history,px[1],py[2],width,valid_h),fetch(history,px[2],py[1],width,valid_h)};
 V3 result{values[0].x*weights[0],values[0].y*weights[0],values[0].z*weights[0]};
 for(uint j=1;j<5;j++){result.x=float(__builtin_fma(double(values[j].x),double(weights[j]),double(result.x)));result.y=float(__builtin_fma(double(values[j].y),double(weights[j]),double(result.y)));result.z=float(__builtin_fma(double(values[j].z),double(weights[j]),double(result.z)));}
 float total=weights[1]+weights[0];total=total+weights[2];total=total+weights[3];total=total+weights[4];float reciprocal=native_rcp(total,rcptable);
 // Prefix consumes normalized history. Post keeps raw sum+reciprocal for its original fused subtraction.
 prefix[i]={result.x*reciprocal,result.y*reciprocal,result.z*reciprocal,1.f};raw[i]={result.x,result.y,result.z,reciprocal};
}
KERNEL void temporal_store(const float*rgb,V4*history,uint width,uint valid_h){
 uint i=__builtin_amdgcn_workgroup_id_x()*256+__builtin_amdgcn_workitem_id_x();if(i>=width*valid_h)return;
 // Explicit experimental history policy: f16 RNE texels in an f32 buffer, not a claim about private API descriptor.
 history[i]={float((_Float16)rgb[i*3]),float((_Float16)rgb[i*3+1]),float((_Float16)rgb[i*3+2]),1.f};
}
