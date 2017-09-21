__precompile__(true)
module KeysightQubits

import ICCommon: source, Stimulus, measure, Response
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments

Waveform = AWGM320XA.Waveform
nums_to_mask = AWGM320XA.nums_to_mask

include("Pulses.jl")
include("Stimulus.jl")
include("Response.jl")
include("Configure.jl")

end
