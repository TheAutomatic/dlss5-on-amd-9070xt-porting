// Build compute pipelines on the (drm-shim) RADV device and dump ACO statistics + disassembly through
// VK_KHR_pipeline_executable_properties. usage: dump_isa <out_dir> <shader.spv> [...]; bindings come from <shader>.bind.
#include <vulkan/vulkan.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#define CK(x) do { VkResult r_ = (x); if (r_ != VK_SUCCESS) { fprintf(stderr, "%s failed: %d\n", #x, r_); exit(1); } } while (0)

static std::vector<uint32_t> ReadWords(const std::string& p) {
    std::ifstream f(p, std::ios::binary);
    std::vector<char> b((std::istreambuf_iterator<char>(f)), {});
    std::vector<uint32_t> w(b.size() / 4);
    memcpy(w.data(), b.data(), w.size() * 4);
    return w;
}

int main(int argc, char** argv) {
    if (argc < 3) { fprintf(stderr, "usage: dump_isa <out_dir> <spv>...\n"); return 2; }
    VkApplicationInfo app{VK_STRUCTURE_TYPE_APPLICATION_INFO};
    app.apiVersion = VK_API_VERSION_1_3;
    VkInstanceCreateInfo ici{VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO};
    ici.pApplicationInfo = &app;
    VkInstance inst; CK(vkCreateInstance(&ici, nullptr, &inst));
    uint32_t n = 1; VkPhysicalDevice phys; vkEnumeratePhysicalDevices(inst, &n, &phys);
    if (!n) { fprintf(stderr, "no device\n"); return 1; }
    VkPhysicalDeviceProperties pp; vkGetPhysicalDeviceProperties(phys, &pp);
    fprintf(stderr, "device: %s\n", pp.deviceName);

    // Same features as DLSSNR-AMD's host (linux/src/core/nrvk.hpp) plus executable properties.
    VkPhysicalDevicePipelineExecutablePropertiesFeaturesKHR exe{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PIPELINE_EXECUTABLE_PROPERTIES_FEATURES_KHR};
    exe.pipelineExecutableInfo = VK_TRUE;
    VkPhysicalDeviceCooperativeMatrixFeaturesKHR coop{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_COOPERATIVE_MATRIX_FEATURES_KHR};
    coop.cooperativeMatrix = VK_TRUE;
    VkPhysicalDeviceShaderFloat8FeaturesEXT fp8{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT8_FEATURES_EXT};
    fp8.shaderFloat8 = VK_TRUE; fp8.shaderFloat8CooperativeMatrix = VK_TRUE;
    VkPhysicalDeviceVulkan11Features f11{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES};
    f11.storageBuffer16BitAccess = VK_TRUE;
    VkPhysicalDeviceVulkan12Features f12{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES};
    f12.storageBuffer8BitAccess = VK_TRUE; f12.shaderFloat16 = VK_TRUE; f12.shaderInt8 = VK_TRUE; f12.vulkanMemoryModel = VK_TRUE;
    VkPhysicalDeviceVulkan13Features f13{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
    f13.subgroupSizeControl = VK_TRUE; f13.synchronization2 = VK_TRUE;
    VkPhysicalDeviceShaderFloatControls2FeaturesKHR fc2{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_FLOAT_CONTROLS_2_FEATURES_KHR};
    fc2.shaderFloatControls2 = VK_TRUE;
    VkPhysicalDeviceShaderMixedFloatDotProductFeaturesVALVE mix{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SHADER_MIXED_FLOAT_DOT_PRODUCT_FEATURES_VALVE};
    mix.shaderMixedFloatDotProductFloat16AccFloat32 = VK_TRUE;
    exe.pNext = &coop; coop.pNext = &fp8; fp8.pNext = &f11; f11.pNext = &f12; f12.pNext = &f13; f13.pNext = &fc2; fc2.pNext = &mix;
    const char* exts[] = {"VK_KHR_pipeline_executable_properties", "VK_KHR_cooperative_matrix", "VK_EXT_shader_float8",
                          "VK_KHR_shader_float_controls2", "VK_VALVE_shader_mixed_float_dot_product"};
    float prio = 1.f;
    VkDeviceQueueCreateInfo qci{VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO};
    qci.queueCount = 1; qci.pQueuePriorities = &prio;
    VkDeviceCreateInfo dci{VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO};
    dci.pNext = &exe; dci.queueCreateInfoCount = 1; dci.pQueueCreateInfos = &qci;
    dci.enabledExtensionCount = sizeof exts / sizeof *exts; dci.ppEnabledExtensionNames = exts;
    VkDevice dev; CK(vkCreateDevice(phys, &dci, nullptr, &dev));
    auto getExe = (PFN_vkGetPipelineExecutablePropertiesKHR)vkGetDeviceProcAddr(dev, "vkGetPipelineExecutablePropertiesKHR");
    auto getStats = (PFN_vkGetPipelineExecutableStatisticsKHR)vkGetDeviceProcAddr(dev, "vkGetPipelineExecutableStatisticsKHR");
    auto getIr = (PFN_vkGetPipelineExecutableInternalRepresentationsKHR)vkGetDeviceProcAddr(dev, "vkGetPipelineExecutableInternalRepresentationsKHR");

    const std::string outDir = argv[1];
    int failures = 0;
    for (int a = 2; a < argc; ++a) {
        std::string spv = argv[a], base = spv.substr(0, spv.size() - 4);
        std::string name = base.substr(base.find_last_of('/') + 1);
        std::vector<VkDescriptorSetLayoutBinding> binds;
        std::ifstream bf(base + ".bind");
        for (std::string line; std::getline(bf, line);) {
            std::istringstream is(line); uint32_t b; std::string t; is >> b >> t;
            VkDescriptorType dt = t == "buf" ? VK_DESCRIPTOR_TYPE_STORAGE_BUFFER
                                : t == "cis" ? VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER
                                : t == "ubo" ? VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER
                                             : VK_DESCRIPTOR_TYPE_STORAGE_IMAGE;
            binds.push_back({b, dt, 1, VK_SHADER_STAGE_COMPUTE_BIT, nullptr});
        }
        VkDescriptorSetLayoutCreateInfo dl{VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO};
        dl.bindingCount = uint32_t(binds.size()); dl.pBindings = binds.data();
        VkDescriptorSetLayout dsl; CK(vkCreateDescriptorSetLayout(dev, &dl, nullptr, &dsl));
        VkPushConstantRange pcr{VK_SHADER_STAGE_COMPUTE_BIT, 0, 128};
        VkPipelineLayoutCreateInfo pl{VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO};
        pl.setLayoutCount = 1; pl.pSetLayouts = &dsl; pl.pushConstantRangeCount = 1; pl.pPushConstantRanges = &pcr;
        VkPipelineLayout layout; CK(vkCreatePipelineLayout(dev, &pl, nullptr, &layout));
        auto code = ReadWords(spv);
        VkShaderModuleCreateInfo smi{VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO};
        smi.codeSize = code.size() * 4; smi.pCode = code.data();
        VkShaderModule mod; CK(vkCreateShaderModule(dev, &smi, nullptr, &mod));
        VkPipelineShaderStageRequiredSubgroupSizeCreateInfo req{VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_REQUIRED_SUBGROUP_SIZE_CREATE_INFO};
        req.requiredSubgroupSize = 32;
        VkComputePipelineCreateInfo cpi{VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO};
        cpi.flags = VK_PIPELINE_CREATE_CAPTURE_STATISTICS_BIT_KHR | VK_PIPELINE_CREATE_CAPTURE_INTERNAL_REPRESENTATIONS_BIT_KHR;
        cpi.stage = {VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO};
        cpi.stage.pNext = &req; cpi.stage.stage = VK_SHADER_STAGE_COMPUTE_BIT; cpi.stage.module = mod; cpi.stage.pName = "main";
        cpi.layout = layout;
        VkPipeline pipe;
        VkResult r = vkCreateComputePipelines(dev, VK_NULL_HANDLE, 1, &cpi, nullptr, &pipe);
        if (r != VK_SUCCESS) { fprintf(stderr, "%s: pipeline failed %d\n", name.c_str(), r); ++failures; continue; }
        VkPipelineInfoKHR pinfo{VK_STRUCTURE_TYPE_PIPELINE_INFO_KHR}; pinfo.pipeline = pipe;
        uint32_t ne = 0; getExe(dev, &pinfo, &ne, nullptr);
        std::vector<VkPipelineExecutablePropertiesKHR> props(ne, {VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_PROPERTIES_KHR});
        getExe(dev, &pinfo, &ne, props.data());
        std::ofstream st(outDir + "/" + name + ".stats"), isa(outDir + "/" + name + ".s");
        for (uint32_t e = 0; e < ne; ++e) {
            VkPipelineExecutableInfoKHR ei{VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_INFO_KHR}; ei.pipeline = pipe; ei.executableIndex = e;
            uint32_t ns = 0; getStats(dev, &ei, &ns, nullptr);
            std::vector<VkPipelineExecutableStatisticKHR> s(ns, {VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_STATISTIC_KHR});
            getStats(dev, &ei, &ns, s.data());
            for (auto& x : s) {
                st << x.name << " = ";
                switch (x.format) {
                case VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_BOOL32_KHR: st << x.value.b32; break;
                case VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_INT64_KHR: st << x.value.i64; break;
                case VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_UINT64_KHR: st << x.value.u64; break;
                case VK_PIPELINE_EXECUTABLE_STATISTIC_FORMAT_FLOAT64_KHR: st << x.value.f64; break;
                default: break;
                }
                st << "\n";
            }
            uint32_t nir = 0; getIr(dev, &ei, &nir, nullptr);
            std::vector<VkPipelineExecutableInternalRepresentationKHR> ir(nir, {VK_STRUCTURE_TYPE_PIPELINE_EXECUTABLE_INTERNAL_REPRESENTATION_KHR});
            getIr(dev, &ei, &nir, ir.data());
            std::vector<std::vector<char>> buf(nir);
            for (uint32_t i = 0; i < nir; ++i) { buf[i].resize(ir[i].dataSize); ir[i].pData = buf[i].data(); }
            getIr(dev, &ei, &nir, ir.data());
            for (uint32_t i = 0; i < nir; ++i)
                if (strstr(ir[i].name, "Assembly")) isa << buf[i].data();
        }
        fprintf(stderr, "%s ok\n", name.c_str());
        vkDestroyPipeline(dev, pipe, nullptr); vkDestroyShaderModule(dev, mod, nullptr);
        vkDestroyPipelineLayout(dev, layout, nullptr); vkDestroyDescriptorSetLayout(dev, dsl, nullptr);
    }
    vkDestroyDevice(dev, nullptr); vkDestroyInstance(inst, nullptr);
    return failures ? 1 : 0;
}
