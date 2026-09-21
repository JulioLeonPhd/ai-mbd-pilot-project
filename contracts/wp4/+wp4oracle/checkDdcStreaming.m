function diagnostic = checkDdcStreaming(data)
%CHECKDDCSTREAMING Recompute unequal-chunk DDC evidence with local state.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["input", "chunkLengths", "expectedOutput", "expectedLength"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if ~isreal(data.input) || ~isa(data.input, "double") || any(~isfinite(data.input(:)))
    diagnostic = failDiagnostic("TYPE_MISMATCH", "input", ...
        "Streaming input must be finite real double samples.");
    return
end
if sum(data.chunkLengths) ~= numel(data.input) || numel(data.chunkLengths) < 2 || ...
        any(data.chunkLengths <= 0)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "chunkLengths", ...
        "Streaming chunks must cover the input in at least two positive chunks.");
    return
end
stage1 = fir1(24, 25e6 / 75e6, kaiser(25, 8.6));
stage2 = fir1(240, 5.625e6 / 25e6, kaiser(241, 8.6));
mixed = data.input(:) .* exp(-1i * 2 * pi * 50e6 / 150e6 * (0:numel(data.input) - 1).');
recomputed = processChunks(mixed, data.chunkLengths(:), stage1, stage2);
if numel(recomputed) ~= data.expectedLength || ...
        numel(data.expectedOutput) ~= data.expectedLength || ...
        max(abs(recomputed(:) - data.expectedOutput(:))) > 5e-11
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "expectedOutput", ...
        "Streaming DDC output is not reproducible with continuous state.");
else
    diagnostic = passDiagnostic();
end
end

function output = processChunks(inputSignal, chunkLengths, stage1, stage2)
firstDelay = zeros(numel(stage1) - 1, 1);
secondDelay = zeros(numel(stage2) - 1, 1);
inputOffset = 0;
firstPhase = 0;
secondPhase = 0;
pieces = cell(numel(chunkLengths), 1);
for chunkIndex = 1:numel(chunkLengths)
    chunkSize = chunkLengths(chunkIndex);
    indices = inputOffset + (1:chunkSize);
    [firstOutput, firstDelay] = filter(stage1, 1, inputSignal(indices), firstDelay);
    keepFirst = 1 + mod(3 - firstPhase, 3);
    if keepFirst <= numel(firstOutput)
        retained = firstOutput(keepFirst:3:end);
    else
        retained = zeros(0, 1);
    end
    [secondOutput, secondDelay] = filter(stage2, 1, retained, secondDelay);
    keepSecond = 1 + mod(4 - secondPhase, 4);
    if keepSecond <= numel(secondOutput)
        pieces{chunkIndex} = secondOutput(keepSecond:4:end);
    else
        pieces{chunkIndex} = zeros(0, 1);
    end
    inputOffset = inputOffset + chunkSize;
    firstPhase = mod(firstPhase + chunkSize, 3);
    secondPhase = mod(secondPhase + numel(retained), 4);
end
output = vertcat(pieces{:});
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
        diagnostic = failDiagnostic("MISSING_FIELD", fields(index), "A required field is missing.");
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
