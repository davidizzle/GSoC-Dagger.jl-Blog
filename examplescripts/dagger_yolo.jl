ENV["JULIA_DEBUG"] = "Dagger"
ENV["JULIA_DAGGER_DEBUG"] = "execute,stream,stream_push,stream_pull"
using Dagger, VideoIO, FileIO, ObjectDetector

global counter = 0

function read_vid(video)
    global counter
    if counter > 4 || eof(video)
        println("Finished fetching frames")
        return Dagger.finish_stream(result=nothing)
    end
    counter = counter + 1
    img = VideoIO.read(video)
    println("Video read!")
    return img
end

function push_aux(stack, img)
    println("pushing img")
    if img === nothing
        println("Wrapping up...")
        return Dagger.finish_stream(result=stack)
    end
    push!(stack, img)
    println(length(stack))
    return stack
end

function prepare_imgaux(img, yolomod)
    println("prepare img")
    if img === nothing
        println("Nothing to prepare")
        return Dagger.finish_stream(result=nothing)
    end
    var, out = prepareImage(img, yolomod)
    return out
end

function drawBoxesAux(img, yolomod, padding, res)
    println("drawin boxes")
    if img === nothing
        println("Almost through...")
        return Dagger.finish_stream(result=nothing)
    end
    return drawBoxes(img, yolomod, padding, res)
end

# Define input and output video file paths
video_source = "cars.mp4"   # Replace with your input video file path
output_video = "yolo_dagger_cars.mp4"  # Path for the output video filevideo_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam

Dagger.spawn_streaming() do
    global stack
    video = VideoIO.openvideo(video_source)
    # Load the YOLOv3-tiny model pretrained on COCO, with a batch size of 1
    yolomod = YOLO.v3_608_COCO(batch=1, silent=true)
    imgstack = Vector()
    batch = emptybatch(yolomod)

    img = Dagger.@spawn read_vid(video)
    res = Dagger.@spawn yolomod(batch, detectThresh=0.5, overlapThresh=0.8)
    padding = Dagger.@spawn prepare_imgaux(img, yolomod)
    imgBoxes = Dagger.@spawn drawBoxesAux(img, yolomod, padding, res)
    stack = Dagger.@spawn push_aux(imgstack, imgBoxes)
end

imgout = fetch(stack)
println("Fetched output, initiating file save...")
encoder_options = (crf=23, preset="ultrafast")
VideoIO.save(output_video, stack, framerate=30, encoder_options=encoder_options)

println("Video processing complete!")
