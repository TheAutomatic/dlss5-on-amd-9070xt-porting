// rt_outside (2026-10-02, results/outside-net-20261002): rt_timing + per-frame timeline outside the network (see loop).
// env: OUT_PIPE=1 (3 frames in flight, no per-frame CPU wait), OUT_TIMING=0 (no GetTimings), OUT_LATE_RECORD=1 (record list B after EnqueueHip).
// usage: rt_timing.exe <LmxxfNrRuntime.dll> <modules_dir> <WxH[,WxH...]> <frames_per_size> <rounds>
// Before the session: GetApi with LMXXF_NR_API_V1_SIZE (old host) must succeed without GetTimings, a wrong size must fail,
// the full size must expose GetTimings. Per frame: GetTimings right after EnqueueHip (frame N not finished yet, so it must
// report frame N-1) -> "timing frame=N valid=V ms=X id=I". Per size: median network_ms and the hash/status line as rt_bench.
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <d3d12.h>
#include <dxgi1_4.h>
#include "LmxxfNrApi.h"
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <algorithm>

static void Die(const char *what, long hr = 0) { std::fprintf(stderr, "FAIL: %s %08lx\n", what, hr); std::exit(1); }
static void Check(HRESULT hr, const char *what) { if (FAILED(hr)) Die(what, hr); }
static uint16_t Half(float f)
{
    uint32_t b; std::memcpy(&b, &f, 4);
    uint32_t s = (b >> 16) & 0x8000, e = (b >> 23) & 0xff, m = b & 0x7fffff;
    if (e < 113) return uint16_t(s);
    return uint16_t(s | ((e - 112) << 10) | (m >> 13));
}

int wmain(int argc, wchar_t **argv)
{
    if (argc < 6) { std::fprintf(stderr, "usage: rt_bench <dll> <modules> <WxH,...> <frames> <rounds>\n"); return 2; }
    setvbuf(stdout, nullptr, _IONBF, 0);
    HMODULE dll = LoadLibraryW(argv[1]);
    if (!dll) Die("LoadLibrary");
    auto getApi = reinterpret_cast<int32_t (*)(uint32_t, LmxxfNrApi *)>(GetProcAddress(dll, "LmxxfNrGetApi"));
    if (!getApi) Die("GetApi export");
    { LmxxfNrApi old{}; old.struct_size = LMXXF_NR_API_V1_SIZE; old.GetTimings = reinterpret_cast<int32_t (*)(void *, LmxxfNrTimings *)>(1);
      if (getApi(2, &old) != LMXXF_NR_OK) Die("GetApi(V1 size)");
      if (old.struct_size != LMXXF_NR_API_V1_SIZE || old.GetTimings != reinterpret_cast<int32_t (*)(void *, LmxxfNrTimings *)>(1) || !old.GetStatus) Die("V1 table wrote past its size");
      std::printf("abi: v1-size ok (GetTimings slot untouched)\n"); }
    { LmxxfNrApi bad{}; bad.struct_size = LMXXF_NR_API_V1_SIZE - 8; if (getApi(2, &bad) == LMXXF_NR_OK) Die("GetApi accepted a wrong size"); std::printf("abi: wrong size rejected\n"); }
    LmxxfNrApi api{}; api.struct_size = sizeof(api);
    if (getApi(2, &api) != LMXXF_NR_OK) Die("GetApi(2)");
    if (!api.GetTimings) Die("GetTimings missing");
    { LmxxfNrTimings t{}; t.struct_size = 8; if (api.GetTimings(nullptr, &t) == LMXXF_NR_OK) Die("GetTimings accepted a wrong size");
      t.struct_size = sizeof(t); if (api.GetTimings(nullptr, &t) == LMXXF_NR_OK || t.valid) Die("GetTimings accepted a null context");
      std::printf("abi: full size ok, GetTimings argument checks ok\n"); }
    std::vector<std::pair<UINT, UINT>> sizes;
    for (wchar_t *p = argv[3]; *p;) { UINT w = wcstoul(p, &p, 10); if (*p == L'x') ++p; UINT h = wcstoul(p, &p, 10); sizes.push_back({w, h}); if (*p == L',') ++p; }
    const int frames = _wtoi(argv[4]), rounds = _wtoi(argv[5]);

    IDXGIFactory4 *factory = nullptr; Check(CreateDXGIFactory1(IID_PPV_ARGS(&factory)), "factory");
    IDXGIAdapter1 *adapter = nullptr; ID3D12Device *device = nullptr;
    for (UINT i = 0; factory->EnumAdapters1(i, &adapter) != DXGI_ERROR_NOT_FOUND; ++i)
    {
        DXGI_ADAPTER_DESC1 d{}; adapter->GetDesc1(&d);
        if (d.VendorId == 0x1002 && SUCCEEDED(D3D12CreateDevice(adapter, D3D_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device)))) break;
        adapter->Release(); adapter = nullptr;
    }
    if (!device) Die("AMD device");
    IDXGIAdapter3 *adapter3 = nullptr; adapter->QueryInterface(IID_PPV_ARGS(&adapter3));
    D3D12_COMMAND_QUEUE_DESC qd{}; qd.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
    ID3D12CommandQueue *queue = nullptr; Check(device->CreateCommandQueue(&qd, IID_PPV_ARGS(&queue)), "queue");
    ID3D12CommandAllocator *allocA = nullptr, *allocB = nullptr;
    Check(device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&allocA)), "allocA");
    Check(device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&allocB)), "allocB");
    ID3D12GraphicsCommandList *listA = nullptr, *listB = nullptr;
    Check(device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, allocA, nullptr, IID_PPV_ARGS(&listA)), "listA");
    Check(device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, allocB, nullptr, IID_PPV_ARGS(&listB)), "listB");
    listA->Close(); listB->Close();
    /* RT_PIPE=1: game-like host, no CPU wait per frame; up to 3 frames of command lists in flight (allocator ring), GetTimings
       read after EnqueueHip and again after Retire. The lag check then only requires a valid frame_id in [N-4, N-1]. */
    const bool pipe = std::getenv("OUT_PIPE") && !std::strcmp(std::getenv("OUT_PIPE"), "1");
    /* RT_AFTER_WAIT=1 (net-timing #3, TheAutomatic's harness order): serial; per frame EnqueueHip, execute the output list,
       wait for the queue, then GetTimings, then Retire. The frame just finished must be reported (frame_id == N). */
    const bool after = false;
    ID3D12CommandAllocator *pa[3]{}, *pb[3]{}; ID3D12GraphicsCommandList *pla[3]{}, *plb[3]{}; UINT64 pv[3]{};
    for (int i = 0; i < 3; ++i) { Check(device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&pa[i])), "pa"); Check(device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&pb[i])), "pb");
        Check(device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, pa[i], nullptr, IID_PPV_ARGS(&pla[i])), "pla"); Check(device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, pb[i], nullptr, IID_PPV_ARGS(&plb[i])), "plb"); pla[i]->Close(); plb[i]->Close(); }
    unsigned tiny = 0, collapsed = 0;
    ID3D12Fence *fence = nullptr; Check(device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence)), "fence");
    HANDLE ev = CreateEventW(nullptr, FALSE, FALSE, nullptr); UINT64 fv = 0;
    auto wait = [&] { Check(queue->Signal(fence, ++fv), "signal"); Check(fence->SetEventOnCompletion(fv, ev), "evt"); if (WaitForSingleObject(ev, 30000) != WAIT_OBJECT_0) Die("timeout"); };
    auto exec = [&](ID3D12GraphicsCommandList *l) { ID3D12CommandList *a[] = {l}; queue->ExecuteCommandLists(1, a); };

    D3D12_HEAP_PROPERTIES def{}; def.Type = D3D12_HEAP_TYPE_DEFAULT;
    D3D12_HEAP_PROPERTIES up{}; up.Type = D3D12_HEAP_TYPE_UPLOAD;
    D3D12_HEAP_PROPERTIES rb{}; rb.Type = D3D12_HEAP_TYPE_READBACK;
    auto buffer = [&](D3D12_HEAP_PROPERTIES &hp, UINT64 bytes, D3D12_RESOURCE_STATES st) {
        D3D12_RESOURCE_DESC d{}; d.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER; d.Width = bytes; d.Height = 1; d.DepthOrArraySize = d.MipLevels = 1;
        d.SampleDesc.Count = 1; d.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR; ID3D12Resource *r = nullptr;
        Check(device->CreateCommittedResource(&hp, D3D12_HEAP_FLAG_NONE, &d, st, nullptr, IID_PPV_ARGS(&r)), "buffer"); return r; };

    // exposure 1x1 R32 = 1
    D3D12_RESOURCE_DESC ed{}; ed.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D; ed.Width = ed.Height = 1; ed.DepthOrArraySize = ed.MipLevels = 1;
    ed.Format = DXGI_FORMAT_R32_FLOAT; ed.SampleDesc.Count = 1;
    ID3D12Resource *exposure = nullptr; Check(device->CreateCommittedResource(&def, D3D12_HEAP_FLAG_NONE, &ed, D3D12_RESOURCE_STATE_COPY_DEST, nullptr, IID_PPV_ARGS(&exposure)), "exposure");
    {
        ID3D12Resource *eu = buffer(up, 256, D3D12_RESOURCE_STATE_GENERIC_READ); void *m = nullptr; D3D12_RANGE z{0, 0}; eu->Map(0, &z, &m); *(float *)m = 1.f; eu->Unmap(0, nullptr);
        allocA->Reset(); listA->Reset(allocA, nullptr);
        D3D12_TEXTURE_COPY_LOCATION dst{}, src{}; dst.pResource = exposure; dst.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
        src.pResource = eu; src.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT; src.PlacedFootprint.Footprint = {DXGI_FORMAT_R32_FLOAT, 1, 1, 1, 256};
        listA->CopyTextureRegion(&dst, 0, 0, 0, &src, nullptr);
        D3D12_RESOURCE_BARRIER b{}; b.Transition = {exposure, D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES, D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE};
        listA->ResourceBarrier(1, &b); listA->Close(); exec(listA); wait(); eu->Release();
    }

    D3D12_QUERY_HEAP_DESC qhd{}; qhd.Type = D3D12_QUERY_HEAP_TYPE_TIMESTAMP; qhd.Count = 12; ID3D12QueryHeap *tsHeap = nullptr; Check(device->CreateQueryHeap(&qhd, IID_PPV_ARGS(&tsHeap)), "query heap");
    ID3D12Resource *tsRead = buffer(rb, 96, D3D12_RESOURCE_STATE_COPY_DEST);
    UINT64 tsfreq = 0; Check(queue->GetTimestampFrequency(&tsfreq), "ts freq"); const double tsf = double(tsfreq);
    LARGE_INTEGER qfl; QueryPerformanceFrequency(&qfl); const double qf = double(qfl.QuadPart);
    const bool timing = !(std::getenv("OUT_TIMING") && !std::strcmp(std::getenv("OUT_TIMING"), "0"));
    const bool lateRecord = std::getenv("OUT_LATE_RECORD") && !std::strcmp(std::getenv("OUT_LATE_RECORD"), "1");
    std::printf("outside: pipe=%d timing=%d late_record=%d tsfreq=%llu qpcfreq=%.0f\n", pipe ? 1 : 0, timing ? 1 : 0, lateRecord ? 1 : 0, (unsigned long long)tsfreq, qf);
    std::wstring modules = argv[2];
    LmxxfNrCreateInfo ci{}; ci.struct_size = sizeof(ci); ci.device = device; ci.queue = queue; ci.assets_directory = modules.c_str();
    void *ctx = nullptr;
    if (api.Create(&ci, &ctx) != LMXXF_NR_OK) { char e[512]{}; api.GetLastError(e, sizeof e); std::fprintf(stderr, "Create: %s\n", e); return 1; }
    if (api.PrepareSession(ctx) != LMXXF_NR_OK) { char e[512]{}; api.GetLastError(e, sizeof e); std::fprintf(stderr, "PrepareSession: %s\n", e); return 1; }
    if (timing) { LmxxfNrTimings t{}; t.struct_size = sizeof(t); if (api.GetTimings(ctx, &t) != LMXXF_NR_OK || t.valid) Die("GetTimings before any frame"); std::printf("abi: before first frame valid=0 ok\n"); }
    unsigned bad_lag = 0;

    for (int r = 0; r < rounds; ++r)
        for (auto [W, H] : sizes)
        {
            D3D12_RESOURCE_DESC td{}; td.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D; td.Width = W; td.Height = H; td.DepthOrArraySize = td.MipLevels = 1;
            td.Format = DXGI_FORMAT_R16G16B16A16_FLOAT; td.SampleDesc.Count = 1;
            ID3D12Resource *color = nullptr; Check(device->CreateCommittedResource(&def, D3D12_HEAP_FLAG_NONE, &td, D3D12_RESOURCE_STATE_COPY_DEST, nullptr, IID_PPV_ARGS(&color)), "color");
            D3D12_PLACED_SUBRESOURCE_FOOTPRINT fp{}; UINT64 total = 0; device->GetCopyableFootprints(&td, 0, 1, 0, &fp, nullptr, nullptr, &total);
            ID3D12Resource *upc = buffer(up, total, D3D12_RESOURCE_STATE_GENERIC_READ);
            { void *m = nullptr; D3D12_RANGE z{0, 0}; upc->Map(0, &z, &m); uint32_t s = 0x9e3779b9u;
              for (UINT y = 0; y < H; ++y) for (UINT x = 0; x < W; ++x) { uint16_t *p = (uint16_t *)((char *)m + y * fp.Footprint.RowPitch + 8 * x);
                  for (int c = 0; c < 3; ++c) { s = s * 1664525u + 1013904223u; p[c] = Half(float((s >> 8) & 0xffff) / 65535.f * 0.9f); } p[3] = 0x3c00; }
              upc->Unmap(0, nullptr); }
            allocA->Reset(); listA->Reset(allocA, nullptr);
            { D3D12_TEXTURE_COPY_LOCATION dst{}, src{}; dst.pResource = color; dst.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX; src.pResource = upc; src.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT; src.PlacedFootprint = fp;
              listA->CopyTextureRegion(&dst, 0, 0, 0, &src, nullptr);
              D3D12_RESOURCE_BARRIER b{}; b.Transition = {color, D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES, D3D12_RESOURCE_STATE_COPY_DEST, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE}; listA->ResourceBarrier(1, &b); }
            listA->Close(); exec(listA); wait();

            LmxxfNrFrameInfo fi{}; fi.struct_size = sizeof(fi); fi.color_width = W; fi.color_height = H; fi.color = color;
            fi.color_state = D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE; fi.exposure = exposure;
            fi.exposure_state = D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE; fi.pre_exposure = fi.exposure_scale = 1.f;
            std::vector<float> tms; double sum = 0; int used = 0; uint64_t hash = 0; ID3D12Resource *out = nullptr;
            // outside-net (2026-10-02): per-frame timeline. CPU QPC c0..c6, GPU timestamps TS0/TS1 around RecordInputs (list A) and
            // TS2/TS3 around RecordOutputs (list B), mapped to QPC with GetClockCalibration; network_ms from GetTimings.
            enum { P_PREP, P_REC, P_LAUNCH, P_IN, P_GAP, P_NET, P_HAND, P_OUT, P_WAKE, P_ENQ, P_LBLATE, P_WALL, P_N };
            static const char *pname[P_N] = {"cpu_prepare", "cpu_record", "launch_latency", "gpu_inputs", "gap_in_out", "hip_net", "handoff", "gpu_outputs", "wake_latency", "cpu_enqueue", "lb_submit_after_ts1", "wall"};
            std::vector<double> pv_[P_N]; double prevC0 = 0;
            double cq[3][8]{}; int slotFrame[3] = {-1, -1, -1}; std::vector<float> slotNet(3, -1.f);
            auto qpc = [] { LARGE_INTEGER t; QueryPerformanceCounter(&t); return double(t.QuadPart); };
            auto harvest = [&](int slot, double wakeQ) {
                if (slotFrame[slot] < frames / 4) return;
                UINT64 *ts = nullptr; D3D12_RANGE rr{size_t(slot) * 32, size_t(slot) * 32 + 32}; Check(tsRead->Map(0, &rr, (void **)&ts), "ts map");
                UINT64 t[4]; std::memcpy(t, (char *)ts + slot * 32, 32); D3D12_RANGE none{0, 0}; tsRead->Unmap(0, &none);
                UINT64 gcal = 0, ccal = 0; Check(queue->GetClockCalibration(&gcal, &ccal), "calib");
                auto toQ = [&](UINT64 g) { return double(ccal) + (double(g) - double(gcal)) * qf / tsf; };
                const double ms = 1000.0 / qf; const double *c = cq[slot];
                pv_[P_PREP].push_back((c[1] - c[0]) * ms); pv_[P_REC].push_back((c[2] - c[1]) * ms);
                pv_[P_LAUNCH].push_back((toQ(t[0]) - c[3]) * ms); pv_[P_IN].push_back((t[1] - t[0]) * 1000.0 / tsf);
                const double gap = (t[2] - t[1]) * 1000.0 / tsf; pv_[P_GAP].push_back(gap);
                if (slotNet[slot] > 0) { pv_[P_NET].push_back(slotNet[slot]); pv_[P_HAND].push_back(gap - slotNet[slot]); }
                pv_[P_OUT].push_back((t[3] - t[2]) * 1000.0 / tsf);
                if (wakeQ > 0) pv_[P_WAKE].push_back((wakeQ - toQ(t[3])) * ms);
                pv_[P_ENQ].push_back((c[4] - c[3]) * ms); pv_[P_LBLATE].push_back((c[5] - toQ(t[1])) * ms);
                if (wakeQ > 0) pv_[P_WALL].push_back((wakeQ - c[0]) * ms);
            };
            for (int f = 0; f < frames; ++f)
            {
                auto t0 = std::chrono::steady_clock::now();
                fi.frame_id = uint64_t(r) * 100000 + f;
                ID3D12GraphicsCommandList *la = listA, *lb = listB; const int slot = pipe ? f % 3 : 0;
                double c[8]{}; c[0] = qpc();
                if (pipe && f > frames / 4 && prevC0 > 0) pv_[P_WALL].push_back((c[0] - prevC0) * 1000.0 / qf); prevC0 = c[0];
                if (pipe) { if (pv[slot] && fence->GetCompletedValue() < pv[slot]) { Check(fence->SetEventOnCompletion(pv[slot], ev), "slot evt"); WaitForSingleObject(ev, 30000); }
                    if (pv[slot]) harvest(slot, 0);
                    pa[slot]->Reset(); pla[slot]->Reset(pa[slot], nullptr); pb[slot]->Reset(); plb[slot]->Reset(pb[slot], nullptr); la = pla[slot]; lb = plb[slot]; }
                else { allocA->Reset(); listA->Reset(allocA, nullptr); allocB->Reset(); listB->Reset(allocB, nullptr); }
                LmxxfNrJob job{}; job.struct_size = sizeof(job);
                if (api.PrepareFrame(ctx, &fi, &job) != LMXXF_NR_OK) { char e[512]{}; api.GetLastError(e, sizeof e); std::fprintf(stderr, "PrepareFrame %ux%u: %s\n", W, H, e); return 1; }
                c[1] = qpc();
                la->EndQuery(tsHeap, D3D12_QUERY_TYPE_TIMESTAMP, slot * 4 + 0);
                if (api.RecordInputs(ctx, job.handle, la) != LMXXF_NR_OK) Die("RecordInputs");
                la->EndQuery(tsHeap, D3D12_QUERY_TYPE_TIMESTAMP, slot * 4 + 1);
                la->Close();
                auto recordB = [&] {
                    lb->EndQuery(tsHeap, D3D12_QUERY_TYPE_TIMESTAMP, slot * 4 + 2);
                    if (api.RecordOutputs(ctx, job.handle, lb) != LMXXF_NR_OK) { char e[512]{}; api.GetLastError(e, sizeof e); std::fprintf(stderr, "RecordOutputs: %s\n", e); std::exit(1); }
                    lb->EndQuery(tsHeap, D3D12_QUERY_TYPE_TIMESTAMP, slot * 4 + 3);
                    lb->ResolveQueryData(tsHeap, D3D12_QUERY_TYPE_TIMESTAMP, slot * 4, 4, tsRead, slot * 32);
                    lb->Close(); };
                if (!lateRecord) recordB();
                c[2] = qpc();
                exec(la); c[3] = qpc();
                if (reinterpret_cast<int32_t (*)(void *, void *)>(api.EnqueueHip)(ctx, job.handle) != LMXXF_NR_OK) { char e[512]{}; api.GetLastError(e, sizeof e); std::fprintf(stderr, "EnqueueHip: %s\n", e); return 1; }
                c[4] = qpc();
                if (lateRecord) recordB();
                exec(lb);
                if (api.Retire(ctx, job.handle) != LMXXF_NR_OK) Die("Retire");
                c[5] = qpc();
                std::memcpy(cq[slot], c, sizeof c); slotFrame[slot] = f; slotNet[slot] = -1.f;
                if (timing) { LmxxfNrTimings t{}; t.struct_size = sizeof(t); if (api.GetTimings(ctx, &t) != LMXXF_NR_OK) Die("GetTimings");
                    // serial: t is frame f-1 (already complete); attribute to the slot that ran it
                    if (t.valid && f >= frames / 4) tms.push_back(t.network_ms);
                    if (t.valid) { const int fid = int(t.frame_id - uint64_t(r) * 100000); for (int k = 0; k < 3; ++k) if (slotFrame[k] == fid) slotNet[k] = t.network_ms; } }
                if (pipe) { Check(queue->Signal(fence, ++fv), "pipe signal"); pv[slot] = fv; }
                else { wait(); const double wq = qpc();
                    if (timing) { LmxxfNrTimings t{}; t.struct_size = sizeof(t); api.GetTimings(ctx, &t); if (t.valid && t.frame_id == fi.frame_id) slotNet[0] = t.network_ms; else slotNet[0] = -1.f; }
                    harvest(0, wq); }
                const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
                if (f >= frames / 4) { sum += ms; ++used; }
                out = static_cast<ID3D12Resource *>(job.private_output);
            }
            for (int p = 0; p < P_N; ++p) { auto &v = pv_[p]; if (v.empty()) continue; std::sort(v.begin(), v.end());
                double m = 0; for (double x : v) m += x; std::printf("outside size=%ux%u %s med=%.4f mean=%.4f p10=%.4f p90=%.4f n=%zu\n", W, H, pname[p], v[v.size() / 2], m / v.size(), v[v.size() / 10], v[v.size() * 9 / 10], v.size()); }
            if (pipe) wait();
            if (out)
            {
                D3D12_RESOURCE_DESC od = out->GetDesc(); D3D12_PLACED_SUBRESOURCE_FOOTPRINT ofp{}; UINT64 ob = 0; UINT rows = 0; UINT64 rowBytes = 0;
                device->GetCopyableFootprints(&od, 0, 1, 0, &ofp, &rows, &rowBytes, &ob);
                ID3D12Resource *rbk = buffer(rb, ob, D3D12_RESOURCE_STATE_COPY_DEST);
                allocA->Reset(); listA->Reset(allocA, nullptr);
                D3D12_RESOURCE_BARRIER b{}; b.Transition = {out, D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES, D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE, D3D12_RESOURCE_STATE_COPY_SOURCE};
                listA->ResourceBarrier(1, &b);
                D3D12_TEXTURE_COPY_LOCATION dst{}, src{}; dst.pResource = rbk; dst.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT; dst.PlacedFootprint = ofp;
                src.pResource = out; src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX; listA->CopyTextureRegion(&dst, 0, 0, 0, &src, nullptr);
                std::swap(b.Transition.StateBefore, b.Transition.StateAfter); listA->ResourceBarrier(1, &b);
                listA->Close(); exec(listA); wait();
                void *m = nullptr; rbk->Map(0, nullptr, &m); hash = 1469598103934665603ull;
                for (UINT y = 0; y < rows; ++y) { const uint8_t *p = (const uint8_t *)m + y * ofp.Footprint.RowPitch; for (UINT64 i = 0; i < rowBytes; ++i) { hash ^= p[i]; hash *= 1099511628211ull; } }
                rbk->Unmap(0, nullptr); rbk->Release();
            }
            DXGI_QUERY_VIDEO_MEMORY_INFO vm{}; if (adapter3) adapter3->QueryVideoMemoryInfo(0, DXGI_MEMORY_SEGMENT_GROUP_LOCAL, &vm);
            char status[768]{}; api.GetStatus(ctx, status, sizeof status);
            std::sort(tms.begin(), tms.end());
            std::printf("net_timing size=%ux%u median_ms=%.3f min_ms=%.3f max_ms=%.3f n=%zu\n", W, H, tms.empty() ? 0.f : tms[tms.size() / 2],
                        tms.empty() ? 0.f : tms.front(), tms.empty() ? 0.f : tms.back(), tms.size());
            std::printf("round=%d size=%ux%u mean_ms=%.3f hash=%016llx vram_mib=%llu status=%s\n", r, W, H, used ? sum / used : 0.0,
                        (unsigned long long)hash, (unsigned long long)(vm.CurrentUsage >> 20), status);
            upc->Release(); color->Release();
        }
    api.Drain(ctx);
    api.Destroy(ctx);
    std::printf("lag_mismatch=%u tiny_reads=%u collapsed_lt0.01=%u pipe=%u after_wait=%u\n", bad_lag, tiny, collapsed, pipe ? 1u : 0u, after ? 1u : 0u);
    std::printf("rt_timing: %s\n", bad_lag ? "LAG MISMATCH" : "ok");
    return bad_lag ? 3 : tiny ? 4 : 0;
    return 0;
}
