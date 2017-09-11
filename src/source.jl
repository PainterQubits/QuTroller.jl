function source(stim::T1, τ::Real)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    πPulse = stim.πPulse
    readoutPulse = stim.readoutPulse

    #prepping AWG for sourcing
    #stopping AWG in case it wasn't stopped before
    @KSerror_handler SD_AOU_AWGstopMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_AWGstopMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    if τ == 0 #first time point in the sweep; initialize AWG here
        configure_awgs(stim)
    end
    queue_flush.(awgXY, stim.IQ_XY_chs) #flushing queue of XY channel to reset delays

    #compute delays in multiples 10 of ns or 5XTLK
    readout_length = 2*(stim.readout.duration + stim.decay_delay) + τ
    readout_length_10ns = Int(div(readout_length/1e-9, 10))
    decay_delay_10ns = Int(div(stim.decay_delay/1e-9, 10))
    #NEEDS CHANGE!!!!!!!!!!
    read_marker_delay = Int(round((readoutPulse.duration + stim.decay_delay)*sample_rate))
    XY_marker_delay = Int(round((πPulse.duration + τ)*sample_rate))

    #queueing waveforms
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    queue_waveform(awgXY, πPulse.envelope, XY_I, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    queue_waveform(awgXY, πPulse.envelope, XY_Q, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform(awgRead, readout.I_waveform, read_I, :External, repetitions = 1)
    queue_waveform(awgRead, readout.Q_waveform, read_Q, :External, repetitions = 1)
    queue_waveform(awgRead, readout.I_waveform, read_I, :Auto, repetitions = 1,
                   delay = decay_delay_10ns)
    queue_waveform(awgRead, readout.Q_waveform, read_Q, :Auto, repetitions = 1,
                  delay = decay_delay_10ns)

    #Configure Markers
    marker_duration = Int(round(readout.duration/1e-9))
    @KSerror_handler SD_AOU_AWGqueueMarkerConfig(awgXY.ID, XY_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.XY_PXI_marker), 1, 1, 1, marker_duration, XY_marker_delay)
    @KSerror_handler SD_AOU_AWGqueueMarkerConfig(awgRead.ID, read_I, 2, #2--> On WF start after WF delay
        nums_to_mask(stim.XY_PXI_marker), 1, 1, 1, marker_duration, read_marker_delay)

    #Start AWGs
    @KSerror_handler SD_AOU_AWGstartMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_AWGstartMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    nothing
end

function source(stim::Rabi, t::Real)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    πPulse = stim.πPulse
    readoutPulse = stim.readoutPulse

    #prepping AWG for sourcing
    #stopping AWG in case it wasn't stopped before
    @KSerror_handler SD_AOU_AWGstopMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_AWGstopMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    if t == 0 #first time point in the sweep; initialize AWG here
        configure_awgs(stim)
        if size(collect(keys(awgXY.waveforms)))[1] == 0
            new_id = 1
        else
            new_id = sort(collect(keys(awgXY.waveforms)))[end] + 1 #load first XY pulse with new ID
        end
    else
        new_id = sort(collect(keys(awgXY.waveforms)))[end] #load subsequent XY pulses with same ID
    end
    queue_flush.(awgXY, stim.IQ_XY_chs) #flushing queue of XY channel to reset delays

    #compute delays in multiples 10 of ns or 5XTLK
    readout_length = 2*(stim.readout.duration + stim.decay_delay)
    readout_length_10ns = Int(div(readout_length/1e-9, 10))
    decay_delay_10ns = Int(div(stim.decay_delay/1e-9, 10))
    #NEEDS CHANGE!!!!!!!!!!
    read_marker_delay = Int(round((readoutPulse.duration + stim.decay_delay)*sample_rate))
    XY_marker_delay = Int(round(t*sample_rate))

    #complete XYPulse envelope and load it
    sample_rate = awgXY[SampleRate]
    env = make_CosEnvelope(t, CosEnvelope)
    XYPulse.envelope = Waveform(env, "Rabi_XYPulse")
    XYPulse.duration = t
    (XYPulse.envelope in values(awgXY.waveforms)) || load_waveform(awgXY,
                                                    XYPulse.envelope, new_id) #new_id defined earlier in function

    #queueing waveforms
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    queue_waveform(awgXY, XYPulse.envelope, XY_I, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    queue_waveform(awgXY, XYPulse.envelope, XY_Q, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform(awgRead, readout.I_waveform, read_I, :External, repetitions = 1)
    queue_waveform(awgRead, readout.Q_waveform, read_Q, :External, repetitions = 1)
    queue_waveform(awgRead, readout.I_waveform, read_I, :Auto, repetitions = 1,
                   delay = decay_delay_10ns)
    queue_waveform(awgRead, readout.Q_waveform, read_Q, :Auto, repetitions = 1,
                   delay = decay_delay_10ns)

    #Configure Markers
    marker_duration = Int(round(readout.duration/1e-9))
    @KSerror_handler SD_AOU_AWGqueueMarkerConfig(awgXY.ID, XY_I, 2, #2--> On WF start after WF delay
       nums_to_mask(stim.XY_PXI_marker), 1, 1, 1, marker_duration, XY_marker_delay)
    @KSerror_handler SD_AOU_AWGqueueMarkerConfig(awgRead.ID, read_I, 2, #2--> On WF start after WF delay
       nums_to_mask(stim.XY_PXI_marker), 1, 1, 1, marker_duration, read_marker_delay)

    #Start AWGs
    @KSerror_handler SD_AOU_AWGstartMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_AWGstartMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    nothing
end

function source(stim::Ramsey, τ::Real)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    π_2Pulse = stim.π_2Pulse
    readoutPulse = stim.readoutPulse

    #prepping AWG for sourcing
    #stopping AWG in case it wasn't stopped before
    @KSerror_handler SD_AOU_AWGstopMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_AWGstopMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    if τ == 0 #first time point in the sweep; initialize AWG here
        configure_awgs(stim)
    end
    queue_flush.(awgXY, stim.IQ_XY_chs) #flushing queue of XY channel to reset delays

    #compute delays in multiples 10 of ns or 5XTLK
    readout_length = 2*(stim.readout.duration + stim.decay_delay) #readout sequence length
    readout_length_10ns = Int(div(readout_length/1e-9, 10))
    decay_delay_10ns = Int(div(stim.decay_delay/1e-9, 10))
    #NEEDS CHANGE!!!!!!!!!!
    read_marker_delay = Int(round((readoutPulse.duration + stim.decay_delay)*sample_rate))
    XY_marker_delay = Int(round(2*π_2Pulse.duration + τ))


    #queueing waveforms
    XY_I = stim.IQ_XY_chs[1]
    XY_Q = stim.IQ_XY_chs[2]
    queue_waveform(awgXY, π_2Pulse.envelope, XY_I, :Auto, repetitions = 1,
                            delay = readout_length_10ns) #after last waveform in queue, it waits readout_length long for queue to repeat
    queue_waveform(awgXY, π_2Pulse.envelope, XY_Q, :Auto, repetitions = 1,
                            delay = readout_length_10ns)
    queue_waveform(awgXY, π_2Pulse.envelope, XY_I, :Auto, repetitions = 1, delay = τ)
    queue_waveform(awgXY, π_2Pulse.envelope, XY_Q, :Auto, repetitions = 1, delay = τ)
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform(awgRead, readout.I_waveform, read_I, :External, repetitions = 1)
    queue_waveform(awgRead, readout.Q_waveform, read_Q, :External, repetitions = 1)
    queue_waveform(awgRead, readout.I_waveform, read_I, :Auto, repetitions = 1,
                   delay = decay_delay_10ns)
    queue_waveform(awgRead, readout.Q_waveform, read_Q, :Auto, repetitions = 1,
                  delay = decay_delay_10ns)

    #Configure Markers
    marker_duration = Int(round(readout.duration/1e-9))
    @KSerror_handler SD_AOU_AWGqueueMarkerConfig(awgXY.ID, XY_I, 2, #2--> On WF start after WF delay
     nums_to_mask(stim.XY_PXI_marker), 1, 1, 1, marker_duration, XY_marker_delay)
    @KSerror_handler SD_AOU_AWGqueueMarkerConfig(awgRead.ID, read_I, 2, #2--> On WF start after WF delay
     nums_to_mask(stim.XY_PXI_marker), 1, 1, 1, marker_duration, read_marker_delay)

    #Start AWGs
    @KSerror_handler SD_AOU_AWGstartMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_AWGstartMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    nothing
end
