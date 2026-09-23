function diagnostic = checkDdcStreaming(data)
%CHECKDDCSTREAMING Check chunk continuity with independent combined-FIR oracles.
diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["input", "chunkLengths", "expectedOutput", "expectedLength", ...
    "boundaryEvidence"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if ~isreal(data.input) || ~isa(data.input, "double") || any(~isfinite(data.input(:)))
    diagnostic = failDiagnostic("TYPE_MISMATCH", "input", ...
        "Short-stream input must be finite real double samples.");
    return
end
if ~isvector(data.chunkLengths) || numel(data.chunkLengths) < 2 || ...
        any(data.chunkLengths <= 0) || sum(data.chunkLengths) ~= numel(data.input)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "chunkLengths", ...
        "Short-stream chunks must cover the finite input.");
    return
end
taps = combinedTaps();
shortTicks = 12 * (0:ceil(numel(data.input) / 12) - 1).';
shortExpected = directConvolution(data.input(:), shortTicks, taps, 50e6, 150e6);
if numel(shortExpected) ~= data.expectedLength || ...
        numel(data.expectedOutput) ~= data.expectedLength || ...
        any(~isfinite(data.expectedOutput(:))) || ...
        max(abs(shortExpected(:) - data.expectedOutput(:))) > 5e-11
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "expectedOutput", ...
        "Short-stream output differs from independent combined-FIR convolution.");
    return
end
diagnostic = checkBoundaryEvidence(data.boundaryEvidence, taps);
end

function diagnostic = checkBoundaryEvidence(evidence, taps)
required = ["schedule", "stimulus", "inputSampleCount", "channelCount", ...
    "maxChunkSamples", "chunkLengths", "checkpoints", "boundaryTicks", ...
    "windowRadiusTicks", "outputTicks", "outputSamples", ...
    "expectedOutputCount", "tolerance"];
diagnostic = requireFields(evidence, required);
if ~diagnostic.accepted
    diagnostic.path = "boundaryEvidence." + diagnostic.path;
    return
end
scheduleDiagnostic = wp4oracle.checkSchedule(evidence.schedule);
if ~scheduleDiagnostic.accepted
    diagnostic = scheduleDiagnostic;
    diagnostic.path = "boundaryEvidence.schedule." + diagnostic.path;
    return
end
schedule = evidence.schedule;
totalTicks = double(schedule.totalTicks);
boundaries = double([schedule.records(1:end - 1).endTick]).';
if numel(boundaries) ~= 150 || ...
        ~isequal(double(evidence.boundaryTicks(:)), boundaries) || ...
        double(evidence.inputSampleCount) ~= totalTicks || ...
        double(evidence.channelCount) ~= 1 || double(evidence.maxChunkSamples) ~= 8192 || ...
        double(evidence.windowRadiusTicks) ~= 768 || ...
        double(evidence.expectedOutputCount) ~= ceil(totalTicks / 12) || ...
        double(evidence.tolerance) ~= 5e-11
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "boundaryEvidence.boundaryTicks", ...
        "Boundary evidence must cover the frozen single-channel scan and output lattice.");
    return
end
stimulus = evidence.stimulus;
stimulusFields = ["frequenciesHz", "amplitudes", "phasesRad", ...
    "sampleRateHz", "mixerFrequencyHz"];
if ~isstruct(stimulus) || any(~isfield(stimulus, stimulusFields))
    diagnostic = failDiagnostic("MISSING_FIELD", "boundaryEvidence.stimulus", ...
        "The fixed multitone waveform and mixer parameters are required.");
    return
end
if ~isequal(double(stimulus.frequenciesHz(:).'), [49e6, 49.6e6, 50.4e6, 51e6]) || ...
        ~isequal(double(stimulus.amplitudes(:).'), [0.41, 0.32, 0.23, 0.17]) || ...
        ~isequal(double(stimulus.phasesRad(:).'), [0.17, 0.73, 1.19, 2.07]) || ...
        double(stimulus.sampleRateHz) ~= 150e6 || ...
        double(stimulus.mixerFrequencyHz) ~= 50e6
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "boundaryEvidence.stimulus", ...
        "The boundary stream stimulus differs from the frozen multitone witness.");
    return
end
offsets = [-17, -5, 0, 7, 17, 23];
candidateCuts = reshape(boundaries + offsets, [], 1);
candidateCuts = candidateCuts(candidateCuts > 0 & candidateCuts < totalTicks);
expectedCuts = unique([ (0:8192:totalTicks).'; candidateCuts; totalTicks ]);
expectedChunkLengths = diff(expectedCuts);
if ~isvector(evidence.chunkLengths) || ...
        ~isequal(double(evidence.chunkLengths(:)), expectedChunkLengths) || ...
        any(expectedChunkLengths <= 0) || any(expectedChunkLengths > 8192)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "boundaryEvidence.chunkLengths", ...
        "Chunks must include each off-lattice cut and cover the scan in at most 8192 samples.");
    return
end
cumulativeInputs = cumsum(expectedChunkLengths);
firstStageCounts = ceil(cumulativeInputs / 3);
expectedCheckpoints = [cumulativeInputs, mod(cumulativeInputs, 3), ...
    mod(firstStageCounts, 4), ceil(cumulativeInputs / 12)];
if ~isequal(size(evidence.checkpoints), size(expectedCheckpoints)) || ...
        any(double(evidence.checkpoints(:)) ~= expectedCheckpoints(:))
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", "boundaryEvidence.checkpoints", ...
        "Input counts and decimator phases must continue across every chunk.");
    return
end
expectedTicks = observationTicks(boundaries, totalTicks, 768);
if ~isequal(double(evidence.outputTicks(:)), expectedTicks) || ...
        numel(evidence.outputSamples) ~= numel(expectedTicks) || ...
        any(~isfinite(evidence.outputSamples(:)))
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "boundaryEvidence.outputTicks", ...
        "Observed complex output windows must cover startup, end, and all schedule boundaries.");
    return
end
recomputed = directToneConvolution(stimulus, expectedTicks, taps, totalTicks);
maximumError = max(abs(recomputed(:) - evidence.outputSamples(:)));
if maximumError > double(evidence.tolerance)
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "boundaryEvidence.outputSamples", ...
        "Continuous DDC samples differ from the independent combined-FIR oracle.");
else
    diagnostic = passDiagnostic();
end
diagnostic.output.maxAbsoluteError = maximumError;
end

function taps = combinedTaps()
stage1 = fir1(24, 25e6 / 75e6, kaiser(25, 8.6));
stage2 = fir1(240, 5.625e6 / 25e6, kaiser(241, 8.6));
expandedStage2 = zeros(1, (numel(stage2) - 1) * 3 + 1);
expandedStage2(1:3:end) = stage2;
taps = conv(stage1, expandedStage2);
end

function output = directConvolution(input, outputTicks, taps, mixerFrequencyHz, sampleRateHz)
output = complex(zeros(numel(outputTicks), 1));
lags = 0:numel(taps) - 1;
for first = 1:64:numel(outputTicks)
    last = min(first + 63, numel(outputTicks));
    sampleIndices = outputTicks(first:last) - lags;
    valid = sampleIndices >= 0 & sampleIndices < numel(input);
    samples = zeros(size(sampleIndices));
    samples(valid) = input(sampleIndices(valid) + 1);
    mixer = exp(-1i * 2 * pi * mixerFrequencyHz / sampleRateHz .* sampleIndices);
    output(first:last) = sum(samples .* mixer .* taps, 2);
end
end

function output = directToneConvolution(stimulus, outputTicks, taps, inputLength)
output = complex(zeros(numel(outputTicks), 1));
lags = 0:numel(taps) - 1;
for first = 1:48:numel(outputTicks)
    last = min(first + 47, numel(outputTicks));
    sampleIndices = outputTicks(first:last) - lags;
    valid = sampleIndices >= 0 & sampleIndices < inputLength;
    realInput = zeros(size(sampleIndices));
    for toneIndex = 1:numel(stimulus.frequenciesHz)
        realInput = realInput + stimulus.amplitudes(toneIndex) .* ...
            cos(2 * pi * stimulus.frequenciesHz(toneIndex) / stimulus.sampleRateHz .* ...
            sampleIndices + stimulus.phasesRad(toneIndex));
    end
    realInput(~valid) = 0;
    mixer = exp(-1i * 2 * pi * stimulus.mixerFrequencyHz / ...
        stimulus.sampleRateHz .* sampleIndices);
    output(first:last) = sum(realInput .* mixer .* taps, 2);
end
end

function ticks = observationTicks(boundaries, totalTicks, radius)
lastOutputTick = 12 * (ceil(totalTicks / 12) - 1);
boundaryWindows = reshape(boundaries + (-radius:12:radius), [], 1);
startup = 0:12:min(lastOutputTick, radius);
ending = (lastOutputTick - radius):12:lastOutputTick;
ticks = unique([startup(:); ending(:); boundaryWindows]);
ticks = ticks(ticks >= 0 & ticks <= lastOutputTick & mod(ticks, 12) == 0);
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
            "A required streaming evidence field is missing.");
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
