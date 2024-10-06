using VideoIO, FileIO, ObjectDetector

# Define input and output video file paths
video_source = "dogs1.mp4"   # Replace with your input video file path
output_video = "yolo_dogs1.mp4"  # Path for the output video filevideo_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam

video = VideoIO.openvideo(video_source)

# Load the YOLOv3-tiny model pretrained on COCO, with a batch size of 1
yolomod = YOLO.v3_608_COCO(batch=1, silent=true)
imgstack = Vector()
batch = emptybatch(yolomod)

while !eof(video)
    img = read(video)
        # Run the model on the length-1 batch
    res = yolomod(batch, detectThresh=0.5, overlapThresh=0.8)
    # Prepare the image and add it to the batch
    batch[:, :, :, 1], padding = prepareImage(img, yolomod)
    # Draw boxes around detected objects
    imgBoxes = drawBoxes(img, yolomod, padding, res)

    push!(imgstack, imgBoxes)
end

VideoIO.save(output_video, imgstack, framerate=30)

println("Video processing complete!")
