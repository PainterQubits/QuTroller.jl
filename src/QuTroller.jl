__precompile__(true)
module QuTroller

import ICCommon: source, Stimulus, measure, Response

export DCSource
export Qubit

using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments
using AxisArrays

Waveform = AWGM320XA.Waveform
nums_to_mask = AWGM320XA.nums_to_mask

include("Pulses.jl")
include("helper.jl")
include("Properties.jl")

abstract type DCSource end

mutable struct keysightDC <: DCSource
    awg::InsAWGM320XA
    ch::Int
end

mutable struct Qubit
    awg::Instrument
    Ich::Int
    Qch::Int
    #dc::DCSource
end

#using struct instead of mutable struct can help runtime performance (due to simpler structure on memory)...
#and can help pre-compiling time (since limiting the user means more straight forward "machine level" code)
struct QubitController
    qubits::Dict{String, Qubit}
    configuration::Dict{Any, Any}

    QubitController() = begin
        qubits = Dict{String, Qubit}()
        configuration = Dict{Any, Any}()
        Qcon = new(qubits, configuration)
        Qcon.configuration[ReadoutIF] = 100e6
        Qcon.configuration[ReadoutLength] = 500e-9
        Qcon.configuration[ReadoutPulse] = DigitalPulse(100e6, 0, 500e-9)
        return Qcon
    end
end

function Qubit(Qcon::QubitController, awg, Ich, Qch, dc, name::AbstractString)
    q = Qubit(awg, Ich, Qch, dc)
    Qcon.qubits[name] = q
    XY_delay_20ns = DelayPulse(20e-9, q.awg[SampleRate], name = "20ns_delay")
    load_pulse(q.awg, XY_delay_20ns, "20ns_delay")
    nothing
end

include("Inspect.jl")
include("Configure.jl")
include("Response.jl")
include("Stimulus.jl")

const global qubitController = Ref{QubitController}()

function __init__()
    qubitController[] = QubitController()
end

end #end module
