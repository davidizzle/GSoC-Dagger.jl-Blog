using Dagger, VideoIO, FFMPEG, ImageView

function dispvideo(img, guidict)
    ImageView.imshow(guidict["gui"]["canvas"], img)
    sleep(0.001)
end

Dagger.spawn_streaming() do
    video_source = "cars.mp4"  # Replace with your video file path or use "0" for webcam
    video = VideoIO.openvideo(video_source)

    guidict = ImageView.imshow(VideoIO.read(video));
    img = Dagger.@spawn VideoIO.read(video)
    p1 = Dagger.@spawn dispvideo(img, guidict)
end
