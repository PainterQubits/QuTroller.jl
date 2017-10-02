__precompile__(true)
module KeysightQubits

import ICCommon: source, Stimulus, measure, Response
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments

Waveform = AWGM320XA.Waveform
nums_to_mask = AWGM320XA.nums_to_mask

#helper function
function make_wav_id(awg::InsAWGM320XA)
    if size(collect(keys(awg.waveforms)))[1] == 0
        new_id = 1
    else
        new_id = sort(collect(keys(awg.waveforms)))[end] + 1
    end
end

include("Pulses.jl")
include("Stimulus.jl")
include("Response.jl")
include("Configure.jl")

end
