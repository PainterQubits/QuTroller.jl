__precompile__(true)
module KeysightQubits

import ICCommon: source, Stimulus, measure, Response
using InstrumentControl
using InstrumentControl.AWGM320XA

abstract type Envelope end
abstract type Pulse end

export Envelope
export Pulse

include("Core.jl")
include("Stimulus.jl")
include("Configure.jl")
include("source.jl")

end
