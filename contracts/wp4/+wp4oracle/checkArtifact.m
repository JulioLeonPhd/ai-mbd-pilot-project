function diagnostic = checkArtifact(domain, data)
%CHECKARTIFACT Dispatch one fixture to an independent domain oracle.
%   DIAGNOSTIC = WP4ORACLE.CHECKARTIFACT(DOMAIN, DATA) returns the ordered
%   acceptance diagnostic for one draft.2 fixture.

arguments
    domain (1, 1) string
    data
end

if contains(domain, "fusion-") && domain ~= "fusion-zero"
    diagnostic = checkFusionCase(data, extractAfter(domain, "fusion-"));
    return
end
switch domain
    case "schedule"
        diagnostic = wp4oracle.checkSchedule(data);
    case "timing"
        diagnostic = wp4oracle.checkTiming(data);
    case "ddc"
        diagnostic = wp4oracle.checkDdc(data);
    case "ddc-streaming"
        diagnostic = wp4oracle.checkDdcStreaming(data);
    case "ddc-zero"
        diagnostic = wp4oracle.checkDdcZero(data);
    case "beam"
        diagnostic = wp4oracle.checkBeam(data);
    case "fusion-zero"
        diagnostic = wp4oracle.checkFusionZero(data);
    case "clustering"
        diagnostic = wp4oracle.checkClustering(data);
    otherwise
        diagnostic = failDiagnostic("TYPE_MISMATCH", "domain", ...
            "Unknown WP4 fixture domain.");
end
end

function diagnostic = failDiagnostic(code, path, message)
diagnostic = struct("accepted", false, "code", string(code), "path", string(path), ...
    "message", string(message), "output", struct());
end

function diagnostic = checkFusionCase(data, caseId)
diagnostic = wp4oracle.checkFusion(data, caseId);
end
