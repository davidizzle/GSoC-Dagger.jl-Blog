using Dagger, ColorTypes, VideoIO, Images, ImageFiltering

# Function to process each frame and turn it grayscale
function process_frame(frame)
    if frame === nothing
        println("No more frames to process")
        return Dagger.finish_stream(frame)
    end
    return Gray.(frame)  # Convert to grayscale
end

# Function to filter each frame
function filter_frame(frame)
    if frame === nothing
        println("No more frames to process")
        return Dagger.finish_stream(frame)
    end
    # out = imfilter(frame, Kernel.gaussian(5))  # Blur out
    out = imfilter(frame, Kernel.Laplacian())  # Cool filter?
    out = abs.(out)
    out = map(clamp01nan, out)
    return convert(Matrix{RGB{N0f8}}, out)
end

function push_aux_TLS(img)
    stack = []
    if img === nothing
        println("Wrapping up...")
        stack = task_local_storage("stack")
        return Dagger.finish_stream(result=stack)
    end
    if !haskey(task_local_storage(), "stack")
        task_local_storage("stack", [img])
    else
       stack = task_local_storage("stack")
       push!(stack, img)
       println(length(stack))
       task_local_storage("stack", stack)
    end
    return stack;
end

function read_vid(video)
    if eof(video)
        println("Finished fetching frames")
        return Dagger.finish_stream(nothing)
    end
    img = VideoIO.read(video)

    return img
end

output_video = "./Dagger_out/output_Dagger_filtered_dogs1.mp4"  # Path for the output video filevideo_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam

Dagger.spawn_streaming() do
    global imgarray

    # imgstack = Vector()
    # Define input and output video file paths
    video_source = "dogs1.mp4"   # Replace with your input video file path

    video = VideoIO.openvideo(video_source)

    img = Dagger.@spawn read_vid(video)
    frame = Dagger.@spawn filter_frame(img)
    # imgout = Dagger.@spawn push_aux(imgstack, frame)
    imgarray = Dagger.@spawn push_aux_TLS(frame)
end

stack = fetch(imgarray)
println(typeof(stack))
pop!(stack)
println("Starting conversion...")
encoder_options = (crf=23, preset="ultrafast")
VideoIO.save(output_video, stack, framerate=30, encoder_options=encoder_options)

println("Video processing complete!")
