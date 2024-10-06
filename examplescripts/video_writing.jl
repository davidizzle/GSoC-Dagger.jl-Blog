using VideoIO, Images

# Define input and output video file paths
video_source = "dogs1.mp4"   # Replace with your input video file path
output_video = "output_dogs1.mp4"  # Path for the output video filevideo_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam

video = VideoIO.openvideo(video_source)

# Function to process each frame
function process_frame(frame)
    return Gray.(frame)  # Convert to grayscale
end

imgstack = Vector()

while !eof(video)
    img = read(video)
    frame = process_frame(img)
    push!(imgstack, frame)
end
println("now saving...")
VideoIO.save(output_video, imgstack, framerate=30)

println("Video processing complete!")
