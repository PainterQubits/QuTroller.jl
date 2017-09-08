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
    sample_rate::Float64
    duration::Float64
    IF_phase::Float64
    amplitude::Float64
    envelope::Waveform

    AnalogPulse(IF_freq::Real, sample_rate::Real, duration::Real, IF_phase::Real) =
                new(IF_freq, sample_rate, duration, IF_phase)

    AnalogPulse(IF_freq::Real, sample_rate::Real, duration::Real, IF_phase::Real,
                env::Waveform) = begin
        pulse = new(IF_freq, sample_rate, duration, IF_phase)
        pulse.envelope = env
        return pulse
    end

    AnalogPulse(IF_freq::Real, sample_rate::Real, duration::Real, IF_phase::Real,
    amplitude::Real) = new(IF_freq, sample_rate, duration, IF_phase, amplitude)

    AnalogPulse(IF_freq::Real, sample_rate::Real, duration::Real, IF_phase::Real,
                amplitude::Real, env::Waveform) = new(IF_freq, sample_rate, duration,
                                                      IF_phase, amplitude, env)
end

function AnalogPulse(IF_freq::Real, sample_rate::Real, duration::Real,
                    ::Type{CosEnvelope}, IF_phase::Real = 0; name = string(CosEnvelope)*"_"*
                    string(amplitude)*"_"*string(duration))
        pulse = AnalogPulse(IF_freq, sample_rate, duration, IF_phase)
        pulse.envelope = Waveform(name, make_CosEnvelope(duration, sample_rate, name))
        return pulse
end

function AnalogPulse(IF_freq::Real, sample_rate::Real, duration::Real, amplitude::Real,
                    ::Type{CosEnvelope}, IF_phase::Real = 0; name = string(CosEnvelope)*"_"*
                    string(amplitude)*"_"*string(duration))
    pulse = AnalogPulse(IF_freq, sample_rate, duration, IF_phase, amplitude)
    pulse.envelope = Waveform(name, make_CosEnvelope(duration, sample_rate))
    return pulse
end

function AnalogPulse(IF_freq::Real, sample_rate::Real, duration::Real,
                    ::Type{RectEnvelope}, IF_phase::Real = 0; name = string(RectEnvelope)*"_"*
                    string(amplitude)*"_"*string(duration))
        pulse = AnalogPulse(IF_freq, sample_rate, duration, IF_phase)
        pulse.envelope = Waveform(name, make_RectEnvelope(duration, sample_rate))
        return pulse
end

function AnalogPulse(sample_rate::Real, duration::Real, ::Type{Delay},
                     name = string(Delay)*"_"*string(duration))
        pulse = AnalogPulse(0, sample_rate, duration, 0)
        pulse.envelope = Waveform(name, make_Delay(duration, sample_rate))
        return pulse
end

mutable struct DigitalPulse <: Pulse
    IF_freq::Float64
    sample_rate::Float64
    duration::Float64
    IF_phase::Float64
    amplitude::Float64
    I_waveform::Waveform
    Q_waveform::Waveform
    DigitalPulse(IF_freq::Real, sample_rate::Real, duration::Real, IF_phase::Real,
                amplitude::Real) = new(IF_freq, sample_rate, duration, IF_phase, amplitude)
end

function DigitalPulse(IF_freq::Real, sample_rate::Real, duration::Real, amplitude::Real,
            ::Type{CosEnvelope}, IF_phase::Real = 0; name = string(T)*"_"*
            string(amplitude)*"_"*string(duration))
    pulse = DigitalPulse(IF_freq, sample_rate, duration, IF_phase, amplitude)
    env = make_CosEnvelope(duration, sample_rate, "temp_wav_object")
    IF_signal = exp(im*(2π*IF_freq*t + IF_phase))
    full_pulse = IF_signal*amplitude* env
    I_pulse = real(full_pulse)
    Q_pulse = imag(full_pulse)
    pulse.I_waveform = Waveform(I_pulse, "I_"*name)
    pulse.Q_waveform = Waveform(Q_pulse, "Q_"*name)
    return pulse
end

#helper functions
function make_CosEnvelope(duration::Real, sample_rate::Real)
    d = duration
    time_step = 1/sample_rate
    t = collect(0:time_step:duration)
    env = (1 + cos(2π*(t - d/2)/d))/2
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
