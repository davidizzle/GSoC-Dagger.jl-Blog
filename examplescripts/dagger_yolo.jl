# ENV["JULIA_DEBUG"] = "Dagger"
# ENV["JULIA_DAGGER_DEBUG"] = "execute,stream,stream_push,stream_pull"
using Dagger, VideoIO, FileIO, ObjectDetector

global counter = 0

function read_vid(video)
    if eof(video)
        println("Finished fetching frames")
        return Dagger.finish_stream(result=nothing)
    end
    img = VideoIO.read(video)
    println("Video read!")
    return img
end

function push_aux_TLS(img)
    stack = []
    global counter
    if counter > 10 || img === nothing
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
       counter = counter + 1
    end
    return stack;
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

function prepare_imgaux_b(img, yolomod)
    println("prepare img")
    if img === nothing
        println("Nothing to prepare")
        return Dagger.finish_stream(result=nothing)
    end
    var, out = prepareImage(img, yolomod)
    return var
end

function drawBoxesAux(img, yolomod, padding, res)
    println("drawin boxes")
    if img === nothing
        println("Almost through...")
        return Dagger.finish_stream(result=nothing)
    end
    return drawBoxes(img, yolomod, padding, res)
end

function yolomodAux(batch, aux)
    if aux !== nothing
        batch[:,:,:,1] = aux
    end

    return yolomod(batch, detectThresh=0.5, overlapThresh=0.8)
end

# Define input and output video file paths
video_source = "cats1.mp4"   # Replace with your input video file path
output_video = "yolo_dagger_cats1.mp4"  # Path for the output video filevideo_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam

Dagger.spawn_streaming() do
    global stack
    video = VideoIO.openvideo(video_source)
    # Load the YOLOv3-tiny model pretrained on COCO, with a batch size of 1
    yolomod = YOLO.v3_608_COCO(batch=1, silent=true)
    imgstack = Vector()
    batch = emptybatch(yolomod)

    img = Dagger.@spawn read_vid(video)
    res = Dagger.@spawn yolomodAux(batch, b)
    b = Dagger.@spawn prepare_imgaux_b(img, yolomod)
    padding = Dagger.@spawn prepare_imgaux(img, yolomod)
    imgBoxes = Dagger.@spawn drawBoxesAux(img, yolomod, padding, res)
    stack = Dagger.@spawn push_aux_TLS(imgBoxes)
end

imgout = fetch(stack)
println("Fetched output, initiating file save...")
encoder_options = (crf=23, preset="ultrafast")
VideoIO.save(output_video, imgout, framerate=30, encoder_options=encoder_options)

println("Video processing complete!")
