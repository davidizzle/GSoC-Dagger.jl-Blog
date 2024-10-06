# This is an exmaple script to showcase Dagger stream working with VideoIO.jl

using Dagger, VideoIO, ImageView, ImageFiltering

function read_frame(camera)
    frame = read(camera);
    sleep(2);
    yield();
    return frame;
end

Dagger.spawn_streaming() do
    global p1, frame
    cam = VideoIO.opencamera();
    fr = VideoIO.read(cam);
    buf = fr;
    guidict = ImageView.imshow(buf);
    # guidictfilt = ImageView.imshow(buf);
    sleep(1);

    frame = Dagger.@spawn read_frame(cam)
#    print = Dagger.@spawn println(frame)
#    p1 = Dagger.@spawn ImageView.imshow(guidict["gui"]["canvas"], frame);
    p1 = Dagger.@spawn ImageView.imshow(frame);
#    d = Dagger.@spawn display(p1)
end
# fetch(frame)
readline();
