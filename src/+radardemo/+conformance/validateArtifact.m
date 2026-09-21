function diagnostic = validateArtifact(domain, artifact)
%VALIDATEARTIFACT Validate a WP4 artifact envelope at production boundaries.
%   DIAGNOSTIC = RADARDEMO.CONFORMANCE.VALIDATEARTIFACT(DOMAIN, ARTIFACT)
%   returns accepted/code/path/message with ordered diagnostics.

arguments
    domain (1, 1) string
    artifact
end

if ~isstruct(artifact)
    diagnostic = failDiagnostic("TYPE_MISMATCH", "artifact", "Artifact envelope must be a struct.");
    return
end
if ~isfield(artifact, "schemaVersion")
    diagnostic = failDiagnostic("MISSING_FIELD", "schemaVersion", "Schema version is required.");
    return
end
if string(artifact.schemaVersion) ~= "1.0.0-draft.2"
    diagnostic = failDiagnostic("VERSION_MISMATCH", "schemaVersion", ...
        "Only schema 1.0.0-draft.2 is accepted.");
    return
end
switch domain
    case "schedule"
        diagnostic = validateSchedule(artifact);
    case "ddc"
        diagnostic = validateDdc(artifact);
    case "beam"
        diagnostic = validateBeam(artifact);
    case "fusion"
        diagnostic = validateFusion(artifact);
    case "clustering"
        diagnostic = validateClustering(artifact);
    otherwise
        diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "domain", "Unknown artifact domain.");
end
end

function diagnostic = validateSchedule(artifact)
required = ["recordCount", "prfsHz", "priSampleCounts", "usableCounts", ...
    "transitionGapTicks", "totalTicks", "capTicks", "midpointOffsetTicks", "records"];
diagnostic = requireFields(artifact, required);
if ~diagnostic.accepted
    return
end
if numel(artifact.prfsHz) ~= 5 || numel(artifact.priSampleCounts) ~= 5 || ...
        numel(artifact.usableCounts) ~= 5
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "usableCounts", ...
        "Schedule arrays must have five entries.");
    return
end
expectedPrfs = [1700, 1900, 2150, 2450, 2700];
expectedPri = [88236, 78948, 69768, 61224, 55560];
expectedUsable = [22, 25, 28, 32, 35];
if ~isequal(double(artifact.prfsHz(:).'), expectedPrfs) || ...
        ~isequal(double(artifact.priSampleCounts(:).'), expectedPri) || ...
        ~isequal(double(artifact.usableCounts(:).'), expectedUsable)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "usableCounts", ...
        "Schedule arrays differ from the frozen five-PRF grammar.");
    return
end
if artifact.recordCount ~= 151 || numel(artifact.records) ~= 151 || ...
        artifact.transitionGapTicks ~= 106872 || artifact.totalTicks ~= 10553388 || ...
        artifact.midpointOffsetTicks ~= 5276694 || artifact.capTicks ~= 10597950
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", "records", ...
        "Schedule totals differ from the frozen tick contract.");
    return
end
roles = string({artifact.records.role});
invalidRole = find(~ismember(roles, ["priming", "usable", "transition"]), 1);
if ~isempty(invalidRole)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", ...
        "records[" + string(invalidRole - 1) + "].role", "Unknown schedule role.");
    return
end
if sum(roles == "priming") ~= 5 || sum(roles == "usable") ~= 142 || ...
        sum(roles == "transition") ~= 4
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "records", ...
        "Schedule role counts do not match the frozen group grammar.");
    return
end
currentTick = uint64(0);
recordIndex = 0;
for groupIndex = 1:5
    recordIndex = recordIndex + 1;
    diagnostic = validateScheduleRecord(artifact.records(recordIndex), recordIndex - 1, ...
        "priming", groupIndex, currentTick, uint64(expectedPri(groupIndex)));
    if ~diagnostic.accepted, return, end
    currentTick = artifact.records(recordIndex).endTick;
    for usableIndex = 1:expectedUsable(groupIndex)
        recordIndex = recordIndex + 1;
        diagnostic = validateScheduleRecord(artifact.records(recordIndex), recordIndex - 1, ...
            "usable", groupIndex, currentTick, uint64(expectedPri(groupIndex)));
        if ~diagnostic.accepted, return, end
        currentTick = artifact.records(recordIndex).endTick;
    end
    if groupIndex < 5
        recordIndex = recordIndex + 1;
        diagnostic = validateScheduleRecord(artifact.records(recordIndex), recordIndex - 1, ...
            "transition", groupIndex + 1, currentTick, uint64(106872));
        if ~diagnostic.accepted, return, end
        currentTick = artifact.records(recordIndex).endTick;
    end
end
if currentTick ~= uint64(10553388)
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", "records", ...
        "Schedule record enumeration does not reach the final tick.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = validateDdc(artifact)
required = ["adcRateHz", "intermediateRateHz", "outputRateHz", ...
    "decimationFactors", "stage1Numerator", "stage2Numerator", ...
    "kaiserBeta", "stage1Order", "stage2Order", "stage1CutoffHz", ...
    "stage2CutoffHz", "passbandHz", "stopbandStartHz", "metricToleranceDb"];
diagnostic = requireFields(artifact, required);
if ~diagnostic.accepted
    return
end
if artifact.adcRateHz ~= 150e6 || artifact.intermediateRateHz ~= 50e6 || ...
        artifact.outputRateHz ~= 12.5e6 || ~isequal(artifact.decimationFactors, [3, 4])
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "decimationFactors", ...
        "DDC rates and decimation factors are not frozen.");
elseif ~isvector(artifact.stage1Numerator) || numel(artifact.stage1Numerator) ~= 25 || ...
        ~isvector(artifact.stage2Numerator) || numel(artifact.stage2Numerator) ~= 241
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "stage2Numerator", ...
        "DDC coefficients must have 25 and 241 taps.");
elseif any(~isfinite(artifact.stage1Numerator(:))) || any(~isfinite(artifact.stage2Numerator(:)))
    diagnostic = failDiagnostic("NONFINITE", "stage2Numerator[0]", ...
        "DDC coefficients must be finite.");
elseif artifact.kaiserBeta ~= 8.6 || artifact.stage1Order ~= 24 || ...
        artifact.stage2Order ~= 240 || artifact.stage1CutoffHz ~= 25e6 || ...
        artifact.stage2CutoffHz ~= 5.625e6
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "stage2Numerator", ...
        "DDC FIR design parameters are not frozen.");
else
    expectedStage1 = fir1(24, 25e6 / (150e6 / 2), kaiser(25, 8.6));
    expectedStage2 = fir1(240, 5.625e6 / (50e6 / 2), kaiser(241, 8.6));
    if max(abs(artifact.stage1Numerator(:) - expectedStage1(:))) > 5e-15 || ...
            max(abs(artifact.stage2Numerator(:) - expectedStage2(:))) > 5e-15
        diagnostic = failDiagnostic("DDC_COEFFICIENT_MISMATCH", "stage1Numerator", ...
            "DDC coefficients do not match the frozen FIR identities.");
    elseif max(abs(artifact.stage1Numerator(:) - flipud(artifact.stage1Numerator(:)))) > 1e-13 || ...
            max(abs(artifact.stage2Numerator(:) - flipud(artifact.stage2Numerator(:)))) > 1e-13 || ...
            abs(sum(artifact.stage1Numerator(:)) - 1) > 1e-13 || ...
            abs(sum(artifact.stage2Numerator(:)) - 1) > 1e-13
        diagnostic = failDiagnostic("DDC_COEFFICIENT_SYMMETRY", "stage1Numerator", ...
            "DDC FIR symmetry or DC normalization is outside tolerance.");
    elseif artifact.stopbandStartHz > 6.25e6
        diagnostic = failDiagnostic("DDC_STOPBAND_EDGE", "stopbandStartHz", ...
            "Stage two stopband starts later than 6.25 MHz.");
    else
        metrics = radardemo.ddc.measureResponse(artifact, struct());
        if metrics.passbandRippleDb > 0.1 + artifact.metricToleranceDb
            diagnostic = failDiagnostic("DDC_RIPPLE_EXCEEDED", "stage2Numerator", ...
                "Recomputed passband ripple exceeds 0.1 dB.");
        elseif metrics.stage2AliasRejectionDb < 60 - artifact.metricToleranceDb || ...
                metrics.digitalAliasRejectionDb < 60 - artifact.metricToleranceDb
            diagnostic = failDiagnostic("DDC_ALIAS_REJECTION", "stage2Numerator", ...
                "Recomputed DDC alias rejection is below 60 dB.");
        elseif ~metrics.accepted
            diagnostic = failDiagnostic("DDC_PRINCIPAL_RESPONSE", "stage1Numerator", ...
                "Recomputed principal cascade response is invalid.");
        else
            diagnostic = passDiagnostic();
        end
    end
end
end

function diagnostic = validateScheduleRecord(record, pathIndex, expectedRole, expectedPrf, expectedStart, expectedDuration)
required = ["role", "prfIndex", "startTick", "endTick", "durationTicks", ...
    "sampleCount", "pulseSampleCount", "isTransition"];
diagnostic = requireFields(record, required);
if ~diagnostic.accepted, return, end
path = "records[" + string(pathIndex) + "]";
if string(record.role) ~= expectedRole || record.prfIndex ~= expectedPrf
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", path + ".role", ...
        "Schedule role or PRF index violates the frozen grammar.");
elseif record.startTick ~= expectedStart || record.endTick ~= record.startTick + expectedDuration || ...
        record.durationTicks ~= expectedDuration
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", path + ".startTick", ...
        "Schedule interval is not contiguous and half-open.");
elseif record.sampleCount ~= expectedDuration || record.pulseSampleCount ~= expectedDuration || ...
        logical(record.isTransition) ~= (expectedRole == "transition")
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", path + ".sampleCount", ...
        "Schedule sample counts or transition flag violate the role contract.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = validateBeam(artifact)
if ~isfield(artifact, "input") || size(artifact.input, 2) ~= 64
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "input", "Beam input must have 64 channels.");
elseif any(~isfinite(artifact.input(:)))
    diagnostic = failDiagnostic("NONFINITE", "input", "Beam input must be finite.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = validateFusion(artifact)
required = ["validityMask", "supportMask", "passMask"];
diagnostic = requireFields(artifact, required);
if ~diagnostic.accepted
    return
end
if any([numel(artifact.validityMask), numel(artifact.supportMask), numel(artifact.passMask)] ~= 5)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "passMask", ...
        "Fusion masks must have length five.");
elseif any(artifact.supportMask & ~artifact.validityMask)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "supportMask", ...
        "Support must be a subset of validity.");
end
end

function diagnostic = validateClustering(artifact)
if ~isfield(artifact, "hypotheses") || ~isfield(artifact, "clusters")
    diagnostic = failDiagnostic("MISSING_FIELD", "clusters", ...
        "Clustering aggregate fields are required.");
else
    diagnostic = passDiagnostic();
end
end

function diagnostic = requireFields(artifact, fields)
diagnostic = passDiagnostic();
for index = 1:numel(fields)
    if ~isfield(artifact, fields(index))
        diagnostic = failDiagnostic("MISSING_FIELD", fields(index), "Required field is missing.");
        return
    end
end
end

function diagnostic = passDiagnostic()
diagnostic = struct("accepted", true, "code", "", "path", "", "message", "");
end

function diagnostic = failDiagnostic(code, path, message)
diagnostic = struct("accepted", false, "code", code, "path", path, "message", message);
end
