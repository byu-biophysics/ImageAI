using FileIO 
using JLD2
using ImageContrastAdjustment
using ImageView
using Images
using ImageFiltering
using PlotlyJS
using Plots

""" Subsample array by a factors which are powers of 2 greater than or equal to 1. """
function downsample(array, factors::AbstractVector)
    if length(factors) != ndims(array)
        throw(
            ErrorException("Each element of factors should correspond to an axis of the array.")
        )
    end
    for factor in factors
        if !ispow2(factor) || factor < 1
            throw(ErrorException("$factor is not a power of 2 greater than or equal to 2."))
        end
    end

    indices = [firstindex(i_range):factor:lastindex(i_range)
                for (i_range, factor) in zip(axes(array), factors)]
    return array[indices...]
end

function find_edges(file, downsample_rate)
    seg_data = downsample(load_object(segmentation),[downsample_rate,downsample_rate,downsample_rate])
    

    # Compute the gradient in each direction
    gradient_x = imgradients(seg_data, KernelFactors.ando3, "replicate")[1]
    gradient_y = imgradients(seg_data, KernelFactors.ando3, "replicate")[2]
    gradient_z = imgradients(seg_data, KernelFactors.ando3, "replicate")[3]

    gradient_magnitude = sqrt.(gradient_x.^2 + gradient_y.^2 + gradient_z.^2)

    x_size = floor(Int,size(gradient_x)[1])
    y_size = floor(Int,size(gradient_y)[2])
    z_size = floor(Int,size(gradient_z)[3])


    threshold = 0.5
    edges = gradient_magnitude .> threshold
    # Prepare the 3D codordinates
    gradx = range(-x_size/2,x_size/2,length=x_size)
    grady = range(-y_size/2,y_size/2,length=y_size)
    gradz = range(-z_size/2,z_size/2,length=z_size)

    X,Y,Z = mgrid(gradx, grady, gradz)
    # Prepare the value array (intensity or values at each point)
    values = edges 

    grad_vol = volume(
        x=X[:],
        y=Y[:],
        z=Z[:],
        value=values[:],
        isomin=0.1,
        isomax=0.8,
        opacity=0.1, # needs to be small to see through all surfaces
        surface_count=17, # needs to be a large number for good volume rendering
    )


    plotly()
    PlotlyJS.plot(grad_vol)
end

#Load in data
file = "/Users/mward19/Documents/Segmentation/segment-bacteria/experiments/sample_data/run_6076.jld2"
segmentation = "/Users/mward19/Documents/Segmentation/segment-bacteria/experiments/sample_data/filled_seg_6074.jld2"
# tom_data = downsample(load_object(file),[2,8,8])

find_edges(segmentation, 8)

