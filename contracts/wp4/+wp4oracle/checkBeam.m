function diagnostic = checkBeam(data)
%CHECKBEAM Independently validate commanded-look beam evidence.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["input", "expectedOutput", "commandAngleDeg", "inputShape", ...
    "outputShape", "normalization", "signConvention"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if ~isequal(size(data.input, 2), 64) || ~isequal(size(data.expectedOutput, 2), 4) || ...
        ~isequal(data.inputShape, size(data.input)) || ...
        ~isequal(data.outputShape, size(data.expectedOutput))
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "input", ...
        "Beam input and output dimensions must be [N,64] and [N,4].");
    return
end
if any(~isfinite(data.input(:))) || any(~isfinite(data.expectedOutput(:)))
    diagnostic = failDiagnostic("NONFINITE", "input", "Beam samples must be finite.");
    return
end
elementIndex = (0:15).';
steering = exp(-1i * 2 * pi * 0.5 * elementIndex * sind(data.commandAngleDeg));
recomputed = zeros(size(data.expectedOutput));
for sampleIndex = 1:size(data.input, 1)
    for rowIndex = 1:4
        channels = rowIndex:4:64;
        recomputed(sampleIndex, rowIndex) = sum(conj(steering) .* ...
            data.input(sampleIndex, channels).');
    end
end
if max(abs(recomputed(:) - data.expectedOutput(:))) > 1e-12
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "expectedOutput", ...
        "Beam output does not match the independent commanded-look sum.");
else
    diagnostic = passDiagnostic();
end
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
