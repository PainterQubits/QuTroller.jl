__precompile__(true)
module KeysightQubits

import ICCommon: source, Stimulus, measure, Response
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A

Waveform = AWGM320XA.Waveform

include("Pulses.jl")
include("Stimulus.jl")
include("Response.jl")
include("Configure.jl")

end
