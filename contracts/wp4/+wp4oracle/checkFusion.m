function diagnostic = checkFusion(data, caseId)
%CHECKFUSION Independently validate one projected five-layer fusion case.

if isfield(data, "cases")
    matches = string({data.cases.caseId}) == caseId;
    if ~any(matches)
        diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "caseId", ...
            "Unknown fusion case.");
        return
    end
    data = data.cases(find(matches, 1));
end
diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["validityMask", "supportMask", "passMask", "voteThreshold"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if any([numel(data.validityMask), numel(data.supportMask), numel(data.passMask)] ~= 5)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "passMask", ...
        "Fusion masks must have length five.");
    return
end
if any(logical(data.supportMask(:).') & ~logical(data.validityMask(:).'))
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "supportMask", ...
        "Support must be a subset of validity.");
    return
end
if data.voteThreshold ~= 3
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "voteThreshold", ...
        "Fusion vote threshold must be three.");
    return
end
voteCount = sum(logical(data.passMask(:).'));
validCount = sum(logical(data.validityMask(:).'));
if validCount < 3
    outcome = "invalid";
elseif voteCount >= 3
    outcome = "pass";
else
    outcome = "fail";
end
if isfield(data, "voteCount") && data.voteCount ~= voteCount
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "voteCount", ...
        "Stored vote count differs from the masks.");
elseif isfield(data, "outcome") && string(data.outcome) ~= outcome
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "outcome", ...
        "Stored outcome differs from the masks.");
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
