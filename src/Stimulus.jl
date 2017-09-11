export T1
export Rabi
export Ramsey

#CHANGE CHANGE CHANGE CHANGE FIX FIX FIX FIX
global const DECAY_TIME = 125e-6

"""
A Stimulus subtype for doing single qubit characterization experiments, such as
measuring T1, T2, doing Rabi oscillation experiments, etc. It's composite subtypes
usually hold the following fields: AWG object for XY pulses, AWG object for readout pulses,
an XY pulse, a readout pulse, the channels used to generate these pulses, and
a PXI trigger line to trigger readout pulses and recording by digitizer (as well
as the usual axisname and axislabel fields)
"""
abstract type QubitCharacterization <: Stimulus end

mutable struct T1 <: QubitCharacterization
    #AWGs and pulses
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    πPulse::AnalogPulse
    readoutPulse::DigitalPulse
    decay_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int

    #data
    axisname::Symbol
    axislabel::String

    T1(awgXY, awgRead, πPulse, readoutPulse, IQ_XY_chs, IQ_readout_chs,
       XY_PXI_marker) = new(awgXY, awgRead, πPulse, readoutPulse, DECAY_TIME, IQ_XY_chs,
                            IQ_readout_chs, XY_PXI_marker, :t1delay, "Delay")

    T1(awgXY, awgRead, πPulse, readoutPulse, decay_delay, IQ_XY_chs, IQ_readout_chs,
       XY_PXI_marker, axisname, axislabel) = new(awgXY, awgRead, πPulse, readoutPulse,
          decay_delay, IQ_XY_chs, IQ_readout_chs, XY_PXI_marker, axisname, axislabel)
end

mutable struct Rabi <: QubitCharacterization
    #AWGs and pulses
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    XY_pulse::AnalogPulse #meant to hold IF_freq and
    readoutPulse::DigitalPulse
    decay_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int

    #data
    axisname::Symbol
    axislabel::String

    Rabi(awgXY, awgRead, XYPulse, readoutPulse, IQ_XY_chs, IQ_readout_chs,
       XY_PXI_marker) = new(awgXY, awgRead, XYPulse, readoutPulse, DECAY_TIME, IQ_XY_chs,
                        IQ_readout_chs, XY_PXI_marker, :xyduration, "XY Pulse Duration")

    Rabi(awgXY, awgRead, XYPulse, readoutPulse, decay_delay, IQ_XY_chs, IQ_readout_chs,
       XY_PXI_marker, axisname, axislabel) = new(awgXY, awgRead, XYPulse, readoutPulse,
          decay_delay, IQ_XY_chs, IQ_readout_chs, XY_PXI_marker, axisname, axislabel)
end

mutable struct Ramsey <: QubitCharacterization
    #AWGs and pulses
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    π_2Pulse::AnalogPulse
    readoutPulse::DigitalPulse
    decay_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int

    #data
    axisname::Symbol
    axislabel::String

    Ramsey(awgXY, awgRead, π_2Pulse, readoutPulse, IQ_XY_chs, IQ_readout_chs,
      XY_PXI_marker) = new(awgXY, awgRead, π_2Pulse, readoutPulse, DECAY_TIME, IQ_XY_chs,
                       IQ_readout_chs, XY_PXI_marker, :ramseydelay, "Free Evolution Time")

    Ramsey(awgXY, awgRead, π_2Pulse, readoutPulse, decay_delay, IQ_XY_chs, IQ_readout_chs,
      XY_PXI_marker, axisname, axislabel) = new(awgXY, awgRead, π_2Pulse, readoutPulse,
          decay_delay, IQ_XY_chs, IQ_readout_chs, XY_PXI_marker, axisname, axislabel)
end


"""
Creates a "standard" `T1` stimulus object assuming that one AWG Keysight card corresponds
to just one qubit; the object is initialized given just an AWG object, a π pulse,
a readout pulse, and PXI trigger line for synchronizing readout pulse generation and
digitizer data recording. This function sets the other `T1` fields with standard values.
"""
T1(awg::InsAWGM320XA, πPulse::AnalogPulse, readoutPulse::DigitalPulse, XY_PXI_marker::Integer) =
    T1(awg, awg, πPulse, readoutPulse, (1,2), (3,4), XY_PXI_marker)

"""
Creates a "standard" `Rabi` stimulus object assuming that one AWG Keysight card corresponds
to just one qubit; the object is initialized given just an AWG object, a XY pulse,
a readout pulse, and PXI trigger line for synchronizing readout pulse generation and
digitizer data recording. This function sets the other `Rabi` fields with standard values.
"""
Rabi(awg::InsAWGM320XA, XYPulse::AnalogPulse, readoutPulse::DigitalPulse, XY_PXI_marker::Integer) =
    Rabi(awg, awg, XYPulse, readoutPulse, (1,2), (3,4), XY_PXI_marker)

"""
Creates a "standard" `Ramsey` stimulus object assuming that one AWG Keysight card corresponds
to just one qubit; the object is initialized given just an AWG object, a π/2 pulse,
a readout pulse, and PXI trigger line for synchronizing readout pulse generation and
digitizer data recording. This function sets the other `Ramsey` fields with standard values.
"""
Ramsey(awg::InsAWGM320XA, π_2Pulse::AnalogPulse, readoutPulse::DigitalPulse, XY_PXI_marker::Integer) =
    Ramsey(awg, awg, π_2Pulse, readoutPulse, (1,2), (3,4), XY_PXI_marker)

include("source.jl")
