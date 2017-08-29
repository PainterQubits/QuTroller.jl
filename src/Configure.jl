function configure_awg(stim::T1)
    awg = stim.awg

    #Configuring Xpi channels
    Xpi_I = stim.IQ_Xpi_chs[1]
    Xpi_Q = stim.IQ_Xpi_chs[2]
    awg[WaveformShape, stim.IQ_Xpi_chs...] = :Sinusoidal
    awg[FGFrequency, stim.IQ_Xpi_chs...] = Xpi.IF_freq
    awg[FGPhase, Xpi_I] = 0
    awg[FGPhase, Xpi_Q] = π/2
    awg[WaveAmplitude,stim.IQ_Xpi_chs...] = 0
    awg[DCOffset,stim.IQ_Xpi_chs...] = 0
    awg[QueueCycleMode, stim.IQ_Xpi_chs...] = :Cyclic
    awg[QueueSyncMode, stim.IQ_Xpi_chs...] = :CLKPXI
    awg[TrigSource, stim.IQ_Xpi_chs...] = :Auto

    #Configuring Readout channels
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    awg[WaveformShape, stim.IQ_readout_chs...] = :Arbitrary
    awg[QueueCycleMode, stim.IQ_readout_chs...] = :Cyclic
    awg[QueueSyncMode, stim.IQ_readout_chs...] = :CLKPXI
    awg[TrigBehavior, stim.IQ_readout_chs...] = :Falling
    awg[TrigSource, stim.IQ_readout_chs...] = XY_PXI_marker

    #checking to see if pulse waveforms were loaded; if not, we load them here
    biggest_id = sort(collect(keys(awg.waveforms)))[end]
    Xpi_wav = stim.Xpi.envelope.waveform
    read_wav = stim.readout.waveform
    if !(Xpi_wav in values(awg.waveforms))
        load_waveform(awg, Xpi_wav, biggest_id+1)
        biggest_id = biggest_id+1
    end
    read_wav in values(awg.waveforms) || load_waveform(awg, read_wav, biggest_id+1,
                                                       waveform_type = :Digital)
    nothing
end
