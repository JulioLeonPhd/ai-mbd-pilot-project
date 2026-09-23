function diagnostic = checkTiming(data)
%CHECKTIMING Independently reconstruct delay, priming, and gated pulse timing.
diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["decimationFactors", "delayTicks", "delayOutputSamples", ...
    "historySpanTicks", "primingRequired", "primingVerified", ...
    "primingRecordIndices", "primingDurationsTicks", "usableRecordEvidence", ...
    "nominalRawMarginTicks", "motionBoundRawMarginTicks", ...
    "motionBoundAlignedMarginTicks", "nearRangeMarginTicks", ...
    "finalPhaseModuloTicks", "scheduleRecordCount", "scanMidpointOffsetTicks", ...
    "schedule", "timingDesign", "timingSpec"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
scheduleDiagnostic = wp4oracle.checkSchedule(data.schedule);
if ~scheduleDiagnostic.accepted
    diagnostic = scheduleDiagnostic;
    return
end
design = data.timingDesign;
designRequired = ["decimationFactors", "stage1Numerator", "stage2Numerator", "adcRateHz"];
if ~isstruct(design) || any(~isfield(design, designRequired))
    diagnostic = failDiagnostic("MISSING_FIELD", "timingDesign", ...
        "Timing design coefficients, factors, and sample rate are required.");
    return
end
factors = double(design.decimationFactors(:).');
stage1 = double(design.stage1Numerator(:));
stage2 = double(design.stage2Numerator(:));
if ~isequal(factors, [3, 4]) || numel(stage1) ~= 25 || numel(stage2) ~= 241
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "timingDesign.stage2Numerator", ...
        "Timing oracle requires 25- and 241-tap stages with factors [3 4].");
    return
end
if any(~isfinite(stage1)) || any(~isfinite(stage2)) || ...
        max(abs(stage1 - flipud(stage1))) > 1e-13 || ...
        max(abs(stage2 - flipud(stage2))) > 1e-13
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "timingDesign.stage1Numerator", ...
        "Timing coefficients must be finite and symmetric.");
    return
end
spec = data.timingSpec;
specRequired = ["adcRateHz", "speedOfLightMps", "nominalRangeM", ...
    "radialSpeedBoundMps", "transmitBlankingTicks", "guardTicks"];
if ~isstruct(spec) || any(~isfield(spec, specRequired))
    diagnostic = failDiagnostic("MISSING_FIELD", "timingSpec", ...
        "Frozen physical timing inputs are required.");
    return
end
rate = double(spec.adcRateHz);
c = double(spec.speedOfLightMps);
rangeM = double(spec.nominalRangeM);
speed = double(spec.radialSpeedBoundMps);
blanking = double(spec.transmitBlankingTicks);
guard = double(spec.guardTicks);
if any(~isfinite([rate, c, rangeM, speed, blanking, guard])) || ...
        rate ~= double(design.adcRateHz) || rate <= 0 || c <= 0 || ...
        rangeM <= 0 || speed < 0 || blanking < 0 || guard < 0
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "timingSpec", ...
        "Timing physical inputs are outside their valid range.");
    return
end
stage1GroupDelay = (length(stage1) - 1) / 2;
stage2GroupDelay = (length(stage2) - 1) / 2;
derivedDelay = stage1GroupDelay + factors(1) * stage2GroupDelay;
derivedHistory = (length(stage1) - 1) + factors(1) * (length(stage2) - 1);
lattice = prod(factors);
schedule = data.schedule;
scanLength = double(schedule.totalTicks);
midpoint = double(schedule.midpointOffsetTicks);
nominalArrival = 2 * rangeM * rate / c;
nominalMargin = floor(nominalArrival) - blanking - guard;
worstElapsed = max(midpoint, scanLength - midpoint) / rate;
worstRange = rangeM - speed * worstElapsed;
motionArrival = 2 * worstRange * rate / c;
motionMargin = floor(motionArrival) - blanking - guard;
records = schedule.records;
primerIndices = find(string({records.role}) == "priming");
pulseIndices = find(string({records.role}) == "usable");
primerDurations = uint64([records(primerIndices).durationTicks]).';
primerValid = numel(primerIndices) == 5 && numel(pulseIndices) == 142 && ...
    all(double(primerDurations) > derivedHistory);
recordEvidence = repmat(struct("recordIndex", 0, "startTick", uint64(0), ...
    "rawGateTick", uint64(0), "compensatedGateTick", int64(0), ...
    "earliestInputTick", int64(0), "previousOutputCompensatedTick", int64(0), ...
    "motionBoundAlignedMarginTicks", int64(0), "minimalGate", false, ...
    "guardSupported", false), numel(pulseIndices), 1);
for index = 1:numel(pulseIndices)
    rowIndex = pulseIndices(index);
    pulseStart = double(records(rowIndex).startTick);
    candidate = lattice * ceil((pulseStart + blanking + guard + derivedDelay) / lattice);
    compensated = candidate - derivedDelay;
    previous = candidate - lattice - derivedDelay;
    earliest = candidate - derivedHistory;
    alignedMargin = floor(motionArrival) - (compensated - pulseStart);
    recordEvidence(index) = struct("recordIndex", rowIndex - 1, ...
        "startTick", uint64(pulseStart), "rawGateTick", uint64(candidate), ...
        "compensatedGateTick", int64(compensated), "earliestInputTick", int64(earliest), ...
        "previousOutputCompensatedTick", int64(previous), ...
        "motionBoundAlignedMarginTicks", int64(alignedMargin), ...
        "minimalGate", previous < pulseStart + blanking + guard, ...
        "guardSupported", earliest > pulseStart + blanking);
end
alignedMargins = [recordEvidence.motionBoundAlignedMarginTicks];
alignedMargin = min(alignedMargins);
if ~isequal(double(data.decimationFactors(:).'), factors) || ...
        double(data.delayTicks) ~= derivedDelay || ...
        double(data.delayOutputSamples) ~= derivedDelay / lattice || ...
        double(data.historySpanTicks) ~= derivedHistory || ...
        ~logical(data.primingRequired) || ~logical(data.primingVerified) || ~primerValid
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", "delayTicks", ...
        "Stored delay or priming evidence differs from independently derived timing.");
    return
end
if ~isequal(double(data.primingRecordIndices(:).'), double(primerIndices - 1)) || ...
        ~isequal(uint64(data.primingDurationsTicks(:)), primerDurations)
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", "primingRecordIndices", ...
        "Priming records or durations do not match the frozen schedule.");
    return
end
if ~isequaln(data.usableRecordEvidence, recordEvidence)
    diagnostic = failDiagnostic("TICK_DISCONTINUITY", "usableRecordEvidence", ...
        "A pulse gate, guard, lattice minimum, or compensated tick is incorrect.");
    return
end
if int64(data.nominalRawMarginTicks) ~= int64(nominalMargin) || ...
        int64(data.motionBoundRawMarginTicks) ~= int64(motionMargin) || ...
        int64(data.motionBoundAlignedMarginTicks) ~= int64(alignedMargin) || ...
        int64(data.nearRangeMarginTicks) ~= int64(nominalMargin) || ...
        data.finalPhaseModuloTicks ~= mod(derivedDelay, lattice) || ...
        double(data.scheduleRecordCount) ~= double(schedule.recordCount) || ...
        double(data.scanMidpointOffsetTicks) ~= midpoint || ...
        any(~[recordEvidence.minimalGate]) || any(~[recordEvidence.guardSupported]) || ...
        any(alignedMargins <= 0) || ~logical(data.accepted)
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "motionBoundAlignedMarginTicks", ...
        "Derived raw/aligned margins or accepted timing status are inconsistent.");
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
        diagnostic = failDiagnostic("MISSING_FIELD", fields(index), ...
            "A required timing evidence field is missing.");
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
