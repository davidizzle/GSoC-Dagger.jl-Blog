using Dagger, FFTW, Plots, FileIO, LinearAlgebra
# ENV["JULIA_DEBUG"] = "Dagger"

# This function has been edited for displaying purposes
# For example, the below variable is only used to display so many frames
global counter = 0
global n_pulses = 10
global resolution = 30

function generate_target_response(samples, carrier, chirp, wd)
   global n_pulses
   # sleep(1/15)
   
   # Input parameters
   # Sampling rate 3.5 MHz
   f_s = 2.5e6
   light_speed = 299792458
   # AWGN(0,1)
   signal = 1/sqrt(2) * (randn(samples) + 1im*randn(samples))

   if !haskey(task_local_storage(), "pulse") || task_local_storage("pulse") == n_pulses 
      task_local_storage("pulse", 1)
      
      # Target speed
      velocity = rand(-60:60) 
      task_local_storage("target_vel", velocity)

      
      lnt = length(chirp)
      idx = rand(1: (samples-lnt))
      task_local_storage("index", idx)

      signal[idx:idx+lnt-1] = signal[idx:idx+lnt-1] .+ chirp
      return signal
   else
      p = task_local_storage("pulse")
      p += 1
      wd = wd .+ (samples / f_s) * p
      task_local_storage("pulse", p)
      velocity = task_local_storage("target_vel")
      # Pulse length
      lnt = length(chirp)

      # Add doppler shift for every pulse that is not the first one
      doppler_shift = 2 * velocity * carrier / light_speed 
      chirp_doppler = chirp .* exp.(1im * 2 * pi * doppler_shift * wd)
      
      idx = task_local_storage("index")

      signal[idx:idx+lnt-1] = signal[idx:idx+lnt-1] .+ chirp_doppler
      return signal
   end

end

function moving_target_detector(dpc_signal)
   global n_pulses, resolution
   if !haskey(task_local_storage(), "pulse") || task_local_storage("dpc_signal") === nothing
      task_local_storage("pulse", 1)
      task_local_storage("dpc_signal", dpc_signal)
      if !haskey(task_local_storage(), "mtd_signals")
         task_local_storage("mtd_signals", fill(NaN + 1im*NaN, resolution, length(dpc_signal)))
      end
   else
      # Accumulate signal
      dpc_acc = task_local_storage("dpc_signal")
      dpc_acc = hcat(dpc_acc, dpc_signal)
      task_local_storage("dpc_signal", dpc_acc)
      p = task_local_storage("pulse")
      p += 1
      task_local_storage("pulse", p)
   end
   if task_local_storage("pulse") == n_pulses
      # New burst
      task_local_storage("pulse", 0)
      dpc_acc = task_local_storage("dpc_signal")
      # println(typeof(dpc_acc))
      # println(size(dpc_acc))
      # dpc_acc = adjoint(dpc_acc)

      # For graphic purposes, increase frequency grid with zero padding
      dpc_acc = hcat(dpc_acc, zeros(length(dpc_signal), resolution - n_pulses))

      mtd_signals = fft(dpc_acc, 2)
      mtd_signals = adjoint(mtd_signals) / sqrt(n_pulses)
      task_local_storage("mtd_signals", mtd_signals)
      # println(size(mtd_signals))
      
      hw = Int(size(mtd_signals,1)/2)
      # temp = mtd_signals[1:hw/2]
      # mtd_signals[1:hw/2] = mtd_signals[hw/2+1:end]
      # mtd_signals[hw/2+1:end] = mtd_signals[1:hw/2] 

      mtd_signals[1:hw, :], mtd_signals[hw+1:end, :] = mtd_signals[hw+1:end, :], mtd_signals[1:hw, :]

      task_local_storage("dpc_signal", nothing)
   end

   return task_local_storage("mtd_signals")
end

# Using task local storage push_aux_TLS(plt)
function push_aux_TLS(plt)
    global counter
    anim = []
    if counter > 104
        println("Wrapping up...")
        anim = task_local_storage("stack")
        return Dagger.finish_stream(result=anim)
    end
    if !haskey(task_local_storage(), "stack")
        anim = Animation()
        frame(anim, plt)
        task_local_storage("stack", anim)
    else
       anim = task_local_storage("stack")
       frame(anim, plt)
       task_local_storage("stack", anim)
    end
    counter = counter + 1
    println(counter)
    return anim;
end

Dagger.spawn_streaming() do
            global tt
            
            l = @layout [a{.2h}; b{.2h}; c{.5w} d{.5w}]
            # l = @layout [a{.2h};b{.2h};c{.6h}]
            # l = @layout [a{.15h};b{.15h};c{.25h}; d{.35h}]
            samples = 1000
            carrier = 3e9
            BW = 2e6
            f_s = 2.75e6
            
            light_speed = 299792458
            PRF = f_s / samples
            vlim = PRF / 2 / carrier * light_speed / 2
            v = range(-vlim, vlim, length = resolution)
            window_l = convert(Int, floor(samples/10))
            window = range(0, window_l / f_s, length=window_l)
            chirp = 3 * exp.(1im * pi * BW / window[end] * ( window .- window[end] / 2).^2)
            filterm = conj(chirp) ./ norm(chirp, 2)
            padded_filt = vcat(filterm, zeros(samples - window_l))
            padded_filt = padded_filt[end:-1:1]

            t = range(0, samples / f_s, length=samples)
            kmt = light_speed * t / 2 / 1e3

            s = Dagger.@spawn generate_target_response(samples, carrier, chirp, window)
            ff = Dagger.@spawn fft(s)
            filt_fft = Dagger.@spawn fft(padded_filt)
            dpc_f = Dagger.@spawn ff .* filt_fft
            dpc = Dagger.@spawn ifft(dpc_f)
            mtd = Dagger.@spawn moving_target_detector(dpc)
            s_plot = Dagger.@spawn (s) -> map((x) -> 10*log10(abs(x)^2), s)
            p1 = Dagger.@spawn plot(kmt, s_plot, title="Signal", xlabel="Distance [km]", ylabel="SNR [dB]", legend=false, ylim=(-40, 30))
            dpc_plot = Dagger.@spawn (dpc) -> map((x) -> 10*log10(abs(x)^2), dpc)
            p2 = Dagger.@spawn plot(kmt, dpc_plot, title="Pulse Compression", xlabel="Distance [km]", ylabel="SNR [dB]", legend=false, ylim=(-40, 30))
            mtd_plot = Dagger.@spawn (mtd) -> map((x) -> 10*log10(abs(x)^2), mtd)
            # pr = Dagger.@spawn (mtd_plot) -> println(size(mtd_plot))
            p3 = Dagger.@spawn heatmap(kmt, v, mtd_plot, clims=(-10,15), xlabel="Distance [km]", ylabel="Velocities [m/s]", title="Moving Target Detection")
            p4 = Dagger.@spawn surface(kmt, v, mtd_plot, title="Moving Target Detection", xlabel="Distance [km]", ylabel="Velocities [m/s]", zlabel = "SNR [dB]", camera=(45,30))
            # p = Dagger.@spawn plot(p1, p2, p3, layout=l, size = (1200, 800))
            p = Dagger.@spawn plot(p1, p2, p3, p4, layout=l, size = (1920, 1080), left_margin=15Plots.mm, top_margin=10Plots.mm, bottom_margin=15Plots.mm)
            # d1 = Dagger.@spawn display(p)
            tt = Dagger.@spawn push_aux_TLS(p)
            # ts = Dagger.@spawn push_aux_TLS(p4)

       end

output_gif = "Dagger_radar_processing_sur.gif"
anim = fetch(tt)
gif(anim, output_gif, fps=25)
println("Video processing complete!")