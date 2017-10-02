function source(stim::T1, τ::Real)
    #renaming for convinience
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    πPulse = stim.πPulse
    readoutPulse = stim.readoutPulse

    #computing delays
    decay_num_100ns = Int(div(stim.decay_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    println()
    end_num_100ns = Int(div(stim.end_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 6  #channels 1 and 3 on awg in slot 3 are somewhat unsynced, this is a fudge factor--> might depend on whatever awgs and whatever channels
    read_T1_delay = Waveform(make_Delay(τ + πPulse.duration, awgRead[SampleRate]), "read_T1_delay")
    marker_T1_delay = Waveform(make_Delay(τ + πPulse.duration, awgMarker[SampleRate]), "marker_T1_delay")
    τ_delay = Waveform(make_Delay(τ, awgXY[SampleRate]), "τ_delay")
    load_waveform(awgXY, τ_delay, make_wav_id(awgXY) ) #make_wav_id - 1 gives the last id in this case
    load_waveform(awgRead, read_T1_delay, make_wav_id(awgRead) )
    load_waveform(awgMarker, marker_T1_delay, make_wav_id(awgMarker) )
    readoutPulse_delay_id = -1 #initializing this number
    for key in keys(awgXY.waveforms)
        if awgXY.waveforms[key].name == "readoutPulse_delay"
            readoutPulse_delay_id = key
            break
        end
    end
    println("hi")

    #prepping AWG for sourcing: stopping AWG in case it wasn't stopped before, flushing
    #queue to reset it, setting the PXI_line to off
    @KSerror_handler SD_AOU_AWGstopMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_AWGstopMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_AWGstop(awgMarker.ID, stim.markerCh)
    SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 1)
    queue_flush.(awgXY, stim.IQ_XY_chs)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    queue_flush(awgMarker, stim.markerCh)

    #awgXY queueing
    queue_waveform.(awgXY, πPulse.envelope, stim.IQ_XY_chs, :External)
    queue_waveform.(awgXY, τ_delay, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, readoutPulse_delay_id, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, DELAY_ID, stim.IQ_XY_chs, :Auto, repetitions = decay_num_100ns)
    queue_waveform.(awgXY, readoutPulse_delay_id, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, DELAY_ID, stim.IQ_XY_chs, :Auto, repetitions = end_num_100ns)

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgRead, read_T1_delay, stim.IQ_readout_chs, :External, delay = read_fudge)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead, DELAY_ID, stim.IQ_readout_chs, :Auto, repetitions = decay_num_100ns)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead, DELAY_ID, stim.IQ_readout_chs, :Auto, repetitions = end_num_100ns-Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform.(awgMarker, marker_T1_delay, stim.markerCh, :External)
    queue_waveform(awgMarker, MARKER_PULSE_ID, stim.markerCh, :Auto)
    queue_waveform(awgMarker, DELAY_ID, stim.markerCh, :Auto, repetitions = decay_num_100ns)
    queue_waveform(awgMarker, MARKER_PULSE_ID, stim.markerCh, :Auto)
    queue_waveform.(awgMarker, DELAY_ID, stim.markerCh, :Auto, repetitions = end_num_100ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgXY, stim.IQ_XY_chs...)
    awg_start(awgMarker, stim.markerCh) #this starts releasing markers, which triggers other AWGs
    sleep(0.001)
    SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 0)
    nothing
end

function source(stim::Rabi, t::Real, trials::Integer)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    XYPulse = stim.XYPulse
    readoutPulse = stim.readoutPulse
    XY_delay_10ns = Int(div((t + 1e-9)/1e-9, 10))
    decay_delay_10ns = Int(div((stim.decay_delay + 1e-9)/1e-9, 10)) #in units of 10ns
    read_fudge = 6

    #prepping AWG for sourcing: stopping AWG in case it wasn't stopped before, flushing
    #queue to reset it, setting the PXI_line to off
    @KSerror_handler SD_AOU_AWGstopMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_AWGstopMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_AWGstop(awgMarker.ID, stim.markerCh)
    SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 1)
    queue_flush.(awgXY, stim.IQ_XY_chs)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    queue_flush(awgMarker, stim.markerCh)

    #complete XYPulse envelope and load it
    sample_rate = awgXY[SampleRate]
    XYPulse.duration = t
    env = make_CosEnvelope(t, sample_rate)
    XYPulse.envelope = Waveform(env, "Rabi_XYPulse")
    load_waveform(awgXY, XYPulse.envelope, make_wav_id(awgXY)) #new_id defined earlier in function

    #queueing waveforms
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgXY, XYPulse.envelope, stim.IQ_XY_chs, :External)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :External, delay = XY_delay_10ns + read_fudge)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :External, delay = XY_delay_10ns + read_fudge)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto, delay = decay_delay_10ns)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto, delay = decay_delay_10ns)
    queue_waveform(awgMarker, MARKER_PULSE_ID, stim.markerCh, :External, delay = XY_delay_10ns)
    queue_waveform(awgMarker, MARKER_PULSE_ID, stim.markerCh, :Auto, delay = decay_delay_10ns)

    #Start AWGs
    sleep(0.001)
    for i=1:trials
        awg_start(awgRead, stim.IQ_readout_chs...)
        awg_start(awgXY, stim.IQ_XY_chs...)
        awg_start(awgMarker, stim.markerCh) #this starts releasing markers, which triggers other AWGs
        SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 0)
        SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 1)
    end
    nothing
end

function source(stim::Ramsey, τ::Real, trials::Integer)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    π_2Pulse = stim.π_2Pulse
    readoutPulse = stim.readoutPulse
    XY_delay_10ns = Int(div((2*π_2Pulse.duration + τ + 1e-9)/1e-9, 10))
    decay_delay_10ns = Int(div((stim.decay_delay + 1e-9)/1e-9, 10)) #in units of 10ns
    τ_delay = Int(div((τ + 1e-9)/1e-9, 10))

    read_fudge = 6


    #prepping AWG for sourcing: stopping AWG in case it wasn't stopped before, flushing
    #queue to reset it, setting the PXI_line to off
    @KSerror_handler SD_AOU_AWGstopMultiple(awgXY.ID, nums_to_mask(stim.IQ_XY_chs...))
    @KSerror_handler SD_AOU_AWGstopMultiple(awgRead.ID, nums_to_mask(stim.IQ_readout_chs...))
    @KSerror_handler SD_AOU_AWGstop(awgMarker.ID, stim.markerCh)
    SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 1)
    queue_flush.(awgXY, stim.IQ_XY_chs)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    queue_flush(awgMarker, stim.markerCh)

    #queueing waveforms
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgXY, π_2Pulse.envelope, stim.IQ_XY_chs, :External)
    queue_waveform.(awgXY, π_2Pulse.envelope, stim.IQ_XY_chs, :Auto, delay = τ_delay)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :External, delay = XY_delay_10ns + read_fudge)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :External, delay = XY_delay_10ns + read_fudge)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto, delay = decay_delay_10ns)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto, delay = decay_delay_10ns)
    queue_waveform(awgMarker, MARKER_PULSE_ID, stim.markerCh, :External, delay = XY_delay_10ns)
    queue_waveform(awgMarker, MARKER_PULSE_ID, stim.markerCh, :Auto, delay = decay_delay_10ns)

    #Start AWGs
    sleep(0.001)
    for i=1:trials
        awg_start(awgRead, stim.IQ_readout_chs...)
        awg_start(awgXY, stim.IQ_XY_chs...)
        awg_start(awgMarker, stim.markerCh) #this starts releasing markers, which triggers other AWGs
        SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 0)
        SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 1)
    end
    nothing
end
