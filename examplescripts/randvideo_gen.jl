using Random #For generating fake live video data
using Makie, ImageTransformations, Interpolations, Colors, FixedPointNumbers
using GLMakie
nframes = 500
previewscalefactor = 0.2

img = rand(UInt8,1536,2048) #Raw image
scene = Scene(resolution = (size(img,2),size(img,1)),colormap=Reverse(:Greys)) #Reverse colormap to match normal greyscale image representation 

preview_size = (round(Int,size(img,1)*previewscalefactor), round(Int,size(img,2)*previewscalefactor))
#Lower resolution preview, with efficient downsampling
buff = zeros(N0f8, preview_size[1],preview_size[2])
itp = interpolate!(reinterpret(N0f8, img), BSpline(Linear()))
#Set up Makie scene for preview
hmap = heatmap!(scene, buff)
display(scene)

#Test dummy image capture with preview
t = @elapsed for i = 1:nframes
    rand!(img)     # aquire new data into raw image array
    ImageTransformations.imresize!(buff, itp)
    hmap[1] = buff
    yield()
end
println("Video generation & live preview at ",previewscalefactor," scale: ",round(nframes/t,digits=1)," FPS")
