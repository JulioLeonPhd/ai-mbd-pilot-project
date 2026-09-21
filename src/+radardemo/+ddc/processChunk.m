function [output, state] = processChunk(input, state, design)
%PROCESSCHUNK Process one real ADC chunk with continuous DDC state.
%   [OUTPUT, STATE] = RADARDEMO.DDC.PROCESSCHUNK(INPUT, STATE, DESIGN)
%   mixes, filters, and decimates a finite real double [N,C] chunk. An empty
%   chunk returns an empty output and an unchanged state.

arguments
    input double
    state struct
    design struct
end

if isempty(input)
    output = complex(zeros(0, state.channelCount));
    return
end
if ~isreal(input)
    error("radardemo:ddc:InputType", "DDC input must be real double samples.");
end
if ~ismatrix(input) || size(input, 2) ~= state.channelCount
    error("radardemo:ddc:InputShape", "DDC input must have shape [N, channelCount].");
end
if any(~isfinite(input), "all")
    error("radardemo:ddc:NonfiniteInput", "DDC input must be finite real double.");
end
sampleCount = size(input, 1);
sampleIndex = double(state.inputSampleCount) + (0:sampleCount - 1).';
mixer = exp(-1i * 2 * pi * design.mixerFrequencyHz / design.adcRateHz * sampleIndex);
mixed = input .* mixer;
[stage1Output, state.stage1Delay] = filter(design.stage1Numerator, 1, mixed, ...
    state.stage1Delay, 1);
firstStageIndex = 1 + mod(3 - double(state.stage1Phase), 3);
stage1Samples = stage1Output(firstStageIndex:3:end, :);
state.stage1Phase = uint8(mod(double(state.stage1Phase) + sampleCount, 3));
[stage2Output, state.stage2Delay] = filter(design.stage2Numerator, 1, stage1Samples, ...
    state.stage2Delay, 1);
firstOutputIndex = 1 + mod(4 - double(state.stage2Phase), 4);
output = stage2Output(firstOutputIndex:4:end, :);
state.stage2Phase = uint8(mod(double(state.stage2Phase) + size(stage1Samples, 1), 4));
state.inputSampleCount = state.inputSampleCount + uint64(sampleCount);
end
