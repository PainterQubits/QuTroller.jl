import Base: getindex

function getindex(Qcon::QubitController, q::AbstractString)
    return Qcon.qubits[q]
end

function getindex(Qcon::QubitController, ::Type{Marker})
    return Qcon.configuration[Marker]
end

function getindex(Qcon::QubitController, ::Type{Digitizer})
    return Qcon.configuration[Digitizer]
end

function getindex(Qcon::QubitController, ::Type{RO})
    return Qcon.configuration[RO]
end

function getindex(Qcon::QubitController, ::Type{ReadoutPulse})
    return Qcon.configuration[ReadoutPulse]
end

function getindex(Qcon::QubitController, ::Type{ReadoutLength})
    return Qcon.configuration[ReadoutLength]
end

function getindex(Qcon::QubitController, ::Type{ReadoutIF})
    return Qcon.configuration[ReadoutIF]
end

function getindex(Qcon::QubitController, ::Type{DecayDelay})
    return Qcon.configuration[DecayDelay]
end

function getindex(Qcon::QubitController, ::Type{EndDelay})
    return Qcon.configuration[EndDelay]
end

function getindex(Qcon::QubitController, ::Type{Averages})
    return Qcon.configuration[Averages]
end

function getindex(Qcon::QubitController, ::Type{DigDelay})
    return Qcon.configuration[DigDelay]
end

function getindex(Qcon::QubitController, ::Type{PXI})
    return Qcon.configuration[PXI]
end

function getindex(Qcon::QubitController, ::Type{ReadoutPower})
    if Qcon[RO].awg[SinePower, Qcon[RO].Ich] != Qcon[RO].awg[SinePower, Qcon[RO].Qch]
        error("I and Q powers are not configured to be the same. Please reconfigure power")
    else
        return Qcon[RO].awg[SinePower, Qcon[RO].Ich]
    end
end

function getindex(Qcon::QubitController, ::Type{ReadoutAmplitude})
    if Qcon[RO].awg[Amplitude, Qcon[RO].Ich] != Qcon[RO].awg[Amplitude, Qcon[RO].Qch]
        error("I and Q amplitudes are not configured to be the same. Please reconfigure amplitudes")
    else
        return Qcon[RO].awg[Amplitude, Qcon[RO].Ich]
    end
end

function getindex(Qcon::QubitController, q::AbstractString, ::Type{xyAmplitude})
    if Qcon[q].awg[Amplitude, Qcon[q].Ich] != Qcon[q].awg[AmpModGain, Qcon[q].Qch]
        error("I and Q amplitudes are not configured to be the same. Please reconfigure amplitudes")
    else
        return Qcon[q].awg[AmpModGain, Qcon[q].Ich]
    end
end

function getindex(Qcon::QubitController, q::AbstractString, ::Type{xyIF})
    if Qcon[q].awg[FGFrequency, Qcon[q].Ich] != Qcon[q].awg[FGFrequency, Qcon[q].Qch]
        error("I and Q frequencies are not configured to be the same. Please reconfigure frequencies")
    else
        return Qcon[q].awg[FGFrequency, Qcon[q].Ich]
    end
end
