function source(stim::T1, τ::Real)
    #prepping AWG for sourcing
    @error_handler SD_AOU_AWGstopMultiple(ins.index, #stopping AWG in case it wasn't stopped before
            nums_to_mask(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)...))
    if τ == 0 #first time point in the sweep; initialize AWG here
        configure_awg(stim)
        new_id = sort(collect(keys(awg.waveforms)))[end] + 1 #load first XY pulse with new ID
    else
        new_id = sort(collect(keys(awg.waveforms)))[end] #load subsequent XY pulses with same ID
    end
    queue_flush.(awg, stim.IQ_XY_chs...) #flushing queue of XY channel to reset delays

    #compute delays in multiples 10 of ns or 5XTLK
    readout_length = 2*stim.readout.duration + stim.decay_delay + stim.end_delay
    readout_length_10ns = div(readout_length, 10)
    decay_delay_10ns = div(stim.decay_delay, 10)
    #NEEDS CHANGE!!!!!!!!!!
    read_marker_delay = stim.readout.duration + stim.decay_delay
    XY_marker_delay = Xpi.duration + τ


    #queueing waveforms
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    queue_waveform(awg, Xpi.envelope, XY_I, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    queue_waveform(awg, Xpi.envelope, XY_Q, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform(awg, readout.I_waveform, read_I, :External, repetitions = 1)
    queue_waveform(awg, readout.Q_waveform, read_Q :External, repetitions = 1)
    queue_waveform(awg, readout.I_waveform, read_I, :Auto, repetitions = 1,
                   delay = decay_delay_10ns)
    queue_waveform(awg, readout.Q_waveform, read_Q, :Auto, repetitions = 1,
                  delay = decay_delay_10ns)

    #Configure Markers
    @error_handler SD_AOU_AWGqueueMarkerConfig(awg.index, XY_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.PXI_trig_num), 1, 1, 1, readout.duration, XY_marker_delay)
    @error_handler SD_AOU_AWGqueueMarkerConfig(awg.index, read_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.PXI_trig_num), 1, 1, 1, readout.duration, read_marker_delay)

    #Start AWGs
    @error_handler SD_AOU_AWGstartMultiple(awg.index,
            nums_to_mask(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)...))
    nothing
end

function source(stim::Rabi, t::Real)
    #prepping AWG for sourcing
    @error_handler SD_AOU_AWGstopMultiple(ins.index, #stopping AWG in case it wasn't stopped before
            nums_to_mask(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)...))
    if t == 0 #first time point in the sweep; initialize AWG here
        configure_awg(stim)
    end
    queue_flush.(awg, stim.IQ_XY_chs...) #flushing queue of XY channel to reset delays

    #compute delays in multiples 10 of ns or 5XTLK
    readout_length = 2*stim.readout.duration + stim.decay_delay + stim.end_delay
    readout_length_10ns = div(readout_length, 10)
    decay_delay_10ns = div(stim.decay_delay, 10)
    #NEEDS CHANGE!!!!!!!!!!
    read_marker_delay = stim.readout.duration + stim.decay_delay
    XY_marker_delay = t

    #making XY pulse and loading it
    XY_pulse = AnalogPulse(stim.IF_freq, readout.sample_rate, t, CosEnvelope)
    XY_wav = XY_pulse.envelope
    if !(XY_wav in values(awg.waveforms))
        load_waveform(awg, XY_wav, new_id, waveform_type = :Analog32) #new_id defined earlier in function
    end

    #queueing waveforms
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    queue_waveform(awg, XY_pulse.envelope, XY_I, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    queue_waveform(awg, XY_pulse.envelope, XY_Q, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform(awg, readout.I_waveform, read_I, :External, repetitions = 1)
    queue_waveform(awg, readout.Q_waveform, read_Q :External, repetitions = 1)
    queue_waveform(awg, readout.I_waveform, read_I, :Auto, repetitions = 1,
                   delay = decay_delay_10ns)
    queue_waveform(awg, readout.Q_waveform, read_Q, :Auto, repetitions = 1,
                  delay = decay_delay_10ns)

    #Configure Markers
    @error_handler SD_AOU_AWGqueueMarkerConfig(awg.index, XY_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.PXI_trig_num), 1, 1, 1, readout.duration, XY_marker_delay)
    @error_handler SD_AOU_AWGqueueMarkerConfig(awg.index, read_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.PXI_trig_num), 1, 1, 1, readout.duration, read_marker_delay)

    #Start AWGs
    @error_handler SD_AOU_AWGstartMultiple(awg.index,
            nums_to_mask(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)...))
    nothing
end

function source(stim::Ramsey, τ::Real)
    #prepping AWG for sourcing
    @error_handler SD_AOU_AWGstopMultiple(ins.index, #stopping AWG in case it wasn't stopped before
            nums_to_mask(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)...))
    if τ == 0 #first time point in the sweep; initialize AWG here
        configure_awg(stim)
    end
    queue_flush.(awg, stim.IQ_XY_chs...) #flushing queue of XY channel to reset delays

    #compute delays in multiples 10 of ns or 5XTLK
    readout_length = 2*stim.readout.duration + stim.decay_delay + stim.end_delay
    readout_length_10ns = div(readout_length, 10)
    decay_delay_10ns = div(stim.decay_delay, 10)
    #NEEDS CHANGE!!!!!!!!!!
    read_marker_delay = stim.readout.duration + stim.decay_delay
    XY_marker_delay = 2*X_half_pi.duration + τ


    #queueing waveforms
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    queue_waveform(awg, X_half_pi.envelope, XY_I, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    queue_waveform(awg, X_half_pi.envelope, XY_Q, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    queue_waveform(awg, X_half_pi.envelope, XY_I, :Auto, repetitions = 1,
                            delay = τ)
    queue_waveform(awg, X_half_pi.envelope, XY_Q, :Auto, repetitions = 1,
                            delay = τ)
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform(awg, readout.I_waveform, read_I, :External, repetitions = 1)
    queue_waveform(awg, readout.Q_waveform, read_Q :External, repetitions = 1)
    queue_waveform(awg, readout.I_waveform, read_I, :Auto, repetitions = 1,
                   delay = decay_delay_10ns)
    queue_waveform(awg, readout.Q_waveform, read_Q, :Auto, repetitions = 1,
                  delay = decay_delay_10ns)

    #Configure Markers
    @error_handler SD_AOU_AWGqueueMarkerConfig(awg.index, XY_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.PXI_trig_num), 1, 1, 1, readout.duration, XY_marker_delay)
    @error_handler SD_AOU_AWGqueueMarkerConfig(awg.index, read_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.PXI_trig_num), 1, 1, 1, readout.duration, read_marker_delay)

    #Start AWGs
    @error_handler SD_AOU_AWGstartMultiple(awg.index,
            nums_to_mask(tuple(stim.IQ_XY_chs..., stim.IQ_readout_chs...)...))
    nothing
end
