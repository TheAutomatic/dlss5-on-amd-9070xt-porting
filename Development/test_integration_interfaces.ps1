param([switch]$Amd)
$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue)) { throw 'MSVC x64 developer shell required' }
    & "$PSScriptRoot/test_codec_integration.ps1" -Amd:$Amd
    $out = Join-Path $PWD 'exports/integration-interfaces'
    New-Item -ItemType Directory -Force $out | Out-Null
    & cl.exe /nologo /std:c++17 /EHsc /utf-8 /DNOMINMAX /I src /c Development/HIP/bridge_network.cpp "/Fo:$out/bridge.obj"
    if ($LASTEXITCODE) { throw 'Bridge compilation failed' }
    & cl.exe /nologo /std:c++17 /EHsc /utf-8 Development/HIP/test_module_load.cpp "/Fe:$out/module.exe" "/Fo:$out/module.obj"
    if ($LASTEXITCODE) { throw 'Module ownership test compilation failed' }
    & "$out/module.exe" Development/HIP/test_module_load.cpp
    if ($LASTEXITCODE) { throw 'Module ownership test failed' }
    & cl.exe /nologo /std:c++17 /EHsc /utf-8 /I src Development/test_fast_history.cpp "/Fe:$out/history.exe" "/Fo:$out/history.obj" d3d12.lib dxgi.lib d3dcompiler.lib dxguid.lib
    if ($LASTEXITCODE) { throw 'Fast History test compilation failed' }
    & cl.exe /nologo /std:c++17 /EHsc /utf-8 /DDLSS5_USE_HIP /I src Development/test_addon_fast_history.cpp "/Fe:$out/addon.exe" "/Fo:$out/addon.obj" d3d12.lib dxgi.lib d3dcompiler.lib dxguid.lib user32.lib
    if ($LASTEXITCODE) { throw 'Addon History compilation failed' }
    & "$out/addon.exe"
    if ($LASTEXITCODE) { throw 'Addon deferred History failed' }
    & "$out/history.exe"
    if ($LASTEXITCODE) { throw 'Fast History WARP failed' }
    if ($Amd) {
        & "$out/addon.exe" --hardware
        if ($LASTEXITCODE) { throw 'Addon deferred GPU History failed' }
        & "$out/history.exe" --hardware
        if ($LASTEXITCODE) { throw 'Fast History GPU failed' }
    }
} finally { Pop-Location }
