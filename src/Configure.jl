import Base: setindex!

function setindex!(Qcon::QubitController, marker::Tuple{InsAWGM320XA, Int}, ::Type{Marker})
    marker_obj = Marker(marker...)
    marker_delay_20ns = DelayPulse(20e-9, marker_obj.awg[SampleRate], name = "20ns_delay")
    load_pulse(marker_obj.awg, marker_delay_20ns, "20ns_delay")
    Qcon.configuration[Marker] = marker_obj
    nothing
end

function setindex!(Qcon::QubitController, digitizer::Tuple{InsDigitizerM3102A, Int, Int},
                   ::Type{Digitizer})
    digitizer_obj = Digitizer(digitizer...)
    Qcon.configuration[Digitizer] = digitizer_obj
    nothing
end

function setindex!(Qcon::QubitController, readout::Tuple{InsAWGM320XA, Int, Int, Instrument},
                   ::Type{RO})
    readout_obj = RO(readout...)
    read_delay_20ns = DelayPulse(20e-9, readout_obj.awg[SampleRate], name = "20ns_delay")
    load_pulse(readout_obj.awg, read_delay_20ns, "20ns_delay")
    Qcon.configuration[RO] = readout_obj
    nothing
end

function setindex!(Qcon::QubitController, lo::Instrument, ::Type{xyLOsource})
    Qcon.configuration[xyLOsource] = lo
    nothing
end

function setindex!(Qcon::QubitController, length::Real, ::Type{ReadoutLength})
    roPulse = DigitalPulse(Qcon[ReadoutIF], length, RectEnvelope, Qcon[RO].awg[SampleRate],
                           name = "Qubit Controller Readout Pulse")
    load_pulse(Qcon[RO].awg, roPulse, "Qubit Controller Readout Pulse")
    marker_pulse = DCPulse(length, RectEdge, Qcon[Marker].awg[SampleRate],
                           name = "Qubit Controller Marker Pulse")
    load_pulse(Qcon[Marker].awg, marker_pulse, "Qubit Controller Marker Pulse")
    Qcon[ReadoutPulse] = roPulse
    Qcon.configuration[ReadoutLength] = length
    nothing
end

function setindex!(Qcon::QubitController, freq::Real, ::Type{ReadoutIF})
    roPulse = DigitalPulse([freq], Qcon[ReadoutLength], RectEnvelope, Qcon[RO].awg[SampleRate],
                           name = "Qubit Controller Readout Pulse")
    load_pulse(Qcon[RO].awg, roPulse, "Qubit Controller Readout Pulse")
    marker_pulse = DCPulse(Qcon[ReadoutLength], RectEdge, Qcon[Marker].awg[SampleRate],
                           name = "Qubit Controller Marker Pulse")
    load_pulse(Qcon[Marker].awg, marker_pulse, "Qubit Controller Marker Pulse")
    Qcon[ReadoutPulse] = roPulse
    Qcon.configuration[ReadoutIF] = freq
    nothing
end

function setindex!(Qcon::QubitController, freqs::Vector{Float64}, ::Type{ReadoutIF})
    roPulse = DigitalPulse(freqs, Qcon[ReadoutLength], RectEnvelope, Qcon[RO].awg[SampleRate],
                           name = "Qubit Controller Readout Pulse")
    load_pulse(Qcon[RO].awg, roPulse, "Qubit Controller Readout Pulse")
    marker_pulse = DCPulse(Qcon[ReadoutLength], RectEdge, Qcon[Marker].awg[SampleRate],
                           name = "Qubit Controller Marker Pulse")
    load_pulse(Qcon[Marker].awg, marker_pulse, "Qubit Controller Marker Pulse")
    Qcon[ReadoutPulse] = roPulse
    Qcon.configuration[ReadoutIF] = freqs
    nothing
end

function setindex!(Qcon::QubitController, freq::Real, ::Type{ReadoutLO})
    Qcon[RO].lo[Frequency] = freq
    nothing
end

function setindex!(Qcon::QubitController, power::Real, ::Type{ReadoutPower})
    Qcon[RO].awg[SinePower, Qcon[RO].Ich, Qcon[RO].Qch] = power
    Qcon.configuration[ReadoutPower] = power
    nothing
end

function setindex!(Qcon::QubitController, amp::Real, ::Type{ReadoutAmplitude})
    Qcon[RO].awg[Amplitude, Qcon[RO].Ich, Qcon[RO].Qch] = amp
    Qcon.configuration[ReadoutPower] = amp
    nothing
end

function setindex!(Qcon::QubitController, delay::Real, ::Type{DecayDelay})
    Qcon.configuration[DecayDelay] = delay
    nothing
end

function setindex!(Qcon::QubitController, delay::Real, ::Type{EndDelay})
    Qcon.configuration[EndDelay] = delay
    nothing
end

function setindex!(Qcon::QubitController, averages::Integer, ::Type{Averages})
    Qcon.configuration[Averages] = averages
    nothing
end

function setindex!(Qcon::QubitController, delay::Integer, ::Type{DigDelay})
    Qcon.configuration[DigDelay] = delay
    nothing
end

function setindex!(Qcon::QubitController, line::Integer, ::Type{PXI})
    Qcon.configuration[PXI] = line
    nothing
end

function setindex!(Qcon::QubitController, freq::Real, q::AbstractString, ::Type{xyIF})
    Qcon[q].awg[FGFrequency, Qcon[q].Ich, Qcon[q].Qch] = freq
    nothing
end

function setindex!(Qcon::QubitController, amp::Real, q::AbstractString, ::Type{xyAmplitude})
    Qcon[q].awg[AmpModGain, Qcon[q].Ich, Qcon[q].Qch] = amp
    nothing
end

function setindex!(Qcon::QubitController, freq::Real, ::Type{xyLO})
    Qcon[xyLOsource][Frequency] = freq
    nothing
end

function setindex!(Qcon::QubitController, roPulse::DigitalPulse, ::Type{ReadoutPulse})
    Qcon.configuration[ReadoutPulse] = roPulse
    nothing
end
