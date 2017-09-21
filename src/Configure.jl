function configure_awgs_general(stim::QubitCharacterization)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    #flushing queues, reseting clocks, resetting phase
    queue_flush.(awgXY, stim.IQ_XY_chs)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    @KSerror_handler SD_AOU_clockResetPhase(awgXY.ID, symbols_to_keysight(:Falling), 1, 0) #third input: PXI line, 4th input: skew
    @KSerror_handler SD_Module_PXItriggerWrite(awgXY.ID, 1, 0) #turning line 1 on
    @KSerror_handler SD_Module_PXItriggerWrite(awgXY.ID, 1, 1) #turning line 1 off
    @KSerror_handler SD_AOU_clockResetPhase(awgRead.ID, symbols_to_keysight(:Falling), 1, 0) #third input: PXI line, 4th input: skew
    @KSerror_handler SD_Module_PXItriggerWrite(awgRead.ID, 1, 0) #turning line 1 on
    @KSerror_handler SD_Module_PXItriggerWrite(awgRead.ID, 1, 1) #turning line 1 off
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...)) 

    #Configuring XY channels
    awgXY[Amplitude,stim.IQ_XY_chs...] = 0 #turning off generator in case it was already on
    awgXY[OutputMode, stim.IQ_XY_chs...] = :Sinusoidal
    awgXY[DCOffset,stim.IQ_XY_chs...] = 0
    awgXY[QueueCycleMode, stim.IQ_XY_chs...] = :OneShot
    awgXY[QueueSyncMode, stim.IQ_XY_chs...] = :CLK10
    awgXY[AmpModMode, stim.IQ_XY_chs...] = :AmplitudeMod
    awgXY[AngModMode, stim.IQ_XY_chs...] = :Off

    #Configuring Readout channels
    awgRead[OutputMode, stim.IQ_readout_chs...] = :Arbitrary
    awgRead[Amplitude,stim.IQ_readout_chs...] = stim.readoutPulse.amplitude #loaded waveforms are normalized, this sets their actual amplitude
    awgRead[DCOffset,stim.IQ_readout_chs...] = 0 #still can set DCoffset to arbitrary waves
    awgRead[QueueCycleMode, stim.IQ_readout_chs...] = :OneShot
    awgRead[QueueSyncMode, stim.IQ_readout_chs...] = :CLKsys
    awgRead[TrigSource, stim.IQ_readout_chs...] = stim.XY_PXI_marker
    awgRead[TrigBehavior, stim.IQ_readout_chs...] = :Falling
    awgRead[TrigSync, stim.IQ_readout_chs...] = :CLKsys
    awgRead[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgRead[AngModMode, stim.IQ_readout_chs...] = :Off

    #load readout waveforms into awgRead if not already loaded
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    if size(collect(keys(awgRead.waveforms)))[1] == 0
        new_id = 1
    else
        new_id = sort(collect(keys(awgRead.waveforms)))[end] + 1
    end
    read_I_wav = stim.readoutPulse.I_waveform
    read_Q_wav = stim.readoutPulse.Q_waveform
    if !(read_I_wav in values(awgRead.waveforms))
        load_waveform(awgRead, read_I_wav, new_id)
        new_id = new_id + 1
    end
    (read_Q_wav in values(awgRead.waveforms)) || load_waveform(awgRead, read_Q_wav, new_id)
    nothing
end

function configure_awgs(stim::T1)
    configure_awgs_general(stim)
    awgXY = stim.awgXY
    πPulse = stim.πPulse

    #further configuring XY channels
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    awgXY[AmpModGain, stim.IQ_XY_chs...] = πPulse.amplitude
    awgXY[FGFrequency, stim.IQ_XY_chs...] = πPulse.IF_freq
    awgXY[FGPhase, XY_I] = πPulse.IF_phase
    awgXY[FGPhase, XY_Q] = πPulse.IF_phase + π/2

    #loading πPulse waveforms
    new_id = sort(collect(keys(awgXY.waveforms)))[end] + 1
    πPulse_env = πPulse.envelope
    (πPulse_env in values(awgXY.waveforms)) || load_waveform(awgXY, πPulse_env, new_id)
    nothing
end

function configure_awgs(stim::Rabi)
    configure_awgs_general(stim)
    awgXY = stim.awgXY
    XYPulse = stim.XYPulse

    #further configuring XY channels
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    awgXY[AmpModGain, stim.IQ_XY_chs...] = XYPulse.amplitude
    awgXY[FGFrequency, stim.IQ_XY_chs...] = XYPulse.IF_freq
    awgXY[FGPhase, XY_I] = XYPulse.IF_phase
    awgXY[FGPhase, XY_Q] = XYPulse.IF_phase + π/2
    nothing
end

function configure_awgs(stim::Ramsey)
    #I make a T1 object because these two types have the exact same fields and
    #configuration instructions, they only differ on the source function
    temp_T1 = T1(stim.awgXY, stim.awgRead, stim.π_2Pulse, stim.readoutPulse, stim.decay_delay,
                 stim.IQ_XY_chs, stim.IQ_readout_chs, stim.XY_PXI_marker, stim.axisname, stim.axislabel)
    configure_awg(temp_T1)
    nothing
end
