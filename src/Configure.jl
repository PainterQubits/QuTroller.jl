export configure_awgs

"""
        configure_awgs(stim::T1)
        configure_awgs(stim::Rabi)
        configure_awgs(stim::Ramsey)

Function to configure AWG channels and load appropriate waveforms prior to
sourcing of Stimulus `QubitCharacterization` objects.
"""
function configure_awgs end

function configure_awgs_general(stim::QubitCharacterization)
    (rem(round(stim.readoutPulse.duration/1e-9), 10) != 0.0) &&
                        error("Readout pulse length must be in mutiple of 10ns")
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    #reseting clocks and resetting phase
    # @KSerror_handler SD_AOU_clockResetPhase(awgXY.ID, symbol_to_keysight(:Falling),
    #                                         stim.PXI_line, 0) #4th input: skew
    # @KSerror_handler SD_AOU_clockResetPhase(awgRead.ID, symbol_to_keysight(:Falling),
    #                                         stim.PXI_line, 0) #4th input: skew
    # @KSerror_handler SD_AOU_clockResetPhase(awgMarker.ID, symbol_to_keysight(:Falling),
    #                                         stim.PXI_line, 0) #4th input: skew
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_channelPhaseReset(awgMarker.ID, stim.markerCh)
    @KSerror_handler SD_Module_PXItriggerWrite(awgXY.ID, stim.PXI_line, 0) #turning line on
    @KSerror_handler SD_Module_PXItriggerWrite(awgXY.ID, stim.PXI_line, 1) #turning line off

    #Configuring XY channels
    awgXY[Amplitude,stim.IQ_XY_chs...] = 0 #turning off generator in case it was already on
    awgXY[OutputMode, stim.IQ_XY_chs...] = :Sinusoidal
    awgXY[DCOffset,stim.IQ_XY_chs...] = 0
    awgXY[QueueCycleMode, stim.IQ_XY_chs...] = :Cyclic
    awgXY[QueueSyncMode, stim.IQ_XY_chs...] = :CLK10
    awgXY[TrigSource, stim.IQ_XY_chs...] = stim.PXI_line
    awgXY[TrigBehavior, stim.IQ_XY_chs...] = :Low
    awgXY[TrigSync, stim.IQ_XY_chs...] = :CLK10
    awgXY[AmpModMode, stim.IQ_XY_chs...] = :AmplitudeMod
    awgXY[AngModMode, stim.IQ_XY_chs...] = :Off

    #Configuring Readout channels
    awgRead[OutputMode, stim.IQ_readout_chs...] = :Arbitrary
    awgRead[Amplitude,stim.IQ_readout_chs...] = stim.readoutPulse.amplitude
    awgRead[DCOffset,stim.IQ_readout_chs...] = 0
    awgRead[QueueCycleMode, stim.IQ_readout_chs...] = :Cyclic
    awgRead[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awgRead[TrigSource, stim.IQ_readout_chs...] = stim.PXI_line
    awgRead[TrigBehavior, stim.IQ_readout_chs...] = :Low
    awgRead[TrigSync, stim.IQ_readout_chs...] = :CLK10
    awgRead[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgRead[AngModMode, stim.IQ_readout_chs...] = :Off

    #Configuring marker channel
    awgMarker[OutputMode, stim.IQ_readout_chs...] = :Arbitrary
    awgMarker[Amplitude,stim.IQ_readout_chs...] = 1 #arbitrary marker voltage I chose
    awgMarker[DCOffset,stim.IQ_readout_chs...] = 0
    awgMarker[QueueCycleMode, stim.IQ_readout_chs...] = :Cyclic
    awgMarker[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awgMarker[TrigSource, stim.IQ_readout_chs...] = stim.PXI_line
    awgMarker[TrigBehavior, stim.IQ_readout_chs...] = :Low
    awgMarker[TrigSync, stim.IQ_readout_chs...] = :CLK10
    awgMarker[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgMarker[AngModMode, stim.IQ_readout_chs...] = :Off

    #loading readout, marker, and delay pulses
    load_pulse(awgRead, stim.readoutPulse)
    marker_pulse = DCPulse(1, stim.readoutPulse.duration, RectEdge, awgMarker[SampleRate],
                           name = "Markers_Voltage=1")
    load_pulse(awgMarker, marker_pulse, "Markers_Voltage=1")
    readoutPulse_delay = DelayPulse(stim.readoutPulse.duration, awgXY[SampleRate], name = "readoutPulse_delay")
    load_pulse(awgXY, readoutPulse_delay, "readoutPulse_delay")
    XY_delay_20ns = DelayPulse(20e-9, awgXY[SampleRate], name = "20ns_delay")
    load_pulse(awgXY, XY_delay_20ns, "20ns_delay")
    read_delay_20ns = DelayPulse(20e-9, awgRead[SampleRate], name = "20ns_delay")
    load_pulse(awgRead, read_delay_20ns, "20ns_delay")
    marker_delay_20ns = DelayPulse(20e-9, awgMarker[SampleRate], name = "20ns_delay")
    load_pulse(awgMarker, marker_delay_20ns, "20ns_delay")
    nothing
end

function configure_awgs(stim::T1)
    configure_awgs_general(stim)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    πPulse = stim.πPulse
    load_pulse(awgXY, πPulse)

    #further configuring XY channels
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    awgXY[AmpModGain, stim.IQ_XY_chs...] = πPulse.amplitude
    awgXY[FGFrequency, stim.IQ_XY_chs...] = πPulse.IF_freq
    awgXY[FGPhase, XY_I] = πPulse.IF_phase
    awgXY[FGPhase, XY_Q] = πPulse.IF_phase - π/2 #cos(phi -pi/2) = sin(phi)
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
    awgXY[FGPhase, XY_Q] = XYPulse.IF_phase - π/2
    nothing
end

function configure_awgs(stim::Ramsey)
    #I make a T1 object because these two types have the exact same fields and
    #configuration instructions, they only differ on the source function
    temp_T1 = T1(stim.awgXY, stim.awgRead, stim.awgMarker, stim.π_2Pulse, stim.readoutPulse, stim.decay_delay,
                 stim.end_delay, stim.IQ_XY_chs, stim.IQ_readout_chs, stim.markerCh, stim.PXI_line, stim.axisname, stim.axislabel)
    configure_awgs(temp_T1)
    nothing
end
