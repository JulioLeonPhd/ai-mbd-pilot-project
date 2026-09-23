function ddc = generateDdc(schedule, options)
%GENERATEDDC Record DDC response, short-stream, schedule-boundary, and zero evidence.
arguments
    schedule struct
    options struct
end
design = radardemo.ddc.createDesign(struct());
metrics = radardemo.ddc.measureResponse(design, struct());
design.frequencyHz = metrics.frequencyHz;
design.sampleRateHz = design.adcRateHz;
design.stage1Response = metrics.stage1Response;
design.stage2Response = metrics.stage2Response;
design.stage1AliasBranches = metrics.stage1AliasBranches;
design.stage2AliasBranches = metrics.stage2AliasBranches;
design.cascadeAliasBranches = metrics.cascadeAliasBranches;
design.cascadeBranchPairs = metrics.cascadeBranchPairs;
design.principalCascadeResponse = metrics.principalCascadeResponse;
design.principalPassbandGain = metrics.principalPassbandGain;
design.principalPassbandValid = metrics.principalPassbandValid;
design.passbandRippleDb = metrics.passbandRippleDb;
design.stage2AliasRejectionDb = metrics.stage2AliasRejectionDb;
design.digitalAliasRejectionDb = metrics.digitalAliasRejectionDb;
design.gridResolutionHz = metrics.gridResolutionHz;
design.seed = options.Seeds.ddc;
design = wp4gen.addProvenance(design, options, options.Seeds.ddc, "ddc");

sampleCount = 2400;
sampleIndex = (0:sampleCount - 1).';
inputSignal = cos(2 * pi * 50e6 / 150e6 * sampleIndex) + ...
    0.1 * cos(2 * pi * 2e6 / 150e6 * sampleIndex);
chunkLengths = [317, 911, 503, sampleCount - 317 - 911 - 503];
state = radardemo.ddc.initializeState(design, 1);
outputChunks = cell(numel(chunkLengths), 1);
offset = 0;
for index = 1:numel(chunkLengths)
    chunk = inputSignal(offset + (1:chunkLengths(index)), :);
    [outputChunks{index}, state] = radardemo.ddc.processChunk(chunk, state, design);
    offset = offset + chunkLengths(index);
end
streaming = struct();
streaming.schemaName = "radar.wp4.ddc-streaming";
streaming.schemaVersion = "1.0.0-draft.2";
streaming.input = inputSignal;
streaming.chunkLengths = chunkLengths;
streaming.expectedOutput = vertcat(outputChunks{:});
streaming.expectedLength = numel(streaming.expectedOutput);
streaming.tolerance = 5e-11;
streaming.seed = options.Seeds.ddc;
streaming.boundaryEvidence = generateBoundaryEvidence(schedule, design);
streaming = wp4gen.addProvenance(streaming, options, options.Seeds.ddc, "ddc-streaming");

zero = struct();
zero.schemaName = "radar.wp4.ddc-zero";
zero.schemaVersion = "1.0.0-draft.2";
zero.input = zeros(240, 64);
zeroState = radardemo.ddc.initializeState(design, 64);
[zero.output, zeroState] = radardemo.ddc.processChunk(zero.input, zeroState, design);
zero.output = complex(zero.output);
zero.decimationFactors = design.decimationFactors;
zero.tolerance = 0;
zero.expectedInputShape = [240, 64];
zero.expectedOutputShape = [20, 64];
zero.finalState = zeroState;
zero.seed = options.Seeds.ddc;
zero = wp4gen.addProvenance(zero, options, options.Seeds.ddc, "ddc-zero");
ddc = struct("design", design, "streaming", streaming, "zero", zero);
end

function evidence = generateBoundaryEvidence(schedule, design)
totalTicks = double(schedule.totalTicks);
boundaryTicks = double([schedule.records(1:end - 1).endTick]).';
stimulus = struct("frequenciesHz", [49e6, 49.6e6, 50.4e6, 51e6], ...
    "amplitudes", [0.41, 0.32, 0.23, 0.17], ...
    "phasesRad", [0.17, 0.73, 1.19, 2.07], "sampleRateHz", 150e6, ...
    "mixerFrequencyHz", 50e6);
regularCuts = 0:8192:totalTicks;
offsets = [-17, -5, 0, 7, 17, 23];
boundaryCuts = reshape(boundaryTicks + offsets, [], 1);
boundaryCuts = boundaryCuts(boundaryCuts > 0 & boundaryCuts < totalTicks);
cuts = unique([regularCuts(:); boundaryCuts; totalTicks]);
chunkLengths = diff(cuts);
if any(chunkLengths <= 0) || any(chunkLengths > 8192) || sum(chunkLengths) ~= totalTicks
    error("wp4gen:DdcChunkPlan", "Boundary stream chunks must cover the scan in bounded pieces.");
end
lastOutputTick = 12 * (ceil(totalTicks / 12) - 1);
boundaryWindows = reshape(boundaryTicks + (-768:12:768), [], 1);
startupWindow = 0:12:min(lastOutputTick, 768);
endWindow = (lastOutputTick - 768):12:lastOutputTick;
outputTicks = unique([startupWindow(:); endWindow(:); boundaryWindows]);
outputTicks = outputTicks(outputTicks >= 0 & outputTicks <= lastOutputTick & ...
    mod(outputTicks, 12) == 0);
outputSamples = complex(zeros(numel(outputTicks), 1));
outputOrdinals = outputTicks / 12;
checkpoints = zeros(numel(chunkLengths), 4);
state = radardemo.ddc.initializeState(design, 1);
offset = 0;
outputCount = 0;
for chunkIndex = 1:numel(chunkLengths)
    chunkSize = chunkLengths(chunkIndex);
    indices = offset + (0:chunkSize - 1).';
    input = makeStimulus(indices, stimulus);
    [chunkOutput, state] = radardemo.ddc.processChunk(input, state, design);
    if ~isempty(chunkOutput)
        firstOrdinal = ceil(offset / 12);
        ordinals = firstOrdinal + (0:numel(chunkOutput) - 1).';
        selected = find(outputOrdinals >= firstOrdinal & outputOrdinals <= ordinals(end));
        if ~isempty(selected)
            localIndices = outputOrdinals(selected) - firstOrdinal + 1;
            outputSamples(selected) = chunkOutput(localIndices);
        end
    end
    outputCount = outputCount + numel(chunkOutput);
    offset = offset + chunkSize;
    checkpoints(chunkIndex, :) = [double(state.inputSampleCount), ...
        double(state.stage1Phase), double(state.stage2Phase), outputCount];
end
expectedOutputCount = ceil(totalTicks / 12);
if offset ~= totalTicks || outputCount ~= expectedOutputCount || ...
        any(~isfinite(outputSamples))
    error("wp4gen:DdcBoundaryStream", ...
        "The continuous DDC stream did not produce the expected bounded observations.");
end
evidence = struct("schedule", schedule, "stimulus", stimulus, ...
    "inputSampleCount", uint64(totalTicks), "channelCount", 1, ...
    "maxChunkSamples", 8192, "chunkLengths", chunkLengths, ...
    "checkpoints", checkpoints, "boundaryTicks", uint64(boundaryTicks), ...
    "windowRadiusTicks", 768, "outputTicks", uint64(outputTicks), ...
    "outputSamples", outputSamples, "expectedOutputCount", uint64(expectedOutputCount), ...
    "tolerance", 5e-11);
end

function samples = makeStimulus(sampleIndices, stimulus)
samples = zeros(numel(sampleIndices), 1);
for toneIndex = 1:numel(stimulus.frequenciesHz)
    samples = samples + stimulus.amplitudes(toneIndex) .* ...
        cos(2 * pi * stimulus.frequenciesHz(toneIndex) / stimulus.sampleRateHz .* ...
        sampleIndices + stimulus.phasesRad(toneIndex));
end
end
