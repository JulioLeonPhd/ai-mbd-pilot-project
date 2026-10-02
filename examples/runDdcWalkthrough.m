function metrics = runDdcWalkthrough(outputDirectory)
%RUNDDCWALKTHROUGH Run a deterministic streaming DDC learning example.
%   METRICS = RUNDDCWALKTHROUGH() runs the 6,000-sample example without
%   writing files. Add the examples folder to the MATLAB path before calling
%   this function. The generated stimulus is a real double [N, 1] vector in
%   ADC sample order. It contains a 51 MHz desired tone and a smaller 70 MHz
%   pedagogic probe at 150 MHz; the probe is outside the ideal +/-5 MHz band.
%
%   METRICS = RUNDDCWALKTHROUGH(OUTPUTDIRECTORY) also saves three PNG
%   figures in OUTPUTDIRECTORY. The DDC uses a negative 50 MHz complex
%   mixer, a 25-tap FIR followed by decimation by 3, and a 241-tap FIR
%   followed by decimation by 4. METRICS is a structure with rates, error,
%   fault-signature, delay, and optional figure-path results. Streaming state
%   persists across frames; this function restores the MATLAB path if needed.

arguments
    outputDirectory (1, 1) string = ""
end

%% 01 Setup and stimulus
repositoryRoot = fileparts(fileparts(mfilename("fullpath")));
sourceRoot = fullfile(repositoryRoot, "src");
pathEntries = string(strsplit(path, pathsep));
addedSourcePath = ~any(pathEntries == string(sourceRoot));
if addedSourcePath
    addpath(sourceRoot);
end
pathCleanup = onCleanup(@() restoreSourcePath(sourceRoot, addedSourcePath));

design = radardemo.ddc.createDesign(struct());
sampleCount = 6000;
% This split is not aligned to the first /3 decimator, so frame two must
% resume the saved decimation phase as well as the filter and mixer state.
splitAfterSamples = 1001;
% Mixing the 51 MHz tone by -50 MHz places it at +1 MHz. The 70 MHz probe
% moves to +20 MHz and should be removed by the low-pass stages.
desiredFrequencyHz = 51e6;
probeFrequencyHz = 70e6;
desiredAmplitude = 1.0;
probeAmplitude = 0.2;
sampleIndex = (0:sampleCount - 1).';
input = desiredAmplitude * cos(2 * pi * desiredFrequencyHz / ...
    design.adcRateHz * sampleIndex) + probeAmplitude * cos(2 * pi * ...
    probeFrequencyHz / design.adcRateHz * sampleIndex);

%% 02 Uninterrupted and split processing
initialState = radardemo.ddc.initializeState(design, 1);
[oneShotOutput, ~] = radardemo.ddc.processFrame(input, initialState, design);
[firstFrame, splitState] = radardemo.ddc.processFrame( ...
    input(1:splitAfterSamples, :), initialState, design);
[secondFrame, ~] = radardemo.ddc.processFrame( ...
    input(splitAfterSamples + 1:end, :), splitState, design);
splitOutput = [firstFrame; secondFrame];

%% 03 Independent comparison
% The oracle uses direct convolution and has no streaming state shared with
% the DDC implementation, so agreement checks both the values and the shape.
oracleOutput = runIndependentOracle(input, design);
assert(isequal(size(oneShotOutput), size(oracleOutput)), ...
    "radardemo:example:OracleShapeMismatch", ...
    "One-shot DDC and oracle outputs must have the same shape.");
assert(isequal(size(splitOutput), size(oneShotOutput)), ...
    "radardemo:example:SplitShapeMismatch", ...
    "Split and one-shot DDC outputs must have the same shape.");

absoluteTolerance = 2e-12;
oracleError = oneShotOutput - oracleOutput;
splitError = splitOutput - oneShotOutput;
oracleMaxError = max(abs(oracleError), [], "all");
splitMaxError = max(abs(splitError), [], "all");
assert(oracleMaxError <= absoluteTolerance, ...
    "radardemo:example:OracleMismatch", ...
    "One-shot DDC differs from the independent convolution oracle.");
assert(splitMaxError <= absoluteTolerance, ...
    "radardemo:example:SplitMismatch", ...
    "Split processing differs from one-shot processing.");

%% 04 Isolated fault experiments
% Each run below resets one state field at the split. This separates a mixer
% phase-reference error from a filter-memory transient.
[inputCountResetOutput, stage1DelayResetOutput] = runFaultExperiments( ...
    input, design, splitAfterSamples, initialState);
outputAdcTicks = (0:numel(oneShotOutput) - 1).' * ...
    prod(design.decimationFactors);

% Group delay describes the signal's timing offset. FIR memory describes
% how long a reset can affect outputs; the settled window starts after that
% complete cascade memory has passed beyond the split.
cascadeMemoryTicks = design.stage1Order + ...
    design.stage2Order * design.decimationFactors(1);
settledMask = outputAdcTicks >= splitAfterSamples + cascadeMemoryTicks;
if nnz(settledMask) < 10
    error("radardemo:example:ShortSettledWindow", ...
        "The input must leave at least ten output samples after cascade memory.");
end

phaseRatio = inputCountResetOutput(settledMask) ./ oneShotOutput(settledMask);
observedPhaseDeg = rad2deg(angle(mean(phaseRatio)));
% The reset occurs before zero-based sample 1001. At 50/150 MHz, those
% intervals leave a 2/3-cycle difference modulo one; the negative mixer
% makes the reset output -120 degrees relative to uninterrupted processing.
expectedPhaseDeg = -120;
phaseErrorDeg = abs(rad2deg(angle(exp(1i * deg2rad( ...
    observedPhaseDeg - expectedPhaseDeg)))));
amplitudeRatio = mean(abs(phaseRatio));
assert(phaseErrorDeg <= 1.0, "radardemo:example:PhaseFaultSignature", ...
    "Resetting only inputSampleCount did not produce the expected -120 degree phase.");
assert(abs(amplitudeRatio - 1) <= 0.02, ...
    "radardemo:example:PhaseFaultAmplitude", ...
    "The settled inputSampleCount fault changed output amplitude unexpectedly.");

boundaryMask = outputAdcTicks >= splitAfterSamples & ...
    outputAdcTicks < splitAfterSamples + cascadeMemoryTicks;
stage1TransientMaxError = max(abs(stage1DelayResetOutput(boundaryMask) - ...
    oneShotOutput(boundaryMask)));
stage1SettledMaxError = max(abs(stage1DelayResetOutput(settledMask) - ...
    oneShotOutput(settledMask)));
assert(stage1TransientMaxError > 1e-3, ...
    "radardemo:example:MissingStage1Transient", ...
    "Resetting only stage1Delay did not produce a visible boundary transient.");
assert(stage1SettledMaxError <= absoluteTolerance, ...
    "radardemo:example:Stage1DidNotSettle", ...
    "The stage1Delay fault did not settle after the full cascade memory.");

%% 05 Metrics
metrics = struct();
metrics.sampleCount = sampleCount;
metrics.channelCount = 1;
metrics.inputClass = "double";
metrics.inputFrequenciesHz = [desiredFrequencyHz, probeFrequencyHz];
metrics.inputAmplitudes = [desiredAmplitude, probeAmplitude];
metrics.adcRateHz = design.adcRateHz;
metrics.intermediateRateHz = design.intermediateRateHz;
metrics.outputRateHz = design.outputRateHz;
metrics.decimationFactors = design.decimationFactors;
metrics.splitAfterSamples = splitAfterSamples;
metrics.oneShotVsOracleMaxAbsError = oracleMaxError;
metrics.splitVsOneShotMaxAbsError = splitMaxError;
metrics.absoluteTolerance = absoluteTolerance;
metrics.cascadeMemoryTicks = cascadeMemoryTicks;
metrics.settledWindowStartsAtAdcTick = ...
    splitAfterSamples + cascadeMemoryTicks;
metrics.inputSampleCountResetExpectedPhaseDeg = expectedPhaseDeg;
metrics.inputSampleCountResetObservedPhaseDeg = observedPhaseDeg;
metrics.inputSampleCountResetPhaseErrorDeg = phaseErrorDeg;
metrics.inputSampleCountResetAmplitudeRatio = amplitudeRatio;
metrics.stage1DelayResetTransientMaxAbsError = stage1TransientMaxError;
metrics.stage1DelayResetSettledMaxAbsError = stage1SettledMaxError;
metrics.groupDelayTicks = design.delayTicks;
metrics.groupDelayOutputPeriods = design.delayOutputSamples;
metrics.figures = struct("spectra", "", "boundaryErrors", "", "timing", "");

%% 06 Optional figures
if strlength(outputDirectory) > 0
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end
    spectraPath = fullfile(outputDirectory, "ddc-spectra.png");
    errorsPath = fullfile(outputDirectory, "ddc-boundary-errors.png");
    timingPath = fullfile(outputDirectory, "ddc-timing.png");
    saveSpectrumFigure(spectraPath, input, oneShotOutput, design);
    saveBoundaryErrorFigure(errorsPath, outputAdcTicks, splitAfterSamples, ...
        cascadeMemoryTicks, splitError, inputCountResetOutput, ...
        stage1DelayResetOutput, oneShotOutput);
    saveTimingFigure(timingPath, sampleCount, splitAfterSamples, design);
    metrics.figures = struct("spectra", string(spectraPath), ...
        "boundaryErrors", string(errorsPath), "timing", string(timingPath));
end

%% 07 Summary
fprintf("DDC one-shot/oracle max error: %.3g (tolerance %.3g)\n", ...
    oracleMaxError, absoluteTolerance);
fprintf("DDC split/one-shot max error: %.3g (tolerance %.3g)\n", ...
    splitMaxError, absoluteTolerance);
fprintf("inputSampleCount-only reset: %.3f deg settled (expected %.1f deg)\n", ...
    observedPhaseDeg, expectedPhaseDeg);
fprintf("stage1Delay-only reset: transient %.3g, settled %.3g\n", ...
    stage1TransientMaxError, stage1SettledMaxError);
if strlength(outputDirectory) > 0
    fprintf("DDC figures saved in %s\n", outputDirectory);
end

clear pathCleanup
end

function output = runIndependentOracle(input, design)
%RUNINDEPENDENTORACLE Compute the DDC output with direct causal convolution.
%   OUTPUT = RUNINDEPENDENTORACLE(INPUT, DESIGN) accepts real ADC samples as
%   an [N, 1] column and the DDC design structure. OUTPUT is a complex [M, 1]
%   column at the final decimated rate. This calculation has no side effects.

sampleCount = size(input, 1);
sampleIndex = (0:sampleCount - 1).';
mixer = exp(-1i * 2 * pi * design.mixerFrequencyHz / ...
    design.adcRateHz * sampleIndex);
mixed = input .* mixer;
stage1Full = conv(mixed, design.stage1Numerator(:), "full");
% Full convolution includes the FIR tail beyond the finite input record.
% Keep the first N outputs to match causal streaming from zero initial state.
stage1Causal = stage1Full(1:sampleCount);
% Start at index 1 to match the DDC's zero-based tick 0 selection, then
% retain every third causal output for the first decimator.
stage1Decimated = stage1Causal(1:design.decimationFactors(1):end);
stage2Full = conv(stage1Decimated, design.stage2Numerator(:), "full");
% Apply the same finite-record truncation and phase-zero index selection
% after stage 2, now at the intermediate rate.
stage2Causal = stage2Full(1:numel(stage1Decimated));
output = stage2Causal(1:design.decimationFactors(2):end);
end

function [inputCountResetOutput, stage1DelayResetOutput] = ...
    runFaultExperiments(input, design, splitAfterSamples, initialState)
%RUNFAULTEXPERIMENTS Compare two single-field state resets at a frame boundary.
%   The real [N, 1] INPUT is in ADC sample order; SPLITAFTERSAMPLES is the
%   number of samples in frame one, and INITIALSTATE is the initialized DDC
%   state for DESIGN. Each output is a complex [M, 1] DDC stream: first the
%   inputSampleCount-only reset, then the stage1Delay-only reset. State edits
%   are local to these runs; the helper writes no files.

[firstFrame, state] = radardemo.ddc.processFrame( ...
    input(1:splitAfterSamples, :), initialState, design);
state.inputSampleCount = uint64(0);
[secondFrame, ~] = radardemo.ddc.processFrame( ...
    input(splitAfterSamples + 1:end, :), state, design);
inputCountResetOutput = [firstFrame; secondFrame];

[firstFrame, state] = radardemo.ddc.processFrame( ...
    input(1:splitAfterSamples, :), initialState, design);
state.stage1Delay = zeros(size(state.stage1Delay));
[secondFrame, ~] = radardemo.ddc.processFrame( ...
    input(splitAfterSamples + 1:end, :), state, design);
stage1DelayResetOutput = [firstFrame; secondFrame];
end

function saveSpectrumFigure(filePath, input, finalOutput, design)
%SAVESPECTRUMFIGURE Save spectra at the mixer and both decimator stages.
%   FILEPATH is the destination PNG path. INPUT is a real [N, 1] ADC column;
%   FINALOUTPUT is a complex [M, 1] column at the output rate; DESIGN gives
%   each stage's filter and sample rate. The helper writes one PNG and closes
%   the invisible figure it creates.

sampleIndex = (0:size(input, 1) - 1).';
mixer = exp(-1i * 2 * pi * design.mixerFrequencyHz / ...
    design.adcRateHz * sampleIndex);
mixed = input .* mixer;
stage1Filtered = filter(design.stage1Numerator, 1, mixed);
stage1 = stage1Filtered(1:design.decimationFactors(1):end);
figureHandle = figure("Color", "w", "Theme", "light", "Visible", "off", ...
    "Position", [100, 100, 1200, 780]);
figureCleanup = onCleanup(@() close(figureHandle));
layout = tiledlayout(figureHandle, 3, 1, "TileSpacing", "compact", ...
    "Padding", "compact");
signals = {mixed, stage1, finalOutput};
rates = [design.adcRateHz, design.intermediateRateHz, design.outputRateHz];
titles = ["Mixer output", "After stage 1 and /3", "After stage 2 and /4"];
for index = 1:numel(signals)
    axesHandle = nexttile(layout);
    [frequencyHz, magnitudeDb] = normalizedSpectrum(signals{index}, rates(index));
    plot(axesHandle, frequencyHz / 1e6, magnitudeDb, "LineWidth", 1.0);
    grid(axesHandle, "on");
    xlim(axesHandle, [-0.5, 0.5] * rates(index) / 1e6);
    ylim(axesHandle, [-120, 5]);
    ylabel(axesHandle, "Amplitude (dB re 1)");
    title(axesHandle, sprintf("%s, Fs = %.1f MHz", titles(index), ...
        rates(index) / 1e6));
end
xlabel(layout, "Frequency (MHz; centered two-sided spectrum)");
title(layout, "DDC spectra; FFT magnitude divided by record length");
exportgraphics(figureHandle, filePath, "Resolution", 140);
clear figureCleanup
end

function [frequencyHz, magnitudeDb] = normalizedSpectrum(signal, sampleRateHz)
%NORMALIZEDSPECTRUM Return a centered, record-length-normalized FFT magnitude.
%   SIGNAL is a real or complex vector sampled at SAMPLE_RATE_HZ in hertz.
%   FREQUENCYHZ and MAGNITUDEDB are [K, 1] columns in hertz and dB relative
%   to unit amplitude. The FFT is zero-padded; no graphics are created.

fftLength = 2 ^ nextpow2(2 * numel(signal));
% Dividing by record length gives a magnitude relative to the input scale;
% the small floor keeps exact FFT zeros finite on a logarithmic axis.
spectrum = fftshift(fft(signal, fftLength)) / numel(signal);
frequencyIndex = (-floor(fftLength / 2):ceil(fftLength / 2) - 1).';
frequencyHz = frequencyIndex * sampleRateHz / fftLength;
% The 1e-12 floor maps exact zeros to -240 dB; the spectra axes show down
% to -120 dB, keeping the displayed passband readable.
magnitudeDb = 20 * log10(max(abs(spectrum), 1e-12));
end

function saveBoundaryErrorFigure(filePath, outputAdcTicks, splitAfterSamples, ...
    cascadeMemoryTicks, splitError, inputCountResetOutput, ...
    stage1DelayResetOutput, oneShotOutput)
%SAVEBOUNDARYERRORFIGURE Save output differences around the frame boundary.
%   FILEPATH is the destination PNG path. OUTPUTADCTICKS contains selected
%   output times in ADC ticks; SPLITAFTERSAMPLES and CASCADEMEMORYTICKS are
%   counts in ADC ticks. The four output streams are complex [M, 1] columns
%   in DDC amplitude units. This helper writes one PNG and closes the
%   invisible figure it creates.

relativeTicks = outputAdcTicks / 12;
splitPosition = splitAfterSamples / 12;
figureHandle = figure("Color", "w", "Theme", "light", "Visible", "off", ...
    "Position", [100, 100, 1200, 800]);
figureCleanup = onCleanup(@() close(figureHandle));
layout = tiledlayout(figureHandle, 3, 1, "TileSpacing", "compact", ...
    "Padding", "compact");
errorSignals = {splitError, inputCountResetOutput - oneShotOutput, ...
    stage1DelayResetOutput - oneShotOutput};
panelTitles = ["Normal split: one-shot difference", ...
    "Reset inputSampleCount only: persistent phase change", ...
    "Reset stage1Delay only: temporary cascade transient"];
for index = 1:numel(errorSignals)
    axesHandle = nexttile(layout);
    % A 1e-15 floor keeps zero differences finite at the plotted -300 dB.
    errorDb = 20 * log10(max(abs(errorSignals{index}), 1e-15));
    plot(axesHandle, relativeTicks, errorDb, "LineWidth", 1.0);
    hold(axesHandle, "on");
    xline(axesHandle, splitPosition, "--", "split after sample 1001", ...
        "Color", [0.5, 0.05, 0.35], "LabelColor", [0.5, 0.05, 0.35]);
    xline(axesHandle, (splitAfterSamples + cascadeMemoryTicks) / 12, ...
        ":", "full cascade memory", "Color", [0.15, 0.15, 0.15], ...
        "LabelColor", [0.15, 0.15, 0.15]);
    hold(axesHandle, "off");
    grid(axesHandle, "on");
    xlim(axesHandle, [max(0, splitPosition - 8), ...
        min(relativeTicks(end), splitPosition + 90)]);
    ylabel(axesHandle, "Error magnitude (dB re 1)");
    title(axesHandle, panelTitles(index));
end
xlabel(layout, "Output-period coordinate (12 ADC ticks per period)");
title(layout, ...
    "Boundary behavior; relative error shown with a -300 dB display floor");
exportgraphics(figureHandle, filePath, "Resolution", 140);
clear figureCleanup
end

function saveTimingFigure(filePath, sampleCount, splitAfterSamples, design)
%SAVETIMINGFIGURE Save a diagram of ADC, intermediate, and output sample ticks.
%   FILEPATH is the destination PNG path. SAMPLECOUNT and SPLITAFTERSAMPLES
%   are counts of ADC samples; DESIGN supplies the decimation factors and
%   group delay in ADC ticks. The x-axis is in output periods from ADC tick
%   zero. The helper writes one PNG and closes the invisible figure it creates.

lastTick = sampleCount - 1;
outputPeriodTicks = prod(design.decimationFactors);
displayedLastTick = min(lastTick, splitAfterSamples + 2 * outputPeriodTicks);
adcTicks = 0:displayedLastTick;
stage1Ticks = 0:design.decimationFactors(1):lastTick;
outputTicks = 0:outputPeriodTicks:lastTick;
figureHandle = figure("Color", "w", "Theme", "light", "Visible", "off", ...
    "Position", [100, 100, 1200, 540]);
figureCleanup = onCleanup(@() close(figureHandle));
axesHandle = axes(figureHandle);
hold(axesHandle, "on");
adcScatter = scatter(axesHandle, adcTicks / outputPeriodTicks, ...
    ones(size(adcTicks)), 5, ...
    [0.55, 0.55, 0.55], "filled", "DisplayName", "ADC: every tick");
stage1Scatter = scatter(axesHandle, stage1Ticks / outputPeriodTicks, ...
    2 * ones(size(stage1Ticks)), 10, ...
    [0.1, 0.45, 0.8], "filled", "DisplayName", "Stage 1: every 3 ADC ticks");
outputScatter = scatter(axesHandle, outputTicks / outputPeriodTicks, ...
    3 * ones(size(outputTicks)), 18, ...
    [0.0, 0.55, 0.25], "filled", "DisplayName", "Output: every 12 ADC ticks");
xline(axesHandle, 0, "-", "selected tick 0", "LineWidth", 1.4, ...
    "Color", [0.65, 0.08, 0.08], "LabelColor", [0.65, 0.08, 0.08]);
xline(axesHandle, design.delayTicks / outputPeriodTicks, "--", ...
    "group delay: 372 ADC ticks = 31 output periods", "LineWidth", 1.4, ...
    "Color", [0.05, 0.2, 0.45], "LabelColor", [0.05, 0.2, 0.45]);
xline(axesHandle, splitAfterSamples / outputPeriodTicks, "--", ...
    "split after sample 1001", "LineWidth", 1.4, ...
    "Color", [0.5, 0.05, 0.35], "LabelColor", [0.5, 0.05, 0.35]);
hold(axesHandle, "off");
grid(axesHandle, "on");
ylim(axesHandle, [0.5, 3.5]);
yticks(axesHandle, [1, 2, 3]);
yticklabels(axesHandle, ["ADC", "After /3", "After /12"]);
xlim(axesHandle, [0, splitAfterSamples / outputPeriodTicks + 2]);
xlabel(axesHandle, "Output-period coordinate from selected tick zero");
ylabel(axesHandle, "Sample positions");
title(axesHandle, "DDC sample timing and frame boundary");
legend(axesHandle, [adcScatter, stage1Scatter, outputScatter], ...
    "Location", "northeastoutside");
exportgraphics(figureHandle, filePath, "Resolution", 140);
clear figureCleanup
end

function restoreSourcePath(sourceRoot, addedSourcePath)
%RESTORESOURCEPATH Remove the source folder only when this example added it.
%   SOURCEROOT is the project source folder, and ADDEDSOURCEPATH records
%   whether this call added it. This helper changes the MATLAB path only in
%   that case, preserving a path entry that existed before the walkthrough.

if addedSourcePath
    currentEntries = string(strsplit(path, pathsep));
    if any(currentEntries == string(sourceRoot))
        rmpath(sourceRoot);
    end
end
end
