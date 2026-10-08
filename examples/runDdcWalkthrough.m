%% One complete physical PRI through the receive DDC
% Run with the project src folder on the MATLAB path. Inputs are ADC counts;
% the DDC output stays on that count scale after complex downconversion.

%% 01 Define one aligned PRI
design = radardemo.ddc.createDesign(struct());
sampleCount = 88236;
startTick = 0;
adcRateHz = design.adcRateHz;
outputRateHz = design.outputRateHz;
desiredToneHz = 51e6;
imageProbeHz = 70e6;
desiredAmplitudeCounts = 18000;
imageProbeAmplitudeCounts = 3500;
globalSampleIndex = startTick + (0:sampleCount - 1).';

%% 02 Synthesize and quantize the real ADC input
adcSignal = desiredAmplitudeCounts * cos( ...
    2 * pi * desiredToneHz / adcRateHz * globalSampleIndex) + ...
    imageProbeAmplitudeCounts * cos( ...
    2 * pi * imageProbeHz / adcRateHz * globalSampleIndex);
adcPriSamples = int16(round(adcSignal));
adcPriDouble = double(adcPriSamples);

%% 03 Process one PRI with fresh mixer and filter state
[output, metadata] = radardemo.ddc.processFrame(adcPriDouble, design);
expectedOutputCount = sampleCount / prod(design.decimationFactors);
assert(isequal(size(adcPriSamples), [sampleCount, 1]));
assert(isequal(size(output), [expectedOutputCount, 1]));
assert(~isreal(output));
repeatOutput = radardemo.ddc.processFrame(adcPriDouble, design);
assert(isequal(output, repeatOutput));

fprintf("%d int16 ADC samples at %.0f MS/s -> %d complex output samples " + ...
    "at %.1f MS/s.\n", sampleCount, adcRateHz / 1e6, ...
    metadata.outputSampleCount, outputRateHz / 1e6);
fprintf("Group delay: %d ADC samples (%d output periods); startup interval: " + ...
    "%d output sample periods.\n", metadata.groupDelayInputSamples, ...
    metadata.groupDelayOutputSamples, metadata.startupOutputSamples);

%% 04 Inspect spectra and the retained startup samples
% The real ADC spectrum is one-sided and scaled to cosine amplitude in counts.
inputFftLength = 2 ^ nextpow2(sampleCount);
inputSpectrum = fft(adcPriDouble, inputFftLength) / sampleCount;
inputFrequencyHz = (0:inputFftLength / 2).' * adcRateHz / inputFftLength;
inputMagnitudeCounts = 2 * abs(inputSpectrum(1:inputFftLength / 2 + 1));
inputMagnitudeCounts([1, end]) = inputMagnitudeCounts([1, end]) / 2;

% Keep every output sample; exclude rows 1:62 only from steady-state analysis.
steadyOutput = output(metadata.startupOutputSamples + 1:end);
outputFftLength = 2 ^ nextpow2(numel(steadyOutput));
outputSpectrum = fftshift(fft(steadyOutput, outputFftLength)) / ...
    numel(steadyOutput);
outputFrequencyHz = (-outputFftLength / 2:outputFftLength / 2 - 1).' * ...
    outputRateHz / outputFftLength;
outputMagnitudeCounts = abs(outputSpectrum);
[~, peakIndex] = max(outputMagnitudeCounts);
outputPeakFrequencyHz = outputFrequencyHz(peakIndex);
expectedBasebandHz = desiredToneHz - design.mixerFrequencyHz;
assert(abs(outputPeakFrequencyHz - expectedBasebandHz) <= ...
    outputRateHz / numel(steadyOutput));
fprintf("Steady-state complex spectrum peak: %.1f kHz (expected +1 MHz).\n", ...
    outputPeakFrequencyHz / 1e3);

figure("Name", "DDC input and output spectra", "Color", "w", ...
    "Theme", "light", "Position", [100, 100, 900, 650]);
tiledlayout(2, 1);
nexttile;
plot(inputFrequencyHz / 1e6, inputMagnitudeCounts);
xlim([0, adcRateHz / 2e6]);
grid on;
title("Real input PRI: one-sided amplitude spectrum");
xlabel("Frequency (MHz)");
ylabel("Magnitude (counts)");

nexttile;
plot(outputFrequencyHz / 1e6, outputMagnitudeCounts);
xlim([-outputRateHz / 2e6, outputRateHz / 2e6]);
grid on;
title("Complex output steady state: two-sided spectrum");
xlabel("Frequency (MHz)");
ylabel("Magnitude (counts)");

startupPlotSampleCount = min(4 * metadata.startupOutputSamples, ...
    metadata.outputSampleCount);
startupSampleIndex = (0:startupPlotSampleCount - 1).';
figure("Name", "DDC startup", "Color", "w", "Theme", "light");
plot(startupSampleIndex, real(output(1:startupPlotSampleCount)), ...
    startupSampleIndex, imag(output(1:startupPlotSampleCount)));
xline(metadata.startupOutputSamples - 0.5, "--", ...
    "Steady-state analysis begins");
grid on;
title("Startup I/Q samples; all rows remain in output");
xlabel("Output sample index (zero-based)");
ylabel("Complex output (ADC counts)");
legend("I", "Q", "Location", "best");

%% 05 Calculate and plot the approved filter response
responseMetrics = radardemo.ddc.measureResponse(design, struct());
assert(responseMetrics.accepted);
fprintf("Response (%s): ripple %.6f dB; stage-2 alias rejection %.3f dB; " + ...
    "full-cascade alias rejection %.3f dB.\n", ...
    responseMetrics.responseMetricProfile, responseMetrics.passbandRippleDb, ...
    responseMetrics.stage2AliasRejectionDb, ...
    responseMetrics.digitalAliasRejectionDb);

responseFrequencyMHz = responseMetrics.frequencyHz / 1e6;
passbandMask = abs(responseMetrics.frequencyHz) <= 5e6;
principalResponses = [responseMetrics.stage1Response, ...
    responseMetrics.stage2Response, responseMetrics.principalCascadeResponse];
principalMagnitudeDb = 20 * log10(max(abs(principalResponses), 1e-12));
figure("Name", "DDC principal passband response", "Color", "w", "Theme", "light");
plot(responseFrequencyMHz(passbandMask), ...
    principalMagnitudeDb(passbandMask, :));
grid on;
title("Principal passband response");
xlabel("Frequency (MHz)");
ylabel("Magnitude (dB re 1)");
legend("Stage 1", "Stage 2", "Cascade", "Location", "best");

branchPairs = responseMetrics.cascadeBranchPairs;
principalBranch = branchPairs(:, 1) == 0 & branchPairs(:, 2) == 0;
aliasBranches = responseMetrics.cascadeAliasBranches( ...
    passbandMask, ~principalBranch);
aliasEnvelope = max(abs(aliasBranches), [], 2) / ...
    responseMetrics.principalPassbandGain;
figure("Name", "DDC cascade alias envelope", "Color", "w", "Theme", "light");
plot(responseFrequencyMHz(passbandMask), ...
    20 * log10(max(aliasEnvelope, 1e-12)));
yline(-60, "--", "60 dB acceptance");
grid on;
title("Cascade alias envelope relative to peak passband");
xlabel("Output frequency (MHz)");
ylabel("Relative alias magnitude (dB)");
