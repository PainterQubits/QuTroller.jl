mutable struct T1 <: Stimulus
    awg::InsAWGM320XA
    Xpi::AnalogPulse
    readout::DigitalPulse
    IQ_Xpi_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    XY_PXI_marker::Int
    readouts_delay::Int
    final_delay::Int
    axisname::Symbol
    axislabel::String
end

"""
    T1(awg, Xpi, readout, axisname = :t1delay, axislabel = "Delay",
        finaldelay1=DEF_READ_DLY, finaldelay2=DEF_READ_DLY)
Creates a T1 stimulus object given an AWG, pi pulse, and readout pulse.
Sourcing with a `Float64` will set the delay between the end of the pi pulse and
the start of the readout pulse, sequencing a T1 measurement.
"""
T1(awg::InsAWGM320XA, Xpi::Pulse, readout::Pulse, IQ_Xpi_chs::Tuple{Integer,Integer} = (1,2),
    IQ_readout_chs::Tuple{Integer,Integer} = (3,4), XY_PXI_marker::Integer,
    readouts_delay  axisname = :t1delay, axislabel = "Delay",
    finaldelay1=DEF_READ_DLY, finaldelay2=DEF_READ_DLY) =
    T1(awg, Xpi, readout, IF, finaldelay1, finaldelay2, axisname, axislabel)
