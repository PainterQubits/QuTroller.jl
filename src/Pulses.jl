export Pulse

export Envelope
export CosEnvelope
export RectEnvelope

export PulseEdge
export SineEdge
export RectEdge

export AnalogPulse
export DigitalPulse
export DCPulse
export DelayPulse

export make_RectEnvelope
export make_Delay
export make_CosEnvelope
export make_SineEdge

export load_pulse

"""
Subtypes of this abstract type are meant to be inputs to `DigitalPulse` and `AnalogPulse`
functions; this input informs the function which kind of windowing to apply to a pulse.
"""
abstract type Envelope end


abstract type CosEnvelope <: Envelope end
abstract type RectEnvelope <: Envelope end
abstract type Delay <: Envelope end

"""
Subtypes of this abstract type are meant to be inputs to the `DCPulse` function;
this input informs the function which kind of edges to synthesize for a DC pulse.
"""
abstract type PulseEdge end

abstract type SineEdge <: PulseEdge end
abstract type RectEdge <: PulseEdge end


"""
Substypes of this abstract type are handles to pulses, which will be synthesized
by the AWG. They hold, as fields, the waveform values as well as parameters
for configuring the AWG channels which will output the pulses
"""
abstract type Pulse end

"""
An object of `AnalogPulse` is meant to be a handle to a pulse generated by using
a channel's arbitrary waveform generator to amplitude modulate the output of a
channel's Function Generator. It holds the envelope waveform which is the modulating signal,
it's duration, as well as well as the phase of the periodic signal.

There are two inner constructors to make an `AnalogPulse` object:
        AnalogPulse(IF_phase, duration)
        AnalogPulse(IF_phase, duration, env)

as well as an overloaded function which allows for standard/optional arguments:
        AnalogPulse(duration::Real, ::Type{CosEnvelope}, sample_rate::Real, IF_phase::Real = 0)
        AnalogPulse(duration::Real, ::Type{RectEnvelope}, sample_rate::Real, IF_phase::Real = 0)

where besides fields on the type, the function also takes as input singleton objects
of subtypes of the abstract type `Envelope`; this input determines what kind of
envelope will be synthesized to be used as a modulating signal.
"""
mutable struct AnalogPulse <: Pulse
    IF_phase::Float64
    duration::Float64
    envelope::Waveform

    AnalogPulse(IF_phase, duration) = new(IF_phase, duration)
    AnalogPulse(IF_phase, duration, env) = new(IF_phase, duration, env)
end

function AnalogPulse(duration::Real, ::Type{CosEnvelope}, sample_rate::Real,
                    IF_phase::Real = 0; name = "CosEnvelope_"*string(duration))
        env = Waveform(make_CosEnvelope(duration, sample_rate), name)
        #loop below front-pads pulses with zeros
        if (rem(floor(duration/1e-9 + 0.001), 10) != 0.0)
            ten_ns = Int(round(10e-9*sample_rate))
            pad_zeros = ten_ns - Int(rem(floor(duration*sample_rate + 0.001), ten_ns))
            env.waveformValues = append!(zeros(pad_zeros), env.waveformValues)
            duration = size(env.waveformValues)[1]/sample_rate
            println("Your pulse was front-padded with zeros to achieve correct samples number")
        end
        pulse = AnalogPulse(IF_phase, duration, env)
        return pulse
end

function AnalogPulse(duration::Real, ::Type{RectEnvelope}, sample_rate::Real,
                    IF_phase::Real = 0; name = "RectEnvelope_"*string(duration))
        env = Waveform(make_RectEnvelope(duration, sample_rate), name)
        #loop below front-pads pulses with zeros
        if (rem(floor(duration/1e-9 + 0.001), 10) != 0.0)
            ten_ns = Int(round(10e-9*sample_rate))
            pad_zeros = ten_ns - Int(rem(floor(duration*sample_rate + 0.001), ten_ns))
            env.waveformValues = append!(zeros(pad_zeros), env.waveformValues)
            duration = size(env.waveformValues)[1]/sample_rate
            println("Your pulse was front-padded with zeros to achieve correct samples number")
        end
        pulse = AnalogPulse(IF_phase, duration, env)
        return pulse
end


"""
An object of `DigitalPulse` is meant to be a handle to I and Q pulses generated
directly by a channel's arbitrary waveform generator, which eventually are used
to make a ~GHz pulse (along with an IQ mixer). It holds both the I and Q
waveforms, as wll as the pulse's duration.

There are three inner constructors to make an `DigitalPulse` object:
        DigitalPulse(IF_freq, IF_phase)
        DigitalPulse(IF_freq, IF_phase, duration)
        DigitalPulse(IF_freq, IF_phase, duration, I_wav, Q_wav)

as well as an overloaded function which allows for standard/optional arguments:
        DigitalPulse(IF_freq::Real, duration::Real, ::Type{CosEnvelope},
           sample_rate::Real, IF_phase::Real = 0)
        DigitalPulse(IF_freq::Real, duration::Real, ::Type{RectEnvelope},
           sample_rate::Real, IF_phase::Real = 0)

where besides fields on the type, the function also takes as input singleton objects of
subtypes of the abstract type `Envelope`; this input determines what kind of envelope
will be synthesized to be multiplied to the periodic signal to make the final I and Q waveforms

"""
mutable struct DigitalPulse <: Pulse
    IF_freq::Float64
    IF_phase::Float64
    duration::Float64
    I_waveform::Waveform
    Q_waveform::Waveform

    DigitalPulse(IF_freq, IF_phase) = new(IF_freq, IF_phase)
    DigitalPulse(IF_freq, IF_phase, duration) = new(IF_freq, IF_phase, duration)
    DigitalPulse(IF_freq, IF_phase, duration, I_wav, Q_wav) =
                 new(IF_freq, IF_phase, duration, I_wav, Q_wav)
end

function DigitalPulse(IF_freq::Real, duration::Real, ::Type{CosEnvelope},
                      sample_rate::Real, IF_phase::Real = 0; name = "CosEnvelope_"*
                      string(duration))
    env = make_CosEnvelope(duration, sample_rate)
    pulse = DigitalPulse_general(IF_freq, duration, env, sample_rate,
                                 IF_phase, name)
    return pulse
end

function DigitalPulse(IF_freq::Real, duration::Real, ::Type{RectEnvelope},
                      sample_rate::Real, IF_phase::Real = 0; name = "CosEnvelope_"*
                      string(duration))
    env = make_RectEnvelope(duration, sample_rate)
    pulse = DigitalPulse_general(IF_freq, duration, env, sample_rate,
                                 IF_phase, name)
    return pulse
end

"""
An object of the `DCPulse` subtype is meant to be a handle to square pulses which
are used to entangle two qubits; where the pulse is generated directly by a channel's
arbitrary waveform generator. It holds the actual pulse waveform, as well as
it's duration and information to configure the channel that will be outputting the pulse

There are two inner constructors to make an `DCPulse` object:
        DCPulse(duration, waveform)
        DCPulse()

as well as an overloaded function which allows for standard/optional arguments:
        DCPulse(duration::Real, ::Type{SineEdge}, sample_rate::Real,
          edge_freq = 20e6)
        DCPulse(duration::Real, ::Type{RectEdge}, sample_rate::Real)

where besides fields on the type, the function also takes as input singleton objects of
subtypes of the abstract type `Edge`; this input determines what kind of edges the
square pulse will have.
"""
mutable struct DCPulse <: Pulse
    duration::Float64
    waveform::Waveform

    DCPulse(duration, waveform) = new(duration, waveform)
    DCPulse() = new()
end

function DCPulse(duration::Real, ::Type{SineEdge}, sample_rate::Real;
             name = "DCPulse_"*string(duration), edge_freq::Real = 20e6)
    rising_edge, falling_edge = make_SineEdge(sample_rate, edge_freq)
    pulse = DCPulse_general(duration, rising_edge, falling_edge, sample_rate, name)
    return pulse
end

function DCPulse(duration::Real, ::Type{RectEdge}, sample_rate::Real;
             name = "DCPulse_"*string(duration))
    offset = make_RectEnvelope(duration, sample_rate)
    offset_wav = Waveform(offset, name)
    if (rem(floor(duration/1e-9 + 0.001), 10) != 0.0)
        ten_ns = Int(round(10e-9*sample_rate))
        pad_zeros = ten_ns - Int(rem(floor(duration*sample_rate + 0.001), ten_ns))
        append!(offset_wav.waveformValues, zeros(pad_zeros))
        duration = size(offset_wav.waveformValues)[1]/sample_rate
        println("Your pulse was back-padded with zeros to achieve correct samples number")
    end
    pulse = DCPulse(duration, offset_wav)
    return pulse
end

"""
An object of the `DelayPulse` subtype is meant to be a handle to "pulses" which
just consist zero output, which provide a means of inserting delays between
non-delay pulses. The object holds the duration of the pulse as well as the actual
pulse waveform. There are two inner constructors for making this object:

        DelayPulse(duration::Real, sample_rate::Real; name = "Delay_" * string(duration) * "s")
        DelayPulse(duration::Real, waveform::Waveform) = new(duration, waveform)

The second constructor takes as input both fields of the object; the first constructor
takes as input the duration, sample_rate and a name, constructs the waveform
and then makes the object.
"""
mutable struct DelayPulse <: Pulse
    duration::Float64
    waveform::Waveform

    DelayPulse(duration::Real, sample_rate::Real; name = "Delay_" * string(duration) * "s") = begin
        delay_wav = Waveform(make_Delay(duration, sample_rate), name)
        pulse = new(duration, delay_wav)
        return pulse
    end

    DelayPulse(duration::Real, waveform::Waveform) = new(duration, waveform)
end

"""
        load_pulse(awg::InsAWGM320XA, pulse::Pulse, id::Integer)
        load_pulse(awg::InsAWGM320XA, pulse::DigitalPulse, I_id::Integer, Q_id::Integer)
        load_pulse(awg::InsAWGM320XA, pulse::Pulse, name::AbstractString)
        load_pulse(awg::InsAWGM320XA, pulse::Pulse)

Funtion to load the waveforms of pulse objects. If id(s) are provided as input,
then the waveforms are loaded with those id(s). If a name is provided as input, then
the function first looks to see if there is a waveform with the pulse's waveform name
already loaded in the awg, and if there is, it loads the new pulse waveform with that
same id (thereby replacing the old waveform with the same name in memory). If there is
not a waveform with the pulse's waveform name already loaded, then it simply loads
the pulse waveform with an id +1 bigger than the largest waveform id of the waveforms
loaded in the awg.
"""
function load_pulse end

load_pulse(awg::InsAWGM320XA, pulse::AnalogPulse, id::Integer) = load_waveform(awg, pulse.envelope, id)

load_pulse(awg::InsAWGM320XA, pulse::DCPulse, id::Integer) = load_waveform(awg, pulse.waveform, id)

load_pulse(awg::InsAWGM320XA, pulse::DelayPulse, id::Integer) = load_waveform(awg, pulse.waveform, id)

function load_pulse(awg::InsAWGM320XA, pulse::DigitalPulse, I_id::Integer, Q_id::Integer)
    load_waveform(awg, pulse.I_waveform, I_id)
    load_waveform(awg, pulse.Q_waveform, Q_id)
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::DCPulse, name::AbstractString)
    if !(pulse.waveform in values(awg.waveforms))
        load_waveform(awg, pulse.waveform, find_wav_id(awg, name))
    end
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::DelayPulse, name::AbstractString)
    if !(pulse.waveform in values(awg.waveforms))
        load_waveform(awg, pulse.waveform, find_wav_id(awg, name))
    end
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::AnalogPulse, name::AbstractString)
    if !(pulse.envelope in values(awg.waveforms))
        load_waveform(awg, pulse.envelope, find_wav_id(awg, name))
    end
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::DigitalPulse, name::AbstractString)
    if !(pulse.I_waveform in values(awg.waveforms))
        load_waveform(awg, pulse.I_waveform, find_wav_id(awg, "I_"*name))
    end
    if !(pulse.Q_waveform in values(awg.waveforms))
        load_waveform(awg, pulse.Q_waveform, find_wav_id(awg, "Q_"*name))
    end
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::AnalogPulse)
    env = pulse.envelope
    (env in values(awg.waveforms)) || load_waveform(awg, env, make_wav_id(awg))
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::DCPulse)
    wav = pulse.waveform
    (wav in values(awg.waveforms)) || load_waveform(awg, wav, make_wav_id(awg))
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::DelayPulse)
    wav = pulse.waveform
    (wav in values(awg.waveforms)) || load_waveform(awg, wav, make_wav_id(awg))
    nothing
end

function load_pulse(awg::InsAWGM320XA, pulse::DigitalPulse)
    read_I_wav = pulse.I_waveform
    read_Q_wav = pulse.Q_waveform
    (read_I_wav in values(awg.waveforms)) || load_waveform(awg, read_I_wav, make_wav_id(awg))
    (read_Q_wav in values(awg.waveforms)) || load_waveform(awg, read_Q_wav, make_wav_id(awg))
    nothing
end


#helper functions

function DigitalPulse_general(IF_freq::Real, duration::Real,
                              env::Vector{Float64}, sample_rate::Real, IF_phase::Real,
                              name::AbstractString)
    d = duration
    time_step = 1/sample_rate; t = linspace(time_step, d, floor(d/time_step + 0.001))
    IF_signal = exp.(im*(2π*IF_freq*t + IF_phase))
    full_pulse = IF_signal.*env
    I_pulse = real(full_pulse)
    Q_pulse = imag(full_pulse)
    I_wav = Waveform(I_pulse, "I_"*name)
    Q_wav = Waveform(Q_pulse, "Q_"*name)
    if (rem(floor(duration/1e-9 + 0.001), 10) != 0.0)
        ten_ns = Int(round(10e-9*sample_rate))
        pad_zeros = ten_ns - Int(rem(floor(duration*sample_rate + 0.001), ten_ns))
        append!(I_wav.waveformValues, zeros(pad_zeros))
        append!(Q_wav.waveformValues, zeros(pad_zeros))
        duration = size(I_wav.waveformValues)[1]/sample_rate
        println("Your pulse was back-padded with zeros to achieve correct samples number")
    end
    pulse = DigitalPulse(IF_freq, IF_phase, duration, I_wav, Q_wav)
    return pulse
 end

function DCPulse_general(duration::Real, rising_edge::Vector{Float64},
           falling_edge::Vector{Float64}, sample_rate::Real, name::AbstractString)
    num_t_points = Int(round(duration * sample_rate))
    dc_part = ones(num_t_points - size(rising_edge)[1] - size(falling_edge)[1])
    pulse_values = vcat(rising_edge, dc_part, falling_edge)
    pulse_wav = Waveform(pulse_values, name)
    if (rem(floor(duration/1e-9 + 0.001), 10) != 0.0)
        ten_ns = Int(round(10e-9*sample_rate))
        pad_zeros = ten_ns - Int(rem(floor(duration*sample_rate + 0.001), ten_ns))
        append!(pulse_wav.waveformValues, zeros(pad_zeros))
        duration = size(pulse_wav.waveformValues)[1]/sample_rate
        println("Your pulse was back-padded with zeros to achieve correct samples number")
    end
    pulse = DCPulse(duration, pulse_wav)
    return pulse
end

function make_CosEnvelope(duration::Real, sample_rate::Real)
    d = duration
    time_step = 1/sample_rate
    t = linspace(time_step, d, floor(d/time_step + 0.001)) #floor and + 0.001 for consistent rounding and no floating point errors
    env = (1 + cos.(2π*(t - d/2)/d))/2
    return env
end

function make_RectEnvelope(duration::Real, sample_rate::Real)
    d = duration
    time_step = 1/sample_rate
    t = linspace(time_step, d, floor(d/time_step + 0.001)); num_points = size(t)[1] #floor and + 0.001 for consistent rounding and no floating point errors
    env = ones(num_points)
    return env
end

function make_Delay(duration::Real, sample_rate::Real)
    d = duration
    time_step = 1/sample_rate
    num_points = floor(duration/time_step + 0.001) #floor and + 0.001 for consistent rounding and no floating point errors
    env = zeros(num_points)
    return env
end

function make_SineEdge(sample_rate::Real, edge_freq::Real)
    edge_length = 0.25*(1/edge_freq)
    edge_length_rising = floor(edge_length, 9)
    edge_length_falling = floor(edge_length, 9)
    time_step = 1/sample_rate
    rise_t = linspace(time_step, edge_length_rising, round(edge_length_rising/time_step))
    fall_t = linspace(time_step, edge_length_falling, round(edge_length_falling/time_step))
    rising_edge = sin.(2*π*edge_freq*rise_t)
    falling_edge = sin.(2*π*edge_freq*fall_t + π/2)
    return rising_edge, falling_edge
end
