function diagnostic = checkFusionZero(data)
%CHECKFUSIONZERO Validate the executable empty fusion result.

diagnostic = wp4oracle.checkVersion(data);
if ~diagnostic.accepted
    return
end
if ~isfield(data, "hypotheses") || ~isfield(data, "results") || ...
        ~isfield(data, "seed") || data.seed ~= 401041 || ...
        ~isempty(data.hypotheses) || ~isempty(data.results)
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", "hypotheses", ...
        "The zero fusion fixture must contain no hypotheses or results.");
else
    diagnostic = wp4oracle.passDiagnostic();
end
end
