using FFMPEG, Colors, VideoIO, Images, ImageMagick

# Define input and output video file paths
video_source = "cars.mp4"   # Replace with your input video file path
output_video = "output_cars.gif"  # Path for the output video filevideo_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam

video = VideoIO.openvideo(video_source)
# io = FFMPEG.open(output_video, "w")

# Function to process each frame
function process_frame(frame)
    return Gray.(frame)  # Convert to grayscale
end

global imgst = []
global first_frame = true

while !eof(video)
    img = read(video)
    frame = process_frame(img)
    # frame_uint8 = collect(channelview(frame))
    # FFMPEG.write(io, frame_uint8)
    # frame = map(clamp01nan, img)
    #push!(imgstack, frame)
    global imgst, first_frame
    if first_frame
        imgst = frame
        first_frame = false
    else
        imgst = cat(imgst, frame, dims=3)
    end
end
println("now saving...")
# save(output_video, imgstack, fps=30)
save(output_video, imgst, fps=30)
# FFMPEG.close(io)
println("Video processing complete!")
