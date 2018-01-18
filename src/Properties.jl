export Marker
export Digitizer
export RO
export ReadoutLength
export ReadoutIF
export ReadoutPower
export ReadoutAmplitude
export DecayDelay
export EndDelay

export Averages
export DigDelay
export PXI

export xyIF
export xyAmplitude

mutable struct Marker
    awg::InsAWGM320XA
    ch::Integer
end

mutable struct Digitizer
    dig::InsDigitizerM3102A
    Ich::Int
    Qch::Int
end

mutable struct RO
    awg::Instrument
    Ich::Int
    Qch::Int
end

abstract type ReadoutLength end
abstract type ReadoutIF end
abstract type ReadoutPower end
abstract type ReadoutAmplitude end
abstract type DecayDelay end
abstract type EndDelay end

abstract type Averages end
abstract type DigDelay end
abstract type PXI end

abstract type xyIF end
abstract type xyAmplitude end

abstract type ReadoutPulse end
