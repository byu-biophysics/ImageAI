using PyCall
using JLD2
using FileIO
using Infiltrator
# Import SimpleITK and mrcfile via PyCall
sitk = pyimport("SimpleITK")
mrcfile = pyimport("mrcfile")

function convert_image_to_julia(input_file::String)
    # Determine the file extension
    input_dir = dirname(input_file)
    file_ext = splitext(input_file)[2]
    file_name = basename(input_file)
    # Read the image file based on the extension
    if file_ext == ".mha"
        # Read the .mha file using SimpleITK (via PyCall)
        image = sitk.ReadImage(input_file)
        numpy_array = sitk.GetArrayFromImage(image)
        output_file = replace(file_name, ".mha" => ".jld2")
        @infiltrate
    elseif file_ext == ".mrc"
        # Read the .mrc file using mrcfile (via PyCall)
        mrc = mrcfile.open(input_file, permissive=true)
        numpy_array = mrc.data
        output_file = replace(file_name, ".mrc" => ".jld2")
        @infiltrate
        mrc.close()
    else
        println("Unsupported file format: $file_ext")
        return
    end
    
    output_path = joinpath(input_dir, output_file)
    # Convert the image to a Julia array
    julia_array = convert(Array{Float64}, numpy_array)  # Adjust the data type as needed

    # Strip off the extension and set the output path
    

    # Save the Julia array to a .jld2 file
    JLD2.save(output_path, "data", julia_array)
    println("Julia array saved to $output_path")
end

# Usage
if length(ARGS) != 1
    println("Usage: julia script.jl <input_file.{mha,mrc}>")
    exit(1)
end

input_file = ARGS[1]
convert_image_to_julia(input_file)
