function [draft2, diagnostic] = adaptWp4Draft1(domain, draft1, context)
%ADAPTWP4DRAFT1 Explicitly migrate derivable draft.1 data to draft.2.
%   Migration never invents missing numerical or provenance values. Every
%   compatibility field is derived from DRAFT1 or explicitly supplied CONTEXT.

arguments
    domain (1, 1) string
    draft1 struct
    context struct = struct()
end

draft2 = draft1;
if ~isfield(draft1, "schemaVersion") || string(draft1.schemaVersion) ~= "1.0.0-draft.1"
    diagnostic = result(false, "VERSION_MISMATCH", "schemaVersion", ...
        "The adapter accepts only draft.1 input.");
    return
end
switch domain
    case "schedule"
        [draft2, diagnostic] = migrateSchedule(draft1, context);
    case "ddc"
        [draft2, diagnostic] = migrateDdc(draft1, context);
    case "fusion"
        [draft2, diagnostic] = migrateFusion(draft1);
    case "clustering"
        [draft2, diagnostic] = migrateClustering(draft1, context);
    otherwise
        diagnostic = result(false, "VALUE_OUT_OF_RANGE", "domain", "Unknown migration domain.");
end
end

function [output, diagnostic] = migrateSchedule(input, context)
output = input;
required = ["records", "priSampleCounts", "transitionGapTicks"];
for index = 1:numel(required)
    if ~isfield(input, required(index)) && ~isfield(context, required(index))
        diagnostic = result(false, "MISSING_FIELD", "context." + required(index), ...
            "Schedule migration context is required.");
        return
    end
end
if isfield(context, "priSampleCounts")
    pri = context.priSampleCounts;
else
    pri = input.priSampleCounts;
end
if isfield(context, "transitionGapTicks")
    transitionGap = context.transitionGapTicks;
else
    transitionGap = input.transitionGapTicks;
end
if numel(pri) ~= 5 || isempty(input.records)
    diagnostic = result(false, "DIMENSION_MISMATCH", "context.priSampleCounts", ...
        "Five configured PRI counts and records are required.");
    return
end
for index = 1:numel(input.records)
    record = input.records(index);
    if ~isfield(record, "prfIndex") || record.prfIndex < 1 || record.prfIndex > 5
        diagnostic = result(false, "VALUE_OUT_OF_RANGE", ...
            "records[" + string(index - 1) + "].prfIndex", "PRF index is not derivable.");
        return
    end
    isTransition = isfield(record, "isTransition") && logical(record.isTransition);
    if isTransition
        duration = uint64(transitionGap);
        role = "transition";
    else
        duration = uint64(pri(record.prfIndex));
        previousPrf = record.prfIndex;
        if index > 1
            previousPrf = input.records(index - 1).prfIndex;
        end
        role = "usable";
        if index == 1 || previousPrf ~= record.prfIndex
            role = "priming";
        end
    end
    if ~isfield(record, "startTick") || ~isfield(record, "endTick")
        diagnostic = result(false, "MISSING_FIELD", ...
            "records[" + string(index - 1) + "].startTick", "Record ticks are required.");
        return
    end
    output.records(index).role = char(role);
    output.records(index).durationTicks = duration;
    output.records(index).endTick = uint64(record.startTick) + duration;
    output.records(index).isTransition = strcmp(role, "transition");
    if isTransition
        output.records(index).sampleCount = duration;
        output.records(index).pulseSampleCount = duration;
    end
end
output.schemaVersion = "1.0.0-draft.2";
output.migrationSeed = 401061;
diagnostic = result(true, "", "", "Schedule migrated with explicit PRI and transition context.");
end

function [output, diagnostic] = migrateDdc(input, context)
output = input;
if ~isfield(context, "design")
    diagnostic = result(false, "MISSING_FIELD", "context.design", ...
        "DDC migration requires explicit coefficient context.");
    return
end
design = context.design;
required = ["stage1Numerator", "stage2Numerator", "adcRateHz", ...
    "intermediateRateHz", "outputRateHz", "decimationFactors", ...
    "passbandHz", "stopbandStartHz", "metricToleranceDb", "kaiserBeta", ...
    "stage1Order", "stage2Order", "stage1CutoffHz", "stage2CutoffHz"];
for index = 1:numel(required)
    if ~isfield(design, required(index))
        diagnostic = result(false, "MISSING_FIELD", "context.design." + required(index), ...
            "DDC migration context is incomplete.");
        return
    end
end
if ~isvector(design.stage1Numerator) || numel(design.stage1Numerator) ~= 25 || ...
        ~isvector(design.stage2Numerator) || numel(design.stage2Numerator) ~= 241 || ...
        any(~isfinite(design.stage1Numerator(:))) || any(~isfinite(design.stage2Numerator(:))) || ...
        ~isequal(design.decimationFactors, [3, 4])
    diagnostic = result(false, "VALUE_OUT_OF_RANGE", "context.design", ...
        "DDC migration requires finite complete two-stage coefficient context.");
    return
end
if design.adcRateHz ~= 150e6 || design.intermediateRateHz ~= 50e6 || ...
        design.outputRateHz ~= 12.5e6 || design.kaiserBeta ~= 8.6 || ...
        design.stage1Order ~= 24 || design.stage2Order ~= 240 || ...
        design.stage1CutoffHz ~= 25e6 || design.stage2CutoffHz ~= 5.625e6
    diagnostic = result(false, "VALUE_OUT_OF_RANGE", "context.design", ...
        "DDC migration context rates, orders, cutoffs, or Kaiser beta are not frozen.");
    return
end
if design.stopbandStartHz > 6.25e6
    diagnostic = result(false, "DDC_STOPBAND_EDGE", "context.design.stopbandStartHz", ...
        "DDC migration stopband edge is later than the frozen limit.");
    return
end
metrics = radardemo.ddc.measureResponse(design, struct());
if ~metrics.accepted
    if metrics.passbandRippleDb > 0.1 + design.metricToleranceDb
        diagnostic = result(false, "DDC_RIPPLE_EXCEEDED", ...
            "context.design.stage2Numerator", "DDC migration passband ripple exceeds 0.1 dB.");
    elseif metrics.stage2AliasRejectionDb < 60 - design.metricToleranceDb || ...
            metrics.digitalAliasRejectionDb < 60 - design.metricToleranceDb
        diagnostic = result(false, "DDC_ALIAS_REJECTION", ...
            "context.design.stage2Numerator", "DDC migration alias rejection is below 60 dB.");
    else
        diagnostic = result(false, "DDC_PRINCIPAL_RESPONSE", ...
            "context.design.stage1Numerator", "DDC migration principal response is invalid.");
    end
    return
end
expectedStage1 = fir1(24, 25e6 / (150e6 / 2), kaiser(25, 8.6));
expectedStage2 = fir1(240, 5.625e6 / (50e6 / 2), kaiser(241, 8.6));
if max(abs(design.stage1Numerator(:) - expectedStage1(:))) > 5e-15
    diagnostic = result(false, "DDC_COEFFICIENT_MISMATCH", ...
        "context.design.stage1Numerator", "Stage-one coefficients are not the frozen FIR identity.");
    return
end
if max(abs(design.stage2Numerator(:) - expectedStage2(:))) > 5e-15
    diagnostic = result(false, "DDC_COEFFICIENT_MISMATCH", ...
        "context.design.stage2Numerator", "Stage-two coefficients are not the frozen FIR identity.");
    return
end
if max(abs(design.stage1Numerator(:) - flipud(design.stage1Numerator(:)))) > 1e-13 || ...
        max(abs(design.stage2Numerator(:) - flipud(design.stage2Numerator(:)))) > 1e-13 || ...
        abs(sum(design.stage1Numerator(:)) - 1) > 1e-13 || ...
        abs(sum(design.stage2Numerator(:)) - 1) > 1e-13
    diagnostic = result(false, "DDC_COEFFICIENT_SYMMETRY", "context.design.stage1Numerator", ...
        "DDC migration FIR symmetry or DC normalization is outside tolerance.");
    return
end
output.schemaVersion = "1.0.0-draft.2";
output.stage1Numerator = design.stage1Numerator;
output.stage2Numerator = design.stage2Numerator;
output.sampleRateHz = design.adcRateHz;
output.intermediateRateHz = design.intermediateRateHz;
output.outputRateHz = design.outputRateHz;
output.decimationFactors = design.decimationFactors;
output.passbandHz = design.passbandHz;
output.stopbandStartHz = design.stopbandStartHz;
output.metricToleranceDb = design.metricToleranceDb;
responseFields = ["frequencyHz", "stage1Response", "stage2Response", ...
    "stage1AliasBranches", "stage2AliasBranches", "cascadeAliasBranches", ...
    "cascadeBranchPairs", "passbandRippleDb", "stage2AliasRejectionDb", ...
    "digitalAliasRejectionDb", "gridResolutionHz", "metricToleranceDb", ...
    "principalCascadeResponse", "principalPassbandGain", "principalPassbandValid"];
for index = 1:numel(responseFields)
    fieldName = responseFields(index);
    if ~isfield(metrics, fieldName) || any(~isfinite(metrics.(fieldName)), "all")
        diagnostic = result(false, "VALUE_OUT_OF_RANGE", "context.design.response", ...
            "DDC migration response evidence is incomplete or nonfinite.");
        return
    end
    output.(fieldName) = metrics.(fieldName);
end
output.passbandRippleDb = metrics.passbandRippleDb;
output.digitalAliasRejectionDb = metrics.digitalAliasRejectionDb;
output.migrationSeed = 401061;
diagnostic = result(true, "", "", "DDC coefficients and response were recomputed from context.");
end

function [output, diagnostic] = migrateFusion(input)
output = input;
required = ["validityMask", "supportMask", "passMask"];
for index = 1:numel(required)
    if ~isfield(input, required(index))
        diagnostic = result(false, "MISSING_FIELD", required(index), ...
            "Fusion migration requires all legacy masks.");
        return
    end
end
output.schemaVersion = "1.0.0-draft.2";
output.voteThreshold = 3;
output.voteCount = sum(input.passMask);
validCount = sum(input.validityMask);
if validCount < 3
    output.outcome = "invalid";
elseif output.voteCount >= 3
    output.outcome = "pass";
else
    output.outcome = "fail";
end
output.migrationSeed = 401061;
diagnostic = result(true, "", "", "Fusion outcome was derived from legacy masks.");
end

function [output, diagnostic] = migrateClustering(input, context)
output = input;
if ~isfield(context, "commandedLooks")
    diagnostic = result(false, "MISSING_FIELD", "context.commandedLooks", ...
        "Explicit commanded-look provenance is required.");
    return
end
if numel(context.commandedLooks) ~= numel(input.hypotheses)
    diagnostic = result(false, "PROVENANCE_MISMATCH", "context.commandedLooks[1]", ...
        "Commanded-look mapping cardinality is ambiguous.");
    return
end
for index = 1:numel(input.hypotheses)
    hypothesis = input.hypotheses(index);
    look = context.commandedLooks(index);
    required = ["hypothesisId", "azimuthLookIndex", "elevationLookIndex", ...
        "clusterCell", "clusterEligible"];
    for fieldIndex = 1:numel(required)
        if ~isfield(look, required(fieldIndex))
            diagnostic = result(false, "MISSING_FIELD", ...
                "context.commandedLooks[" + string(index - 1) + "]." + required(fieldIndex), ...
                "Look provenance is incomplete.");
            return
        end
    end
    if string(look.hypothesisId) ~= string(hypothesis.hypothesisId)
        diagnostic = result(false, "PROVENANCE_MISMATCH", ...
            "context.commandedLooks[" + string(index) + "]", ...
            "Commanded-look identity is ambiguous.");
        return
    end
    output.hypotheses(index).clusterEligible = logical(look.clusterEligible);
    output.hypotheses(index).azimuthLookIndex = look.azimuthLookIndex;
    output.hypotheses(index).elevationLookIndex = look.elevationLookIndex;
    output.hypotheses(index).clusterCell = look.clusterCell;
    maskFields = ["validityMask", "supportMask", "passMask"];
    for maskIndex = 1:numel(maskFields)
        maskName = maskFields(maskIndex);
        if isfield(input.hypotheses(index), maskName)
            mask = input.hypotheses(index).(maskName);
        elseif isfield(look, maskName)
            mask = look.(maskName);
        else
            diagnostic = result(false, "MISSING_FIELD", ...
                "context.commandedLooks[" + string(index - 1) + "]." + maskName, ...
                "Clustering migration requires all derivable layer masks.");
            return
        end
        if numel(mask) ~= 5 || any(~isfinite(double(mask(:))))
            diagnostic = result(false, "DIMENSION_MISMATCH", ...
                "context.commandedLooks[" + string(index - 1) + "]." + maskName, ...
                "Clustering migration masks must have length five.");
            return
        end
        output.hypotheses(index).(maskName) = logical(mask(:).');
    end
    if any(output.hypotheses(index).supportMask & ...
            ~output.hypotheses(index).validityMask)
        diagnostic = result(false, "VALUE_OUT_OF_RANGE", ...
            "context.commandedLooks[" + string(index - 1) + "].supportMask", ...
            "Support mask must be a subset of validity mask.");
        return
    end
end
output.schemaVersion = "1.0.0-draft.2";
output.migrationSeed = 401061;
diagnostic = result(true, "", "", "Cluster provenance migrated explicitly.");
end

function output = result(accepted, code, path, message)
output = struct("accepted", accepted, "code", code, "path", path, "message", message);
end
