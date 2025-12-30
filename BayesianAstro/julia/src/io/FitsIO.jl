"""
FITS file I/O operations for astronomical image data.
"""
module FitsIO

using FITSIO
using ..BayesianAstro: FrameMetadata, ImageStack

export load_fits, save_fits, load_frame_sequence, get_fits_metadata

"""
    load_fits(filepath::String) -> Matrix{Float32}

Load a FITS file and return the image data as a Float32 matrix.
Handles both 2D images and 3D cubes (returns first plane).
"""
function load_fits(filepath::String)::Matrix{Float32}
    f = FITS(filepath, "r")
    try
        data = read(f[1])
        
        # Handle different dimensionalities
        if ndims(data) == 2
            return Float32.(data)
        elseif ndims(data) == 3
            # Return first channel/plane
            return Float32.(data[:, :, 1])
        else
            error("Unsupported FITS dimensionality: $(ndims(data))")
        end
    finally
        close(f)
    end
end

"""
    load_fits_cube(filepath::String) -> Array{Float32, 3}

Load a FITS file containing a 3D data cube.
"""
function load_fits_cube(filepath::String)::Array{Float32, 3}
    f = FITS(filepath, "r")
    try
        data = read(f[1])
        if ndims(data) != 3
            error("Expected 3D FITS cube, got $(ndims(data))D data")
        end
        return Float32.(data)
    finally
        close(f)
    end
end

"""
    save_fits(filepath::String, data::AbstractMatrix; header_cards=Dict())

Save image data to a FITS file with optional header cards.
"""
function save_fits(filepath::String, data::AbstractMatrix; header_cards::Dict{String,Any}=Dict{String,Any}())
    f = FITS(filepath, "w")
    try
        write(f, Float32.(data))
        
        # Add custom header cards
        for (key, value) in header_cards
            write_key(f[1], key, value)
        end
    finally
        close(f)
    end
end

"""
    save_fits(filepath::String, data::AbstractArray{T,3}; header_cards=Dict()) where T

Save 3D data cube to a FITS file.
"""
function save_fits(filepath::String, data::AbstractArray{T,3}; header_cards::Dict{String,Any}=Dict{String,Any}()) where T
    f = FITS(filepath, "w")
    try
        write(f, Float32.(data))
        
        for (key, value) in header_cards
            write_key(f[1], key, value)
        end
    finally
        close(f)
    end
end

"""
    get_fits_metadata(filepath::String) -> FrameMetadata

Extract metadata from FITS header to construct FrameMetadata.
Attempts to read common keywords for FWHM, background, etc.
"""
function get_fits_metadata(filepath::String)::FrameMetadata
    f = FITS(filepath, "r")
    try
        hdr = read_header(f[1])
        
        # Try to extract common metadata keywords
        fwhm = get(hdr, "FWHM", get(hdr, "SEEING", 0.0f0))
        background = get(hdr, "BACKGRND", get(hdr, "SKYLEVEL", 0.0f0))
        noise = get(hdr, "NOISE", get(hdr, "RDNOISE", 0.0f0))
        
        # Try to get timestamp
        timestamp = 0.0
        if haskey(hdr, "DATE-OBS")
            # TODO: Parse DATE-OBS to Unix timestamp
            timestamp = 0.0
        elseif haskey(hdr, "JD")
            # Julian date to Unix timestamp (approximate)
            timestamp = (hdr["JD"] - 2440587.5) * 86400.0
        end
        
        return FrameMetadata(
            filepath;
            fwhm=Float32(fwhm),
            background=Float32(background),
            noise=Float32(noise),
            weight=1.0f0,
            timestamp=timestamp
        )
    finally
        close(f)
    end
end

"""
    load_frame_sequence(filepaths::Vector{String}; extract_metadata=true) -> ImageStack

Load a sequence of FITS files into an ImageStack.

# Arguments
- `filepaths`: Vector of paths to FITS files
- `extract_metadata`: Whether to parse FITS headers for frame metadata
"""
function load_frame_sequence(filepaths::Vector{String}; extract_metadata::Bool=true)::ImageStack{Float32}
    @assert length(filepaths) > 0 "Must provide at least one file"
    
    frames = Matrix{Float32}[]
    metadata = FrameMetadata[]
    
    for (i, filepath) in enumerate(filepaths)
        @info "Loading frame $i/$(length(filepaths)): $(basename(filepath))"
        
        frame = load_fits(filepath)
        push!(frames, frame)
        
        if extract_metadata
            meta = get_fits_metadata(filepath)
        else
            meta = FrameMetadata(filepath)
        end
        push!(metadata, meta)
    end
    
    # Validate all frames have same dimensions
    ref_size = size(frames[1])
    for (i, frame) in enumerate(frames)
        if size(frame) != ref_size
            error("Frame $i has different dimensions: $(size(frame)) vs $ref_size")
        end
    end
    
    return ImageStack(frames, metadata)
end

"""
    find_fits_files(directory::String; pattern=r"\\.fits?\$"i) -> Vector{String}

Find all FITS files in a directory matching the given pattern.
"""
function find_fits_files(directory::String; pattern::Regex=r"\.fits?$"i)::Vector{String}
    files = String[]
    for entry in readdir(directory; join=true)
        if isfile(entry) && occursin(pattern, entry)
            push!(files, entry)
        end
    end
    return sort(files)
end

end # module FitsIO
