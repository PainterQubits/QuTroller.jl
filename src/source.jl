function source(stim::T1, τ::Real)
    #renaming for convinience
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    πPulse = stim.πPulse
    readoutPulse = stim.readoutPulse

    #computing delays and loading delays
    decay_num_20ns = Int(div(stim.decay_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    end_num_20ns = Int(div(stim.end_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 8  #channels 1 and 3 on awg in slot 3 are somewhat unsynced, this is a fudge factor--> might depend on whatever awgs and whatever channels
    read_T1_delay = Waveform(make_Delay(τ + πPulse.duration, awgRead[SampleRate]), "read_T1_delay")
    marker_T1_delay = Waveform(make_Delay(τ + πPulse.duration, awgMarker[SampleRate]), "marker_T1_delay")
    τ_delay = Waveform(make_Delay(τ, awgXY[SampleRate]), "τ_delay") #note: can't do τ equal zero, that's an edge case
    load_waveform(awgXY, τ_delay, find_wav_id(awgXY, "τ_delay") )
    load_waveform(awgRead, read_T1_delay, find_wav_id(awgRead, "read_T1_delay") )
    load_waveform(awgMarker, marker_T1_delay, find_wav_id(awgMarker, "marker_T1_delay") )
    readoutPulse_delay_id = find_wav_id(awgXY, "readoutPulse_delay")
    markerPulseID = find_wav_id(awgMarker, "Markers_Voltage=1")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

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
    queue_waveform.(awgXY, delay_id_XY, stim.IQ_XY_chs, :Auto, repetitions = decay_num_20ns)
    queue_waveform.(awgXY, readoutPulse_delay_id, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, delay_id_XY, stim.IQ_XY_chs, :Auto, repetitions = end_num_20ns)

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgRead, read_T1_delay, stim.IQ_readout_chs, :External, delay = read_fudge)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead,delay_id_Read, stim.IQ_readout_chs, :Auto, repetitions = decay_num_20ns)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead, delay_id_Read, stim.IQ_readout_chs, :Auto, repetitions = end_num_20ns-Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform.(awgMarker, marker_T1_delay, stim.markerCh, :External)
    queue_waveform(awgMarker, markerPulseID, stim.markerCh, :Auto)
    queue_waveform(awgMarker, delay_id_Marker, stim.markerCh, :Auto, repetitions = decay_num_20ns)
    queue_waveform(awgMarker, markerPulseID, stim.markerCh, :Auto)
    queue_waveform.(awgMarker, delay_id_Marker, stim.markerCh, :Auto, repetitions = end_num_20ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgXY, stim.IQ_XY_chs...)
    awg_start(awgMarker, stim.markerCh) #this starts releasing markers, which triggers other AWGs
    sleep(0.001)
    SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 0)
    nothing
end

function source(stim::Rabi, t::Real)
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
    read_Rabi_delay = Waveform(make_Delay(t, awgRead[SampleRate]), "read_Rabi_delay")
    marker_Rabi_delay = Waveform(make_Delay(t, awgMarker[SampleRate]), "marker_Rabi_delay")
    load_waveform(awgRead, read_Rabi_delay, find_wav_id(awgRead, "read_Rabi_delay") )
    load_waveform(awgMarker, marker_Rabi_delay, find_wav_id(awgMarker, "marker_Rabi_delay") )
    readoutPulse_delay_id = find_wav_id(awgXY, "readoutPulse_delay")
    markerPulseID = find_wav_id(awgMarker, "Markers_Voltage=1")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

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
    queue_waveform.(awgXY, XYPulse.envelope, stim.IQ_XY_chs, :External)
    queue_waveform.(awgXY, readoutPulse_delay_id, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, delay_id_XY, stim.IQ_XY_chs, :Auto, repetitions = decay_num_20ns)
    queue_waveform.(awgXY, readoutPulse_delay_id, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, delay_id_XY, stim.IQ_XY_chs, :Auto, repetitions = end_num_20ns)

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgRead, read_Rabi_delay, stim.IQ_readout_chs, :External, delay = read_fudge)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead,delay_id_Read, stim.IQ_readout_chs, :Auto, repetitions = decay_num_20ns)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead, delay_id_Read, stim.IQ_readout_chs, :Auto, repetitions = end_num_20ns-Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform.(awgMarker, marker_Rabi_delay, stim.markerCh, :External)
    queue_waveform(awgMarker, markerPulseID, stim.markerCh, :Auto)
    queue_waveform(awgMarker, delay_id_Marker, stim.markerCh, :Auto, repetitions = decay_num_20ns)
    queue_waveform(awgMarker, markerPulseID, stim.markerCh, :Auto)
    queue_waveform.(awgMarker, delay_id_Marker, stim.markerCh, :Auto, repetitions = end_num_20ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgXY, stim.IQ_XY_chs...)
    awg_start(awgMarker, stim.markerCh) #this starts releasing markers, which triggers other AWGs
    sleep(0.001)
    SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 0)
    nothing
end

function source(stim::Ramsey, τ::Real)
    awgXY = stim.awgXY
    awgRead = stim.awgRead
    awgMarker = stim.awgMarker
    π_2Pulse = stim.π_2Pulse
    readoutPulse = stim.readoutPulse

    #computing delays and loading delays
    decay_num_20ns = Int(div(stim.decay_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    end_num_20ns = Int(div(stim.end_delay + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 8  #channels 1 and 3 on awg in slot 3 are somewhat unsynced, this is a fudge factor--> might depend on whatever awgs and whatever channels
    read_Ramsey_delay = Waveform(make_Delay(τ + 2*π_2Pulse.duration, awgRead[SampleRate]), "read_Ramsey_delay")
    marker_Ramsey_delay = Waveform(make_Delay(τ + 2*π_2Pulse.duration, awgMarker[SampleRate]), "marker_Ramsey_delay")
    τ_delay = Waveform(make_Delay(τ, awgXY[SampleRate]), "τ_delay") #note: can't do τ equal zero, that's an edge case
    load_waveform(awgXY, τ_delay, find_wav_id(awgXY, "τ_delay") )
    load_waveform(awgRead, read_Ramsey_delay, find_wav_id(awgRead, "read_Ramsey_delay") )
    load_waveform(awgMarker, marker_Ramsey_delay, find_wav_id(awgMarker, "marker_Ramsey_delay") )
    readoutPulse_delay_id = find_wav_id(awgXY, "readoutPulse_delay")
    markerPulseID = find_wav_id(awgMarker, "Markers_Voltage=1")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

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
    queue_waveform.(awgXY, π_2Pulse.envelope, stim.IQ_XY_chs, :External)
    queue_waveform.(awgXY, τ_delay, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, π_2Pulse.envelope, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, readoutPulse_delay_id, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, delay_id_XY, stim.IQ_XY_chs, :Auto, repetitions = decay_num_20ns)
    queue_waveform.(awgXY, readoutPulse_delay_id, stim.IQ_XY_chs, :Auto)
    queue_waveform.(awgXY, delay_id_XY, stim.IQ_XY_chs, :Auto, repetitions = end_num_20ns)

    #awgRead queueing
    read_I = stim.IQ_readout_chs[1]
    read_Q = stim.IQ_readout_chs[2]
    queue_waveform.(awgRead, read_Ramsey_delay, stim.IQ_readout_chs, :External, delay = read_fudge)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead,delay_id_Read, stim.IQ_readout_chs, :Auto, repetitions = decay_num_20ns)
    queue_waveform(awgRead, readoutPulse.I_waveform, read_I, :Auto)
    queue_waveform(awgRead, readoutPulse.Q_waveform, read_Q, :Auto)
    queue_waveform.(awgRead, delay_id_Read, stim.IQ_readout_chs, :Auto, repetitions = end_num_20ns-Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform.(awgMarker, marker_Ramsey_delay, stim.markerCh, :External)
    queue_waveform(awgMarker, markerPulseID, stim.markerCh, :Auto)
    queue_waveform(awgMarker, delay_id_Marker, stim.markerCh, :Auto, repetitions = decay_num_20ns)
    queue_waveform(awgMarker, markerPulseID, stim.markerCh, :Auto)
    queue_waveform.(awgMarker, delay_id_Marker, stim.markerCh, :Auto, repetitions = end_num_20ns)

    #Start AWGs
    awg_start(awgRead, stim.IQ_readout_chs...)
    awg_start(awgXY, stim.IQ_XY_chs...)
    awg_start(awgMarker, stim.markerCh)
    sleep(0.001)
    SD_Module_PXItriggerWrite(awgRead.ID, stim.PXI_line, 0)
    nothing
end
