export Pulse

export Envelope
export CosEnvelope
export RectEnvelope
export AnalogPulse
export DigitalPulse

abstract type Pulse end

abstract type Envelope end
abstract type CosEnvelope <: Envelope end
abstract type RectEnvelope <: Envelope end
abstract type Delay <: Envelope end

mutable struct AnalogPulse <: Pulse
    IF_freq::Float64
    duration::Float64
    IF_phase::Float64
    envelope::Waveform

    AnalogPulse(IF_freq::Real, duration::Real, IF_phase::Real) =
                new(IF_freq, duration, IF_phase)

    AnalogPulse(IF_freq::Real, duration::Real, IF_phase::Real, env::Waveform) =
                new(IF_freq, duration, IF_phase, env)
end

function AnalogPulse(IF_freq::Real, duration::Real, ::Type{CosEnvelope}, sample_rate::Real,
                    IF_phase::Real = 0; name = string(CosEnvelope)*"_"*string(duration))
        env = Waveform(make_CosEnvelope(duration, sample_rate), name)
        pulse = AnalogPulse(IF_freq, duration, IF_phase, env)
        return pulse
end

function AnalogPulse(IF_freq::Real, duration::Real, ::Type{RectEnvelope}, sample_rate::Real,
                    IF_phase::Real = 0; name = string(RectEnvelope)*"_"*string(duration))
        env = Waveform(make_RectEnvelope(duration, sample_rate), name)
        pulse = AnalogPulse(IF_freq, duration, IF_phase, env)
        return pulse
end

function AnalogPulse(duration::Real, ::Type{Delay}, sample_rate::Real,
                     name = string(Delay)*"_"*string(duration))
        env = Waveform(make_Delay(duration, sample_rate), name)
        pulse = AnalogPulse(-1, duration, -1, env)
        return pulse
end

mutable struct DigitalPulse <: Pulse
    IF_freq::Float64
    duration::Float64
    IF_phase::Float64
    I_waveform::Waveform
    Q_waveform::Waveform
    DigitalPulse(IF_freq::Real,duration::Real, IF_phase::Real) = new(IF_freq, duration, IF_phase)

    DigitalPulse(IF_freq::Real,duration::Real, IF_phase::Real, I_wav::Waveform,
                Q_wav::Waveform) = new(IF_freq, duration, IF_phase, I_wav, Q_wav)
end

function DigitalPulse(IF_freq::Real, duration::Real, ::Type{CosEnvelope}, sample_rate::Real,
                      IF_phase::Real = 0; name = string(CosEnvelope)*"_"*string(duration))
    env = make_CosEnvelope(duration, sample_rate)
    time_step = 1/sample_rate; t = collect(0:time_step:duration)
    IF_signal = exp.(im*(2π*IF_freq*t + IF_phase))
    full_pulse = IF_signal.*env
    I_pulse = real(full_pulse)
    Q_pulse = imag(full_pulse)
    I_wav = Waveform(I_pulse, "I_"*name)
    Q_wav = Waveform(Q_pulse, "Q_"*name)
    pulse = DigitalPulse(IF_freq, duration, IF_phase, I_wav, Q_wav)
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
