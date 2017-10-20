__precompile__(true)
module KeysightQubits

import ICCommon: source, Stimulus, measure, Response

export load_pulse

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

load_pulse(ins::InsAWGM320XA, pulse::AnalogPulse, id::Integer) = load_waveform(ins, pulse.envelope, id)

load_pulse(ins::InsAWGM320XA, pulse::DCPulse, id::Integer) = load_waveform(ins, pulse.waveform, id)

function load_pulse(ins::InsAWGM320XA, pulse::DigitalPulse, I_id::Integer, Q_id::Integer)
    load_waveform(ins, pulse.I_waveform, I_id)
    load_waveform(ins, pulse.Q_waveform, Q_id)
    nothing
end

end #end module
