export QubitCharacterization
export T1
export Rabi
export Ramsey
export StarkShift
export CPecho
export CPecho_n
export CPecho_τ
export PiNoPiTesting
export ReadoutReference
export DoubleRabi

"""
A Stimulus subtype for doing single qubit characterization experiments, such as
measuring T1, T2, doing Rabi oscillation experiments, etc. It's composite subtypes
usually hold two fieldsL: a qubit and a XY pulse.
"""
abstract type QubitCharacterization <: Stimulus end

"""
```
mutable struct T1 <: QubitCharacterization
    q::Qubit
    πPulse::AnalogPulse
    axisname::Symbol
    axislabel::String

    T1(q, πPulse) = new(q, πPulse, :t1delay, "Delay")
    T1(q, πPulse, axisname, axislabel) = new(q, πPulse, axisname, axislabel)
end
```

Stimulus type for finding the T1 of a qubit. The corresponding source function
is `source(stim, τ)`, where τ is the delay between the XY pulse and the readout pulse.
Currently, τ cannot be less than 20ns (the equipment cannot queue waveforms of
less than 20ns), and the decay_delay and end_delay (configured in the QubitController
object) are automatically converted to be multiples of 20ns (for efficient implementation)
"""
mutable struct T1 <: QubitCharacterization
    q::Qubit
    πPulse::AnalogPulse
    axisname::Symbol
    axislabel::String

    T1(q, πPulse) = new(q, πPulse, :t1delay, "Delay")
    T1(q, πPulse, axisname, axislabel) = new(q, πPulse, axisname, axislabel)
end

"""
```
mutable struct Rabi <: QubitCharacterization
    q::Qubit
    axisname::Symbol
    axislabel::String

    Rabi(q) = new(q, :xyduration, "XY Pulse Duration")
    Rabi(q, axisname, axislabel) = new(q, axisname, axislabel)
end
```

Stimulus type for doing Rabi Oscillations with a qubit. The corresponding source function
is `source(stim, t)`, where t is the the length of the XY pulse.
Currently, t cannot be less than 20ns (the equipment cannot queue waveforms of
less than 20ns), and the decay_delay and end_delay (configured in the QubitController
object) are automatically converted to be multiples of 20ns (for efficient implementation)
"""

mutable struct Rabi <: QubitCharacterization
    q::Qubit
    axisname::Symbol
    axislabel::String

    Rabi(q) = new(q, :xyduration, "XY Pulse Duration")
    Rabi(q, axisname, axislabel) = new(q, axisname, axislabel)
end

"""
```
mutable struct Ramsey <: QubitCharacterization
    q::Qubit
    π_2Pulse::AnalogPulse
    axisname::Symbol
    axislabel::String

    Ramsey(q, π_2Pulse) = new(q, π_2Pulse, :ramseydelay, "Free Evolution Time")
    Ramsey(q, π_2Pulse, axisname, axislabel) = new(q, π_2Pulse, axisname, axislabel)
end
```
Stimulus type for finding the T2* of a qubit. The corresponding source function
is `source(stim, τ)`, where τ is the delay between the two XY π/2 pulses.
Currently, τ cannot be less than 20ns (the equipment cannot queue waveforms of
less than 20ns), and the decay_delay and end_delay are automatically converted to be
multiples of 20ns (for efficient implementation).

"""
mutable struct Ramsey <: QubitCharacterization
    q::Qubit
    π_2Pulse::AnalogPulse
    axisname::Symbol
    axislabel::String

    Ramsey(q, π_2Pulse) = new(q, π_2Pulse, :ramseydelay, "Free Evolution Time")
    Ramsey(q, π_2Pulse, axisname, axislabel) = new(q, π_2Pulse, axisname, axislabel)
end

"""
```
mutable struct StarkShift <: QubitCharacterization
    q::Qubit
    πPulse::AnalogPulse
    ringdown_delay::Float64
    axisname::Symbol
    axislabel::String

    StarkShift(q, πPulse, ringdown_delay) = new(q, πPulse, ringdown_delay :drivetime, "Drive Pulse Length")
    StarkShift(q, πPulse, ringdown_delay, axisname, axislabel) = new(q, πPulse,
               ringdown_delay, axisname, axislabel)
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
    q::Qubit
    πPulse::AnalogPulse
    ringdown_delay::Float64
    axisname::Symbol
    axislabel::String

    StarkShift(q, πPulse, ringdown_delay) = new(q, πPulse, ringdown_delay :drivetime, "Drive Pulse Length")
    StarkShift(q, πPulse, ringdown_delay, axisname, axislabel) = new(q, πPulse,
               ringdown_delay, axisname, axislabel)
end

"""
```
mutable struct CPecho <: QubitCharacterization
    q::Qubit
    πPulse::AnalogPulse
    π_2Pulse::AnalogPulse
    n_π::Int
    τ::Float64
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
    q::Qubit
    πPulse::AnalogPulse
    π_2Pulse::AnalogPulse
    n_π::Int
    τ::Float64
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

    CPecho_τ(CPstim) = new(CPstim, :echo_delay, "Idle Time Between π/2 Pulses")
    CPecho_τ(CPstim, axisname, axislabel) = new(CPstim, axisname, axislabel)
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

    CPecho_n(CPstim) = new(CPstim, :n_pi, "Number of π Pulses")
    CPecho_n(CPstim, axisname, axislabel) = new(CPstim, axisname, axislabel)
end

"""
```
mutable struct ReadoutReference <: Stimulus
    delay::Float64
end
```

Stimulus type for outputting readout pulses continuously, with a delay between each pulse.
The corresponding source function is source(stim).
"""
mutable struct ReadoutReference <: Stimulus
    delay::Float64
end

mutable struct DoubleRabi <: QubitCharacterization
    q1::Qubit
    q2::Qubit
    axisname::Symbol
    axislabel::String

    DoubleRabi(q1, q2) = new(q1, q2, :xyduration, "XY Pulse Duration")
end

include("configure_awgs.jl")
include("source.jl")
