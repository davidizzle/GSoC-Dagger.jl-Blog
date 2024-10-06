using VideoIO, ImageView, Plots, ImageFiltering
    camera = VideoIO.opencamera();
    frame = VideoIO.read(camera);
    buf = frame[1:3:end, 1:3:end];
    guidict = ImageView.imshow(buf);
    guidictfilt = ImageView.imshow(buf);
        while !eof(camera)
            VideoIO.read!(camera, frame);
            buf = frame[1:3:end, 1:3:end];
            ImageView.imshow(guidict["gui"]["canvas"], buf);
            out = imfilter(frame, Kernel.gaussian(5));
            out = out[1:3:end, 1:3:end];
            ImageView.imshow(guidictfilt["gui"]["canvas"], out);
            sleep(0.00001);
        end
