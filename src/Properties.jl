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
    awg::InsAWGM30XA
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

abstract type ReadoutLength
abstract type ReadoutIF
abstract type ReadoutPower
abstract type ReadoutAmplitude
abstract type DecayDelay
abstract type EndDelay

abstract type Averages
abstract type DigDelay
abstract type PXI

abstract type xyIF
abstract type xyAmplitude

abstract type ReadoutPulse
