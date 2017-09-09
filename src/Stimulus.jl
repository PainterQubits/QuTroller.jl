export T1
export Rabi
export Ramsey

#CHANGE CHANGE CHANGE CHANGE FIX FIX FIX FIX
global const DECAY_TIME = 125e-6

abstract type QubitCharacterization <: Stimulus end

mutable struct T1 <: QubitCharacterization
    #AWGs and pulses
    awg::InsAWGM320XA
    #awg2::InsAWGM320XA  #eventually we might have one awg for XY and a different one for readout
    πPulse::AnalogPulse
    readoutPulse::DigitalPulse
    decay_delay::Float64
    #awg configuration information
    XY_amplitude::Float64
    readout_amplitude::Folat64
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int
    #data
    axisname::Symbol
    axislabel::String

    T1(awg, πPulse, readoutPulse, decay_delay)
end

"""


Creates a `T1` stimulus object given an AWG, π pulse, readout pulse, and PXI trigger
line for signaling the digitizer to record data. This function sets some `T1` field
with some standard values, which here correspond to optional or keyword arguments.
The stimulus object can be further customized by explicitly specifying these optional
or keyword arguments.
"""
T1(awg::InsAWGM320XA, πPulse::AnalogPulse, readout::DigitalPulse, XY_PXI_marker::Integer,
    decay_delay = DECAY_TIME, end_delay = END_DELAY; axisname = :t1delay, axislabel = "Delay",
    IQ_XY_chs::Tuple{Integer,Integer} = (1,2), IQ_readout_chs::Tuple{Integer,Integer} = (3,4)) =
    T1(awg, Xpi, readout, IQ_XY_chs, IQ_readout_chs, XY_PXI_marker, decay_delay, end_delay, axisname, axislabel)

mutable struct Rabi <: QubitCharacterization
    awg::InsAWGM320XA
    XY_IF_feq::Float64
    XY_amplitude::Int
    readout::DigitalPulse
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int
    decay_delay::Float64
    end_delay::Float64
    axisname::Symbol
    axislabel::String
end

"""
    Rabi(awg::InsAWGM320XA, XY_IF_freq::Real, XY_amplitude::Integer, readout::Pulse, XY_PXI_marker::Integer,
    decay_delay = DECAY_TIME, end_delay = END_DELAY; axisname=:xyduration, axislabel="XY pulse duration",
    IQ_XY_chs::Tuple{Integer,Integer} = (1,2), IQ_readout_chs::Tuple{Integer,Integer} = (3,4))

Creates a `Rabi` stimulus object given an AWG, XY pulse parameters, readout pulse, and PXI trigger
line for signaling the digitizer to record data; this functions sets some `Rabi` field
inputs as optional or keyword arguments with some standard values. The stimulus object
can be further customized by explicitly specifying these optional or keyword arguments.
"""
Rabi(awg::InsAWGM320XA, XY_IF_freq::Real, XY_amplitude::Integer, readout::Pulse, XY_PXI_marker::Integer,
    decay_delay = DECAY_TIME, end_delay = END_DELAY; axisname=:xyduration, axislabel="XY pulse duration",
    IQ_XY_chs::Tuple{Integer,Integer} = (1,2), IQ_readout_chs::Tuple{Integer,Integer} = (3,4)) =
    Rabi(awg,XY_IF_freq, XY_amplitude, readout, IQ_XY_chs, IQ_readout_chs, XY_PXI_marker, decay_delay, end_delay, axisname, axislabel)

mutable struct Ramsey <: QubitCharacterization
    awg::InsAWGM320XA
    X_half_pi::AnalogPulse
    readout::DigitalPulse
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int
    decay_delay::Float64
    end_delay::Float64
    axisname::Symbol
    axislabel::String
end

"""
    Ramsey(awg::InsAWGM320XA, X_half_pi::Pulse, readout::Pulse, XY_PXI_marker::Integer,
    decay_delay = DECAY_TIME, end_delay = END DELAY; axisname = :ramseydelay, axislabel = "Delay",
    IQ_XY_chs::Tuple{Integer,Integer} = (1,2), IQ_readout_chs::Tuple{Integer,Integer} = (3,4))

Creates a `Ramsey` stimulus object given an AWG, pi/2 pulse, readout pulse, and PXI trigger
line for signaling the digitizer to record data; this functions sets some `Ramsey` field
inputs as optional or keyword arguments with some standard values. The stimulus object
can be further customized by explicitly specifying these optional or keyword arguments.
"""
Ramsey(awg::InsAWGM320XA, X_half_pi::Pulse, readout::Pulse, XY_PXI_marker::Integer,
    decay_delay = DECAY_TIME, end_delay = END_DELAY; axisname = :ramseydelay, axislabel = "Free Evolution Time",
    IQ_XY_chs::Tuple{Integer,Integer} = (1,2), IQ_readout_chs::Tuple{Integer,Integer} = (3,4)) =
    Ramsey(awg, X_half_pi, readout, IQ_XY_chs, IQ_readout_chs, XY_PXI_marker, decay_delay, end_delay, axisname, axislabel)


include("source.jl")
