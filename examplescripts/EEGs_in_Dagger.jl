using ContinuousWavelets, Dagger, Random, Plots, LinearAlgebra
# ENV["JULIA_DEBUG"] = "Dagger"

function generate_eeg_signal(n, sampling_rate)
    println("Generated!")
    time = range(0, n / sampling_rate, length=n)
    # Delta brain waves (1-4 Hz)
    delta_wave = sin.(2 * pi * rand(1:4) * time)

    # Theta brain waves (4-8 Hz)
    theta_wave = sin.(2 * pi * rand(4:8) * time)

    # Alpha brain waves (8-12 Hz)
    alpha_wave = sin.(2 * pi * rand(8:12) * time)

    # Beta brain waves (12-30 Hz)
    beta_wave = sin.(2 * pi * rand(12:30) * time)

    # Sum of waves plus random noise
    eeg_signal_sample = delta_wave .+ theta_wave .+ alpha_wave .+ beta_wave .+ 0.1*randn(n)

    # 30 fps
    sleep(1/10)

    return eeg_signal_sample
end

Dagger.spawn_streaming() do
    f_s = 1000  # 1 kHz Sampling rate
    window_size = 2047  # Samples per window
    c = wavelet(Morlet(π), β=2)
    freqs = getMeanFreq(computeWavelets(window_size, c)[1])
    freqs[1] = 0

    # Only zoom in on relevant frequencies
    # freq_limit = 50
    # freqs_filtered_idx = findall(freqs .<= freq_limit)  # Get indices where frequencies are <= 50 Hz
    # freqs_filtered = freqs[freqs_filtered_idx]          # Filter frequencies

    signal = Vector{Float64}()
    time = Vector{Float64}()
    l = @layout [a{.3h};b{.7h}]
    # Incremental time for the current window
    tw = (0:1/f_s:(window_size-1)/f_s)

    # Generate EEG signal for this time window
    s = Dagger.@spawn generate_eeg_signal(window_size, f_s)
    # eeg = Dagger.@spawn append!(signal, s)
    p1 = Dagger.@spawn plot(s, legend=false, title="EEG", xticks=false)
    result = Dagger.@spawn cwt(s, c)
    interim1 = Dagger.@spawn (result) -> map(x -> abs(x)^2, result)
    res = Dagger.@spawn (interim1) -> map(x -> log(x), interim1)
    res2 = Dagger.@spawn adjoint(res)
    p2 = Dagger.@spawn heatmap(tw, freqs, res2, xlabel= "time (s)", ylabel="frequency (Hz)", colorbar=false, c=cgrad(:viridis, scale=:log10))

    # Steps to only look at frequencies from 0 to 50
    # interim2 = Dagger.@spawn (interim1) -> map(x -> log(x), interim1)
    # fcp = Dagger.@spawn zip(freqs, eachcol(interim2))
    # filt_pairs = Dagger.@spawn filter(x -> x[1] <= freq_limit, fcp)
    # res_filt = Dagger.@spawn map( x -> x[2], filt_pairs)
    # res_filt = Dagger.@spawn hcat(res_filt...)
    # p2 = Dagger.@spawn heatmap(freqs_filtered, tw, res_filt, ylabel= "time (s)", xlabel="frequency (Hz)", colorbar=false, c=cgrad(:viridis, scale=:log10))

    p = Dagger.@spawn plot(p1,p2, layout=l)
    # p = Dagger.@spawn plot(p1)
    d = Dagger.@spawn display(p)
end

readline()
