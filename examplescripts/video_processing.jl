using VideoIO, FFMPEG, ImageView

video_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam
video = VideoIO.openvideo(video_source)

guidict = ImageView.imshow(VideoIO.read(video));
while !eof(video)
    img = VideoIO.read(video)
    ImageView.imshow(guidict["gui"]["canvas"], img)
    sleep(0.000001)
end

