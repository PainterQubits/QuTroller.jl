export T1
export Rabi
export Ramsey

global const DECAY_TIME = 40e-6
global const END_TIME = 40e-6
global const PXI_LINE = 0
global const DELAY_ID = 0
global const MARKER_CH = 4
global const MARKER_PULSE_ID = 1

"""
A Stimulus subtype for doing single qubit characterization experiments, such as
measuring T1, T2, doing Rabi oscillation experiments, etc. It's composite subtypes
usually hold the following fields: AWG object for XY pulses, AWG object for readout pulses,
AWG object for markers, an XY pulse, a readout pulse, the channels used to generate
these pulses, and a PXI trigger line to trigger readout pulses and recording by
digitizer (as well as the usual axisname and axislabel fields)
"""
abstract type QubitCharacterization <: Stimulus end

mutable struct T1 <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    πPulse::AnalogPulse
    readoutPulse::DigitalPulse
    decay_delay::Float64
    end_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int

    #data
    axisname::Symbol
    axislabel::String

    T1(awgXY, awgRead, awgMarker, πPulse, readoutPulse, IQ_XY_chs, IQ_readout_chs) =
        new(awgXY, awgRead, awgMarker, πPulse, readoutPulse, DECAY_TIME, END_TIME, IQ_XY_chs,
            IQ_readout_chs, MARKER_CH, PXI_LINE, :t1delay, "Delay")

    T1(awgXY, awgRead, awgMarker, πPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel) = new(awgXY, awgRead,
        awgMarker, πPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs,
        markerCh, PXI_line, axisname, axislabel)
end

mutable struct Rabi <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    XYPulse::AnalogPulse #meant to hold IF_freq and
    readoutPulse::DigitalPulse
    decay_delay::Float64
    end_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int

    #data
    axisname::Symbol
    axislabel::String

    Rabi(awgXY, awgRead, awgMarker, XYPulse, readoutPulse, IQ_XY_chs, IQ_readout_chs) =
        new(awgXY, awgRead, awgMarker, XYPulse, readoutPulse, DECAY_TIME, END_TIME, IQ_XY_chs,
            IQ_readout_chs, MARKER_CH, PXI_LINE, :xyduration, "XY Pulse Duration")

    Rabi(awgXY, awgRead, awgMarker, XYPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel) = new(awgXY, awgRead,
        awgMarker, XYPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs,
        markerCh, PXI_line, axisname, axislabel)
end

mutable struct Ramsey <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    π_2Pulse::AnalogPulse
    readoutPulse::DigitalPulse
    decay_delay::Float64
    end_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int

    #data
    axisname::Symbol
    axislabel::String

    Ramsey(awgXY, awgRead, awgMarker, π_2Pulse, readoutPulse, IQ_XY_chs, IQ_readout_chs) =
        new(awgXY, awgRead, awgMarker, π_2Pulse, readoutPulse, DECAY_TIME, END_TIME, IQ_XY_chs,
            IQ_readout_chs, MARKER_CH, PXI_LINE, :ramseydelay, "Free Evolution Time")

    Ramsey(awgXY, awgRead, awgMarker, π_2Pulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel) = new(awgXY, awgRead,
        awgMarker, π_2Pulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs,
        markerCh, PXI_line, axisname, axislabel)
end


"""
Creates a "standard" `T1` stimulus object assuming that one AWG Keysight card corresponds
to just one qubit; the object is initialized given just an AWG object for pulses,
an AWG object for markers, a π pulse, and a readout pulse. This function sets the other
`T1` fields with standard values.
"""
T1(awg::InsAWGM320XA, awgMarker::InsAWGM320XA, πPulse::AnalogPulse,
   readoutPulse::DigitalPulse) = T1(awg, awg, awgMarker, πPulse, readoutPulse,
   (1,2), (3,4))

"""
Creates a "standard" `Rabi` stimulus object assuming that one AWG Keysight card corresponds
to just one qubit; the object is initialized given just an AWG object for pulses,
an AWG object for markers, a XY pulse, and a readout pulse. This function sets
the other `Rabi` fields with standard values.
"""
Rabi(awg::InsAWGM320XA, awgMarker::InsAWGM320XA, XYPulse::AnalogPulse,
     readoutPulse::DigitalPulse) = Rabi(awg, awg, awgMarker, XYPulse, readoutPulse,
    (1,2), (3,4))

"""
Creates a "standard" `Ramsey` stimulus object assuming that one AWG Keysight card corresponds
to just one qubit; the object is initialized given just an AWG object for pulses,
an AWG object for markers, a π/2 pulse, and a readout pulse. This function sets
the other `Ramsey` fields with standard values.
"""
Ramsey(awg::InsAWGM320XA, awgMarker::InsAWGM320XA, π_2Pulse::AnalogPulse,
       readoutPulse::DigitalPulse) = Ramsey(awg, awg, awgMarker, π_2Pulse, readoutPulse,
       (1,2), (3,4))

include("source.jl")
