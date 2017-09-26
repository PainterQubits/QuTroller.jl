function configure_awgs_general(stim::QubitCharacterization)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    #reseting clocks and resetting phase
    @KSerror_handler SD_AOU_clockResetPhase(awgXY.ID, symbols_to_keysight(:Falling),
                                            stim.PXI_line, 0) #4th input: skew
    @KSerror_handler SD_AOU_clockResetPhase(awgRead.ID, symbols_to_keysight(:Falling),
                                            stim.PXI_line, 0) #4th input: skew
    @KSerror_handler SD_AOU_clockResetPhase(awgMarker.ID, symbols_to_keysight(:Falling),
                                            stim.PXI_line, 0) #4th input: skew
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_channelPhaseReset(awgMarker.ID, stim.markerCh)
    @KSerror_handler SD_Module_PXItriggerWrite(awgXY.ID, stim.PXI_line, 0) #turning line on
    @KSerror_handler SD_Module_PXItriggerWrite(awgXY.ID, stim.PXI_line, 1) #turning line off

    #Configuring XY channels
    awgXY[Amplitude,stim.IQ_XY_chs...] = 0 #turning off generator in case it was already on
    awgXY[OutputMode, stim.IQ_XY_chs...] = :Sinusoidal
    awgXY[DCOffset,stim.IQ_XY_chs...] = 0
    awgXY[QueueCycleMode, stim.IQ_XY_chs...] = :OneShot
    awgXY[QueueSyncMode, stim.IQ_XY_chs...] = :CLK10
    awgXY[TrigSource, stim.IQ_XY_chs...] = stim.PXI_line
    awgXY[TrigBehavior, stim.IQ_XY_chs...] = :Falling
    awgXY[TrigSync, stim.IQ_XY_chs...] = :CLKsys
    awgXY[AmpModMode, stim.IQ_XY_chs...] = :AmplitudeMod
    awgXY[AngModMode, stim.IQ_XY_chs...] = :Off

    #Configuring Readout channels
    awgRead[OutputMode, stim.IQ_readout_chs...] = :Arbitrary
    awgRead[Amplitude,stim.IQ_readout_chs...] = stim.readoutPulse.amplitude
    awgRead[DCOffset,stim.IQ_readout_chs...] = 0
    awgRead[QueueCycleMode, stim.IQ_readout_chs...] = :OneShot
    awgRead[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awgRead[TrigSource, stim.IQ_readout_chs...] = stim.PXI_line
    awgRead[TrigBehavior, stim.IQ_readout_chs...] = :Falling
    awgRead[TrigSync, stim.IQ_readout_chs...] = :CLKsys
    awgRead[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgRead[AngModMode, stim.IQ_readout_chs...] = :Off

    #Configuring marker channel
    awgMarker[OutputMode, stim.IQ_readout_chs...] = :Arbitrary
    awgMarker[Amplitude,stim.IQ_readout_chs...] = 1
    awgMarker[DCOffset,stim.IQ_readout_chs...] = 0
    awgMarker[QueueCycleMode, stim.IQ_readout_chs...] = :OneShot
    awgMarker[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awgMarker[TrigSource, stim.IQ_readout_chs...] = stim.PXI_line
    awgMarker[TrigBehavior, stim.IQ_readout_chs...] = :Falling
    awgMarker[TrigSync, stim.IQ_readout_chs...] = :CLKsys
    awgMarker[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgMarker[AngModMode, stim.IQ_readout_chs...] = :Off

    #load readout waveforms into awgRead if not already loaded
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    read_I_wav = stim.readoutPulse.I_waveform
    read_Q_wav = stim.readoutPulse.Q_waveform
    (read_I_wav in values(awgRead.waveforms)) || load_waveform(awgRead, read_Q_wav,
                                                               make_wav_id(awgRead))
    (read_Q_wav in values(awgRead.waveforms)) || load_waveform(awgRead, read_Q_wav,
                                                               make_wav_id(awgRead))

    #load marker pulse
    sample_rate = awgMarker[SampleRate]
    offset = make_RectEnvelope(100e9, sample_rate)
    offset_wav = Waveform(square, "VoltageOffset=1")
    (offset_wav in values(awgMarker.waveforms)) || load_waveform(awgMarker, offset_wav,
                                                                 make_wav_id(awgMarker))

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
    πPulse_env = πPulse.envelope
    (πPulse_env in values(awgXY.waveforms)) || load_waveform(awgXY, πPulse_env,
                                                             make_wav_id(awgXY))
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
                 stim.IQ_XY_chs, stim.IQ_readout_chs, stim.PXI_line, stim.axisname, stim.axislabel)
    configure_awg(temp_T1)
    nothing
end
