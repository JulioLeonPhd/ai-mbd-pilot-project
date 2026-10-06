function diagnostic = checkFusion(data, caseId)
%CHECKFUSION Independently validate one projected five-layer fusion case.

if isfield(data, "cases")
    matches = string({data.cases.caseId}) == caseId;
    if ~any(matches)
        diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", "caseId", ...
            "Unknown fusion case.");
        return
    end
    data = data.cases(find(matches, 1));
end
diagnostic = wp4oracle.checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["validityMask", "supportMask", "passMask", "voteThreshold"];
diagnostic = wp4oracle.requireFields(data, required);
if ~diagnostic.accepted
    return
end
if any([numel(data.validityMask), numel(data.supportMask), numel(data.passMask)] ~= 5)
    diagnostic = wp4oracle.failDiagnostic("DIMENSION_MISMATCH", "passMask", ...
        "Fusion masks must have length five.");
    return
end
if any(logical(data.supportMask(:).') & ~logical(data.validityMask(:).'))
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", "supportMask", ...
        "Support must be a subset of validity.");
    return
end
if data.voteThreshold ~= 3
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", "voteThreshold", ...
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
    diagnostic = wp4oracle.failDiagnostic("NUMERICAL_MISMATCH", "voteCount", ...
        "Stored vote count differs from the masks.");
elseif isfield(data, "outcome") && string(data.outcome) ~= outcome
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", "outcome", ...
        "Stored outcome differs from the masks.");
else
    diagnostic = wp4oracle.passDiagnostic();
end
end
