using Dagger, Sockets, FFTW, Plots, VideoIO
# ENV["JULIA_DEBUG"] = "Dagger"

# This function has been edited for displaying purposes
# For example, the below variable is only used to display so many frames
global counter = 0

function rand_sinusoids(num_samples, num_signals, sampling_rate)
    t = collect(0:1/sampling_rate:(num_samples-1)/sampling_rate)  # Time vector
    signal = zeros(num_samples)  # Initialize the signal

    for _ in 1:num_signals
       frequency = rand(1:500)  # Random frequency between 1 and 10 Hz
    #    println(frequency); 
       amplitude = rand(1:10)  # Random amplitude between 0 and 1
       signal .+= amplitude * sin.(2 * π * frequency * t)  # Add sinusoidal wave to the signal
    end

    sleep(1/15)
    return signal
end

# Using task local storage
function push_aux_TLS(plt)
    global counter
    anim = []
    if counter > 15
        println("Wrapping up...")
        anim = task_local_storage("stack")
        # gif(anim, "Dagger_fft.gif")
        # println("Video processing complete!")
        return Dagger.finish_stream(result=anim)
    end
    if !haskey(task_local_storage(), "stack")
        anim = Animation()
        frame(anim, plt)
        task_local_storage("stack", anim)
    else
       anim = task_local_storage("stack")
    #    push!(stack, plt)
       frame(anim, plt)
    #    println(length(anim))
       task_local_storage("stack", anim)
    end
    counter = counter + 1
    println(counter)
    return anim;
end

Dagger.spawn_streaming() do
            global t
            # ip1 = ip"127.0.0.1"
            # port1 = 8001
            # port2 = 8002
            # natsport = 4222
            x = 1:400
            f_s = 1200
            freq = fftfreq(x[end], f_s)
            t = collect(0:1/f_s:(x[end]-1)/f_s)
            l = @layout [a{.3h};b{.7h}]

            s = Dagger.@spawn rand_sinusoids(x[end], 10, f_s)
            ff = Dagger.@spawn fft(s)
#            ff = Dagger.@spawn fft(Dagger.UDP(s; ip=ip1, port=port2))
            f = Dagger.@spawn (ff)->map(abs,ff)
            p1 = Dagger.@spawn plot(t, s, title="Time discrete signal", xlabel="Time (s)", legend=false)
            p2 = Dagger.@spawn plot(freq, f, title="FFT of signal", xlabel="Frequency (Hz)", legend=false)
            p = Dagger.@spawn plot(p1, p2, layout=l)
#            d1 = Dagger.@spawn display(Dagger.TCP(p; ip=ip1, port=port2))
            d1 = Dagger.@spawn display(p)
            t = Dagger.@spawn push_aux_TLS(p)

       end

output_gif = "Dagger_fft.gif"
anim = fetch(t)
gif(anim, output_gif)
println("Video processing complete!")