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
    end
end

mutable struct AnalogPulse <: Pulse
    IF_freq::Float64
    IF_phase::Float64
    sample_rate::Float64
    envelope::Envelope
end

mutable struct DigitalPulse <: Pulse
    IF_freq::Float64
    IF_phase::Float64
    sample_rate::Float64
    waveform::Waveform
end
