__precompile__(true)
module KeysightQubits

import ICCommon: source, Stimulus, measure, Response
using InstrumentControl
using InstrumentControl.AWGM320XA

include("Pulses.jl")
include("Stimulus.jl")
include("Response.jl")
include("Configure.jl")

end
