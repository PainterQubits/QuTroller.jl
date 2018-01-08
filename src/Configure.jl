export configure_awgs

"""
        configure_awgs(stim::T1)
        configure_awgs(stim::Rabi)
        configure_awgs(stim::Ramsey)
        configure_awgs(stim::StarkShift)
        configure_awgs(stim::ReadoutReference)

Function to configure AWG channels and load appropriate waveforms prior to
sourcing of Stimulus `QubitCharacterization` or `ReadoutReference` objects.
"""
function configure_awgs end

function configure_awgs_general(stim::QubitCharacterization)
    (rem(round(stim.readoutPulse.duration/1e-9), 10) != 0.0) &&
                        error("Readout pulse length must be in mutiple of 10ns")
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    awg_stop(awgXY, stim.IQ_XY_chs...); awg_stop(awgRead, stim.IQ_readout_chs...)
    awg_stop(awgMarker, stim.markerCh)

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
    awgRead[DCOffset, stim.IQ_readout_chs...] = 0
    awgRead[QueueCycleMode, stim.IQ_readout_chs...] = :Cyclic
    awgRead[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awgRead[TrigSource, stim.IQ_readout_chs...] = stim.PXI_line
    awgRead[TrigBehavior, stim.IQ_readout_chs...] = :Low
    awgRead[TrigSync, stim.IQ_readout_chs...] = :CLK10
    awgRead[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgRead[AngModMode, stim.IQ_readout_chs...] = :Off

    #Configuring marker channel
    awgMarker[OutputMode, stim.markerCh] = :Arbitrary
    awgMarker[Amplitude, stim.markerCh] = 1.5 #arbitrary marker voltage I chose
    awgMarker[DCOffset, stim.markerCh] = 0
    awgMarker[QueueCycleMode, stim.markerCh] = :Cyclic
    awgMarker[QueueSyncMode, stim.markerCh] = :CLK10
    awgMarker[TrigSource, stim.markerCh] = stim.PXI_line
    awgMarker[TrigBehavior, stim.markerCh] = :Low
    awgMarker[TrigSync, stim.markerCh] = :CLK10
    awgMarker[AmpModMode, stim.markerCh] = :Off
    awgMarker[AngModMode, stim.markerCh] = :Off

    #loading readout, marker, and delay pulses
    load_pulse(awgRead, stim.readoutPulse)
    marker_pulse = DCPulse(1.5, stim.readoutPulse.duration, RectEdge, awgMarker[SampleRate],
                           name = "Markers_Voltage=1.5")
    load_pulse(awgMarker, marker_pulse, "Markers_Voltage=1.5")
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
    πPulse = stim.πPulse
    load_pulse(awgXY, πPulse)
    awgXY[AmpModGain, stim.IQ_XY_chs...] = πPulse.amplitude
    awgXY[FGFrequency, stim.IQ_XY_chs...] = πPulse.IF_freq
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgXY.ID,  nums_to_mask(stim.IQ_XY_chs...))  #NOTE! through trial and error, I saw that this command needs to come before setting the phases of the FG
    sleep(0.001)
    awgXY[FGPhase, stim.IQ_XY_chs[1]] = stim.πPulse.IF_phase
    awgXY[FGPhase, stim.IQ_XY_chs[2]] = stim.πPulse.IF_phase - 90 #cos(phi -pi/2) = sin(phi)
    nothing
end

function configure_awgs(stim::Rabi)
    configure_awgs_general(stim)
    awgXY = stim.awgXY
    XYPulse = stim.XYPulse
    awgXY[AmpModGain, stim.IQ_XY_chs...] = XYPulse.amplitude
    awgXY[FGFrequency, stim.IQ_XY_chs...] = XYPulse.IF_freq
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgXY.ID,  nums_to_mask(stim.IQ_XY_chs...))
    sleep(0.001)
    awgXY[FGPhase, stim.IQ_XY_chs[1]] = XYPulse.IF_phase
    awgXY[FGPhase, stim.IQ_XY_chs[2]] = XYPulse.IF_phase - 90 #cos(phi -pi/2) = sin(phi)
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


function configure_awgs(stim::StarkShift)
    #I make a T1 object because these two types have the exact same fields and
    #configuration instructions, they only differ on the source function
    temp_T1 = T1(stim.awgXY, stim.awgRead, stim.awgMarker, stim.πPulse, stim.readoutPulse, stim.ringdown_delay,
                 stim.end_delay, stim.IQ_XY_chs, stim.IQ_readout_chs, stim.markerCh, stim.PXI_line, stim.axisname, stim.axislabel)
    configure_awgs(temp_T1)
    nothing
end

function configure_awgs(stim::CPecho)
    configure_awgs_general(stim)
    awgXY = stim.awgXY
    πPulse = stim.πPulse
    π_2Pulse = stim.π_2Pulse
    load_pulse(awgXY, πPulse)
    load_pulse(awgXY, π_2Pulse)
    awgXY[AmpModGain, stim.IQ_XY_chs...] = πPulse.amplitude
    awgXY[FGFrequency, stim.IQ_XY_chs...] = πPulse.IF_freq
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgXY.ID,  nums_to_mask(stim.IQ_XY_chs...))
    sleep(0.001)
    awgXY[FGPhase, stim.IQ_XY_chs[1]] = stim.πPulse.IF_phase
    awgXY[FGPhase, stim.IQ_XY_chs[2]] = stim.πPulse.IF_phase - 90 #cos(phi -pi/2) = sin(phi)
    nothing
end

function configure_awgs(stim::CPecho_n)
    configure_awgs(stim.CPstim)
end

function configure_awgs(stim::CPecho_τ)
    configure_awgs(stim.CPstim)
end

function configure_awgs(stim::ReadoutReference)
    (rem(round(stim.readoutPulse.duration/1e-9), 10) != 0.0) &&
                        error("Readout pulse length must be in mutiple of 10ns")
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    awg_stop(awgRead, stim.IQ_readout_chs...)
    awg_stop(awgMarker, stim.markerCh)

    #Configuring Readout channels
    awgRead[OutputMode, stim.IQ_readout_chs...] = :Arbitrary
    awgRead[Amplitude,stim.IQ_readout_chs...] = stim.readoutPulse.amplitude
    awgRead[DCOffset, stim.IQ_readout_chs...] = 0
    awgRead[QueueCycleMode, stim.IQ_readout_chs...] = :Cyclic
    awgRead[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awgRead[TrigSource, stim.IQ_readout_chs...] = stim.PXI_line
    awgRead[TrigBehavior, stim.IQ_readout_chs...] = :Low
    awgRead[TrigSync, stim.IQ_readout_chs...] = :CLK10
    awgRead[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgRead[AngModMode, stim.IQ_readout_chs...] = :Off

    #Configuring marker channel
    awgMarker[OutputMode, stim.markerCh] = :Arbitrary
    awgMarker[Amplitude, stim.markerCh] = 1.5 #arbitrary marker voltage I chose
    awgMarker[DCOffset, stim.markerCh] = 0
    awgMarker[QueueCycleMode, stim.markerCh] = :Cyclic
    awgMarker[QueueSyncMode, stim.markerCh] = :CLK10
    awgMarker[TrigSource, stim.markerCh] = stim.PXI_line
    awgMarker[TrigBehavior, stim.markerCh] = :Low
    awgMarker[TrigSync, stim.markerCh] = :CLK10
    awgMarker[AmpModMode, stim.markerCh] = :Off
    awgMarker[AngModMode, stim.markerCh] = :Off

    #loading readout, marker, and delay pulses
    load_pulse(awgRead, stim.readoutPulse)
    marker_pulse = DCPulse(1.5, stim.readoutPulse.duration, RectEdge, awgMarker[SampleRate],
                           name = "Markers_Voltage=1.5")
    load_pulse(awgMarker, marker_pulse, "Markers_Voltage=1.5")
    read_delay_20ns = DelayPulse(20e-9, awgRead[SampleRate], name = "20ns_delay")
    load_pulse(awgRead, read_delay_20ns, "20ns_delay")
    marker_delay_20ns = DelayPulse(20e-9, awgMarker[SampleRate], name = "20ns_delay")
    load_pulse(awgMarker, marker_delay_20ns, "20ns_delay")
    nothing
end

function configure_awgs(stim::PiNoPiTesting)
    (rem(round(stim.readoutPulse.duration/1e-9), 10) != 0.0) &&
                        error("Readout pulse length must be in mutiple of 10ns")
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    awg_stop(awgRead, stim.IQ_readout_chs...)
    awg_stop(awgMarker, stim.markerCh)

    #Configuring Readout channels
    awgRead[OutputMode, stim.IQ_readout_chs...] = :Arbitrary
    awgRead[Amplitude,stim.IQ_readout_chs...] = stim.readoutPulse.amplitude
    awgRead[DCOffset, stim.IQ_readout_chs...] = 0
    awgRead[QueueCycleMode, stim.IQ_readout_chs...] = :Cyclic
    awgRead[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awgRead[TrigSource, stim.IQ_readout_chs...] = stim.PXI_line
    awgRead[TrigBehavior, stim.IQ_readout_chs...] = :Low
    awgRead[TrigSync, stim.IQ_readout_chs...] = :CLK10
    awgRead[AmpModMode, stim.IQ_readout_chs...] = :Off
    awgRead[AngModMode, stim.IQ_readout_chs...] = :Off

    #Configuring marker channel
    awgMarker[OutputMode, stim.markerCh] = :Arbitrary
    awgMarker[Amplitude, stim.markerCh] = 1.5 #arbitrary marker voltage I chose
    awgMarker[DCOffset, stim.markerCh] = 0
    awgMarker[QueueCycleMode, stim.markerCh] = :Cyclic
    awgMarker[QueueSyncMode, stim.markerCh] = :CLK10
    awgMarker[TrigSource, stim.markerCh] = stim.PXI_line
    awgMarker[TrigBehavior, stim.markerCh] = :Low
    awgMarker[TrigSync, stim.markerCh] = :CLK10
    awgMarker[AmpModMode, stim.markerCh] = :Off
    awgMarker[AngModMode, stim.markerCh] = :Off

    #loading readout, marker, and delay pulses
    load_pulse(awgRead, stim.readoutPulse)
    marker_pulse = DCPulse(1.5, stim.readoutPulse.duration, RectEdge, awgMarker[SampleRate],
                           name = "Markers_Voltage=1.5")
    load_pulse(awgMarker, marker_pulse, "Markers_Voltage=1.5")
    read_delay_20ns = DelayPulse(20e-9, awgRead[SampleRate], name = "20ns_delay")
    load_pulse(awgRead, read_delay_20ns, "20ns_delay")
    marker_delay_20ns = DelayPulse(20e-9, awgMarker[SampleRate], name = "20ns_delay")
    load_pulse(awgMarker, marker_delay_20ns, "20ns_delay")
    nothing
end
