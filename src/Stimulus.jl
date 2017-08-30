export T1
export RabiOscilattions
export Ramsey

include("source.jl")

abstract type QubitCharacterization <: Stimulus end


mutable struct T1 <: QubitCharacterization
    awg::InsAWGM320XA
    Xpi::AnalogPulse
    readout::DigitalPulse
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int
    decay_delay::Int
    end_delay::Int
    axisname::Symbol
    axislabel::String
end

"""
    T1(awg::InsAWGM320XA, Xpi::Pulse, readout::Pulse, XY_PXI_marker::Integer,
    decay_delay = DECAY_TIME, end_delay = END DELAY; axisname = :t1delay, axislabel = "Delay",
    IQ_Xpi_chs::Tuple{Integer,Integer} = (1,2), IQ_readout_chs::Tuple{Integer,Integer} = (3,4))

Creates a `T1` stimulus object given an AWG, pi pulse, readout pulse, and PXI trigger
line for signaling the digitizer to record data; this functions sets some `T1` field
inputs as optional or keyword arguments with some standard values. The stimulus object
can be further customized by explicitly specifying these optional or keyword arguments.
"""
T1(awg::InsAWGM320XA, Xpi::Pulse, readout::Pulse, XY_PXI_marker::Integer,
    decay_delay = DECAY_TIME, end_delay = END DELAY; axisname = :t1delay, axislabel = "Delay",
    IQ_Xpi_chs::Tuple{Integer,Integer} = (1,2), IQ_readout_chs::Tuple{Integer,Integer} = (3,4)) =
    T1(awg, Xpi, readout, IQ_Xpi_chs, IQ_readout_chs, XY_PXI_marker, decay_delay, end_delay, axisname, axislabel)

mutable struct Rabi <: QubitCharacterization
    awg::InsAWGM320XA
    XY_IF_feq::Float64
    XY_amplitude::Int
    readout::DigitalPulse
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int
    decay_delay::Int
    end_delay::Int
    axisname::Symbol
    axislabel::String
end

mutable struct Ramsey <: QubitCharacterization
    awg::InsAWGM320XA
    X_half_pi::AnalogPulse
    readout::DigitalPulse
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int
    decay_delay::Int
    end_delay::Int
    axisname::Symbol
    axislabel::String
end
