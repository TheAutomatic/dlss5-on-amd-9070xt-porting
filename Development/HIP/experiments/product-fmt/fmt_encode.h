#pragma once
// CPU encoders shared by rt_fmt.cpp and convert_smoke.cpp (product-fmt, 2026-09-30).
#include <windows.h>
#include <dxgiformat.h>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
static void Die(const char *what, long hr = 0) { std::fprintf(stderr, "FAIL: %s %08lx\n", what, hr); std::exit(1); }
static void Check(HRESULT hr, const char *what) { if (FAILED(hr)) Die(what, hr); }
static uint16_t Half(float f)
{
    uint32_t b; std::memcpy(&b, &f, 4);
    uint32_t s = (b >> 16) & 0x8000, e = (b >> 23) & 0xff, m = b & 0x7fffff;
    if (e < 113) return uint16_t(s);
    return uint16_t(s | ((e - 112) << 10) | (m >> 13));
}

static uint32_t Rgb9e5(float r, float g, float b)
{
    auto cl = [](float v) { return v < 0.f ? 0.f : v > 65408.f ? 65408.f : v; };
    r = cl(r); g = cl(g); b = cl(b); float m = r > g ? r : g; m = m > b ? m : b;
    int e = m > 0.f ? int(std::floor(std::log2(m))) + 1 : -15; if (e < -15) e = -15; if (e > 16) e = 16;
    float sc = std::ldexp(1.f, e - 9); if (int(std::lround(m / sc)) == 512) { ++e; sc *= 2.f; }
    uint32_t R = uint32_t(std::lround(r / sc)), G = uint32_t(std::lround(g / sc)), B = uint32_t(std::lround(b / sc));
    return R | (G << 9) | (B << 18) | (uint32_t(e + 15) << 27);
}
static UINT Bpp(DXGI_FORMAT f)
{
    switch (f) { case DXGI_FORMAT_R32G32B32A32_FLOAT: case DXGI_FORMAT_R32G32B32A32_TYPELESS: return 16; case DXGI_FORMAT_R32G32B32_FLOAT: case DXGI_FORMAT_R32G32B32_TYPELESS: return 12;
    case DXGI_FORMAT_R16G16B16A16_FLOAT: case DXGI_FORMAT_R16G16B16A16_SNORM: return 8; case DXGI_FORMAT_B5G6R5_UNORM: case DXGI_FORMAT_B5G5R5A1_UNORM: case DXGI_FORMAT_B4G4R4A4_UNORM: return 2; default: return 4; }
}
static void Encode(DXGI_FORMAT f, const float *v, uint8_t *p)
{
    auto u = [](float x, int bits) { return uint32_t(std::lround(x * float((1 << bits) - 1))); };
    switch (f)
    {
    case DXGI_FORMAT_R16G16B16A16_FLOAT: { uint16_t *h = (uint16_t *)p; for (int c = 0; c < 3; ++c) h[c] = Half(v[c]); h[3] = 0x3c00; break; }
    case DXGI_FORMAT_R9G9B9E5_SHAREDEXP: { uint32_t w = Rgb9e5(v[0], v[1], v[2]); std::memcpy(p, &w, 4); break; }
    case DXGI_FORMAT_B8G8R8X8_UNORM: case DXGI_FORMAT_B8G8R8X8_TYPELESS: case DXGI_FORMAT_B8G8R8X8_UNORM_SRGB: p[0] = uint8_t(u(v[2], 8)); p[1] = uint8_t(u(v[1], 8)); p[2] = uint8_t(u(v[0], 8)); p[3] = 255; break;
    case DXGI_FORMAT_R10G10B10A2_UNORM: case DXGI_FORMAT_R10G10B10A2_TYPELESS: { uint32_t w = u(v[0], 10) | (u(v[1], 10) << 10) | (u(v[2], 10) << 20) | (3u << 30); std::memcpy(p, &w, 4); break; }
    case DXGI_FORMAT_R32G32B32A32_FLOAT: case DXGI_FORMAT_R32G32B32A32_TYPELESS: { float w[4] = {v[0], v[1], v[2], 1.f}; std::memcpy(p, w, 16); break; }
    case DXGI_FORMAT_R32G32B32_FLOAT: case DXGI_FORMAT_R32G32B32_TYPELESS: std::memcpy(p, v, 12); break;
    case DXGI_FORMAT_R16G16B16A16_SNORM: { int16_t *h = (int16_t *)p; for (int c = 0; c < 3; ++c) h[c] = int16_t(std::lround(v[c] * 32767.f)); h[3] = 32767; break; }
    case DXGI_FORMAT_R8G8B8A8_SNORM: for (int c = 0; c < 3; ++c) p[c] = uint8_t(int8_t(std::lround(v[c] * 127.f))); p[3] = 127; break;
    case DXGI_FORMAT_B5G6R5_UNORM: { uint16_t w = uint16_t(u(v[2], 5) | (u(v[1], 6) << 5) | (u(v[0], 5) << 11)); std::memcpy(p, &w, 2); break; }
    case DXGI_FORMAT_B5G5R5A1_UNORM: { uint16_t w = uint16_t(u(v[2], 5) | (u(v[1], 5) << 5) | (u(v[0], 5) << 10) | 0x8000); std::memcpy(p, &w, 2); break; }
    case DXGI_FORMAT_B4G4R4A4_UNORM: { uint16_t w = uint16_t(u(v[2], 4) | (u(v[1], 4) << 4) | (u(v[0], 4) << 8) | 0xF000); std::memcpy(p, &w, 2); break; }
    default: Die("RT_COLOR_FORMAT not handled by the encoder", f);
    }
}

// CPU reference decode of what Encode wrote (float RGB), sRGB views excluded.
static void Decode(DXGI_FORMAT f, const uint8_t *p, float *v)
{
    auto un = [](uint32_t x, int bits) { return float(x) / float((1u << bits) - 1); };
    uint32_t w = 0; std::memcpy(&w, p, 4); uint16_t h16 = 0; std::memcpy(&h16, p, 2);
    switch (f)
    {
    case DXGI_FORMAT_R9G9B9E5_SHAREDEXP: { float sc = std::ldexp(1.f, int(w >> 27) - 24); v[0] = float(w & 511) * sc; v[1] = float((w >> 9) & 511) * sc; v[2] = float((w >> 18) & 511) * sc; break; }
    case DXGI_FORMAT_B8G8R8X8_UNORM: case DXGI_FORMAT_B8G8R8X8_TYPELESS: v[0] = un(p[2], 8); v[1] = un(p[1], 8); v[2] = un(p[0], 8); break;
    case DXGI_FORMAT_R10G10B10A2_UNORM: case DXGI_FORMAT_R10G10B10A2_TYPELESS: v[0] = un(w & 1023, 10); v[1] = un((w >> 10) & 1023, 10); v[2] = un((w >> 20) & 1023, 10); break;
    case DXGI_FORMAT_R32G32B32A32_FLOAT: case DXGI_FORMAT_R32G32B32A32_TYPELESS: case DXGI_FORMAT_R32G32B32_FLOAT: case DXGI_FORMAT_R32G32B32_TYPELESS: std::memcpy(v, p, 12); break;
    case DXGI_FORMAT_R16G16B16A16_SNORM: for (int c = 0; c < 3; ++c) { int16_t x; std::memcpy(&x, p + 2 * c, 2); v[c] = float(x) / 32767.f; } break;
    case DXGI_FORMAT_R8G8B8A8_SNORM: for (int c = 0; c < 3; ++c) v[c] = float(int8_t(p[c])) / 127.f; break;
    case DXGI_FORMAT_B5G6R5_UNORM: v[2] = un(h16 & 31, 5); v[1] = un((h16 >> 5) & 63, 6); v[0] = un(h16 >> 11, 5); break;
    case DXGI_FORMAT_B5G5R5A1_UNORM: v[2] = un(h16 & 31, 5); v[1] = un((h16 >> 5) & 31, 5); v[0] = un((h16 >> 10) & 31, 5); break;
    case DXGI_FORMAT_B4G4R4A4_UNORM: v[2] = un(h16 & 15, 4); v[1] = un((h16 >> 4) & 15, 4); v[0] = un((h16 >> 8) & 15, 4); break;
    default: v[0] = v[1] = v[2] = 0.f;
    }
}
static float HalfToFloat(uint16_t h)
{
    uint32_t s = uint32_t(h & 0x8000) << 16, e = (h >> 10) & 31, m = h & 1023, b;
    if (!e) { float f = std::ldexp(float(m), -24); return s ? -f : f; }
    if (e == 31) b = s | 0x7f800000 | (m << 13); else b = s | ((e + 112) << 23) | (m << 13);
    float f; std::memcpy(&f, &b, 4); return f;
}
