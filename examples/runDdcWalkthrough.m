function metrics = runDdcWalkthrough(outputDirectory)
%RUNDDCWALKTHROUGH Run a deterministic independent-per-PRI DDC example.
%   METRICS = RUNDDCWALKTHROUGH() creates a compact full-scan int16 ADC
%   matrix, processes every physical priming and usable PRI independently,
%   and returns per-PRI sample and timeline observations. Transition samples
%   remain in the ADC matrix and schedule but are not sent to the DDC.
%
%   METRICS = RUNDDCWALKTHROUGH(OUTPUTDIRECTORY) also writes stage alias,
%   cascade alias, and passband zoom figures to OUTPUTDIRECTORY. The ADC
%   matrix has shape [totalScanTicks, 1] and stores quantized int16 counts.
%   Each DDC call receives one finite double [N, 1] PRI and returns complex
%   [N/12, 1] samples without padding, flushing, or public continuation state.

arguments
    outputDirectory (1, 1) string = ""
end

%% 01 Setup
repositoryRoot = fileparts(fileparts(mfilename("fullpath")));
sourceRoot = fullfile(repositoryRoot, "src");
pathEntries = string(strsplit(path, pathsep));
addedSourcePath = ~any(pathEntries == string(sourceRoot));
if addedSourcePath
    addpath(sourceRoot);
end
pathCleanup = onCleanup(@() restoreSourcePath(sourceRoot, addedSourcePath));

design = radardemo.ddc.createDesign(struct());
schedulePath = fullfile(repositoryRoot, "contracts", "wp4", "fixtures", ...
    "schedule.json");
schedule = jsondecode(fileread(schedulePath));
records = schedule.records;
physicalRecordIndices = find(string({records.role}) ~= "transition");
transitionRecordIndices = find(string({records.role}) == "transition");

%% 02 Prepare the complete compact ADC timeline before DDC calls
% The full one-channel scan occupies about 21 MB as int16. Transition samples
% are retained here, but the record loop below never passes them to processFrame.
adcSamples = createAdcScan(schedule.totalTicks, design.adcRateHz);

%% 03 Process each physical PRI with fresh local filter and mixer state
observationTemplate = struct( ...
    "recordIndex", 0, ...
    "role", "", ...
    "prfIndex", 0, ...
    "globalStartTick", 0, ...
    "inputSampleCount", 0, ...
    "outputSampleCount", 0, ...
    "groupDelayInputSamples", 0, ...
    "startupInputSamples", 0, ...
    "firstOutputTick", 0, ...
    "lastOutputTick", 0, ...
    "maximumOutputMagnitude", 0);
recordObservations = repmat(observationTemplate, numel(physicalRecordIndices), 1);
processedOutputSampleCount = 0;
for observationIndex = 1:numel(physicalRecordIndices)
    recordIndex = physicalRecordIndices(observationIndex);
    record = records(recordIndex);
    firstInputRow = double(record.startTick) + 1;
    lastInputRow = firstInputRow + double(record.sampleCount) - 1;
    adcPriSamples = double(adcSamples(firstInputRow:lastInputRow, :));
    [priOutput, metadata] = radardemo.ddc.processFrame(adcPriSamples, design);

    firstOutputTick = double(record.startTick) - metadata.groupDelayInputSamples;
    lastOutputTick = firstOutputTick + ...
        (metadata.outputSampleCount - 1) * metadata.decimationFactor;
    recordObservations(observationIndex) = struct( ...
        "recordIndex", recordIndex, ...
        "role", string(record.role), ...
        "prfIndex", double(record.prfIndex), ...
        "globalStartTick", double(record.startTick), ...
        "inputSampleCount", metadata.inputSampleCount, ...
        "outputSampleCount", metadata.outputSampleCount, ...
        "groupDelayInputSamples", metadata.groupDelayInputSamples, ...
        "startupInputSamples", metadata.startupInputSamples, ...
        "firstOutputTick", firstOutputTick, ...
        "lastOutputTick", lastOutputTick, ...
        "maximumOutputMagnitude", max(abs(priOutput), [], "all"));
    processedOutputSampleCount = processedOutputSampleCount + ...
        metadata.outputSampleCount;

    fprintf("PRI %03d %-7s PRF %d: %d ADC -> %d output samples, " + ...
        "delay-adjusted ticks [%.0f, %.0f], peak %.1f counts\n", ...
        recordIndex, record.role, record.prfIndex, metadata.inputSampleCount, ...
        metadata.outputSampleCount, firstOutputTick, lastOutputTick, ...
        recordObservations(observationIndex).maximumOutputMagnitude);
end

%% 04 Measure the approved stage and cascade response
responseMetrics = radardemo.ddc.measureResponse(design, struct());
figures = struct( ...
    "stage1AliasResponse", "", ...
    "stage2AliasResponse", "", ...
    "cascadeAliasResponse", "", ...
    "passbandZoom", "");
if strlength(outputDirectory) > 0
    if ~isfolder(outputDirectory)
        mkdir(outputDirectory);
    end
    figures = saveResponseFigures(outputDirectory, responseMetrics);
end

%% 05 Return sample-level and caller-owned timeline observations
metrics = struct();
metrics.sampleRateHz = design.adcRateHz;
metrics.outputRateHz = design.outputRateHz;
metrics.inputClass = string(class(adcSamples));
metrics.channelCount = size(adcSamples, 2);
metrics.totalScanTicks = double(schedule.totalTicks);
metrics.transitionGapTicks = double(schedule.transitionGapTicks);
metrics.physicalPriCallCount = numel(physicalRecordIndices);
metrics.primingPriCallCount = nnz(string({records(physicalRecordIndices).role}) == "priming");
metrics.usablePriCallCount = nnz(string({records(physicalRecordIndices).role}) == "usable");
metrics.skippedTransitionCount = numel(transitionRecordIndices);
metrics.inputSampleCount = sum([recordObservations.inputSampleCount]);
metrics.outputSampleCount = processedOutputSampleCount;
metrics.decimationFactor = prod(design.decimationFactors);
metrics.groupDelayInputSamples = design.delayTicks;
metrics.groupDelayOutputSamples = design.delayOutputSamples;
metrics.startupInputSamples = design.stage1Order + ...
    design.stage2Order * design.decimationFactors(1);
metrics.startupOutputSamples = metrics.startupInputSamples / ...
    metrics.decimationFactor;
metrics.responseMetricProfile = responseMetrics.responseMetricProfile;
metrics.passbandRippleDb = responseMetrics.passbandRippleDb;
metrics.stage2AliasRejectionDb = responseMetrics.stage2AliasRejectionDb;
metrics.digitalAliasRejectionDb = responseMetrics.digitalAliasRejectionDb;
metrics.recordObservations = recordObservations;
metrics.figures = figures;

fprintf("Processed %d physical PRIs (%d priming, %d usable); skipped %d " + ...
    "transition gaps of %d ADC ticks.\n", metrics.physicalPriCallCount, ...
    metrics.primingPriCallCount, metrics.usablePriCallCount, ...
    metrics.skippedTransitionCount, metrics.transitionGapTicks);
fprintf("Response (%s): cascade ripple %.6f dB, stage-2 alias rejection " + ...
    "%.3f dB, full-cascade alias rejection %.3f dB.\n", ...
    metrics.responseMetricProfile, metrics.passbandRippleDb, ...
    metrics.stage2AliasRejectionDb, metrics.digitalAliasRejectionDb);
if strlength(outputDirectory) > 0
    fprintf("Response figures saved in %s\n", outputDirectory);
end

clear pathCleanup
end

function adcSamples = createAdcScan(totalTicks, sampleRateHz)
%CREATEADCSCAN Synthesize and quantize the complete contiguous ADC timeline.
%   Transition records are generated in the matrix as timeline samples. They
%   remain outside physical DDC calls, which use schedule record boundaries.

channelCount = 1;
adcSamples = zeros(totalTicks, channelCount, "int16");
randomStream = RandStream("mt19937ar", Seed=2219);
chunkSize = 200000;
for firstRow = 1:chunkSize:totalTicks
    lastRow = min(firstRow + chunkSize - 1, totalTicks);
    globalTick = (firstRow - 1:lastRow - 1).';
    desiredTone = 18000 * cos(2 * pi * 51e6 / sampleRateHz * globalTick);
    imageProbe = 3500 * cos(2 * pi * 70e6 / sampleRateHz * globalTick);
    noise = 600 * randn(randomStream, numel(globalTick), channelCount);
    adcSamples(firstRow:lastRow, :) = int16(round(desiredTone + imageProbe + noise));
end
end

function figures = saveResponseFigures(outputDirectory, responseMetrics)
%SAVERESPONSEFIGURES Save stage alias, cascade alias, and passband response plots.

stage1Path = fullfile(outputDirectory, "ddc-stage1-alias-response.png");
stage2Path = fullfile(outputDirectory, "ddc-stage2-alias-response.png");
cascadePath = fullfile(outputDirectory, "ddc-cascade-alias-response.png");
passbandPath = fullfile(outputDirectory, "ddc-passband-zoom.png");

stage1Grid = abs(responseMetrics.frequencyHz) <= 25e6;
stage1BranchLabels = "alias k=" + string(-1:1);
saveBranchFigure(stage1Path, responseMetrics.frequencyHz(stage1Grid) / 1e6, ...
    responseMetrics.stage1AliasBranches(stage1Grid, :), ...
    "Stage 1 /3 alias branches", "Frequency after /3 (MHz)", ...
    "Branch magnitude (dB re 1)", -120, 5, stage1BranchLabels);

stage2Grid = abs(responseMetrics.frequencyHz) <= 6.25e6;
stage2BranchLabels = "alias k=" + string(-2:1);
saveBranchFigure(stage2Path, responseMetrics.frequencyHz(stage2Grid) / 1e6, ...
    responseMetrics.stage2AliasBranches(stage2Grid, :), ...
    "Stage 2 /4 alias branches", "Output frequency (MHz)", ...
    "Branch magnitude (dB re 1)", -120, 5, stage2BranchLabels);

passbandGrid = abs(responseMetrics.frequencyHz) <= 5e6;
branchPairs = responseMetrics.cascadeBranchPairs;
principalBranch = branchPairs(:, 1) == 0 & branchPairs(:, 2) == 0;
cascadeAlias = responseMetrics.cascadeAliasBranches(passbandGrid, ~principalBranch);
peakPassband = responseMetrics.principalPassbandGain;
cascadeAliasEnvelope = max(abs(cascadeAlias), [], 2) / peakPassband;
cascadeLabels = "Worst alias branch";
saveBranchFigure(cascadePath, responseMetrics.frequencyHz(passbandGrid) / 1e6, ...
    cascadeAliasEnvelope, "Cascade alias envelope relative to peak passband", ...
    "Output frequency (MHz)", "Relative alias magnitude (dB)", -120, 0, ...
    cascadeLabels);

passbandValues = [responseMetrics.stage1Response(passbandGrid), ...
    responseMetrics.stage2Response(passbandGrid), ...
    responseMetrics.principalCascadeResponse(passbandGrid)];
passbandDb = 20 * log10(max(abs(passbandValues), 1e-12));
passbandMarginDb = 0.1 * responseMetrics.passbandRippleDb;
passbandMarginDb = max(passbandMarginDb, 1e-4);
passbandLimitsDb = [min(passbandDb, [], "all") - passbandMarginDb, ...
    max(passbandDb, [], "all") + passbandMarginDb];
saveBranchFigure(passbandPath, responseMetrics.frequencyHz(passbandGrid) / 1e6, ...
    passbandValues, "Principal passband response", "Frequency (MHz)", ...
    "Magnitude (dB re 1)", passbandLimitsDb(1), passbandLimitsDb(2), ...
    ["Stage 1", "Stage 2", "Cascade"]);

figures = struct( ...
    "stage1AliasResponse", string(stage1Path), ...
    "stage2AliasResponse", string(stage2Path), ...
    "cascadeAliasResponse", string(cascadePath), ...
    "passbandZoom", string(passbandPath));
end

function saveBranchFigure(filePath, frequencyMHz, response, figureTitle, ...
        xLabel, yLabel, lowerLimit, upperLimit, branchLabels)
%SAVEBRANCHFIGURE Draw categorized response curves with gramm and save a PNG.

if nargin < 9
    branchLabels = "Branch " + string(1:size(response, 2));
end
frequencyMatrix = repmat(frequencyMHz(:), 1, size(response, 2));
labelMatrix = repmat(string(branchLabels), numel(frequencyMHz), 1);
magnitudeDb = 20 * log10(max(abs(response), 1e-12));
plotObject = gramm("x", frequencyMatrix(:), "y", magnitudeDb(:), ...
    "color", labelMatrix(:));
plotObject.geom_line();
plotObject.set_names("x", xLabel, "y", yLabel, "color", "Path");
plotObject.set_title(figureTitle);
plotObject.set_text_options("base_size", 12, "legend_scaling", 0.85);
plotObject.set_layout_options("legend_width", 0.2);
plotObject.axe_property("ylim", [lowerLimit, upperLimit]);
figureHandle = figure("Color", "w", "Theme", "light", "Visible", "off", ...
    "Position", [100, 100, 1100, 620]);
figureCleanup = onCleanup(@() close(figureHandle));
plotObject.draw();
exportgraphics(gcf, filePath, "Resolution", 140);
clear figureCleanup
end

function restoreSourcePath(sourceRoot, addedSourcePath)
%RESTORESOURCEPATH Remove the source folder only when this example added it.

if addedSourcePath
    currentEntries = string(strsplit(path, pathsep));
    if any(currentEntries == string(sourceRoot))
        rmpath(sourceRoot);
    end
end
end
