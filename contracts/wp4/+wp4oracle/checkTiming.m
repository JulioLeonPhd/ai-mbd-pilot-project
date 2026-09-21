function diagnostic = checkTiming(data)
%CHECKTIMING Independently validate integer delay and near-range alignment.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["decimationFactors", "delayTicks", "delayOutputSamples", ...
    "primingRequired", "nearRangeMarginTicks", "finalPhaseModuloTicks"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if ~isequal(data.decimationFactors, [3, 4]) || data.delayTicks ~= 372 || ...
        data.delayOutputSamples ~= 31 || data.nearRangeMarginTicks ~= 54 || ...
        data.finalPhaseModuloTicks ~= 0
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", "delayTicks", ...
        "Timing gate does not satisfy the frozen decimation alignment.");
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
