using Dagger, VideoIO, Images


# Function to process each frame
function process_frame(frame)
    if frame === nothing
        println("No more frames to process")
        return Dagger.finish_stream(frame)
    end
    return Gray.(frame)  # Convert to grayscale
end

function push_aux(stack, img)
    if img === nothing
        println("Wrapping up...")
        return Dagger.finish_stream(result=stack)
    end
    push!(stack, img)
    return stack
end

function read_vid(video)
    if eof(video)
        println("Finished fetching frames")
        return Dagger.finish_stream(nothing)
    end
    img = VideoIO.read(video)

    return img
end

output_video = "output_Dagger_dogs.mp4"  # Path for the output video filevideo_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam

Dagger.spawn_streaming() do
    global imgout

    imgstack = Vector()
    # Define input and output video file paths
    video_source = "dogs2.mp4"   # Replace with your input video file path

    video = VideoIO.openvideo(video_source)

    img = Dagger.@spawn read_vid(video)
    frame = Dagger.@spawn process_frame(img)
    imgout = Dagger.@spawn push_aux(imgstack, frame)
end

stack = fetch(imgout)
println(typeof(stack))
pop!(stack)
println("Starting conversion...")
VideoIO.save(output_video, stack, framerate=30)

println("Video processing complete!")
