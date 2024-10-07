using Dagger, Sockets, FFTW, Plots
# ENV["JULIA_DEBUG"] = "Dagger"

function rand_finite()
    sleep(1)
    x = rand(1000)
    println("Generated!")
    # println("Value generated: $x")
    if x[1] < 0.25
        return Dagger.finish_stream(x)
    end
    return x
end

function rand_sinusoids_finite(num_samples, num_signals, sampling_rate)
    draw = rand()

    t = collect(0:1/sampling_rate:(num_samples-1)/sampling_rate)  # Time vector
    signal = zeros(num_samples)  # Initialize the signal

    for _ in 1:num_signals
       frequency = rand(1:500)  # Random frequency between 1 and 10 Hz
       println(frequency); amplitude = rand(1:10)  # Random amplitude between 0 and 1
       signal .+= amplitude * sin.(2 * π * frequency * t)  # Add sinusoidal wave to the signal
    end
    if draw < 0.1
        return Dagger.finish_stream(signal)
    end
    sleep(1/30)
    return signal
end

Dagger.spawn_streaming() do
            ip1 = ip"127.0.0.1"
            port1 = 8001
            port2 = 8002
            natsport = 4222
            x = 1:400
            f_s = 1200
            freq = fftfreq(x[end], f_s)

            s = Dagger.@spawn rand_sinusoids_finite(x[end], 10, f_s)
#            ff = Dagger.@spawn fft(s)
            ff = Dagger.@spawn fft(Dagger.UDP(s; ip=ip1, port=port2))
            f = Dagger.@spawn (ff)->map(abs,ff)
            p = Dagger.@spawn plot(freq, f)
            d1 = Dagger.@spawn display(Dagger.TCP(p; ip=ip1, port=port2))
#            d1 = Dagger.@spawn display(p)

       end

readline()
