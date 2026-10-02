function [output, metadata] = processFrame(adcPriSamples, design)
%PROCESSFRAME Process one complete physical PRI with fresh local DDC state.
%   [OUTPUT, METADATA] = RADARDEMO.DDC.PROCESSFRAME(ADCPRISAMPLES, DESIGN)
%   mixes, filters, and decimates finite real double [N,C] samples from one
%   aligned physical PRI. The complex [N/12,C] output retains startup rows
%   and contains no padded or flushed tail. The sample-domain metadata does
%   not include a global timestamp or range coordinate.

arguments
    adcPriSamples double
    design struct
end

if ~ismatrix(adcPriSamples)
    error("radardemo:ddc:InputShape", ...
        "DDC input must be a two-dimensional [N,C] sample matrix.");
end
if ~isreal(adcPriSamples)
    error("radardemo:ddc:InputType", "DDC input must contain real double samples.");
end
if any(~isfinite(adcPriSamples), "all")
    error("radardemo:ddc:NonfiniteInput", "DDC input must contain finite samples.");
end

inputSampleCount = size(adcPriSamples, 1);
channelCount = size(adcPriSamples, 2);
decimationFactor = prod(design.decimationFactors);
sampleIndex = (0:inputSampleCount - 1).';
mixer = exp(-1i * 2 * pi * design.mixerFrequencyHz / ...
    design.adcRateHz * sampleIndex);
mixed = adcPriSamples .* mixer;

stage1InitialConditions = zeros(design.stage1Order, channelCount);
stage1Output = filter(design.stage1Numerator, 1, mixed, ...
    stage1InitialConditions, 1);
stage1Samples = stage1Output(1:design.decimationFactors(1):end, :);

stage2InitialConditions = zeros(design.stage2Order, channelCount);
stage2Output = filter(design.stage2Numerator, 1, stage1Samples, ...
    stage2InitialConditions, 1);
output = stage2Output(1:design.decimationFactors(2):end, :);
if isreal(output)
    output = complex(output);
end

startupInputSamples = design.stage1Order + ...
    design.stage2Order * design.decimationFactors(1);
metadata = struct();
metadata.inputSampleCount = double(inputSampleCount);
metadata.outputSampleCount = double(size(output, 1));
metadata.decimationFactor = double(decimationFactor);
metadata.groupDelayInputSamples = double(design.delayTicks);
metadata.groupDelayOutputSamples = double(design.delayOutputSamples);
metadata.startupInputSamples = double(startupInputSamples);
metadata.startupOutputSamples = double(startupInputSamples / decimationFactor);
end
