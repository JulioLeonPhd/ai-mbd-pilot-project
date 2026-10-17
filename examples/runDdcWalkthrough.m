%[text] # DDC Example Walkthrough: One PRI through the receiver DDC
%[text] This walkthrough follows one real ADC record through the public DDC API.
%[text] It illustrates frequency translation, two filtered rate changes, local state reset, retained startup output, and the sample-only timing contract.
%%
%[text] ## Define one aligned PRI
clc
close
clear

design = radardemo.ddc.createDesign(struct());
sampleCount = 88236;
startTick = 0;
adcRateHz = design.adcRateHz;
outputRateHz = design.outputRateHz;
chirpStartFrequencyHz = 47.5e6;
chirpEndFrequencyHz = 52.5e6;
chirpCenterFrequencyHz = 50e6;
undesiredSignalHz = 70e6;
desiredAmplitudeCounts = 18000;
undesiredSignalAmplitudeCounts = 3500;
globalSampleIndex = startTick + (0:sampleCount - 1).';
decimationFactors = design.decimationFactors;
combinedDecimationFactor = prod(decimationFactors);
stage1RateHz = adcRateHz / decimationFactors(1);
stage2RateHz = stage1RateHz / decimationFactors(2);
sampleIntervalSeconds = 1 / adcRateHz;
inputDurationSeconds = sampleCount * sampleIntervalSeconds;
chirpRateHzPerSecond = (chirpEndFrequencyHz - chirpStartFrequencyHz) / ...
    inputDurationSeconds;
configuration = table(["ADC input"; "FIR 1"; "After /3"; "FIR 2"; "Output"], ...
    [adcRateHz; adcRateHz; stage1RateHz; stage1RateHz; outputRateHz] / 1e6, ...
    ["Real ADC samples"; "25 taps, 25 MHz cutoff"; "Keep every third"; ...
    "241 taps, 5.625 MHz cutoff"; "Keep every fourth"], ...
    'VariableNames', ["Stage", "Rate_MSps", "Operation"]);
disp(configuration)
disp(table(sampleCount, combinedDecimationFactor, ...
    sampleCount / combinedDecimationFactor, inputDurationSeconds * 1e6, ...
    'VariableNames', ["InputSamples", "Decimation", "OutputSamples", "PriDuration_us"]))
%[text] The desired linear chirp sweeps upward from 47.5 MHz at t = 0 to 52.5 MHz at the exclusive PRI endpoint T = N/Fs = 588.24 μs; its center is 50 MHz. The last ADC tick occurs one sample before T. This synthetic full-PRI chirp is not a transmit-pulse model. Complex mixing by 50 MHz translates it to a −2.5 MHz to +2.5 MHz baseband sweep centered at 0 MHz.
%[text] A real chirp also has a negative-frequency image. After mixing, that image spans −102.5 MHz to −97.5 MHz, equivalent to +47.5 MHz to +52.5 MHz at 150 MS/s. Stage 1 suppresses this image before /3.
%[text] The undesired 70 MHz interferer moves to +20 MHz; its negative component moves to −120 MHz, equivalent to +30 MHz. Stage 1 suppresses the +30 MHz component before /3. The +20 MHz component passes near FIR 1's edge, so FIR 2 must reject it before /4; otherwise +20 MHz aliases to −5 MHz at output. This one interferer illustrates the rejection path, not broadband alias rejection.
%%
%[text] ## Synthesize and quantize the real ADC input
%[text] The 70 MHz interferer is outside the desired chirp band. Rounded int16 values model quantized counts, not calibrated volts.
timeSeconds = globalSampleIndex / adcRateHz;
chirpPhaseRadians = 2 * pi * (chirpStartFrequencyHz * timeSeconds + ...
    0.5 * chirpRateHzPerSecond * timeSeconds .^ 2);
desiredChirp = desiredAmplitudeCounts * cos(chirpPhaseRadians);
undesiredSignal = undesiredSignalAmplitudeCounts * cos( ...
    2 * pi * undesiredSignalHz * timeSeconds);
adcSignal = desiredChirp + undesiredSignal;
adcPriSamples = int16(round(adcSignal));
adcPriDouble = double(adcPriSamples);
disp(table(chirpStartFrequencyHz / 1e6, chirpEndFrequencyHz / 1e6, ...
    chirpCenterFrequencyHz / 1e6, undesiredSignalHz / 1e6, ...
    desiredAmplitudeCounts, undesiredSignalAmplitudeCounts, ...
    max(abs(adcSignal)), double(intmax("int16")), ...
    'VariableNames', ["ChirpStart_MHz", "ChirpEnd_MHz", ...
    "ChirpCenter_MHz", "UndesiredSignal_MHz", "DesiredPeak_counts", ...
    "UndesiredPeak_counts", "CombinedPeak_counts", "Int16PeakLimit_counts"]))
%%
%[text] ## Process one PRI with fresh mixer and filter state
%[text] Public execution boundary: one complete physical PRI per call. The API creates local oscillator, FIR-delay, and decimation-phase state for this call; no continuation state passes between calls.
[output, metadata] = radardemo.ddc.processFrame(adcPriDouble, design);
expectedOutputCount = sampleCount / combinedDecimationFactor;
assert(isequal(size(adcPriSamples), [sampleCount, 1]));
assert(isequal(size(output), [expectedOutputCount, 1]));
assert(~isreal(output));
repeatOutput = radardemo.ddc.processFrame(adcPriDouble, design);
assert(isequal(output, repeatOutput));
groupDelaySeconds = metadata.groupDelayInputSamples * sampleIntervalSeconds;
startupSpanSeconds = metadata.startupInputSamples * sampleIntervalSeconds;
disp(table(metadata.outputSampleCount, metadata.decimationFactor, ...
    metadata.groupDelayInputSamples, metadata.groupDelayOutputSamples, ...
    groupDelaySeconds * 1e6, metadata.startupInputSamples, ...
    metadata.startupOutputSamples, startupSpanSeconds * 1e6, ...
    'VariableNames', ["OutputSamples", "Decimation", "DelayInputSamples", ...
    "DelayOutputPeriods", "Delay_us", "StartupInputSamples", ...
    "StartupOutputSamples", "Startup_us"]))
%[text] For zero-based output row q, nominal coordinate tick is startTick + 12*q − 372. Causal input support spans startTick + 12*q − 744 through startTick + 12\*q; full support first holds at q = 62.
%[text] Every produced row remains in output. No input padding, flush, or tail rows. The caller maps global PRI ticks and subtracts group delay once. Downstream range processing owns complete-window validity for startup, blanking, and PRI-end truncation.
%%
%[text] ## Inspect spectra and retained startup samples
%[text] Zero-padded FFTs show the chirp band and undesired signal; finite-record FFT levels are not calibrated amplitude or filter-response measurements. Input amplitude uses a one-sided spectrum; output uses a two-sided complex spectrum.
inputFftLength = 2 ^ nextpow2(sampleCount);
inputSpectrum = fft(adcPriDouble, inputFftLength) / sampleCount;
inputFrequencyHz = (0:inputFftLength / 2).' * adcRateHz / inputFftLength;
inputMagnitudeCounts = 2 * abs(inputSpectrum(1:inputFftLength / 2 + 1));
inputMagnitudeCounts([1, end]) = inputMagnitudeCounts([1, end]) / 2;
steadyOutput = output(metadata.startupOutputSamples + 1:end);
outputFftLength = 2 ^ nextpow2(numel(steadyOutput));
outputSpectrum = fftshift(fft(steadyOutput, outputFftLength)) / numel(steadyOutput);
outputFrequencyHz = (-outputFftLength / 2:outputFftLength / 2 - 1).' * outputRateHz / outputFftLength;
outputMagnitudeCounts = abs(outputSpectrum);
instantaneousFrequencyHz = angle(output(2:end) .* conj(output(1:end - 1))) * ...
    outputRateHz / (2 * pi);
frequencyIntervalIndex = (0:numel(instantaneousFrequencyHz) - 1).';
expectedInstantaneousFrequencyHz = chirpStartFrequencyHz - ...
    design.mixerFrequencyHz + chirpRateHzPerSecond * ...
    (12 * frequencyIntervalIndex + 6 - metadata.groupDelayInputSamples) / adcRateHz;
earlyWindow = frequencyIntervalIndex >= 500 & frequencyIntervalIndex <= 650;
lateWindow = frequencyIntervalIndex >= 6500 & frequencyIntervalIndex <= 6650;
earlyMeasuredFrequencyHz = median(instantaneousFrequencyHz(earlyWindow));
earlyExpectedFrequencyHz = median(expectedInstantaneousFrequencyHz(earlyWindow));
lateMeasuredFrequencyHz = median(instantaneousFrequencyHz(lateWindow));
lateExpectedFrequencyHz = median(expectedInstantaneousFrequencyHz(lateWindow));
earlyFrequencyErrorHz = earlyMeasuredFrequencyHz - earlyExpectedFrequencyHz;
lateFrequencyErrorHz = lateMeasuredFrequencyHz - lateExpectedFrequencyHz;
assert(abs(earlyFrequencyErrorHz) <= 2e3);
assert(abs(lateFrequencyErrorHz) <= 2e3);
inputMagnitudeDb = 20 * log10(max(inputMagnitudeCounts, eps));
outputMagnitudeDb = 20 * log10(max(outputMagnitudeCounts, eps));
spectraFigure = figure("Name", "DDC input and output spectra", "Color", "w", ...
    "Position", [1, 1, 1100, 750], "WindowStyle", "docked");
tiledlayout(2, 1);
nexttile;
plot(inputFrequencyHz / 1e6, inputMagnitudeDb);
xlim([0, adcRateHz / 2e6]);
grid on;
title("Real input PRI: chirp and undesired 70 MHz signal");
xlabel("Frequency (MHz)");
ylabel("Magnitude (dB re 1 ADC count)");
nexttile;
plot(outputFrequencyHz / 1e6, outputMagnitudeDb);
xlim([-outputRateHz / 2e6, outputRateHz / 2e6]);
grid on;
title("Complex output: translated chirp band and interferer rejection");
xlabel("Frequency (MHz)");
ylabel("Magnitude (dB re 1 ADC count)");
xline((chirpStartFrequencyHz - design.mixerFrequencyHz) / 1e6, "--");
xline((chirpEndFrequencyHz - design.mixerFrequencyHz) / 1e6, "--");
%[text] The output spectrum excludes the first 62 rows because local FIR history fills during startup; the output array retains them. The chirp should span approximately −2.5 MHz to +2.5 MHz. FFT leakage broadens the edges, and the remaining interferer level is an illustration rather than a broadband rejection measurement.
disp(table(earlyMeasuredFrequencyHz / 1e6, earlyExpectedFrequencyHz / 1e6, ...
    earlyFrequencyErrorHz / 1e3, lateMeasuredFrequencyHz / 1e6, ...
    lateExpectedFrequencyHz / 1e6, lateFrequencyErrorHz / 1e3, ...
    'VariableNames', ["EarlyMeasured_MHz", "EarlyExpected_MHz", ...
    "EarlyError_kHz", "LateMeasured_MHz", "LateExpected_MHz", ...
    "LateError_kHz"]))
%%
%[text] ## Inspect startup I and Q
%[text] I and Q are signed sample values, so this time-domain plot remains linear.
startupPlotSampleCount = min(4 * metadata.startupOutputSamples, metadata.outputSampleCount);
startupSampleIndex = (0:startupPlotSampleCount - 1).';
startupFigure = figure("Name", "DDC startup", "Color", "w", ...
    "Position", [1, 1, 1100, 750], "WindowStyle", "docked");
plot(startupSampleIndex, real(output(1:startupPlotSampleCount)), ...
    startupSampleIndex, imag(output(1:startupPlotSampleCount)));
xline(metadata.startupOutputSamples - 0.5, "--", "Steady-state analysis begins");
grid on;
title("Startup I/Q samples; all rows remain in output");
xlabel("Output sample index (zero-based)");
ylabel("Complex output (ADC counts)");
legend("I", "Q", "Location", "best");
%%
%[text] ## Calculate and plot the approved filter response
%[text] The public response API reports designed-filter response separately from finite-record chirp and interferer spectra. Cascade acceptance budgets apply at final 12.5 MS/s complex output: passband ripple ≤ 0.1 dB and alias rejection ≥ 60 dB under the named response metric profile.
responseMetrics = radardemo.ddc.measureResponse(design, struct());
assert(responseMetrics.accepted);
disp(table(responseMetrics.responseMetricProfile, responseMetrics.passbandRippleDb, ...
    responseMetrics.stage2AliasRejectionDb, responseMetrics.digitalAliasRejectionDb, ...
    'VariableNames', ["MetricProfile", "PassbandRipple_dB", ...
    "Stage2AliasRejection_dB", "CascadeAliasRejection_dB"]))
%[text] A real cosine with peak amplitude A produces complex envelope A/2 before the approved final ×2 compensation. Output returns toward A, subject to FIR gain, phase, and residual image. The ×2 gain doubles noise amplitude without improving SNR or calibrating counts as volts. This deterministic chirp and interferer example adds no noise stimulus.
responseFrequencyMHz = responseMetrics.frequencyHz / 1e6;
passbandMask = abs(responseMetrics.frequencyHz) <= 5e6;
principalResponses = [responseMetrics.stage1Response, ...
    responseMetrics.stage2Response, responseMetrics.principalCascadeResponse];
principalMagnitudeDb = 20 * log10(max(abs(principalResponses), 1e-12));
responseFigure = figure("Name", "DDC principal passband response", ...
    "Color", "w", "Position", [1, 1, 1100, 750], "WindowStyle", "docked");
plot(responseFrequencyMHz(passbandMask), principalMagnitudeDb(passbandMask, :));
grid on;
title("Principal passband response");
xlabel("Frequency (MHz)");
ylabel("Magnitude (dB re 1)");
legend("Stage 1", "Stage 2", "Cascade", "Location", "best");
%%
%[text] ## Inspect cascade alias envelope
branchPairs = responseMetrics.cascadeBranchPairs;
principalBranch = branchPairs(:, 1) == 0 & branchPairs(:, 2) == 0;
%[text] The cascade alias plot shows only the nonprincipal branch envelope. Full acceptance also includes the direct principal response over the specified stopband; the metric includes that term, but this figure does not draw it.
aliasBranches = responseMetrics.cascadeAliasBranches(passbandMask, ~principalBranch);
aliasEnvelope = max(abs(aliasBranches), [], 2) / responseMetrics.principalPassbandGain;
aliasFigure = figure("Name", "DDC cascade alias envelope", ...
    "Color", "w", "Position", [1, 1, 1100, 750], "WindowStyle", "docked");
plot(responseFrequencyMHz(passbandMask), 20 * log10(max(aliasEnvelope, 1e-12)));
yline(-60, "--", "60 dB acceptance");
grid on;
title("Cascade alias envelope relative to peak passband");
xlabel("Output frequency (MHz)");
ylabel("Relative alias magnitude (dB)");
%%
%[text] ## Interpret gain and evidence
%[text] The response plots show designed-filter behavior. Input and output FFTs show finite-record chirp and interferer content, including leakage. This one-PRI example does not establish full receiver detection, range-window validity, hardware behavior, or real-time performance.

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"hidecode"}
%---
