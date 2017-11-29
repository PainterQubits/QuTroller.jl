__precompile__(true)
module KeysightQubits

import ICCommon: source, Stimulus, measure, Response
using InstrumentControl
using InstrumentControl: AWGM320XA, DigitizerM3102A
using KeysightInstruments
using AxisArrays

Waveform = AWGM320XA.Waveform
nums_to_mask = AWGM320XA.nums_to_mask

global const PXI_LINE = 0

#helper function
function make_wav_id(awg::InsAWGM320XA)
    if size(collect(keys(awg.waveforms)))[1] == 0
        new_id = 1
    else
        new_id = sort(collect(keys(awg.waveforms)))[end] + 1
    end
end

function find_wav_id(awg::InsAWGM320XA, name::AbstractString)
    id = make_wav_id(awg) #initializing id variable/ giving it value if name can't be found
    for key in keys(awg.waveforms)
        if awg.waveforms[key].name == name
            id = key
            break
        end
    end
    return id
end

include("Pulses.jl")
include("Stimulus.jl")
include("Response.jl")
include("Configure.jl")

end
