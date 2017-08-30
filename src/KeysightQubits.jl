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
include("Response.jl")
include("Configure.jl")

end
