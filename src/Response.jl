export IQTrigResponse
export Avg_IQResponse
export Avg_IQResponse2
export IQPXIResponse

mutable struct IQTrigResponse <: Response
    #digitizer
    dig::InsDigitizerM3102A
    I_ch::Int #ch for channel
    Q_ch::Int
    #data acquisition
    daq_cycles::Int
    points_per_cycle::Int
    delay::Int
    trig_source::Any
    control_line::Int
    #processing
    freq::Float64

    IQTrigResponse(dig, I_ch, Q_ch, daq_cycles, points_per_cycle, delay, trig_source,
                    freq) = new(dig, I_ch, Q_ch, daq_cycles, points_per_cycle, delay,
                                trig_source, PXI_LINE, freq)

    IQTrigResponse(dig, I_ch, Q_ch, daq_cycles, points_per_cycle, delay, trig_source,
                    control_line, freq) = new(dig, I_ch, Q_ch, daq_cycles,
                    points_per_cycle, delay, trig_source, control_line, freq)
end

function measure(resp::IQTrigResponse)
        #getting digitizer ready
    dig = resp.dig
    ch1 = resp.I_ch
    ch2 = resp.Q_ch
    control_line = resp.control_line
    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 1)
    daq_points = resp.points_per_cycle * resp.daq_cycles
    @KSerror_handler SD_AIN_triggerIOconfig(dig.ID, 1)
    for ch in [ch1, ch2]
        dig[DAQTrigMode, ch] = :External
        dig[ExternalTrigBehavior, ch] = :Rising
        dig[ExternalTrigSource, ch] = resp.trig_source
        dig[DAQPointsPerCycle, ch] = resp.points_per_cycle
        dig[DAQCycles, ch] = resp.daq_cycles
        dig[DAQTrigDelay, ch] = resp.delay
    end

    #acquiring data
    daq_start(dig, ch1, ch2)
    sleep(0.001)
    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 0)
    all_I_data = daq_read(dig, ch1, daq_points, 1)
    all_I_data = all_I_data * (dig[FullScale, ch1])/2^15
    all_Q_data = daq_read(dig, ch2, daq_points, 1)
    all_Q_data = all_Q_data * (dig[FullScale, ch2])/2^15
    @KSerror_handler SD_Module_PXItriggerWrite(dig.ID, control_line, 1)

    #processing data
    num_samples = resp.points_per_cycle
    num_trials = resp.daq_cycles
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

mutable struct Avg_IQResponse <: Response
    respIQ::Response
end

function measure(resp::Avg_IQResponse)
    all_IQ = measure(resp.respIQ)::Array{Complex{Float32},1}
    return AxisArray([mean(all_IQ[1:2:end]), mean(all_IQ[2:2:end])], Axis{:pulse}([:pi, :nopi]))
end

mutable struct Avg_IQResponse2 <: Response
    respIQ::Response
end

function measure(resp::Avg_IQResponse2)
    all_IQ = measure(resp.respIQ)::Array{Complex{Float32},1}
    return AxisArray([mean(all_IQ[1:2:end])], Axis{:pulse}([:pi]))
end
