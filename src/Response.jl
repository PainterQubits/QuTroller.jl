mutable struct IQ_FPGAResponse <: Response
    dig::InsDigitizerM3102A
    I_ch::Int #ch for channel
    Q_ch::Int
    trials::Int
end

function measure(resp::IQ_FPGAResponse)
    #clockResetPhase?
    dig = resp.dig
    timeout = 0
    for ch in [resp.I_ch, resp.Q_ch]
        dig[DAQTrigMode, ch] = :Analog
        dig[AnalogTrigBehavior, ch] = :FallingAnalog
        dig[AnalogTrigThreshold, ch] = 0.2 #Might need to change, this is value of PXI trigger voltage
        dig[DAQPointsPerCycle, ch] = 1
        dig[DAQCycles, ch] = trials
    end

    daq_start(dig, resp.I_ch, resp.Q_ch)
    while (daq_counter(dig, resp.I_ch) < trials || daq_counter(dig, resp.Q_ch) < trials)
        sleep(0.001) #change
    end
    I_data = daq_read(dig.ID, resp.I_ch, trials, timeout)
    Q_data = daq_read(dig.ID, resp.Q_ch, trials, timeout)
    return
end
