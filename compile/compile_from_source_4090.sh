#!/bin/bash
# Optimized for RTX 4090 + 128GB

set -e

# Target only RTX 4090 (Ada Lovelace, compute capability 8.9)
export TORCH_CUDA_ARCH_LIST="8.9"

# i9-13900K: 8 P-cores (16 threads) + 16 E-cores (16 threads) = 32 threads
# Oversubscribe heavily - DDR5-6000 and 36MB L3 cache can handle it
export MAX_JOBS=48
export EXT_PARALLEL=4
export NVCC_APPEND_FLAGS="--threads 12"

# Suppress verbose output (faster)
export NVCC_APPEND_FLAGS="$NVCC_APPEND_FLAGS -Xptxas=-suppress-stack-size-warning"

# Use ninja if available (faster than make)
if command -v ninja &> /dev/null; then
    export CMAKE_GENERATOR=Ninja
    echo "Using Ninja"
fi

# Enable ccache if available
if command -v ccache &> /dev/null; then
    export PATH="/usr/lib/ccache:$PATH"
    export CCACHE_MAXSIZE=10G
    echo "Using ccache"
fi

# i9-13900K native optimizations (Raptor Lake)
export CFLAGS="-O3 -march=native -mtune=native"
export CXXFLAGS="-O3 -march=native -mtune=native"

# Reduce disk I/O - use tmpfs if available and has space
if [ -d /dev/shm ] && [ $(df /dev/shm --output=avail | tail -1) -gt 10000000 ]; then
    export TMPDIR=/dev/shm
    echo "Using tmpfs for temp files"
fi

# Use uv if available 
if command -v uv &> /dev/null; then
    PIP_CMD="uv pip install"
    echo "Using uv"
else
    PIP_CMD="pip install"
fi

# Clean previous builds
echo "Cleaning previous build..."
rm -rf build/ dist/ *.egg-info/ 2>/dev/null || true

# Build
echo ""
echo "Building........."
echo "  CPU: i9-13900K (24c/32t)"
echo "  MAX_JOBS=$MAX_JOBS, EXT_PARALLEL=$EXT_PARALLEL, NVCC threads=12"
echo ""

time $PIP_CMD . --no-build-isolation --no-cache-dir 2>&1 | grep -v "^  "

echo ""
echo "Build complete!"
