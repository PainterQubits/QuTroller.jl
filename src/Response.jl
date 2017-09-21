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

    mask = chs_to_mask(resp.I_ch, resp.Q_ch)
    @KSerror_handler SD_AIN_DAQstartMultiple(dig.ID, mask)
    while (SD_AIN_DAQcounterRead(dig.ID, resp.I_ch) < trials || SD_AIN_DAQcounterRead(dig.ID, resp.Q_ch) < trials)
        sleep(0.001) #change
    end
    I_data = @KSerror_handler SD_AIN_DAQread(dig.ID, resp.I_ch, trials, timeout)
    Q_data = @KSerror_handler SD_AIN_DAQread(dig.ID, resp.Q_ch, trials, timeout)
    return
end
