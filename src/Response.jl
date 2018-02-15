export RO_IQ_Response
export Avg_IQResponse
export Avg_IQResponse2
export RO_Multi_IQ

mutable struct RO_Multi_IQ <: Response
    trig_source::Any
end

mutable struct RO_IQ_Response <: Response
    trig_source::Any
    freq::Float64
end

function measure(resp::RO_IQ_Response)
    #renaming for convenience
    Qcon = qubitController[]
    dig = Qcon[Digitizer].dig
    ch1 = Qcon[Digitizer].Ich
    ch2 = Qcon[Digitizer].Qch
    control_line = Qcon[PXI]
    points_per_cycle = Int(round(Qcon[ReadoutLength]*dig[SampleRate]))
    daq_cycles = Qcon[Averages]
    delay = Qcon[DigDelay]

    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 1)
    #getting digitizer ready
    daq_flush(dig, ch1, ch2)
    daq_points = points_per_cycle * daq_cycles
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    for ch in [ch1, ch2]
        dig[DAQTrigMode, ch] = :External
        dig[ExternalTrigBehavior, ch] = :Rising
        dig[ExternalTrigSource, ch] = resp.trig_source
        dig[DAQPointsPerCycle, ch] = points_per_cycle
        dig[DAQCycles, ch] = daq_cycles
        dig[DAQTrigDelay, ch] = delay
    end

    #acquiring data
    daq_start(dig, ch1, ch2)
    sleep(0.001)
    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 0)
    try
        all_I_data = daq_read(dig, ch1, daq_points, 1) #1ms timeout
    catch
        println("data isn't coming in. Is the digitizer receiving triggers??")
    end
    all_I_data = all_I_data * (dig[FullScale, ch1])/2^15
    all_Q_data = daq_read(dig, ch2, daq_points, 1) #1ms timeout
    all_Q_data = all_Q_data * (dig[FullScale, ch2])/2^15
    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 1)

    #processing data
    num_samples = points_per_cycle
    num_trials = daq_cycles
    freq = resp.freq
    t = linspace(2e-9, 2e-9*num_samples, num_samples)
    sin_ωt = sin.(2π * freq * t)
    cos_ωt = cos.(2π * freq * t)
    all_IQ = Vector{Complex{Float32}}(num_trials) #initializing the output array
    for j = 1:1:num_trials
        I_data = all_I_data[1+num_samples*(j-1):num_samples*j]
        Q_data = all_Q_data[1+num_samples*(j-1):num_samples*j]
        I = (dot(I_data, cos_ωt) + dot(Q_data, sin_ωt))/num_samples
        Q = (dot(Q_data, cos_ωt) - dot(I_data, sin_ωt))/num_samples
        all_IQ[j] = complex(I,Q)
    end
    return all_IQ::Vector{Complex{Float32}}
end

mutable struct piNopi_IQResponse <: Response
    respIQ::RO_IQ_Response
end

function measure(resp::piNopi_IQResponse)
    all_IQ = measure(resp.respIQ)::Array{Complex{Float32},1}
    return AxisArray([mean(all_IQ[1:2:end]), mean(all_IQ[2:2:end])], Axis{:pulse}([:pi, :nopi]))
end

mutable struct Avg_IQResponse <: Response
    respIQ::RO_IQ_Response
end

function measure(resp::Avg_IQResponse)
    all_IQ = measure(resp.respIQ)::Array{Complex{Float32},1}
    return mean(all_IQ)
end

function measure(resp::RO_Multi_IQ)
    #renaming for convenience
    Qcon = qubitController[]
    dig = Qcon[Digitizer].dig
    ch1 = Qcon[Digitizer].Ich
    ch2 = Qcon[Digitizer].Qch
    control_line = Qcon[PXI]
    points_per_cycle = Int(round(Qcon[ReadoutLength]*dig[SampleRate]))
    daq_cycles = Qcon[Averages]
    delay = Qcon[DigDelay]

    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 1)
    #getting digitizer ready
    daq_flush(dig, ch1, ch2)
    daq_points = points_per_cycle * daq_cycles
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    for ch in [ch1, ch2]
        dig[DAQTrigMode, ch] = :External
        dig[ExternalTrigBehavior, ch] = :Rising
        dig[ExternalTrigSource, ch] = resp.trig_source
        dig[DAQPointsPerCycle, ch] = points_per_cycle
        dig[DAQCycles, ch] = daq_cycles
        dig[DAQTrigDelay, ch] = delay
    end

    #acquiring data
    daq_start(dig, ch1, ch2)
    sleep(0.001)
    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 0)
    try
        all_I_data = daq_read(dig, ch1, daq_points, 1) #1ms timeout
    catch
        println("data isn't coming in. Is the digitizer receiving triggers??")
    end
    all_I_data = all_I_data * (dig[FullScale, ch1])/2^15
    all_Q_data = daq_read(dig, ch2, daq_points, 1) #1ms timeout
    all_Q_data = all_Q_data * (dig[FullScale, ch2])/2^15
    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 1)

    #processing data
    all_freqs_IQ = Vector{Complex{Float32}}(size(Qcon[ReadoutIF])[1])
    for i in range(1, size(Qcon[ReadoutIF])[1])
        freq = Qcon[ReadoutIF][i]
        num_samples = points_per_cycle
        num_trials = daq_cycles
        t = linspace(2e-9, 2e-9*num_samples, num_samples)
        sin_ωt = sin.(2π * freq * t)
        cos_ωt = cos.(2π * freq * t)
        all_IQ = Vector{Complex{Float32}}(num_trials) #initializing the output array
        for j = 1:1:num_trials
            I_data = all_I_data[1+num_samples*(j-1):num_samples*j]
            Q_data = all_Q_data[1+num_samples*(j-1):num_samples*j]
            I = (dot(I_data, cos_ωt) + dot(Q_data, sin_ωt))/num_samples
            Q = (dot(Q_data, cos_ωt) - dot(I_data, sin_ωt))/num_samples
            all_IQ[j] = complex(I,Q)
        end
        all_freqs_IQ[i] = mean(all_IQ)
    end
    return all_freqs_IQ::Vector{Complex{Float32}}
end
