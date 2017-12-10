function source(stim::T1, τ::Real)
    τ<20e-9 && error("τ must be at least 20ns")
    #renaming for convinience
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    πPulse = stim.πPulse
    readoutPulse = stim.readoutPulse

    #computing delays and loading delays
    decay_num_20ns = Int(div(stim.decay_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    end_num_20ns = Int(div(stim.end_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 8  #there is a delay in output when outputting directly from the AWG, vs outputting from FG and amplitude modulating it
    xy_fudge = 2 #there is a delay in output when outputting from the fast AWG compared the slow AWG
    read_T1_delay = Waveform(make_Delay(τ + πPulse.duration, awgRead[SampleRate]), "read_T1_delay")
    marker_T1_delay = Waveform(make_Delay(τ + πPulse.duration, awgMarker[SampleRate]), "marker_T1_delay")
    τ_delay = Waveform(make_Delay(τ, awgXY[SampleRate]), "τ_delay") #note: can't do τ equal zero, that's an edge case
    load_waveform(awgXY, τ_delay, find_wav_id(awgXY, "τ_delay") )
    load_waveform(awgRead, read_T1_delay, find_wav_id(awgRead, "read_T1_delay") )
    load_waveform(awgMarker, marker_T1_delay, find_wav_id(awgMarker, "marker_T1_delay") )
    readoutPulse_delay_id = find_wav_id(awgXY, "readoutPulse_delay")
    markerPulseID = find_wav_id(awgMarker, "Markers_Voltage=1.5")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

    #prepping AWG for sourcing: stopping AWG in case it wasn't stopped before, flushing
    #queue to reset it, setting the PXI_line to off
    awg_stop(awgXY, stim.IQ_XY_chs...)
    awg_stop(awgRead, stim.IQ_readout_chs...)
    awg_stop(awgMarker, stim.markerCh)
    @KSerror_handler SD_Module_PXItriggerWrite(awgMarker.ID, stim.PXI_line, 1) #turning line off in case it was on before
    queue_flush.(awgXY, stim.IQ_XY_chs)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    queue_flush(awgMarker, stim.markerCh)

    #awgXY queueing
    queue_waveform.(awgXY, stim.IQ_XY_chs, πPulse.envelope, :External, delay = xy_fudge)
    queue_waveform.(awgXY, stim.IQ_XY_chs, τ_delay, :Auto)
    queue_waveform.(awgXY, stim.IQ_XY_chs, readoutPulse_delay_id, :Auto)
    queue_waveform.(awgXY, stim.IQ_XY_chs, delay_id_XY,  :Auto, repetitions = decay_num_20ns - Int(xy_fudge/2))
    # queue_waveform.(awgXY, stim.IQ_XY_chs, readoutPulse_delay_id,  :Auto)
    # queue_waveform.(awgXY, stim.IQ_XY_chs, delay_id_XY,  :Auto, repetitions = end_num_20ns - Int(xy_fudge/2))

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgRead, stim.IQ_readout_chs, read_T1_delay, :External, delay = read_fudge)
    queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    queue_waveform.(awgRead, stim.IQ_readout_chs, delay_id_Read, :Auto, repetitions = decay_num_20ns - Int(read_fudge/2))
    # queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    # queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform,  :Auto)
    # queue_waveform.(awgRead, stim.IQ_readout_chs, delay_id_Read,  :Auto, repetitions = end_num_20ns - Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform(awgMarker, stim.markerCh, marker_T1_delay, :External)
    queue_waveform(awgMarker, stim.markerCh, markerPulseID, :Auto)
    queue_waveform(awgMarker, stim.markerCh, delay_id_Marker, :Auto, repetitions = decay_num_20ns)
    # queue_waveform(awgMarker, stim.markerCh, markerPulseID, :Auto)
    # queue_waveform(awgMarker, stim.markerCh, delay_id_Marker, :Auto, repetitions = end_num_20ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgXY, stim.IQ_XY_chs...)
    awg_start(awgMarker, stim.markerCh)
    nothing
end

function source(stim::Rabi, t::Real)
    t<20e-9 && error("t must be at least 20ns")
    (rem(round(t/1e-9), 10) != 0.0) && error("XY pulse length must be in mutiple of 10ns")
    #renaming for convinience
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    XYPulse = stim.XYPulse
    readoutPulse = stim.readoutPulse

    #complete XYPulse envelope and load it
    sample_rate = awgXY[SampleRate]
    XYPulse.duration = t
    env = make_CosEnvelope(t, sample_rate)
    XYPulse.envelope = Waveform(env, "Rabi_XYPulse")
    load_waveform(awgXY, XYPulse.envelope, find_wav_id(awgXY, "Rabi_XYPulse")) #new_id defined earlier in function

    #computing delays and loading delays
    decay_num_20ns = Int(div(stim.decay_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    end_num_20ns = Int(div(stim.end_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 8  #channels 1 and 3 on awg in slot 3 are somewhat unsynced, this is a fudge factor--> might depend on whatever awgs and whatever channels
    xy_fudge = 2 #there is a delay in output when outputting from the fast AWG compared the slow AWG
    read_Rabi_delay = Waveform(make_Delay(t, awgRead[SampleRate]), "read_Rabi_delay")
    marker_Rabi_delay = Waveform(make_Delay(t, awgMarker[SampleRate]), "marker_Rabi_delay")
    load_waveform(awgRead, read_Rabi_delay, find_wav_id(awgRead, "read_Rabi_delay") )
    load_waveform(awgMarker, marker_Rabi_delay, find_wav_id(awgMarker, "marker_Rabi_delay") )
    readoutPulse_delay_id = find_wav_id(awgXY, "readoutPulse_delay")
    markerPulseID = find_wav_id(awgMarker, "Markers_Voltage=1.5")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

    #prepping AWG for sourcing: stopping AWG in case it wasn't stopped before, flushing
    #queue to reset it, setting the PXI_line to off
    awg_stop(awgXY, stim.IQ_XY_chs...)
    awg_stop(awgRead, stim.IQ_readout_chs...)
    awg_stop(awgMarker, stim.markerCh)
    @KSerror_handler SD_Module_PXItriggerWrite(awgMarker.ID, stim.PXI_line, 1)
    queue_flush.(awgXY, stim.IQ_XY_chs)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    queue_flush(awgMarker, stim.markerCh)
    queue_flush(awgMarker, 1)

    #awgXY queueing
    queue_waveform.(awgXY, stim.IQ_XY_chs, XYPulse.envelope, :External, delay = xy_fudge)
    queue_waveform.(awgXY, stim.IQ_XY_chs, readoutPulse_delay_id, :Auto)
    queue_waveform.(awgXY, stim.IQ_XY_chs, delay_id_XY, :Auto, repetitions = decay_num_20ns )
    queue_waveform.(awgXY, stim.IQ_XY_chs, readoutPulse_delay_id, :Auto)
    queue_waveform.(awgXY, stim.IQ_XY_chs, delay_id_XY, :Auto, repetitions = end_num_20ns - Int(xy_fudge/2))

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgRead, stim.IQ_readout_chs, read_Rabi_delay, :External, delay = read_fudge)
    queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    queue_waveform.(awgRead, stim.IQ_readout_chs, delay_id_Read, :Auto, repetitions = decay_num_20ns )
    queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    queue_waveform.(awgRead, stim.IQ_readout_chs, delay_id_Read, :Auto, repetitions = end_num_20ns - Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform.(awgMarker, (stim.markerCh, 1), marker_Rabi_delay, :External)
    queue_waveform.(awgMarker, (stim.markerCh, 1), markerPulseID,  :Auto)
    queue_waveform.(awgMarker, (stim.markerCh, 1), delay_id_Marker, :Auto, repetitions = decay_num_20ns)
    queue_waveform.(awgMarker, (stim.markerCh, 1), markerPulseID, :Auto)
    queue_waveform.(awgMarker, (stim.markerCh, 1), delay_id_Marker, :Auto, repetitions = end_num_20ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgXY, stim.IQ_XY_chs...)
    awg_start(awgMarker, stim.markerCh, 1) #this starts releasing markers, which triggers other AWGs
    nothing
end

function source(stim::Ramsey, τ::Real)
    τ<20e-9 && error("τ must be at least 20ns")
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    π_2Pulse = stim.π_2Pulse
    readoutPulse = stim.readoutPulse

    #computing delays and loading delays
    decay_num_20ns = Int(div(stim.decay_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    end_num_20ns = Int(div(stim.end_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 8  #channels 1 and 3 on awg in slot 3 are somewhat unsynced, this is a fudge factor--> might depend on whatever awgs and whatever channels
    xy_fudge = 2 #there is a delay in output when outputting from the fast AWG compared the slow AWG
    read_Ramsey_delay = Waveform(make_Delay(τ + 2*π_2Pulse.duration, awgRead[SampleRate]), "read_Ramsey_delay")
    marker_Ramsey_delay = Waveform(make_Delay(τ + 2*π_2Pulse.duration, awgMarker[SampleRate]), "marker_Ramsey_delay")
    τ_delay = Waveform(make_Delay(τ, awgXY[SampleRate]), "τ_delay") #note: can't do τ equal zero, that's an edge case
    load_waveform(awgXY, τ_delay, find_wav_id(awgXY, "τ_delay") )
    load_waveform(awgRead, read_Ramsey_delay, find_wav_id(awgRead, "read_Ramsey_delay") )
    load_waveform(awgMarker, marker_Ramsey_delay, find_wav_id(awgMarker, "marker_Ramsey_delay") )
    readoutPulse_delay_id = find_wav_id(awgXY, "readoutPulse_delay")
    markerPulseID = find_wav_id(awgMarker, "Markers_Voltage=1.5")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

    #prepping AWG for sourcing: stopping AWG in case it wasn't stopped before, flushing
    #queue to reset it, setting the PXI_line to off
    awg_stop(awgXY, stim.IQ_XY_chs...)
    awg_stop(awgRead, stim.IQ_readout_chs...)
    awg_stop(awgMarker, stim.markerCh)
    @KSerror_handler SD_Module_PXItriggerWrite(awgMarker.ID, stim.PXI_line, 1)
    queue_flush.(awgXY, stim.IQ_XY_chs)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    queue_flush(awgMarker, stim.markerCh)

    #awgXY queueing
    queue_waveform.(awgXY, stim.IQ_XY_chs, π_2Pulse.envelope, :External, delay = xy_fudge)
    queue_waveform.(awgXY, stim.IQ_XY_chs, τ_delay, :Auto)
    queue_waveform.(awgXY, stim.IQ_XY_chs, π_2Pulse.envelope, :Auto)
    queue_waveform.(awgXY, stim.IQ_XY_chs, readoutPulse_delay_id, :Auto)
    queue_waveform.(awgXY, stim.IQ_XY_chs, delay_id_XY, :Auto, repetitions = decay_num_20ns - Int(xy_fudge/2))
    # queue_waveform.(awgXY, stim.IQ_XY_chs, readoutPulse_delay_id, :Auto)
    # queue_waveform.(awgXY, stim.IQ_XY_chs, delay_id_XY, :Auto, repetitions = end_num_20ns - Int(xy_fudge/2) )

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgRead, stim.IQ_readout_chs, read_Ramsey_delay, :External, delay = read_fudge)
    queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    queue_waveform.(awgRead, stim.IQ_readout_chs, delay_id_Read, :Auto, repetitions = decay_num_20ns -Int(read_fudge/2))
    # queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    # queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    # queue_waveform.(awgRead, stim.IQ_readout_chs, delay_id_Read, :Auto, repetitions = end_num_20ns-Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform(awgMarker, stim.markerCh, marker_Ramsey_delay, :External)
    queue_waveform(awgMarker, stim.markerCh, markerPulseID, :Auto)
    queue_waveform(awgMarker, stim.markerCh, delay_id_Marker, :Auto, repetitions = decay_num_20ns)
    # queue_waveform(awgMarker, stim.markerCh, markerPulseID, :Auto)
    # queue_waveform(awgMarker, stim.markerCh, delay_id_Marker, :Auto, repetitions = end_num_20ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgXY, stim.IQ_XY_chs...)
    awg_start(awgMarker, stim.markerCh)
    nothing
end

function source(stim::ReadoutReference)
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    readoutPulse = stim.readoutPulse

    #computing delays and loading delays
    decay_num_20ns = Int(div(stim.delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 8  #there is a delay in output when outputting directly from the AWG, vs outputting from FG and amplitude modulating it
    markerPulseID = find_wav_id(awgMarker, "Markers_Voltage=1.5")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

    awg_stop(awgRead, stim.IQ_readout_chs...)
    awg_stop(awgMarker, stim.markerCh)
    queue_flush.(awgRead, stim.IQ_readout_chs)
    queue_flush(awgMarker, stim.markerCh)

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    queue_waveform.(awgRead, stim.IQ_readout_chs, delay_id_Read, :Auto, repetitions = decay_num_20ns - Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform(awgMarker, stim.markerCh, markerPulseID, :Auto)
    queue_waveform(awgMarker, stim.markerCh, delay_id_Marker, :Auto, repetitions = decay_num_20ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgMarker, stim.markerCh)
    nothing
end
