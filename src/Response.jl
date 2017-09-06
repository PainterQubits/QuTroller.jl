mutable struct IQ_FPGAResponse <: Response
    ins::InsDigitizerM3102A
    I_ch::Int #ch for channel
    Q_ch::Int
    trials::Int
end

function measure(IQ_FPGAResponse)
    #clockResetPhase?
    ins = resp.ins
    timeout = 0
    for ch in [resp.I_ch, resp.Q_ch]
        ins[DAQTrigMode, ch] = :Analog
        ins[DAQTrigBehavior] = :Falling
        ins[DAQPointsPerCycle, ch] = 1
        ins[DAQCycles, ch] = 0 #this means infinite cycles--> limiting factor will be DAQpoints
    end
    for ch in [resp.I_ch, resp.Q_ch]
        buffer = Ref{Vector{Int16}} #NEEDS TO BE CHANGED
        @error_handler SD_AIN_DAQbufferAdd(ins.index, ch, buffer, trials) #trials goes in place of DAQpoints in this function
        @error_handler SD_AIN_DAQbufferPoolConfig(ins.index, ch, trials, timeout) #the only thing I am configuring here seems to be timeout
    end
    mask = chs_to_mask(resp.I_ch, resp.Q_ch)
    @error_handler SD_AIN_DAQstartMultiple(ins.index, mask)
    I_data = @error_handler SD_AIN_DAQread(ins.index, resp.I_ch, trials, timeout)
    Q_data = @error_handler SD_AIN_DAQread(ins.index, resp.Q_ch, trials, timeout)
    return
end
