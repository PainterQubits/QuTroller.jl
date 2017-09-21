export Pulse

export Envelope
export CosEnvelope
export RectEnvelope
export AnalogPulse
export DigitalPulse

"""
Subtypes of this abstract type are meant to distiguish between the kinds of windowing
to apply to a pulse.
"""
abstract type Envelope end

abstract type CosEnvelope <: Envelope end
abstract type RectEnvelope <: Envelope end
abstract type Delay <: Envelope end

abstract type Pulse end

"""
AnalogPulse is meant to represent a Pulse generated via using a channel's arbitrary
waveform generator to amplitude modulate the output of a channel's Function Generator.
It holds the envelope waveform which is the modulating signal, it's duration, as well
as pulse parameters used to configure the particular AWG channel generating the
pulse: IF_freq, amplitude, and  IF_phase.
"""
mutable struct AnalogPulse <: Pulse
    IF_freq::Float64
    amplitude::Float64
    IF_phase::Float64
    duration::Float64
    envelope::Waveform

    AnalogPulse(IF_freq, amplitude, IF_phase) = new(IF_freq, amplitude, IF_phase)    

    AnalogPulse(IF_freq, amplitude, IF_phase, duration) =
               new(IF_freq, amplitude, IF_phase, duration)

    AnalogPulse(IF_freq, amplitude, IF_phase, duration, env) =
               new(IF_freq, amplitude, IF_phase, duration, env)
end

function AnalogPulse(IF_freq::Real, amplitude::Real, duration::Real, ::Type{CosEnvelope},
                    sample_rate::Real, IF_phase::Real = 0; name = "CosEnvelope_"*
                    string(amplitude)*"_"*string(duration))
        env = Waveform(make_CosEnvelope(duration, sample_rate), name)
        pulse = AnalogPulse(IF_freq, amplitude, IF_phase, duration, env)
        return pulse
end

function AnalogPulse(IF_freq::Real, amplitude::Real, duration::Real, ::Type{RectEnvelope},
                     sample_rate::Real, IF_phase::Real = 0; name = "RectEnvelope_"*
                     string(amplitude)*"_"*string(duration))
        env = Waveform(make_RectEnvelope(duration, sample_rate), name)
        pulse = AnalogPulse(IF_freq, amplitude, IF_phase, duration, env)
        return pulse
end

function AnalogPulse(duration::Real, ::Type{Delay}, sample_rate::Real,
                     name = string(Delay)*"_"*string(duration))
        env = Waveform(make_Delay(duration, sample_rate), name)
        pulse = AnalogPulse(-1,-1, -1,  duration, env)
        return pulse
end

"""
DigitalPulse is meant to represent a Pulse generated entirely via a channel's arbitrary
waveform generator, i.e., it's output is the channel's ouput. It holds the I and Q
waveforms which are meant to be directly outputted from the I and Q channels of the
AWG, as well as parameters used to generate these waveforms:IF_freq, IF_phase, and
duration. It also holds amplitude information, which is used to configure the
I and Q channels of the AWG.
"""
mutable struct DigitalPulse <: Pulse
    IF_freq::Float64
    amplitude::Float64
    IF_phase::Float64
    duration::Float64
    I_waveform::Waveform
    Q_waveform::Waveform

    DigitalPulse(IF_freq, amplitude, IF_phase) = new(IF_freq, amplitude, IF_phase)

    DigitalPulse(IF_freq, amplitude, IF_phase, duration) =
                 new(IF_freq, amplitude, IF_phase, duration)

    DigitalPulse(IF_freq, amplitude, IF_phase, duration, I_wav, Q_wav) =
                 new(IF_freq, amplitude, IF_phase, duration, I_wav, Q_wav)
end

function DigitalPulse(IF_freq::Real, amplitude::Real, duration::Real, ::Type{CosEnvelope},
                      sample_rate::Real, IF_phase::Real = 0; name = name = "CosEnvelope_"*
                      string(amplitude)*"_"*string(duration))
    env = make_CosEnvelope(duration, sample_rate)
    time_step = 1/sample_rate; t = collect(0:time_step:duration)
    IF_signal = exp.(im*(2π*IF_freq*t + IF_phase))
    full_pulse = IF_signal.*env
    I_pulse = real(full_pulse)
    Q_pulse = imag(full_pulse)
    I_wav = Waveform(I_pulse, "I_"*name)
    Q_wav = Waveform(Q_pulse, "Q_"*name)
    pulse = DigitalPulse(IF_freq, amplitude, IF_phase, duration, I_wav, Q_wav)
    return pulse
end

#helper functions
function make_CosEnvelope(duration::Real, sample_rate::Real)
    d = duration
    time_step = 1/sample_rate
    t = collect(0:time_step:d)
    env = (1 + cos.(2π*(t - d/2)/d))/2
    return env
end

function make_RectEnvelope(duration::Real, sample_rate::Real)
    d = duration
    time_step = 1/sample_rate
    num_points = round(duration/time_step)
    env = ones(num_points)
    return env
end

function make_Delay(duration::Real, sample_rate::Real)
    d = duration
    time_step = 1/sample_rate
    num_points = round(duration/time_step)
    env = zeros(num_points)
    return env
end
