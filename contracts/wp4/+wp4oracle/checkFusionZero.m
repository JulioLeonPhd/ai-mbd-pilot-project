function diagnostic = checkFusionZero(data)
%CHECKFUSIONZERO Validate the executable empty fusion result.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
if ~isfield(data, "hypotheses") || ~isfield(data, "results") || ...
        ~isfield(data, "seed") || data.seed ~= 401041 || ...
        ~isempty(data.hypotheses) || ~isempty(data.results)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "hypotheses", ...
        "The zero fusion fixture must contain no hypotheses or results.");
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

function diagnostic = passDiagnostic()
diagnostic = struct("accepted", true, "code", "", "path", "", "message", "", ...
    "output", struct());
end

function diagnostic = failDiagnostic(code, path, message)
diagnostic = struct("accepted", false, "code", string(code), "path", string(path), ...
    "message", string(message), "output", struct());
end
