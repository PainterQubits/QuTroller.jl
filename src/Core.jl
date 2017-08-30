export CosEnvelope
export RectEnvelope
export AnalogPulse
export DigitalPulse


mutable struct CosEnvelope <: Envelope
    amplitude::Int
    duration::Float64
    waveform::Waveform

    CosEnvelope(amplitude::Integer, duration::Float64, sample_rate:: Integer = 1e9
                name::AbstractString = "Cos_A="*string(amplitude)*"_D="*string(duration)) = begin
        a = amplitude ; d = duration
        time_step = 1/sample_rate
        t = collect(0:time_step:duration) #time values
        waveformValues = a*(1 + cos(2π*(t - d/2)/d))/2
        env = new(a,d)
        env.waveform = Waveform(waveformValues, name)
        return env
    end
end

mutable struct RectEnvelope <: Envelope
    amplitude::Int
    duration::Float64
    waveform::Waveform

    RectEnvelope(amplitude::Integer, duration::Float64, sample_rate:: Integer = 1e9
                name::AbstractString = "Cos_A="*string(amplitude)*"_D="*string(duration)) = begin
        a = amplitude ; d = duration
        time_step = 1/sample_rate
        num_points = duration/time_step
        waveformValues = a* ones(num_points)
        env = new(a,d)
        env.waveform = Waveform(waveformValues, name)
        return env
    end
end

mutable struct AnalogPulse <: Pulse
    IF_freq::Float64
    sample_rate::Float64
    envelope::Envelope
    IF_phase::Float64
    AnalogPulse(IF_freq::Float64, sample_rate::Float64, envelope::Envelope,
        IF_phase::Float64 = 0) = new(IF_freq, IF_phase, sample_rate, envelope)
end

mutable struct DigitalPulse <: Pulse
    IF_freq::Float64
    sample_rate::Float64
    envelope::Envelope
    IF_phase::Float64
    I_waveform::Waveform
    Q_waveform::Waveform

    DigitalPulse(IF_freq::Float64, sample_rate::Float64, envelope::Envelope,
                 IF_phase = 0) = begin
        pulse = new(IF_freq, sample_rate, envelope, IF_phase)
        time_step = 1/sample_rate
        t = collect(0:time_step:envelope.duration)
        IF_signal = exp(im*(2π*IF_freq*t + IF_phase))
        full_pulse = IF_signal * envelope.waveform.waveformValues
        I_pulse = real(full_pulse)
        Q_pulse = imag(full_pulse)
        pulse.I_waveform = Waveform(I_pulse, "I_pulse_Freq="*string(IF_freq)*"_D="
                                    *string(envelope.duration))
        pulse.Q_waveform = Waveform(Q_pulse, "Q_pulse_Freq="*string(IF_freq)*"_D="
                                    *string(envelope.duration))
        return pulse
    end
end
