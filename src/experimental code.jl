mutable struct SmartVz <: Stimulus
    Vz::Stimulus
    q::String
    read_freq_range::Vector{Float64}
    xy_freq_range::Vector{Float64}
    π_length_range::Vector{Float64}
    avgIQ::RO_IQ_Response
    bool_RO::Bool
    bool_xy::Bool
    bool_π::Bool
end

function source(stim::SmartVz, voltage::Float64)
    Qcon = qubitController[]
    rabi = Rabi(Qcon[stim.q])
    πLength_guess = q.gates[X].duration
    if bool_RO[1]
        Qcon[xyLOsource][Output] = false
        source(stim.Vz, voltage)
        current_lo = Qcon[ReadoutLO]
        num_freqs = size(stim.read_freq_range)[1]
        amp_values = Vector{Float64}(num_freqs)
        for j in range(1, num_freqs)
            Qcon[ReadoutLO] = stim.read_freq_range[j]
            amplitude = abs(measure(stim.avgIQ))
            amp_values[j] = amplitude
        end
        readout_freq = stim.read_freq_range[indmin(amp_values)]
        Qcon[xyLOsource][Output] = true
        stim.read_freq_range = stim.read_freq_range - (current_lo - readout_freq)
        Qcon[ReadoutLO] = readout_freq
    end
    if bool_xy[2]
        source(stim.Vz, voltage)
        current_lo = Qcon[xyLO]
        num_freqs = size(stim.xy_freq_range)[1]
        amp_values = Vector{Float64}(num_freqs)
        source(rabi, πLength_guess)
        for j in range(1, num_freqs)
            Qcon[xyLO] = stim.xy_freq_range[j]
            amplitude = abs(measure(stim.avgIQ))
            amp_values[j] = amplitude
        end
        xy_freq = stim.xy_freq_range[indmax(amp_values)]
        stim.xy_freq_range = stim.xy_freq_range - (current_lo - xy_freq)
        Qcon[xyLO] = xy_freq
    end
    if bool_π[3]
        source(stim.Vz, voltage)
        num_t = size(stim.π_length_range)[1]
        amp_values = Vector{Float64}(num_t)
        for j in range(1, num_t)
            source(rabi, stim.π_length_range[j])
            amplitude = abs(measure(stim.avgIQ))
            amp_values[j] = amplitude
        end
        πLength = stim.π_length_range[indmax(amp_values)]
        Qcon[Qcon[stim.q], X] = πLength
    end
end


mutable struct DoubleRabi <: QubitCharacterization
    q1::Qubit
    q2::Qubit
    axisname::Symbol
    axislabel::String

    DoubleRabi(q1, q2) = new(q1, q2, :xyduration, "XY Pulse Duration")
end

function source(stim::DoubleRabi, t, t2)
    t<20e-9 && error("t must be at least 20ns")
    #renaming for convinience
    Qcon = qubitController[]
    awgXY = stim.q1.awg
    awgXY2 = stim.q2.awg
    awgRead = Qcon[RO].awg
    awgMarker = Qcon[Marker].awg
    IQ_XY_chs = (stim.q1.Ich, stim.q1.Qch)
    IQ_XY_chs2 = (stim.q2.Ich, stim.q2.Qch)
    IQ_readout_chs = (Qcon[RO].Ich, Qcon[RO].Qch)
    markerCh = Qcon[Marker].ch
    readoutPulse = Qcon[ReadoutPulse]

    #complete XYPulse envelope and load it
    XYPulse = AnalogPulse(t, CosEnvelope, awgXY[SampleRate], name = "Rabi_XYPulse")
    XYPulse2 = AnalogPulse(t2, CosEnvelope, awgXY2[SampleRate], name = "Rabi_XYPulse")
    load_pulse(awgXY, XYPulse, "Rabi_XYPulse")
    load_pulse(awgXY2, XYPulse2, "Rabi_XYPulse")

    #computing delays and loading delays
    decay_num_20ns = Int(div(Qcon[DecayDelay] + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    end_num_20ns = Int(div(Qcon[EndDelay] + 1e-9,20e-9)) #added extra 1e-9 because of floating point issues
    read_fudge = 8  #channels 1 and 3 on awg in slot 3 are somewhat unsynced, this is a fudge factor--> might depend on whatever awgs and whatever channels
    xy_fudge = 2 #there is a delay in output when outputting from the fast AWG compared the slow AWG
    read_Rabi_delay = DelayPulse(XYPulse.duration, awgRead[SampleRate], name = "read_Rabi_delay")
    marker_Rabi_delay = DelayPulse(XYPulse.duration, awgMarker[SampleRate], name = "marker_Rabi_delay")
    readoutPulse_delay = DelayPulse(Qcon[ReadoutPulse].duration, awgXY[SampleRate], name = "readoutPulse_delay")
    readoutPulse_delay2 = DelayPulse(Qcon[ReadoutPulse].duration, awgXY2[SampleRate], name = "readoutPulse_delay")
    load_pulse(awgXY, readoutPulse_delay, "readoutPulse_delay")
    load_pulse(awgXY2, readoutPulse_delay2, "readoutPulse_delay")
    load_pulse(awgRead, read_Rabi_delay, "read_Rabi_delay")
    load_pulse(awgMarker, marker_Rabi_delay, "marker_Rabi_delay")
    markerPulseID = find_wav_id(awgMarker, "Qubit Controller Marker Pulse")
    delay_id_XY = find_wav_id(awgXY, "20ns_delay")
    delay_id_XY2 = find_wav_id(awgXY2, "20ns_delay")
    delay_id_Read = find_wav_id(awgRead, "20ns_delay")
    delay_id_Marker = find_wav_id(awgMarker, "20ns_delay")

    middle_num_20ns = Int(div( (t-t2) + 1e-9,20e-9))

    #flushing queue
    queue_flush.(awgXY, IQ_XY_chs)
    queue_flush.(awgXY2, IQ_XY_chs2)
    queue_flush.(awgRead, IQ_readout_chs)
    queue_flush(awgMarker, markerCh)
    sleep(0.001)

    #awgXY queueing
    queue_waveform.(awgXY, IQ_XY_chs, XYPulse.envelope, :External, delay = xy_fudge)
    queue_waveform.(awgXY, IQ_XY_chs, readoutPulse_delay.waveform, :Auto)
    queue_waveform.(awgXY, IQ_XY_chs, delay_id_XY, :Auto, repetitions = decay_num_20ns - Int(xy_fudge/2))
    # queue_waveform.(awgXY, IQ_XY_chs, readoutPulse_delay_id, :Auto)
    # queue_waveform.(awgXY, IQ_XY_chs, delay_id_XY, :Auto, repetitions = end_num_20ns - Int(xy_fudge/2))

    #awgXY2 queueing
    queue_waveform.(awgXY2, IQ_XY_chs2, XYPulse2.envelope, :External, delay = xy_fudge)
    queue_waveform.(awgXY2, IQ_XY_chs2, delay_id_XY2, :Auto, repetitions = middle_num_20ns)
    queue_waveform.(awgXY2, IQ_XY_chs2, readoutPulse_delay2.waveform, :Auto)
    queue_waveform.(awgXY2, IQ_XY_chs2, delay_id_XY2, :Auto, repetitions = decay_num_20ns - Int(xy_fudge/2))
    # queue_waveform.(awgXY, IQ_XY_chs, readoutPulse_delay_id, :Auto)
    # queue_waveform.(awgXY, IQ_XY_chs, delay_id_XY, :Auto, repetitions = end_num_20ns - Int(xy_fudge/2))

    #awgRead queueing
    read_I = Qcon[RO].Ich
    read_Q = Qcon[RO].Qch
    queue_waveform.(awgRead, IQ_readout_chs, read_Rabi_delay.waveform, :External, delay = read_fudge)
    queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    queue_waveform.(awgRead, IQ_readout_chs, delay_id_Read, :Auto, repetitions = decay_num_20ns - Int(read_fudge/2))
    # queue_waveform(awgRead, read_I, readoutPulse.I_waveform, :Auto)
    # queue_waveform(awgRead, read_Q, readoutPulse.Q_waveform, :Auto)
    # queue_waveform.(awgRead, IQ_readout_chs, delay_id_Read, :Auto, repetitions = end_num_20ns - Int(read_fudge/2))

    #awgMarker queueing
    queue_waveform(awgMarker, markerCh, marker_Rabi_delay.waveform, :External)
    queue_waveform(awgMarker, markerCh, markerPulseID,  :Auto)
    queue_waveform(awgMarker, markerCh, delay_id_Marker, :Auto, repetitions = decay_num_20ns)
    # queue_waveform.(awgMarker, markerCh, markerPulseID, :Auto)
    # queue_waveform.(awgMarker, markerCh, delay_id_Marker, :Auto, repetitions = end_num_20ns)

    #Start AWGs
    awg_start(awgRead, IQ_readout_chs...)
    awg_start(awgXY, IQ_XY_chs...)
    awg_start(awgXY2, IQ_XY_chs2...)
    awg_start(awgMarker, markerCh)
    nothing
end
