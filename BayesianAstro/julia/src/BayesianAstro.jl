"""
    BayesianAstro

A distribution-aware astrophotography stacking pipeline that preserves statistical
information across frames for intelligent fusion decisions.

## Key Features
- Per-pixel statistical distribution tracking via Welford's algorithm
- Confidence metrics derived from distribution properties  
- Multiple fusion strategies (MLE, confidence-weighted, lucky imaging, multi-scale)
- GPU acceleration via CUDA.jl

## Architecture
- `IO`: FITS file reading/writing
- `Statistics`: Distribution accumulation and classification
- `Fusion`: Pixel fusion strategies
- `GPU`: CUDA kernel implementations
- `Pipeline`: High-level processing orchestration
- `Visualization`: Debugging and confidence map generation
"""
module BayesianAstro

using FITSIO
using Distributions
using StatsBase
using StaticArrays
using Optim
using Images

# Conditional CUDA loading
const CUDA_AVAILABLE = Ref(false)
function __init__()
    try
        @eval using CUDA
        if CUDA.functional()
            CUDA_AVAILABLE[] = true
            @info "CUDA available: GPU acceleration enabled"
        else
            @warn "CUDA loaded but not functional: falling back to CPU"
        end
    catch e
        @warn "CUDA not available: falling back to CPU" exception=e
    end
end

# Core types
include("types.jl")

# Submodules
include("io/FitsIO.jl")
include("statistics/Welford.jl")
include("statistics/Classification.jl")
include("statistics/Confidence.jl")
include("fusion/Strategies.jl")
include("pipeline/Pipeline.jl")
include("visualization/ConfidenceMaps.jl")

# GPU module (conditionally loaded)
include("gpu/Kernels.jl")

# Public API
export PixelDistribution, PixelResult, DistributionType, FrameMetadata, ProcessingConfig
export load_fits, save_fits, load_frame_sequence
export accumulate!, finalize_statistics, classify_distribution
export compute_confidence
export fuse_mle, fuse_confidence_weighted, fuse_lucky, fuse_multiscale
export process_stack
export generate_confidence_map

end # module
