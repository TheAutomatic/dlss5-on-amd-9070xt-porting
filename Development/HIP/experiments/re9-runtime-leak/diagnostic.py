# Generate a measurement-only runtime source; compile with the usual include/src/HIP paths.
from pathlib import Path
root=Path(__file__).resolve().parents[4]
s=(root/'src/LmxxfNrRuntime.cpp').read_text()
s=s.replace('    void TeardownCodecChain()', '''    void TraceMemory(const char* stage) {
        IDXGIFactory4* f=nullptr; IDXGIAdapter3* a=nullptr;
        if(SUCCEEDED(CreateDXGIFactory1(IID_PPV_ARGS(&f)))) {
            if(SUCCEEDED(f->EnumAdapterByLuid(device->GetAdapterLuid(), IID_PPV_ARGS(&a)))) {
                DXGI_QUERY_VIDEO_MEMORY_INFO vm{};a->QueryVideoMemoryInfo(0,DXGI_MEMORY_SEGMENT_GROUP_LOCAL,&vm);
                std::printf("MEM stage=%s recreate=%u vram=%.3f tracked=%zu\\n", stage,codecRecreates, vm.CurrentUsage/1048576.,NativeTrackedResources().size());
                a->Release();
            } f->Release();
        }
    }
    void TeardownCodecChain()''')
s=s.replace('        delete bridge;\n        bridge = nullptr;', '        TraceMemory("before-bridge-delete");\n        delete bridge;\n        TraceMemory("after-bridge-delete");\n        bridge = nullptr;')
s=s.replace('        colorFormat = DXGI_FORMAT_UNKNOWN;', '        colorFormat = DXGI_FORMAT_UNKNOWN;\n        TraceMemory("after-codec-delete");')
s=s.replace('        session->LogGeometry();', '        session->LogGeometry();\n        session->TraceMemory("prepared");')
out=Path('/tmp/yami-runtime-20260927/diag.cpp');out.parent.mkdir(parents=True,exist_ok=True);out.write_text(s)
print(out)
