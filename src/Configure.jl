function configure_awg_general(stim::QubitCharacterization)
    awg = stim.awg
    #flushing queues, etc
    queue_flush.(awg, collect(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)))
    @error_handler SD_AOU_channelPhaseResetMultiple(awg.index,
            nums_to_mask(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)...))
    #clockResetPhase?

    #Configuring XY channels
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    awg[WaveAmplitude,stim.IQ_XY_chs...] = 0
    awg[WaveformShape, stim.IQ_XY_chs...] = :Sinusoidal
    awg[DCOffset,stim.IQ_XY_chs...] = 0
    awg[QueueCycleMode, stim.IQ_XY_chs...] = :Cyclic
    awg[QueueSyncMode, stim.IQ_XY_chs...] = :CLK10
    awg[TrigSource, stim.IQ_XY_chs...] = :Auto
    awg[AmpModMode, stim.IQ_XY_chs...] = :AmplitudeMod


    #Configuring Readout channels
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    awg[WaveAmplitude,stim.IQ_XY_chs...] = 0 #turning off function generator in case it was already on
    awg[WaveformShape, stim.IQ_readout_chs...] = :Arbitrary
    awg[QueueCycleMode, stim.IQ_readout_chs...] = :Cyclic
    awg[QueueSyncMode, stim.IQ_readout_chs...] = :CLK10
    awg[TrigBehavior, stim.IQ_readout_chs...] = :Falling
    awg[TrigSource, stim.IQ_readout_chs...] = stim.XY_PXI_marker

    #checking to see if readout waveforms were loaded; if not, we load them here
    try
        biggest_id = sort(collect(keys(awg.waveforms)))[end]
    catch
        biggest_id = 0
    end
    read_I_wav = stim.readout.I_waveform
    read_Q_wav = stim.readout.Q_waveform
    if !(read_I_wav in values(awg.waveforms))
        load_waveform(awg, read_I_wav, biggest_id+1, waveform_type = :Analog16)
        biggest_id = biggest_id+1
    end
    read_Q_wav in values(awg.waveforms) || load_waveform(awg, read_Q_wav, biggest_id+1,
                                                       waveform_type = :Analog16)
    nothing
end

function configure_awg(stim::T1)
    awg = stim.awg
    configure_awg_general(stim)
    try
        awg[AmpModGain, stim.IQ_XY_chs...] = stim.Xpi.amplitude
    catch
        println("Did you set the pulse amplitude?")
    end
    #further configuring XY channels
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    awg[FGFrequency, stim.IQ_XY_chs...] = stim.Xpi.IF_freq
    awg[FGPhase, XY_I] = stim.Xpi.IF_phase
    awg[FGPhase, XY_Q] = stim.Xpi.IF_phase + π/2


    #loading Xpi waveforms
    biggest_id = sort(collect(keys(awg.waveforms)))[end]
    Xpi_wav = stim.Xpi.envelope
    if !(Xpi_wav in values(awg.waveforms))
        load_waveform(awg, Xpi_wav, biggest_id+1, waveform_type = :Analog16)
    end
    nothing
end

function configure_awg(stim::Rabi)
    awg = stim.awg
    configure_awg_general(stim)
    #further configuring XY channels
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    awg[FGFrequency, stim.IQ_XY_chs...] = stim.XY_IF_feq
    awg[FGPhase, XY_I] = 0
    awg[FGPhase, XY_Q] = π/2
    awg[AmpModGain, stim.IQ_XY_chs...] = stim.XY_amplitude
    nothing
end

function configure_awg(stim::Ramsey)
    #I make a T1 object because these two types have the exact same fields and
    #configuration instructions, they only differ on the source function
    temp_T1 = T1(stim.awg, stim.X_half_pi, stim.readout, stim.XY_PXI_marker, stim.decay_delay,
      stim.end_delay, IQ_XY_chs = stim.IQ_XY_chs, IQ_readout_chs = stim.IQ_readout_chs)
    configure_awg(temp_T1)
    nothing
end
