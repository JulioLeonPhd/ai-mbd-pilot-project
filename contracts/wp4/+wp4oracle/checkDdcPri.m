function diagnostic = checkDdcPri(data)
%CHECKDDCPRI Validate independent per-PRI DDC evidence.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["processingProfile", "processingProfileVersion", "schedule", ...
    "design", "cases", "normalizedTolerance", "seed"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if string(data.processingProfile) ~= "independent-pri-v1" || ...
        string(data.processingProfileVersion) ~= "1.0.0"
    diagnostic = failDiagnostic("VERSION_MISMATCH", "processingProfile", ...
        "Per-PRI evidence must identify independent-pri-v1 version 1.0.0.");
    return
end
if ~isa(data.normalizedTolerance, "double") || ...
        ~isscalar(data.normalizedTolerance) || data.normalizedTolerance ~= 5e-11
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "normalizedTolerance", ...
        "Per-PRI evidence must use the proposed normalized tolerance 5e-11.");
    return
end
if ~isa(data.seed, "double") || ~isscalar(data.seed) || ...
        ~isfinite(data.seed) || data.seed < 0 || data.seed ~= fix(data.seed)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "seed", ...
        "Per-PRI evidence must record its nonnegative integer stimulus seed.");
    return
end
scheduleDiagnostic = wp4oracle.checkSchedule(data.schedule);
if ~scheduleDiagnostic.accepted
    diagnostic = scheduleDiagnostic;
    diagnostic.path = "schedule." + diagnostic.path;
    return
end
designDiagnostic = checkProcessingDesign(data.design);
if ~designDiagnostic.accepted
    diagnostic = designDiagnostic;
    diagnostic.path = "design." + diagnostic.path;
    return
end

expectedCaseIds = ["zero-one-channel", "first-sample-impulse", ...
    "last-sample-impulse", "boundary-chirp", "multitone-noise", ...
    "zero-64-channel", "channel-isolation-64"];
if ~isstruct(data.cases) || numel(data.cases) ~= numel(expectedCaseIds) || ...
        ~isequal(string({data.cases.caseId}), expectedCaseIds)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "cases", ...
        "Per-PRI evidence must contain the seven ordered boundary and channel cases.");
    return
end

schedule = data.schedule;
expectedPriLengths = double(schedule.priSampleCounts(:).');
casePriIndices = [1, 2, 3, 4, 5, 1, 1];
caseChannels = [1, 1, 1, 1, 1, 64, 64];
maximumError = -Inf;
maximumAbsoluteError = 0;
referenceAmplitude = 1;
for caseIndex = 1:numel(data.cases)
    item = data.cases(caseIndex);
    caseDiagnostic = checkCase(item, caseIndex, casePriIndices(caseIndex), ...
        caseChannels(caseIndex), expectedPriLengths, schedule, data.design, ...
        data.normalizedTolerance, data.seed);
    if ~caseDiagnostic.accepted
        diagnostic = caseDiagnostic;
        diagnostic.path = "cases[" + (caseIndex - 1) + "]." + diagnostic.path;
        return
    end
    caseNormalizedError = caseDiagnostic.output.maximumNormalizedError;
    if caseNormalizedError > maximumError
        maximumError = caseNormalizedError;
        referenceAmplitude = caseDiagnostic.output.referenceAmplitude;
    end
    maximumAbsoluteError = max(maximumAbsoluteError, ...
        caseDiagnostic.output.maximumAbsoluteError);
end
diagnostic = passDiagnostic();
diagnostic.output = struct("maximumNormalizedError", maximumError, ...
    "maximumAbsoluteError", maximumAbsoluteError, ...
    "normalizationReferenceAmplitude", referenceAmplitude, ...
    "caseCount", numel(data.cases), "processingProfile", data.processingProfile);
end

function diagnostic = checkProcessingDesign(design)
required = ["adcRateHz", "intermediateRateHz", "outputRateHz", ...
    "mixerFrequencyHz", "decimationFactors", "stage1Numerator", ...
    "stage2Numerator", "stage1Order", "stage2Order", ...
    "delayTicks", "delayOutputSamples"];
diagnostic = requireFields(design, required);
if ~diagnostic.accepted
    return
end
if ~isequal([design.adcRateHz, design.intermediateRateHz, design.outputRateHz], ...
        [150e6, 50e6, 12.5e6]) || design.mixerFrequencyHz ~= 50e6 || ...
        ~isequal(design.decimationFactors, [3, 4]) || ...
        design.stage1Order ~= 24 || design.stage2Order ~= 240 || ...
        design.delayTicks ~= 372 || design.delayOutputSamples ~= 31
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "rates", ...
        "Per-PRI evidence differs from the frozen DDC rates and factors.");
    return
end
if ~isTapVector(design.stage1Numerator, 25) || ...
        ~isTapVector(design.stage2Numerator, 241)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "stage1Numerator", ...
        "The frozen two-stage DDC requires 25 and 241 taps.");
    return
end
expectedStage1 = fir1(24, 25e6 / (150e6 / 2), kaiser(25, 8.6));
expectedStage2 = fir1(240, 5.625e6 / (50e6 / 2), kaiser(241, 8.6));
if any(~isfinite(design.stage1Numerator(:))) || ...
        max(abs(design.stage1Numerator(:) - expectedStage1(:))) > 5e-15
    diagnostic = failDiagnostic("DDC_COEFFICIENT_MISMATCH", "stage1Numerator", ...
        "Per-PRI evidence does not contain the frozen stage-one coefficients.");
elseif any(~isfinite(design.stage2Numerator(:))) || ...
        max(abs(design.stage2Numerator(:) - expectedStage2(:))) > 5e-15
    diagnostic = failDiagnostic("DDC_COEFFICIENT_MISMATCH", "stage2Numerator", ...
        "Per-PRI evidence does not contain the frozen stage-two coefficients.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = checkCase(item, caseIndex, expectedPriIndex, ...
        expectedChannels, expectedPriLengths, schedule, design, tolerance, seed)
required = ["caseId", "priIndex", "scheduleRecordIndex", "signalType", ...
    "input", "expectedOutput", "metadata", "coordinateMap", ...
    "targetChannel"];
diagnostic = requireFields(item, required);
if ~diagnostic.accepted
    return
end
if ~isa(item.input, "double") || ~isreal(item.input) || ...
        any(~isfinite(item.input(:))) || ...
        ~isequal(size(item.input), [expectedPriLengths(expectedPriIndex), expectedChannels])
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "input", ...
        "Each call must contain one complete finite real PRI with its declared channel count.");
    return
end
if double(item.priIndex) ~= expectedPriIndex
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "priIndex", ...
        "The evidence case references the wrong PRF index.");
    return
end
recordIndex = double(item.scheduleRecordIndex);
if ~isscalar(recordIndex) || recordIndex < 1 || recordIndex > numel(schedule.records) || ...
        recordIndex ~= fix(recordIndex)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "scheduleRecordIndex", ...
        "The case must reference a physical PRI record in the schedule.");
    return
end
record = schedule.records(recordIndex);
if ~ismember(string(record.role), ["priming", "usable"]) || ...
        double(record.prfIndex) ~= expectedPriIndex || ...
        double(record.sampleCount) ~= size(item.input, 1)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "scheduleRecordIndex", ...
        "DDC calls may reference complete priming or usable PRIs, never transition gaps.");
    return
end
outputCount = size(item.input, 1) / 12;
if outputCount ~= fix(outputCount) || ...
        ~isequal(size(item.expectedOutput), [outputCount, expectedChannels]) || ...
        ~isa(item.expectedOutput, "double") || any(~isfinite(item.expectedOutput(:)))
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "expectedOutput", ...
        "Retained no-tail output must be complex [N/12,C].");
    return
end
metadataDiagnostic = checkMetadata(item.metadata, size(item.input, 1), outputCount);
if ~metadataDiagnostic.accepted
    diagnostic = metadataDiagnostic;
    diagnostic.path = "metadata." + diagnostic.path;
    return
end
coordinateDiagnostic = checkCoordinateMap(item.coordinateMap, record, outputCount);
if ~coordinateDiagnostic.accepted
    diagnostic = coordinateDiagnostic;
    diagnostic.path = "coordinateMap." + diagnostic.path;
    return
end
caseDiagnostic = checkStimulus(item, caseIndex, expectedChannels, ...
    design.adcRateHz, seed);
if ~caseDiagnostic.accepted
    diagnostic = caseDiagnostic;
    return
end

oracleOutput = directPriConvolution(item.input, design);
if caseIndex == 1 || caseIndex == 6
    if any(item.expectedOutput(:) ~= 0)
        diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "expectedOutput", ...
            "Zero-input PRIs must produce exact complex zeros in every channel.");
        return
    end
elseif caseIndex == 7
    inactiveChannels = setdiff(1:expectedChannels, item.targetChannel);
    if any(item.expectedOutput(:, inactiveChannels) ~= 0, "all")
        diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "expectedOutput", ...
            "Inactive channel outputs must remain exact zeros.");
        return
    end
end
if isreal(item.expectedOutput)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "expectedOutput", ...
        "Retained no-tail output must have a complex sample type.");
    return
end
referenceAmplitude = max(abs(item.input(:)));
if referenceAmplitude == 0
    referenceAmplitude = 1;
end
maximumAbsoluteError = max(abs(oracleOutput(:) - item.expectedOutput(:)));
maximumNormalizedError = maximumAbsoluteError / referenceAmplitude;
if maximumNormalizedError > tolerance
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "expectedOutput", ...
        "Stored output differs from independent retained combined-FIR convolution.");
    diagnostic.output.maximumNormalizedError = maximumNormalizedError;
    diagnostic.output.maximumAbsoluteError = maximumAbsoluteError;
    diagnostic.output.referenceAmplitude = referenceAmplitude;
    return
end
diagnostic = passDiagnostic();
diagnostic.output.maximumNormalizedError = maximumNormalizedError;
diagnostic.output.maximumAbsoluteError = maximumAbsoluteError;
diagnostic.output.referenceAmplitude = referenceAmplitude;
end

function diagnostic = checkMetadata(metadata, inputCount, outputCount)
fields = ["inputSampleCount", "outputSampleCount", "decimationFactor", ...
    "groupDelayInputSamples", "groupDelayOutputSamples", ...
    "startupInputSamples", "startupOutputSamples"];
diagnostic = requireFields(metadata, fields);
if ~diagnostic.accepted
    return
end
if numel(fieldnames(metadata)) ~= numel(fields)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "metadata", ...
        "DDC metadata must remain sample-domain only.");
    return
end
expected = [inputCount, outputCount, 12, 372, 31, 744, 62];
for fieldIndex = 1:numel(fields)
    value = metadata.(char(fields(fieldIndex)));
    if ~isa(value, "double") || ~isscalar(value) || ~isfinite(value) || ...
            value ~= expected(fieldIndex)
        diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", fields(fieldIndex), ...
            "Sample-domain DDC metadata differs from the approved per-PRI contract.");
        return
    end
end
diagnostic = passDiagnostic();
end

function diagnostic = checkCoordinateMap(map, record, outputCount)
required = ["timeEpoch", "startTick", "rawOutputStartTick", ...
    "rawOutputLastTick", "compensatedOutputStartTick", ...
    "compensatedOutputLastTick", "groupDelayInputSamples"];
diagnostic = requireFields(map, required);
if ~diagnostic.accepted
    return
end
startTick = int64(record.startTick);
lastRawTick = startTick + int64((outputCount - 1) * 12);
expected = [double(startTick), double(startTick), double(lastRawTick), ...
    double(startTick - 372), double(lastRawTick - 372), 372];
actual = [double(map.startTick), double(map.rawOutputStartTick), ...
    double(map.rawOutputLastTick), double(map.compensatedOutputStartTick), ...
    double(map.compensatedOutputLastTick), double(map.groupDelayInputSamples)];
if ~isa(map.timeEpoch, "uint64") || ~isscalar(map.timeEpoch) || ...
        map.timeEpoch ~= uint64(1) || any(actual ~= expected)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "compensatedOutputStartTick", ...
        "Caller tick mapping must apply the 372-tick delay exactly once.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = checkStimulus(item, caseIndex, expectedChannels, sampleRateHz, seed)
switch caseIndex
    case 1
        valid = all(item.input(:) == 0) && item.targetChannel == 0 && ...
            string(item.signalType) == "zero";
    case 2
        expected = zeros(size(item.input));
        expected(1, 1) = 1;
        valid = isequal(item.input, expected) && item.targetChannel == 1 && ...
            string(item.signalType) == "first-impulse";
    case 3
        expected = zeros(size(item.input));
        expected(end, 1) = 1;
        valid = isequal(item.input, expected) && item.targetChannel == 1 && ...
            string(item.signalType) == "last-impulse";
    case 4
        expected = boundaryChirp(size(item.input, 1), sampleRateHz);
        valid = isequal(item.input, expected) && item.targetChannel == 1 && ...
            string(item.signalType) == "boundary-chirp";
    case 5
        expected = multitoneNoise(size(item.input, 1), sampleRateHz, seed);
        valid = isequal(item.input, expected) && item.targetChannel == 1 && ...
            string(item.signalType) == "multitone-noise";
    case 6
        valid = expectedChannels == 64 && item.targetChannel == 0 && ...
            all(item.input(:) == 0) && string(item.signalType) == "zero";
    case 7
        targetChannel = 17;
        sampleIndex = (0:size(item.input, 1) - 1).';
        expectedSignal = 0.7 .* cos(2 * pi * 49.8e6 / sampleRateHz .* ...
            sampleIndex + 0.13);
        expected = zeros(size(item.input));
        expected(:, targetChannel) = expectedSignal;
        valid = expectedChannels == 64 && item.targetChannel == targetChannel && ...
            string(item.signalType) == "channel-isolation" && isequal(item.input, expected);
    otherwise
        valid = false;
end

function signal = boundaryChirp(sampleCount, sampleRateHz)
chirpSamples = round(40e-6 * sampleRateHz);
chirpTime = (0:chirpSamples - 1).' / sampleRateHz;
bandwidthHz = 3e6;
chirp = 0.5 .* cos(2 * pi * (48.5e6 .* chirpTime + ...
    0.5 * bandwidthHz / 40e-6 .* chirpTime .^ 2));
signal = zeros(sampleCount, 1);
signal(1:chirpSamples) = chirp;
signal(end - chirpSamples + 1:end) = chirp;
end

function signal = multitoneNoise(sampleCount, sampleRateHz, seed)
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
randomStream = RandStream("mt19937ar", "Seed", seed);
signal = signal + 0.05 .* randn(randomStream, sampleCount, 1);
end
if valid
    diagnostic = passDiagnostic();
else
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "signalType", ...
        "The stimulus does not match its declared boundary or isolation case.");
end
end

function output = directPriConvolution(input, design)
stage2Upsampled = zeros(1, 1 + (numel(design.stage2Numerator) - 1) * 3);
stage2Upsampled(1:3:end) = design.stage2Numerator(:).';
combinedTaps = conv(design.stage1Numerator(:).', stage2Upsampled);
outputCount = size(input, 1) / 12;
output = complex(zeros(outputCount, size(input, 2)));
sampleIndex = (0:size(input, 1) - 1).';
mixer = exp(-1i * 2 * pi * design.mixerFrequencyHz / design.adcRateHz * sampleIndex);
for channelIndex = 1:size(input, 2)
    if all(input(:, channelIndex) == 0)
        continue
    end
    mixed = input(:, channelIndex) .* mixer;
    fullConvolution = conv(mixed, combinedTaps);
    output(:, channelIndex) = fullConvolution(1:12:size(input, 1));
end
end

function output = isTapVector(value, lengthExpected)
output = isvector(value) && numel(value) == lengthExpected;
end

function diagnostic = checkVersion(data)
if ~isstruct(data) || ~isfield(data, "schemaVersion")
    diagnostic = failDiagnostic("MISSING_FIELD", "schemaVersion", "Schema version is required.");
elseif string(data.schemaVersion) ~= "1.0.0-draft.2"
    diagnostic = failDiagnostic("VERSION_MISMATCH", "schemaVersion", ...
        "Only schema 1.0.0-draft.2 is accepted.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = requireFields(data, fields)
diagnostic = passDiagnostic();
for index = 1:numel(fields)
    if ~isstruct(data) || ~isfield(data, fields(index))
        diagnostic = failDiagnostic("MISSING_FIELD", fields(index), ...
            "A required per-PRI evidence field is missing.");
        return
    end
end
end

function diagnostic = passDiagnostic()
diagnostic = struct("accepted", true, "code", "", "path", "", "message", "", ...
    "output", struct());
end

function diagnostic = failDiagnostic(code, path, message)
diagnostic = struct("accepted", false, "code", string(code), "path", string(path), ...
    "message", string(message), "output", struct());
end
