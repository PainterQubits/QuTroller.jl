export QubitCharacterization
export T1
export Rabi
export Ramsey

global const DECAY_TIME = 60e-6 #temporary delay for testing purposes
global const END_TIME = 60e-6 #temporary delay for testing purposes
global const MARKER_CH = 4


"""
A Stimulus subtype for doing single qubit characterization experiments, such as
measuring T1, T2, doing Rabi oscillation experiments, etc. It's composite subtypes
usually hold the following fields: AWG object for XY pulses, AWG object for readout pulses,
AWG object for markers, an XY pulse, a readout pulse, the channels used to generate
these pulses, and a PXI trigger line to trigger simultaneous outputs of all those pulses.
"""
abstract type QubitCharacterization <: Stimulus end

"""
```
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
end
```

Stimulus type for finding the T1 of a qubit. The corresponding source function
is `source(stim, τ)`, where τ is the delay between the XY pulse and the readout pulse.
Currently, τ cannot be less than 20ns (the equipment cannot queue waveforms of
less than 20ns), and the decay_delay and end_delay are automatically converted to be
multiples of 20ns (for efficient implementation)
"""
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

    T1(awgXY, awgRead, awgMarker, πPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs) =
        new(awgXY, awgRead, awgMarker, πPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
            IQ_readout_chs, MARKER_CH, PXI_LINE, :t1delay, "Delay")

    T1(awgXY, awgRead, awgMarker, πPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel) = new(awgXY, awgRead,
        awgMarker, πPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs,
        markerCh, PXI_line, axisname, axislabel)
end

"""
```
mutable struct Rabi <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    XYPulse::AnalogPulse
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
end
```

Stimulus type for doing Rabi Oscillations with a qubit. The corresponding source function
is `source(stim, τ)`, where τ is the delay the length of the XY pulse.
Currently, τ cannot be less than 20ns (the equipment cannot queue waveforms of
less than 20ns), and the decay_delay and end_delay are automatically converted to be
multiples of 20ns (for efficient implementation).
"""

mutable struct Rabi <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    XYPulse::AnalogPulse #meant to hold IF_freq and amplitude
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

    Rabi(awgXY, awgRead, awgMarker, XYPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs) =
        new(awgXY, awgRead, awgMarker, XYPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
            IQ_readout_chs, MARKER_CH, PXI_LINE, :xyduration, "XY Pulse Duration")

    Rabi(awgXY, awgRead, awgMarker, XYPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel) = new(awgXY, awgRead,
        awgMarker, XYPulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs,
        markerCh, PXI_line, axisname, axislabel)
end

"""
```
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
end
```
Stimulus type for finding the T2* of a qubit. The corresponding source function
is `source(stim, τ)`, where τ is the delay between the two XY π/2 pulses.
Currently, τ cannot be less than 20ns (the equipment cannot queue waveforms of
less than 20ns), and the decay_delay and end_delay are automatically converted to be
multiples of 20ns (for efficient implementation).

"""
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

    Ramsey(awgXY, awgRead, awgMarker, π_2Pulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs) =
        new(awgXY, awgRead, awgMarker, π_2Pulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
            IQ_readout_chs, MARKER_CH, PXI_LINE, :ramseydelay, "Free Evolution Time")

    Ramsey(awgXY, awgRead, awgMarker, π_2Pulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel) = new(awgXY, awgRead,
        awgMarker, π_2Pulse, readoutPulse, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs,
        markerCh, PXI_line, axisname, axislabel)
end

"""
```
mutable struct StarkShift <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    πPulse::AnalogPulse #meant to hold IF_freq and amplitude
    drivePulse::DigitalPulse
    readoutPulse::DigitalPulse
    ringdown_delay::Float64
    end_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int

    #data
    axisname::Symbol
    axislabel::String
end
```

Stimulus type for finding how many photons go into the resonator for a given
drive pulse length. The corresponding source function is `source(stim, t)`, where
t is the drive pulse length. Briefly, the resonator is excited via a drive pulse of some variable
length (that is sourced), and the qubit is then immediately excited with a π pulse.
The drive pulse populates the resonator with photons, which stark-shifts the qubit,
thereby changing it's resonance frequency. Thus, in conjuction with sweeping the
XY LO frequency, the stark shift on the qubit for a readout pulse length can be found.
This in turn can be used to calculate how many photons go into the readout resonator
for a given pulse length. NOTE: The drive pulse amplitude, IF frequency, and IF phase
will be the same as those of the readout pulse when the stimulus is sourced.
"""
mutable struct StarkShift <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    πPulse::AnalogPulse #meant to hold IF_freq and amplitude
    readoutPulse::DigitalPulse
    ringdown_delay::Float64
    end_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int

    #data
    axisname::Symbol
    axislabel::String

    StarkShift(awgXY, awgRead, awgMarker, πPulse, readoutPulse, ringdown_delay,
        end_delay, IQ_XY_chs, IQ_readout_chs) = new(awgXY, awgRead, awgMarker, πPulse,
        readoutPulse, ringdown_delay, end_delay, IQ_XY_chs, IQ_readout_chs,
        MARKER_CH, PXI_LINE, :t1delay, "Delay")

    StarkShift(awgXY, awgRead, awgMarker, πPulse, readoutPulse, ringdown_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel) = new(awgXY, awgRead,
        awgMarker, πPulse, drivePulse, readoutPulse, ringdown_delay, end_delay, IQ_XY_chs,
        IQ_readout_chs, markerCh, PXI_line, axisname, axislabel)
end

"""
```
mutable struct CPecho <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    πPulse::AnalogPulse
    π_2Pulse::AnalogPulse
    readoutPulse::DigitalPulse
    n_π::Int
    τ::Float64
    decay_delay::Float64
    end_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int
end
```
Stimulus for measuring T2 of a qubit with the Carr-Purcell spin echo sequence.
The corresponding source function is `source(stim)`, where given the stimulus parameters
τ (the delay between the two XY π/2 pulses minus the length of all the intermediate π pulses combined),
and n_π (the number of π pulses), the source function outputs the appropriate echo pulse sequence
from the AWGs.

This stimulus type is not meant to be directly used with `sweep` (since its source function,
by design, does not take any inputs); rather, it acts as a intermediary for the
`CPecho_τ` and `CPecho_n` Stimulus types, which are meant to be easily used with `sweep`.
"""
mutable struct CPecho <: QubitCharacterization
    #AWGs
    awgXY::InsAWGM320XA
    awgRead::InsAWGM320XA
    awgMarker::InsAWGM320XA

    #pulses
    πPulse::AnalogPulse
    π_2Pulse::AnalogPulse
    readoutPulse::DigitalPulse
    n_π::Int
    τ::Float64
    decay_delay::Float64
    end_delay::Float64

    #awg configuration information
    IQ_XY_chs::Tuple{Int,Int}
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int

    CPecho(awgXY, awgRead, awgMarker, πPulse, π_2Pulse, readoutPulse, IQ_XY_chs,
            IQ_readout_chs) = new(awgXY, awgRead, awgMarker, πPulse, π_2Pulse, readoutPulse,
            1, 100e-9, DECAY_TIME, END_TIME, IQ_XY_chs, IQ_readout_chs, MARKER_CH, PXI_LINE)

    CPecho(awgXY, awgRead, awgMarker, πPulse, π_2Pulse, readoutPulse, decay_delay, end_delay,
            IQ_XY_chs, IQ_readout_chs) = new(awgXY, awgRead, awgMarker, πPulse, π_2Pulse, readoutPulse,
            1, 100e-9, decay_delay, end_delay, IQ_XY_chs, IQ_readout_chs, MARKER_CH, PXI_LINE)

    CPecho(awgXY, awgRead, awgMarker, πPulse, π_2Pulse, readoutPulse, n_π, τ, decay_delay,
       end_delay, IQ_XY_chs, IQ_readout_chs, markerCh, PXI_line) = new(awgXY, awgRead,
        awgMarker, πPulse, π_2Pulse, readoutPulse, n_π, τ, decay_delay, end_delay,
        IQ_XY_chs, IQ_readout_chs, markerCh, PXI_line)
end

"""
```
mutable struct CPecho_τ
    CPstim::CPecho
    axisname::Symbol
    axislabel::String
end
```

The corresponding source function for this Stimulus is `source(stim, τ)`. Sourcing
this stimulus changes the τ parameter of its `CPstim` object, and then sources
the `CPstim` object
"""
mutable struct CPecho_τ
    CPstim::CPecho
    axisname::Symbol
    axislabel::String
end

"""
```
mutable struct CPecho_n
    CPstim::CPecho
    axisname::Symbol
    axislabel::String
end
```

The corresponding source function for this Stimulus is `source(stim, n)`. Sourcing
this stimulus changes the n_π parameter of its `CPstim` object, and then sources
the `CPstim` object.
"""
mutable struct CPecho_n
    CPstim::CPecho
    axisname::Symbol
    axislabel::String
end

"""
```
mutable struct ReadoutReference <: Stimulus
    #AWGs
    awgRead::InsAWGM30XA
    awgMarker::InsAWGM30XA
    #pulses
    readoutPulse::DigitalPulse
    delay::Float64
    #awg configuration information
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int
    #data
    axisname::Symbol
    axislabel::String
end
```

Stimulus type for outputting readout pulses continuously, with a delay between each pulse.
The corresponding source function is source(stim).
"""
mutable struct ReadoutReference <: Stimulus
    #AWGs
    awgRead::InsAWGM30XA
    awgMarker::InsAWGM30XA
    #pulses
    readoutPulse::DigitalPulse
    delay::Float64
    #awg configuration information
    IQ_readout_chs::Tuple{Int,Int}
    markerCh::Int
    PXI_line::Int

    ReadoutReference(awgRead, awgMarker, readoutPulse, delay, IQ_readout_chs) =
        new(awgRead, awgMarker, readoutPulse, delay, IQ_readout_chs, MARKER_CH, PXI_LINE)

    ReadoutReference(awgRead, awgMarker, readoutPulse, delay, IQ_readout_chs, markerCh, PXI_line) =
        new(awgRead, awgMarker, readoutPulse, delay, IQ_readout_chs, markerCh, PXI_line)
end

include("source.jl")
