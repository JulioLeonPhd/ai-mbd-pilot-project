function [rangeSamples, metadata] = processPri(inputSamples, inputValid, cfg)
%PROCESSPRI Correlate one PRI independently with the fixed range reference.
%   [RANGESAMPLES, METADATA] = RADARDEMO.RANGECOMPRESSION.PROCESSPRI(
%   INPUTSAMPLES, INPUTVALID, CFG) processes finite double [N,4] elevation
%   streams with a matching logical validity mask. CFG contains only the
%   caller-supplied rangeOriginM in metres. The outputs retain N nonnegative
%   lag bins; invalid windows are complex zero and identified in METADATA.valid.

if ~isa(inputSamples, "double") || ~ismatrix(inputSamples) || ...
        isempty(inputSamples) || size(inputSamples, 2) ~= 4 || ...
        any(~isfinite(inputSamples), "all")
    error("radardemo:rangeCompression:InvalidInput", ...
        "Samples must be a nonempty finite double [N,4] array.");
end

if ~islogical(inputValid) || ~ismatrix(inputValid) || ...
        ~isequal(size(inputValid), size(inputSamples))
    error("radardemo:rangeCompression:InvalidValidity", ...
        "Validity must be a logical [N,4] array matching the samples.");
end

if ~isstruct(cfg) || ~isscalar(cfg) || ...
        ~isequal(fieldnames(cfg), {"rangeOriginM"})
    error("radardemo:rangeCompression:InvalidConfiguration", ...
        "Configuration must contain only the rangeOriginM field.");
end
rangeOriginM = cfg.rangeOriginM;
if ~isa(rangeOriginM, "double") || ~isscalar(rangeOriginM) || ...
        ~isreal(rangeOriginM) || ~isfinite(rangeOriginM)
    error("radardemo:rangeCompression:InvalidConfiguration", ...
        "rangeOriginM must be a finite real double scalar in metres.");
end

sampleCount = size(inputSamples, 1);
referenceLength = 500;
sampleRateHz = 12.5e6;
bandwidthHz = 10e6;
speedOfLightMPerSec = 299792458;
referenceTime = (0:referenceLength - 1).' / sampleRateHz;
referencePhase = 2 * pi * (-bandwidthHz * referenceTime / 2 + ...
    bandwidthHz * referenceTime.^2 / (2 * 40e-6));
reference = exp(1i * referencePhase);
fftLength = 2^nextpow2(sampleCount + referenceLength - 1);
correlation = ifft(fft(inputSamples, fftLength, 1) .* ...
    conj(fft(reference, fftLength, 1)), [], 1) / referenceLength;
rangeSamples = correlation(1:sampleCount, :);

valid = false(sampleCount, 4);
if sampleCount >= referenceLength
    invalidPrefix = [zeros(1, 4); cumsum(double(~inputValid), 1)];
    validRowCount = sampleCount - referenceLength + 1;
    invalidCounts = invalidPrefix(referenceLength + 1:sampleCount + 1, :) - ...
        invalidPrefix(1:validRowCount, :);
    valid(1:validRowCount, :) = invalidCounts == 0;
end
rangeSamples(~valid) = 0;
if isreal(rangeSamples)
    rangeSamples = complex(rangeSamples);
end

rangeSpacingM = speedOfLightMPerSec / (2 * sampleRateHz);
metadata = struct( ...
    "valid", valid, ...
    "rangeBinCentersM", rangeOriginM + (0:sampleCount - 1).' * rangeSpacingM);
end