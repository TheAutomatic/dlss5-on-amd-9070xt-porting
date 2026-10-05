// Original CUBIN replay; independent controlled textures, observed Reset0 packet layout.
#include <cuda.h>
#include <windows.h>
#include <stdexcept>
static decltype(&::cuArray3DCreate) original_cuArray3DCreate;
#undef cuArray3DCreate
#define cuArray3DCreate original_cuArray3DCreate
static decltype(&::cuCtxSetCurrent) original_cuCtxSetCurrent;
#undef cuCtxSetCurrent
#define cuCtxSetCurrent original_cuCtxSetCurrent
static decltype(&::cuCtxSynchronize) original_cuCtxSynchronize;
#undef cuCtxSynchronize
#define cuCtxSynchronize original_cuCtxSynchronize
static decltype(&::cuDeviceGet) original_cuDeviceGet;
#undef cuDeviceGet
#define cuDeviceGet original_cuDeviceGet
static decltype(&::cuDevicePrimaryCtxRetain) original_cuDevicePrimaryCtxRetain;
#undef cuDevicePrimaryCtxRetain
#define cuDevicePrimaryCtxRetain original_cuDevicePrimaryCtxRetain
static decltype(&::cuGetErrorString) original_cuGetErrorString;
#undef cuGetErrorString
#define cuGetErrorString original_cuGetErrorString
static decltype(&::cuInit) original_cuInit;
#undef cuInit
#define cuInit original_cuInit
static decltype(&::cuLaunchKernel) original_cuLaunchKernel;
#undef cuLaunchKernel
#define cuLaunchKernel original_cuLaunchKernel
static decltype(&::cuMemAlloc) original_cuMemAlloc;
#undef cuMemAlloc
#define cuMemAlloc original_cuMemAlloc
static decltype(&::cuMemcpy2D) original_cuMemcpy2D;
#undef cuMemcpy2D
#define cuMemcpy2D original_cuMemcpy2D
static decltype(&::cuMemcpyHtoD) original_cuMemcpyHtoD;
#undef cuMemcpyHtoD
#define cuMemcpyHtoD original_cuMemcpyHtoD
static decltype(&::cuMemsetD8) original_cuMemsetD8;
#undef cuMemsetD8
#define cuMemsetD8 original_cuMemsetD8
static decltype(&::cuModuleGetFunction) original_cuModuleGetFunction;
#undef cuModuleGetFunction
#define cuModuleGetFunction original_cuModuleGetFunction
static decltype(&::cuModuleLoad) original_cuModuleLoad;
#undef cuModuleLoad
#define cuModuleLoad original_cuModuleLoad
static decltype(&::cuSurfObjectCreate) original_cuSurfObjectCreate;
#undef cuSurfObjectCreate
#define cuSurfObjectCreate original_cuSurfObjectCreate
static decltype(&::cuTexObjectCreate) original_cuTexObjectCreate;
#undef cuTexObjectCreate
#define cuTexObjectCreate original_cuTexObjectCreate
static void InitOriginalDriver(){auto d=LoadLibraryA("nvcuda.dll");if(!d)throw std::runtime_error("nvcuda.dll");
original_cuArray3DCreate=reinterpret_cast<decltype(original_cuArray3DCreate)>(GetProcAddress(d,"cuArray3DCreate_v2"));if(!original_cuArray3DCreate)throw std::runtime_error("cuArray3DCreate");
original_cuCtxSetCurrent=reinterpret_cast<decltype(original_cuCtxSetCurrent)>(GetProcAddress(d,"cuCtxSetCurrent"));if(!original_cuCtxSetCurrent)throw std::runtime_error("cuCtxSetCurrent");
original_cuCtxSynchronize=reinterpret_cast<decltype(original_cuCtxSynchronize)>(GetProcAddress(d,"cuCtxSynchronize"));if(!original_cuCtxSynchronize)throw std::runtime_error("cuCtxSynchronize");
original_cuDeviceGet=reinterpret_cast<decltype(original_cuDeviceGet)>(GetProcAddress(d,"cuDeviceGet"));if(!original_cuDeviceGet)throw std::runtime_error("cuDeviceGet");
original_cuDevicePrimaryCtxRetain=reinterpret_cast<decltype(original_cuDevicePrimaryCtxRetain)>(GetProcAddress(d,"cuDevicePrimaryCtxRetain"));if(!original_cuDevicePrimaryCtxRetain)throw std::runtime_error("cuDevicePrimaryCtxRetain");
original_cuGetErrorString=reinterpret_cast<decltype(original_cuGetErrorString)>(GetProcAddress(d,"cuGetErrorString"));if(!original_cuGetErrorString)throw std::runtime_error("cuGetErrorString");
original_cuInit=reinterpret_cast<decltype(original_cuInit)>(GetProcAddress(d,"cuInit"));if(!original_cuInit)throw std::runtime_error("cuInit");
original_cuLaunchKernel=reinterpret_cast<decltype(original_cuLaunchKernel)>(GetProcAddress(d,"cuLaunchKernel"));if(!original_cuLaunchKernel)throw std::runtime_error("cuLaunchKernel");
original_cuMemAlloc=reinterpret_cast<decltype(original_cuMemAlloc)>(GetProcAddress(d,"cuMemAlloc_v2"));if(!original_cuMemAlloc)throw std::runtime_error("cuMemAlloc");
original_cuMemcpy2D=reinterpret_cast<decltype(original_cuMemcpy2D)>(GetProcAddress(d,"cuMemcpy2D_v2"));if(!original_cuMemcpy2D)throw std::runtime_error("cuMemcpy2D");
original_cuMemcpyHtoD=reinterpret_cast<decltype(original_cuMemcpyHtoD)>(GetProcAddress(d,"cuMemcpyHtoD_v2"));if(!original_cuMemcpyHtoD)throw std::runtime_error("cuMemcpyHtoD");
original_cuMemsetD8=reinterpret_cast<decltype(original_cuMemsetD8)>(GetProcAddress(d,"cuMemsetD8_v2"));if(!original_cuMemsetD8)throw std::runtime_error("cuMemsetD8");
original_cuModuleGetFunction=reinterpret_cast<decltype(original_cuModuleGetFunction)>(GetProcAddress(d,"cuModuleGetFunction"));if(!original_cuModuleGetFunction)throw std::runtime_error("cuModuleGetFunction");
original_cuModuleLoad=reinterpret_cast<decltype(original_cuModuleLoad)>(GetProcAddress(d,"cuModuleLoad"));if(!original_cuModuleLoad)throw std::runtime_error("cuModuleLoad");
original_cuSurfObjectCreate=reinterpret_cast<decltype(original_cuSurfObjectCreate)>(GetProcAddress(d,"cuSurfObjectCreate"));if(!original_cuSurfObjectCreate)throw std::runtime_error("cuSurfObjectCreate");
original_cuTexObjectCreate=reinterpret_cast<decltype(original_cuTexObjectCreate)>(GetProcAddress(d,"cuTexObjectCreate"));if(!original_cuTexObjectCreate)throw std::runtime_error("cuTexObjectCreate");
}

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <vector>

static void check(const char *name, CUresult result) {
    if (result != CUDA_SUCCESS) {
        const char *message = nullptr;
        cuGetErrorString(result, &message);
        std::fprintf(stderr, "%s: %d %s\n", name, result,
                     message ? message : "?");
        std::exit(1);
    }
}

static std::vector<unsigned char> read_file(const char *path, size_t bytes) {
    std::vector<unsigned char> result(bytes);
    std::ifstream stream(path, std::ios::binary);
    if (!stream || !stream.read(reinterpret_cast<char *>(result.data()), bytes)) {
        std::fprintf(stderr, "cannot read %zu bytes from %s\n", bytes, path);
        std::exit(2);
    }
    return result;
}

static std::vector<unsigned char> read_native(const char*path,size_t capacity,size_t valid){
    std::ifstream f(path,std::ios::binary|std::ios::ate);
    if(!f)std::exit(2);auto n=f.tellg();
    if(n<=0||size_t(n)>capacity||size_t(n)<valid)std::exit(2);
    std::vector<unsigned char>v(capacity,0);f.seekg(0);if(!f.read((char*)v.data(),n))std::exit(2);
    if(!std::all_of(v.begin()+valid,v.end(),[](unsigned char x){return x==0;}))std::exit(2);
    return v;
}

int main(int argc, char **argv) {
    if (argc < 11 || argc > 15) {
        std::fprintf(stderr,
            "usage: %s cubin symbol main skip weights blend color output "
            "width height [texture-mask=1] [rgb-mode=1] [input-scale=0.03125] "
            "[features|native]\n",
            argv[0]);
        return 2;
    }

    const char *cubin_path = argv[1];
    const char *symbol = argv[2];
    const char *output_path = argv[8];
    const int width = std::atoi(argv[9]);
    const int height = std::atoi(argv[10]);
    const int texture_mask = argc > 11 ? std::atoi(argv[11]) : 1;
    const int rgb_mode = argc > 12 ? std::atoi(argv[12]) : 1;
    const float input_scale = argc > 13 ? std::strtof(argv[13], nullptr)
                                        : 0.03125f;
    const bool feature_mode = argc > 14 && !std::strcmp(argv[14], "features");
    const bool native_mode = argc > 14 && !std::strcmp(argv[14], "native");
    if (argc > 14 && !feature_mode && !native_mode) return 2;
    if(native_mode&&(width<16||height<16||((width>512||height>512)&&!(width==1920&&height==1152))||width%16||height%16))return 2;
    const bool valid1080=std::getenv("DLSS5_POST_TEST_VALID1080")!=nullptr;
    if(valid1080&&(!native_mode||width!=1920||height!=1152))return 2;
    const int texture_height=valid1080?1080:height;
    if (width <= 0 || height <= 0) {
        std::fprintf(stderr, "invalid dimensions %dx%d\n", width, height);
        return 2;
    }

    const size_t activation_bytes = native_mode?size_t(width)*height*32+65536:320*1024*1024;
    auto main_view = native_mode?read_native(argv[3],activation_bytes,size_t(width)*height*8):read_file(argv[3], activation_bytes);
    auto skip_view = native_mode?read_native(argv[4],activation_bytes,size_t(width)*height*32):read_file(argv[4], activation_bytes);
    auto weights = read_file(argv[5], 21808);
    auto blend = read_file(argv[6], 2);
    auto rgba = read_file(argv[7], static_cast<size_t>(width) * texture_height * 16);

    InitOriginalDriver();
    check("cuInit", cuInit(0));
    CUdevice device;
    check("cuDeviceGet", cuDeviceGet(&device, 0));
    CUcontext context;
    check("cuDevicePrimaryCtxRetain", cuDevicePrimaryCtxRetain(&context, device));
    check("cuCtxSetCurrent", cuCtxSetCurrent(context));
    CUmodule module;
    check("cuModuleLoad", cuModuleLoad(&module, cubin_path));
    CUfunction function;
    check("cuModuleGetFunction", cuModuleGetFunction(&function, module, symbol));

    CUdeviceptr main_device, skip_device, weights_device, blend_device;
    check("alloc main", cuMemAlloc(&main_device, main_view.size()));
    check("alloc skip", cuMemAlloc(&skip_device, skip_view.size()));
    check("alloc weights", cuMemAlloc(&weights_device, weights.size()));
    check("alloc blend", cuMemAlloc(&blend_device, 512));
    check("clear blend", cuMemsetD8(blend_device,0,512));
    check("copy main", cuMemcpyHtoD(main_device, main_view.data(), main_view.size()));
    check("copy skip", cuMemcpyHtoD(skip_device, skip_view.data(), skip_view.size()));
    check("copy weights", cuMemcpyHtoD(weights_device, weights.data(), weights.size()));
    check("copy blend", cuMemcpyHtoD(blend_device, blend.data(), blend.size()));

    const bool half_surface=std::getenv("DLSS5_POST_TEST_HALF_SURFACE")!=nullptr;
    if(half_surface&&!native_mode)return 2;
    CUDA_ARRAY3D_DESCRIPTOR output_desc{};
    output_desc.Width = width;
    output_desc.Height = texture_height;
    output_desc.Format = half_surface?CU_AD_FORMAT_HALF:CU_AD_FORMAT_FLOAT;
    output_desc.NumChannels = 4;
    output_desc.Flags = CUDA_ARRAY3D_SURFACE_LDST;
    CUarray output_array;
    check("output array", cuArray3DCreate(&output_array, &output_desc));
    CUDA_RESOURCE_DESC output_resource{};
    output_resource.resType = CU_RESOURCE_TYPE_ARRAY;
    output_resource.res.array.hArray = output_array;
    CUsurfObject output_surface;
    check("output surface", cuSurfObjectCreate(&output_surface, &output_resource));

    CUDA_ARRAY3D_DESCRIPTOR texture_desc{};
    texture_desc.Width = width;
    texture_desc.Height = texture_height;
    texture_desc.Format = CU_AD_FORMAT_FLOAT;
    texture_desc.NumChannels = 4;
    CUarray texture_array;
    check("texture array", cuArray3DCreate(&texture_array, &texture_desc));
    CUDA_MEMCPY2D upload{};
    upload.srcMemoryType = CU_MEMORYTYPE_HOST;
    upload.srcHost = rgba.data();
    upload.srcPitch = width * 16;
    upload.dstMemoryType = CU_MEMORYTYPE_ARRAY;
    upload.dstArray = texture_array;
    upload.WidthInBytes = width * 16;
    upload.Height = texture_height;
    check("texture upload", cuMemcpy2D(&upload));
    CUDA_RESOURCE_DESC texture_resource{};
    texture_resource.resType = CU_RESOURCE_TYPE_ARRAY;
    texture_resource.res.array.hArray = texture_array;
    CUDA_TEXTURE_DESC texture_options{};
    texture_options.addressMode[0] = CU_TR_ADDRESS_MODE_CLAMP;
    texture_options.addressMode[1] = CU_TR_ADDRESS_MODE_CLAMP;
    texture_options.filterMode = CU_TR_FILTER_MODE_LINEAR;
    texture_options.flags = CU_TRSF_NORMALIZED_COORDINATES;
    CUtexObject texture;
    check("texture object", cuTexObjectCreate(
        &texture, &texture_resource, &texture_options, nullptr));

    auto independent_texture=[&](const char*file)->CUtexObject{
      if(!file||!*file)return 0;
      auto values=read_file(file,size_t(width)*texture_height*16);
      CUarray array;check("independent array",cuArray3DCreate(&array,&texture_desc));
      CUDA_MEMCPY2D cp=upload;cp.srcHost=values.data();cp.dstArray=array;check("independent upload",cuMemcpy2D(&cp));
      CUDA_RESOURCE_DESC res{};res.resType=CU_RESOURCE_TYPE_ARRAY;res.res.array.hArray=array;
      CUtexObject obj;check("independent tex",cuTexObjectCreate(&obj,&res,&texture_options,nullptr));return obj;
    };
    const CUtexObject history_texture=independent_texture(std::getenv("DLSS5_POST_HISTORY_RGBA"));
    const CUtexObject motion_texture=independent_texture(std::getenv("DLSS5_POST_MOTION_RGBA"));
    if(bool(history_texture)!=bool(motion_texture)){fprintf(stderr,"history+motion must be paired\n");return 2;}
    alignas(8) unsigned char params[0xb8]{};
    const CUdeviceptr main_pointer = main_device + (native_mode?0:0x2800);
    const CUdeviceptr skip_pointer = skip_device + (native_mode?0:0x2800);
    std::memcpy(params + 0x00, &main_pointer, 8);
    std::memcpy(params + 0x08, &skip_pointer, 8);
    std::memcpy(params + 0x10, &output_surface, 8);
    std::memcpy(params + 0x18, &weights_device, 8);
    std::memcpy(params + 0x20, &height, 4);
    std::memcpy(params + 0x24, &width, 4);
    if(const char*origin_text=std::getenv("DLSS5_POST_TEST_ORIGIN")){
        if(!native_mode||(std::strcmp(origin_text,"0")&&std::strcmp(origin_text,"-4")))return 2;
        const int origin=std::atoi(origin_text);
        std::memcpy(params+0x28,&origin,4);std::memcpy(params+0x2c,&origin,4);
    }
    std::memcpy(params + 0x30, &input_scale, 4);
    std::memcpy(params + 0x34, &rgb_mode, 4);
    if (texture_mask & 1) std::memcpy(params + 0x38, &texture, 8);
    if(texture_mask!=1){fprintf(stderr,"no aliased history/motion allowed; use independent env inputs\n");return 2;}
    if(history_texture){std::memcpy(params+0x58,&history_texture,8);std::memcpy(params+0x60,&motion_texture,8);}
    const unsigned long long texture_transform[3] = {
        0x0ull, 0x4507000045700000ull, 0x39f2b9d639888889ull};
    std::memcpy(params + 0x40, texture_transform, sizeof(texture_transform));
    std::memcpy(params + 0x68, &blend_device, 8);
    if(const char*text=std::getenv("DLSS5_POST_TEST_WORD70")){
        if(!native_mode||(std::strcmp(text,"0")&&std::strcmp(text,"1")))return 2;
        const uint32_t value=uint32_t(text[0]-'0');std::memcpy(params+0x70,&value,4);
    }
    const unsigned long long live_tail[3] = {
        0x3988888900000000ull, 0x00000f0039f2b9d6ull, 0x870ull};
    std::memcpy(params + 0xa0, live_tail, sizeof(live_tail));
    if(native_mode){
        const float transform[]={0,0,float(width),float(texture_height),1.0f/width,1.0f/texture_height};
        std::memcpy(params+0x40,transform,sizeof(transform));
        const float inv_width=1.0f/width,inv_height=1.0f/texture_height;
        std::memcpy(params+0xa4,&inv_width,4);std::memcpy(params+0xa8,&inv_height,4);
        std::memcpy(params+0xac,&width,4);std::memcpy(params+0xb0,&texture_height,4);
    }

    if(history_texture){
      // Layout observed on original second Eval (Reset0), adapted to this controlled full rectangle.
      const unsigned motion_enable=1;std::memcpy(params+0x70,&motion_enable,4);
      const float tf[]={0,0,float(width),float(texture_height),1.f/width,1.f/texture_height};
      std::memcpy(params+0x74,tf,sizeof(tf));std::memcpy(params+0x8c,tf,sizeof(tf));
    }
    void *arguments[] = {params};
    std::vector<float> output(static_cast<size_t>(width) * texture_height * 4);
    std::vector<uint16_t> half_output(half_surface?output.size():0);
    CUDA_MEMCPY2D download{};
    download.srcMemoryType = CU_MEMORYTYPE_ARRAY;
    download.srcArray = output_array;
    download.dstMemoryType = CU_MEMORYTYPE_HOST;
    download.dstHost = half_surface?static_cast<void*>(half_output.data()):static_cast<void*>(output.data());
    download.dstPitch = width * (half_surface?8:16);
    download.WidthInBytes = download.dstPitch;
    download.Height = texture_height;
    const auto launch_and_download = [&]() {
        check("launch", cuLaunchKernel(function, (width + 7) / 8 + 1,
            (height + 7) / 8 + 1, 1, 32, 2, 1, 0, nullptr, arguments, nullptr));
        check("sync", cuCtxSynchronize());
        check("download", cuMemcpy2D(&download));
        if(half_surface)for(size_t i=0;i<output.size();i++){
            unsigned h=half_output[i],e=(h>>10)&31,m=h&1023;
            float value=e==0?std::ldexp(float(m),-24):e==31?(m?NAN:INFINITY):std::ldexp(float(1024+m),int(e)-25);
            output[i]=(h&0x8000)?-value:value;
        }
    };
    if (feature_mode) {
        std::vector<unsigned char> controlled(weights.size(), 0);
        std::copy(weights.begin(), weights.begin() + 10392 * 2,
                  controlled.begin());
        std::vector<float> features(static_cast<size_t>(width) * height * 32);
        std::vector<float> positive(static_cast<size_t>(width) * height);
        constexpr unsigned short positive_half = 0x1400; // FP16 1/1024
        constexpr unsigned short negative_half = 0x9400; // FP16 -1/1024
        constexpr unsigned short zero_half = 0;
        constexpr float probe = 1.0f / 1024.0f;
        for (size_t channel = 0; channel < 32; ++channel) {
            const size_t block = channel < 16 ? 10392 : 10648;
            const size_t local = channel & 15;
            const size_t slot = block + (local / 4) * 8 + local % 4;
            std::memcpy(controlled.data() + slot * 2, &positive_half, 2);
            check("controlled weights", cuMemcpyHtoD(
                weights_device, controlled.data(), controlled.size()));
            launch_and_download();
            for (size_t pixel = 0; pixel < static_cast<size_t>(width) * height;
                 ++pixel)
                positive[pixel] = output[pixel * 4];
            std::memcpy(controlled.data() + slot * 2, &negative_half, 2);
            check("controlled weights", cuMemcpyHtoD(
                weights_device, controlled.data(), controlled.size()));
            launch_and_download();
            for (size_t pixel = 0; pixel < static_cast<size_t>(width) * height;
                 ++pixel) {
                const float source =
                    reinterpret_cast<const float *>(rgba.data())[pixel * 4];
                const float from_positive = (positive[pixel] - source) / probe;
                const float from_negative = (source - output[pixel * 4]) / probe;
                features[pixel * 32 + channel] =
                    std::abs(from_positive) >= std::abs(from_negative)
                    ? from_positive : from_negative;
            }
            std::memcpy(controlled.data() + slot * 2, &zero_half, 2);
        }
        std::ofstream stream(output_path, std::ios::binary);
        stream.write(reinterpret_cast<const char *>(features.data()),
                     features.size() * sizeof(float));
        const auto [low, high] = std::minmax_element(features.begin(), features.end());
        size_t finite = 0;
        for (float value : features) finite += std::isfinite(value);
        std::printf("features=%zu finite=%zu range=%.9g..%.9g output=%s\n",
                    features.size(), finite, *low, *high, output_path);
        return stream ? 0 : 3;
    }
    launch_and_download();
    std::ofstream stream(output_path, std::ios::binary);
    stream.write(reinterpret_cast<const char *>(output.data()),
                 output.size() * sizeof(float));

    size_t finite = 0;
    double chroma = 0.0;
    for (size_t pixel = 0; pixel < output.size(); pixel += 4) {
        finite += std::isfinite(output[pixel]);
        chroma += std::abs(output[pixel] - output[pixel + 1]);
        chroma += std::abs(output[pixel + 1] - output[pixel + 2]);
    }
    std::printf("texture-mask=%d rgb=%d finite=%zu chroma=%.9g "
                "range=%.9g..%.9g output=%s\n",
                texture_mask, rgb_mode, finite, chroma,
                *std::min_element(output.begin(), output.end()),
                *std::max_element(output.begin(), output.end()), output_path);
    return stream ? 0 : 3;
}
