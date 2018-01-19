export configure_awgs

function RO_Marker_config(stim::Stimulus)
    Qcon = qubitController[]
    (rem(round(Qcon[ReadoutPulse].duration/1e-9), 10) != 0.0) &&
                        error("Readout pulse duration(padded or otherwise) must be in mutiple of 10ns")
    awgRead = Qcon[RO].awg
    awgMarker = Qcon[Marker].awg
    IQ_readout_chs = (Qcon[RO].Ich, Qcon[RO].Qch)
    markerCh = Qcon[Marker].ch
    awg_stop(awgRead, IQ_readout_chs...); awg_stop(awgMarker, markerCh)

    #Configuring Readout channels
    awgRead[OutputMode, IQ_readout_chs...] = :Arbitrary
    awgRead[Amplitude,IQ_readout_chs...] = Qcon[ReadoutAmplitude]
    awgRead[DCOffset, IQ_readout_chs...] = 0
    awgRead[QueueCycleMode, IQ_readout_chs...] = :Cyclic
    awgRead[QueueSyncMode, IQ_readout_chs...] = :CLK10
    awgRead[TrigSource, IQ_readout_chs...] = Qcon[PXI]
    awgRead[TrigBehavior, IQ_readout_chs...] = :Low
    awgRead[TrigSync, IQ_readout_chs...] = :CLK10
    awgRead[AmpModMode, IQ_readout_chs...] = :Off
    awgRead[AngModMode, IQ_readout_chs...] = :Off

    #Configuring marker channel
    awgMarker[OutputMode, markerCh] = :Arbitrary
    awgMarker[Amplitude, markerCh] = 1.5 #arbitrary marker needed for digitizer Trig Port
    awgMarker[DCOffset, markerCh] = 0
    awgMarker[QueueCycleMode, markerCh] = :Cyclic
    awgMarker[QueueSyncMode, markerCh] = :CLK10
    awgMarker[TrigSource, markerCh] = Qcon[PXI]
    awgMarker[TrigBehavior, markerCh] = :Low
    awgMarker[TrigSync, markerCh] = :CLK10
    awgMarker[AmpModMode, markerCh] = :Off
    awgMarker[AngModMode, markerCh] = :Off
    nothing
end

"""
        configure_awgs(stim::T1)
        configure_awgs(stim::Rabi)
        configure_awgs(stim::Ramsey)
        configure_awgs(stim::StarkShift)
        configure_awgs(stim::CPecho)
        configure_awgs(stim::CPecho_n)
        configure_awgs(stim::CPecho_τ)
        configure_awgs(stim::ReadoutReference)

Function to configure AWG channels to proper settings prior to sourcing of
Stimulus `QubitCharacterization` or `ReadoutReference` objects.
"""
function configure_awgs end

function single_qubitANDpulse_config(stim::QubitCharacterization)
    RO_Marker_config(stim)
    Qcon = qubitController[]
    awgXY = stim.q.awg
    IQ_XY_chs = (stim.q.Ich, stim.q.Qch)
    awg_stop(awgXY, IQ_XY_chs...)

    #Configuring XY channels
    awgXY[Amplitude,IQ_XY_chs...] = 0 #turning off generator in case it was already on
    awgXY[OutputMode, IQ_XY_chs...] = :Sinusoidal
    awgXY[DCOffset,IQ_XY_chs...] = 0
    awgXY[QueueCycleMode, IQ_XY_chs...] = :Cyclic
    awgXY[QueueSyncMode, IQ_XY_chs...] = :CLK10
    awgXY[TrigSource, IQ_XY_chs...] = Qcon[PXI]
    awgXY[TrigBehavior, IQ_XY_chs...] = :Low
    awgXY[TrigSync, IQ_XY_chs...] = :CLK10
    awgXY[AmpModMode, IQ_XY_chs...] = :AmplitudeMod
    awgXY[AngModMode, IQ_XY_chs...] = :Off
    if typeof(get_XYPulse(stim)) == AnalogPulse
        IF_phase = get_XYPulse(stim).IF_phase
    else
        IF_phase = 0
    @KSerror_handler SD_AOU_channelPhaseResetMultiple(awgXY.ID,  nums_to_mask(IQ_XY_chs...))
    sleep(0.001)
    awgXY[FGPhase, IQ_XY_chs[1]] = IF_phase
    awgXY[FGPhase, IQ_XY_chs[2]] = IF_phase - 90 #cos(phi -pi/2) = sin(phi)
    nothing
end

configure_awgs(stim::Rabi) = single_qubitANDpulse_config(stim)

function configure_awgs(stim::T1)
    single_qubitANDpulse_config(stim)
    load_pulse(stim.q.awg, stim.πPulse)
    nothing
end

function configure_awgs(stim::Ramsey)
    single_qubitANDpulse_config(stim)
    load_pulse(stim.q.awg, stim.π_2Pulse)
    nothing
end

function configure_awgs(stim::StarkShift)
    single_qubitANDpulse_config(stim)
    load_pulse(stim.q.awg, stim.πPulse)
    nothing
end

function configure_awgs(stim::CPecho)
    single_qubitANDpulse_config(stim)
    load_pulse(stim.q.awg, stim.πPulse)
    load_pulse(stim.q.awg, stim.π_2Pulse)
    nothing
end

function configure_awgs(stim::CPecho_n)
    configure_awgs(stim.CPstim)
end

function configure_awgs(stim::CPecho_τ)
    configure_awgs(stim.CPstim)
end

configure_awgs(stim::ReadoutReference) = RO_Marker_config(stim)


get_XYPulse(stim::QubitCharacterization) = getfield(stim, 2)
