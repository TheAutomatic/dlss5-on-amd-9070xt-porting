#!/bin/bash
A=$HOME/work/aco-isa
export LD_LIBRARY_PATH=$(dirname $(find $A/prefix -name libdrm.so | head -1)):$LD_LIBRARY_PATH
export AMDGPU_GPU_ID=gfx1201
export VK_ICD_FILENAMES=$A/build/src/amd/vulkan/radeon_devenv_icd.aarch64.json
export VK_DRIVER_FILES=$VK_ICD_FILENAMES
LD_PRELOAD=$A/build/src/amd/drm-shim/libamdgpu_noop_drm_shim.so exec "$@"
