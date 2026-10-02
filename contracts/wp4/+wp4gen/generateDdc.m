function ddc = generateDdc(schedule, options)
%GENERATEDDC Generate current DDC response and independent-PRI witnesses.
arguments
    schedule struct
    options struct
end

design = radardemo.ddc.createDesign(struct());
metrics = radardemo.ddc.measureResponse(design, struct());
design.responseMetricProfile = metrics.responseMetricProfile;
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
design = wp4gen.addProvenance(design, options, options.Seeds.ddc, "ddc-response-pri");

processingDesign = struct("adcRateHz", design.adcRateHz, ...
    "intermediateRateHz", design.intermediateRateHz, ...
    "outputRateHz", design.outputRateHz, ...
    "mixerFrequencyHz", design.mixerFrequencyHz, ...
    "decimationFactors", design.decimationFactors, ...
    "stage1Order", design.stage1Order, "stage2Order", design.stage2Order, ...
    "delayTicks", design.delayTicks, ...
    "delayOutputSamples", design.delayOutputSamples, ...
    "stage1Numerator", design.stage1Numerator, ...
    "stage2Numerator", design.stage2Numerator);
pri = generatePriEvidence(schedule, processingDesign, options);
ddc = struct("design", design, "pri", pri);
end

function evidence = generatePriEvidence(schedule, design, options)
caseTemplate = struct("caseId", "", "priIndex", 0, ...
    "scheduleRecordIndex", 0, "signalType", "", "input", [], ...
    "expectedOutput", [], "metadata", struct(), "coordinateMap", struct(), ...
    "targetChannel", 0);
caseIds = ["zero-one-channel", "first-sample-impulse", ...
    "last-sample-impulse", "boundary-chirp", "multitone-noise", ...
    "zero-64-channel", "channel-isolation-64"];
priIndices = [1, 2, 3, 4, 5, 1, 1];
signalTypes = ["zero", "first-impulse", "last-impulse", ...
    "boundary-chirp", "multitone-noise", "zero", "channel-isolation"];
channelCounts = [1, 1, 1, 1, 1, 64, 64];
cases = repmat(caseTemplate, numel(caseIds), 1);
randomStream = RandStream("mt19937ar", "Seed", options.Seeds.ddc);

for caseIndex = 1:numel(cases)
    priIndex = priIndices(caseIndex);
    recordIndex = firstPhysicalRecord(schedule, priIndex);
    record = schedule.records(recordIndex);
    sampleCount = double(schedule.priSampleCounts(priIndex));
    inputSignal = zeros(sampleCount, channelCounts(caseIndex));
    switch caseIndex
        case 1
            % The exact zero case covers all output rows of a physical PRI.
            inputSignal(:) = 0;
        case 2
            inputSignal(1, 1) = 1;
        case 3
            inputSignal(end, 1) = 1;
        case 4
            inputSignal(:, 1) = makeBoundaryChirp(sampleCount, design.adcRateHz);
        case 5
            inputSignal(:, 1) = makeMultitoneNoise(sampleCount, design.adcRateHz, randomStream);
        case 6
            inputSignal(:) = 0;
        case 7
            sampleIndex = (0:sampleCount - 1).';
            inputSignal(:, 17) = 0.7 .* cos(2 * pi * 49.8e6 / ...
                design.adcRateHz .* sampleIndex + 0.13);
        otherwise
            error("wp4gen:DdcPriCase", "Unknown per-PRI DDC case index.");
    end

    [expectedOutput, metadata] = radardemo.ddc.processFrame(inputSignal, design);
    outputCount = size(inputSignal, 1) / 12;
    startTick = int64(record.startTick);
    lastTick = startTick + int64((outputCount - 1) * 12);
    coordinateMap = struct("timeEpoch", uint64(1), "startTick", startTick, ...
        "rawOutputStartTick", startTick, "rawOutputLastTick", lastTick, ...
        "compensatedOutputStartTick", startTick - 372, ...
        "compensatedOutputLastTick", lastTick - 372, ...
        "groupDelayInputSamples", 372);
    targetChannel = 0;
    if ismember(caseIndex, [2, 3, 4, 5])
        targetChannel = 1;
    end
    if caseIndex == 7
        targetChannel = 17;
    end
    cases(caseIndex) = struct("caseId", caseIds(caseIndex), ...
        "priIndex", priIndex, "scheduleRecordIndex", recordIndex, ...
        "signalType", signalTypes(caseIndex), "input", inputSignal, ...
        "expectedOutput", expectedOutput, "metadata", metadata, ...
        "coordinateMap", coordinateMap, "targetChannel", targetChannel);
end

evidence = struct("schemaName", "radar.wp4.ddc-pri", ...
    "schemaVersion", "1.0.0-draft.2", ...
    "processingProfile", "independent-pri-v1", ...
    "processingProfileVersion", "1.0.0", "schedule", schedule, ...
    "design", design, "cases", cases, "normalizedTolerance", 5e-11, ...
    "seed", options.Seeds.ddc);
evidence = wp4gen.addProvenance(evidence, options, options.Seeds.ddc, "ddc-pri");
end

function recordIndex = firstPhysicalRecord(schedule, priIndex)
recordRoles = string({schedule.records.role});
recordPrfIndices = [schedule.records.prfIndex];
recordIndex = find(recordPrfIndices == priIndex & ...
    ismember(recordRoles, ["priming", "usable"]), 1, "first");
if isempty(recordIndex)
    error("wp4gen:DdcPriRecord", "The schedule does not contain a physical PRI for this PRF.");
end
end

function signal = makeBoundaryChirp(sampleCount, sampleRateHz)
chirpSamples = round(40e-6 * sampleRateHz);
chirpTime = (0:chirpSamples - 1).' / sampleRateHz;
bandwidthHz = 3e6;
chirp = 0.5 .* cos(2 * pi * (48.5e6 .* chirpTime + ...
    0.5 * bandwidthHz / 40e-6 .* chirpTime .^ 2));
signal = zeros(sampleCount, 1);
signal(1:chirpSamples) = chirp;
signal(end - chirpSamples + 1:end) = chirp;
end

function signal = makeMultitoneNoise(sampleCount, sampleRateHz, randomStream)
sampleIndex = (0:sampleCount - 1).';
frequenciesHz = [49.2e6, 50.15e6, 51e6];
amplitudes = [0.31, 0.23, 0.17];
phasesRad = [0.17, 1.19, 2.07];
signal = zeros(sampleCount, 1);
for toneIndex = 1:numel(frequenciesHz)
    signal = signal + amplitudes(toneIndex) .* ...
        cos(2 * pi * frequenciesHz(toneIndex) / sampleRateHz .* ...
        sampleIndex + phasesRad(toneIndex));
end
signal = signal + 0.05 .* randn(randomStream, sampleCount, 1);
end
