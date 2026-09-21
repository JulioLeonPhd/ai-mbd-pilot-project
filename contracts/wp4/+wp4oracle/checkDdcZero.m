function diagnostic = checkDdcZero(data)
%CHECKDDCZERO Independently validate executable all-zero DDC evidence.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["input", "output", "decimationFactors", "expectedInputShape", ...
    "expectedOutputShape", "finalState", "tolerance"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if ~isreal(data.input) || ~isa(data.input, "double") || ...
        ~isequal(size(data.input), [240, 64]) || any(data.input(:) ~= 0)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "input", ...
        "Zero evidence requires real double zeros with shape [240,64].");
    return
end
if ~isequal(size(data.output), [20, 64]) || isreal(data.output) || ...
        any(data.output(:) ~= 0) || data.tolerance ~= 0
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "output", ...
        "Zero evidence must be exact complex zeros with shape [20,64].");
    return
end
if ~isequal(data.expectedInputShape, [240, 64]) || ...
        ~isequal(data.expectedOutputShape, [20, 64]) || ...
        ~isequal(data.decimationFactors, [3, 4])
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "expectedOutputShape", ...
        "Declared zero-fixture shapes and decimations are inconsistent.");
    return
end
state = data.finalState;
if ~isstruct(state) || ~isfield(state, "stage1Delay") || ...
        ~isfield(state, "stage2Delay") || ~isfield(state, "inputSampleCount") || ...
        ~isfield(state, "stage1Phase") || ~isfield(state, "stage2Phase") || ...
        ~isequal(size(state.stage1Delay), [24, 64]) || ...
        ~isequal(size(state.stage2Delay), [240, 64]) || ...
        any(state.stage1Delay(:) ~= 0) || any(state.stage2Delay(:) ~= 0) || ...
        state.inputSampleCount ~= 240 || state.stage1Phase ~= 0 || state.stage2Phase ~= 0
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "finalState", ...
        "Zero processing did not preserve the expected delays, phases, and count.");
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
