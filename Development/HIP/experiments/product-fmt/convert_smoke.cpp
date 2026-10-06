// product-fmt (2026-09-30): the add-on's colour-format fallback pass (src/native_format_convert.h) on real D3D12.
// usage: convert_smoke.exe <native_format_convert.hlsl>   For each fallback format: a 1920x1080 texture of pseudo-random
// linear RGB in [0,0.9] (CPU-encoded), converted over the 1707x961 render box into RGBA16F, read back, compared with the
// CPU decode of the same bytes. Pass = max |gpu - cpu| within one half ULP (<= 2^-10 relative + 2^-24; D3D lets the f32->f16 UAV store truncate), alpha 1 for X formats.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d12.h>
#include <dxgi1_4.h>
#include <stdexcept>
#include <string>
#include "native_format_convert.h"
#include "fmt_encode.h"
int wmain(int argc, wchar_t **argv)
{
    if (argc < 2) { std::fprintf(stderr, "usage: convert_smoke <hlsl>\n"); return 2; }
    setvbuf(stdout, nullptr, _IONBF, 0);
    IDXGIFactory4 *factory = nullptr; Check(CreateDXGIFactory1(IID_PPV_ARGS(&factory)), "factory");
    IDXGIAdapter1 *adapter = nullptr; ID3D12Device *device = nullptr;
    for (UINT i = 0; factory->EnumAdapters1(i, &adapter) != DXGI_ERROR_NOT_FOUND; ++i)
    { DXGI_ADAPTER_DESC1 d{}; adapter->GetDesc1(&d); if (d.VendorId == 0x1002 && SUCCEEDED(D3D12CreateDevice(adapter, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device)))) break; adapter->Release(); adapter = nullptr; }
    if (!device) Die("AMD device");
    D3D12_COMMAND_QUEUE_DESC qd{}; qd.Type = D3D12_COMMAND_LIST_TYPE_DIRECT; ID3D12CommandQueue *queue = nullptr; Check(device->CreateCommandQueue(&qd, IID_PPV_ARGS(&queue)), "queue");
    ID3D12CommandAllocator *alloc = nullptr; Check(device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&alloc)), "alloc");
    ID3D12GraphicsCommandList *list = nullptr; Check(device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, alloc, nullptr, IID_PPV_ARGS(&list)), "list"); list->Close();
    ID3D12Fence *fence = nullptr; Check(device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence)), "fence"); HANDLE ev = CreateEventW(nullptr, FALSE, FALSE, nullptr); UINT64 fv = 0;
    auto run = [&] { list->Close(); ID3D12CommandList *a[] = {list}; queue->ExecuteCommandLists(1, a); Check(queue->Signal(fence, ++fv), "signal"); Check(fence->SetEventOnCompletion(fv, ev), "evt"); if (WaitForSingleObject(ev, 30000) != WAIT_OBJECT_0) Die("timeout"); Check(device->GetDeviceRemovedReason(), "device removed"); };
    D3D12_HEAP_PROPERTIES def{}, up{}, rb{}; def.Type = D3D12_HEAP_TYPE_DEFAULT; up.Type = D3D12_HEAP_TYPE_UPLOAD; rb.Type = D3D12_HEAP_TYPE_READBACK;
    auto buffer = [&](D3D12_HEAP_PROPERTIES &hp, UINT64 bytes, D3D12_RESOURCE_STATES st) { D3D12_RESOURCE_DESC d{}; d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER; d.Width = bytes; d.Height = 1; d.DepthOrArraySize = d.MipLevels = 1; d.SampleDesc.Count = 1; d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR; ID3D12Resource *r = nullptr; Check(device->CreateCommittedResource(&hp, D3D12_HEAP_FLAG_NONE, &d, st, nullptr, IID_PPV_ARGS(&r)), "buffer"); return r; };
    const UINT W = 1920, H = 1080, RW = 1707, RH = 961;
    NativeFormatConvert convert; convert.shader_path = argv[1];
    std::string why; if (!convert.Available(device, &why)) { std::fprintf(stderr, "convert unavailable: %s\n", why.c_str()); return 1; }
    D3D12_RESOURCE_DESC od{}; od.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D; od.Width = RW; od.Height = RH; od.DepthOrArraySize = od.MipLevels = 1; od.Format = DXGI_FORMAT_R16G16B16A16_FLOAT; od.SampleDesc.Count = 1; od.Flags = D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;
    ID3D12Resource *low = nullptr; Check(device->CreateCommittedResource(&def, D3D12_HEAP_FLAG_NONE, &od, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE, nullptr, IID_PPV_ARGS(&low)), "low");
    D3D12_PLACED_SUBRESOURCE_FOOTPRINT ofp{}; UINT64 ob = 0; device->GetCopyableFootprints(&od, 0, 1, 0, &ofp, nullptr, nullptr, &ob); ID3D12Resource *rbk = buffer(rb, ob, D3D12_RESOURCE_STATE_COPY_DEST);
    const DXGI_FORMAT formats[] = {DXGI_FORMAT_R9G9B9E5_SHAREDEXP, DXGI_FORMAT_B8G8R8X8_UNORM, DXGI_FORMAT_B8G8R8X8_TYPELESS, DXGI_FORMAT_R10G10B10A2_UNORM, DXGI_FORMAT_R10G10B10A2_TYPELESS, DXGI_FORMAT_R32G32B32A32_FLOAT, DXGI_FORMAT_R32G32B32A32_TYPELESS, DXGI_FORMAT_R32G32B32_FLOAT, DXGI_FORMAT_R32G32B32_TYPELESS, DXGI_FORMAT_R16G16B16A16_SNORM, DXGI_FORMAT_R8G8B8A8_SNORM, DXGI_FORMAT_B5G6R5_UNORM, DXGI_FORMAT_B5G5R5A1_UNORM, DXGI_FORMAT_B4G4R4A4_UNORM};
    int failures = 0;
    for (DXGI_FORMAT f : formats)
    {
        const DXGI_FORMAT view = NativeFallbackColor(f);
        D3D12_RESOURCE_DESC td{}; td.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D; td.Width = W; td.Height = H; td.DepthOrArraySize = td.MipLevels = 1; td.Format = f; td.SampleDesc.Count = 1;
        ID3D12Resource *color = nullptr; HRESULT hr = device->CreateCommittedResource(&def, D3D12_HEAP_FLAG_NONE, &td, D3D12_RESOURCE_STATE_COPY_DEST, nullptr, IID_PPV_ARGS(&color));
        if (FAILED(hr)) { std::printf("fmt=%s(%u) SKIP texture not creatable hr=%08lx\n", NativeDxgiFormatName(f), unsigned(f), long(hr)); continue; }
        D3D12_PLACED_SUBRESOURCE_FOOTPRINT fp{}; UINT64 total = 0; device->GetCopyableFootprints(&td, 0, 1, 0, &fp, nullptr, nullptr, &total);
        ID3D12Resource *upc = buffer(up, total, D3D12_RESOURCE_STATE_GENERIC_READ); uint8_t *m = nullptr; D3D12_RANGE z{0, 0}; upc->Map(0, &z, (void **)&m); uint32_t s = 0x9e3779b9u;
        for (UINT y = 0; y < H; ++y) for (UINT x = 0; x < W; ++x) { float v[3]; for (int c = 0; c < 3; ++c) { s = s * 1664525u + 1013904223u; v[c] = float((s >> 8) & 0xffff) / 65535.f * 0.9f; } Encode(f, v, m + y * fp.Footprint.RowPitch + Bpp(f) * x); }
        alloc->Reset(); list->Reset(alloc, nullptr);
        { D3D12_TEXTURE_COPY_LOCATION dst{}, src{}; dst.pResource = color; dst.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX; src.pResource = upc; src.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT; src.PlacedFootprint = fp; list->CopyTextureRegion(&dst, 0, 0, 0, &src, nullptr); }
        D3D12_RESOURCE_BARRIER b{}; b.Transition = {color, D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES, D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE | D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE}; list->ResourceBarrier(1, &b);
        try { convert.Record(list, color, view, D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE | D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE, low, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE, RW, RH); }
        catch (const std::exception &e) { std::printf("fmt=%s(%u) FAIL record %s\n", NativeDxgiFormatName(f), unsigned(f), e.what()); ++failures; list->Close(); upc->Unmap(0, nullptr); upc->Release(); color->Release(); continue; }
        D3D12_RESOURCE_BARRIER lb{}; lb.Transition = {low, D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_COPY_SOURCE}; list->ResourceBarrier(1, &lb);
        { D3D12_TEXTURE_COPY_LOCATION dst{}, src{}; dst.pResource = rbk; dst.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT; dst.PlacedFootprint = ofp; src.pResource = low; src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX; list->CopyTextureRegion(&dst, 0, 0, 0, &src, nullptr); }
        std::swap(lb.Transition.StateBefore, lb.Transition.StateAfter); list->ResourceBarrier(1, &lb);
        run();
        uint8_t *o = nullptr; rbk->Map(0, nullptr, (void **)&o); double maxerr = 0, maxrel = 0; int bad = 0; bool alpha_ok = true;
        for (UINT y = 0; y < RH; ++y) for (UINT x = 0; x < RW; ++x)
        { float ref[3]; Decode(f, m + y * fp.Footprint.RowPitch + Bpp(f) * x, ref); const uint16_t *g = (const uint16_t *)(o + y * ofp.Footprint.RowPitch + 8 * x);
          for (int c = 0; c < 3; ++c) { double e = std::fabs(double(HalfToFloat(g[c])) - ref[c]); if (e > maxerr) maxerr = e; if (e > std::fabs(ref[c]) * 0.000977 + 6e-8) ++bad; }
          if (NativeFallbackOpaque(view) && g[3] != 0x3c00) alpha_ok = false; }
        rbk->Unmap(0, nullptr);
        const bool pass = bad == 0 && alpha_ok; failures += !pass;
        std::printf("fmt=%s(%u) view=%s %s max_abs_err=%.3g out_of_half_rounding=%d alpha=%s\n", NativeDxgiFormatName(f), unsigned(f), NativeDxgiFormatName(view), pass ? "PASS" : "FAIL", maxerr, bad, alpha_ok ? "ok" : "BAD");
        upc->Unmap(0, nullptr); upc->Release(); color->Release();
    }
    std::printf(failures ? "convert_smoke: FAIL %d\n" : "convert_smoke: ok\n", failures);
    return failures ? 1 : 0;
}
