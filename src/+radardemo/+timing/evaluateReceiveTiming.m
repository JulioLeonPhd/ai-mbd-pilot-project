function timing = evaluateReceiveTiming(schedule, design, spec)
%EVALUATERECEIVETIMING Derive delay, priming, and guarded timing margins.
%   TIMING = RADARDEMO.TIMING.EVALUATERECEIVETIMING(SCHEDULE, DESIGN, SPEC)
%   derives the compensated output lattice and verifies every usable pulse.
arguments
    schedule struct
    design struct
    spec struct = struct()
end
if isfield(spec, "nearRangeMarginTicks")
    error("radardemo:timing:ExpectedMarginUnsupported", ...
        "Expected timing margins cannot be supplied by the caller.");
end
requiredDesign = ["decimationFactors", "stage1Numerator", "stage2Numerator", "adcRateHz"];
if any(~isfield(design, requiredDesign))
    error("radardemo:timing:DesignFields", "The DDC design lacks required timing inputs.");
end
factors = double(design.decimationFactors(:).');
stage1 = design.stage1Numerator(:);
stage2 = design.stage2Numerator(:);
if ~isequal(factors, [3, 4]) || numel(stage1) ~= 25 || numel(stage2) ~= 241 || ...
        any(~isfinite(stage1)) || any(~isfinite(stage2)) || ...
        max(abs(stage1 - flipud(stage1))) > 1e-13 || ...
        max(abs(stage2 - flipud(stage2))) > 1e-13
    error("radardemo:timing:DesignShape", ...
        "Timing requires symmetric 25- and 241-tap FIR stages with factors [3 4].");
end
adcRateHz = fieldOr(spec, "adcRateHz", double(design.adcRateHz));
speedOfLightMps = fieldOr(spec, "speedOfLightMps", 299792458);
nominalRangeM = fieldOr(spec, "nominalRangeM", 6800);
radialSpeedBoundMps = fieldOr(spec, "radialSpeedBoundMps", 800 / 3.6);
transmitBlankingTicks = fieldOr(spec, "transmitBlankingTicks", 6000);
guardTicks = fieldOr(spec, "guardTicks", 750);
if any(~isfinite([adcRateHz, speedOfLightMps, nominalRangeM, ...
        radialSpeedBoundMps, transmitBlankingTicks, guardTicks])) || ...
        adcRateHz ~= double(design.adcRateHz) || speedOfLightMps <= 0 || ...
        adcRateHz <= 0 || nominalRangeM <= 0 || radialSpeedBoundMps < 0 || ...
        transmitBlankingTicks < 0 || guardTicks < 0
    error("radardemo:timing:PhysicalInputs", ...
        "Timing physical inputs must be finite and within their supported ranges.");
end
requiredSchedule = ["totalTicks", "midpointOffsetTicks", "recordCount", "records"];
if any(~isfield(schedule, requiredSchedule))
    error("radardemo:timing:ScheduleFields", "The receive schedule lacks required timing inputs.");
end
delayTicks = (numel(stage1) - 1) / 2 + factors(1) * (numel(stage2) - 1) / 2;
historySpanTicks = numel(stage1) - 1 + factors(1) * (numel(stage2) - 1);
decimation = prod(factors);
totalTicks = double(schedule.totalTicks);
midpointOffsetTicks = double(schedule.midpointOffsetTicks);
if totalTicks <= 0 || midpointOffsetTicks < 0 || midpointOffsetTicks > totalTicks
    error("radardemo:timing:ScheduleRange", "The schedule midpoint is outside its scan.");
end
nominalRoundTripTicks = 2 * nominalRangeM * adcRateHz / speedOfLightMps;
nominalRawMarginTicks = floor(nominalRoundTripTicks) - transmitBlankingTicks - guardTicks;
motionElapsedSeconds = max(midpointOffsetTicks, totalTicks - midpointOffsetTicks) / adcRateHz;
minimumRangeM = nominalRangeM - radialSpeedBoundMps * motionElapsedSeconds;
motionRoundTripTicks = 2 * minimumRangeM * adcRateHz / speedOfLightMps;
motionBoundRawMarginTicks = floor(motionRoundTripTicks) - transmitBlankingTicks - guardTicks;
scheduleValid = validateSchedule(schedule);
records = schedule.records;
primingIndices = find(string({records.role}) == "priming");
usableIndices = find(string({records.role}) == "usable");
primingDurationsTicks = zeros(numel(primingIndices), 1, "uint64");
for index = 1:numel(primingIndices)
    primingDurationsTicks(index) = uint64(records(primingIndices(index)).durationTicks);
end
primingVerified = scheduleValid && numel(primingIndices) == 5 && ...
    numel(usableIndices) == 142 && all(double(primingDurationsTicks) > historySpanTicks);
usableRecordEvidence = repmat(struct("recordIndex", 0, "startTick", uint64(0), ...
    "rawGateTick", uint64(0), "compensatedGateTick", int64(0), ...
    "earliestInputTick", int64(0), "previousOutputCompensatedTick", int64(0), ...
    "motionBoundAlignedMarginTicks", int64(0), "minimalGate", false, ...
    "guardSupported", false), numel(usableIndices), 1);
for index = 1:numel(usableIndices)
    recordIndex = usableIndices(index);
    startTick = double(records(recordIndex).startTick);
    rawGateTick = decimation * ceil((startTick + transmitBlankingTicks + ...
        guardTicks + delayTicks) / decimation);
    compensatedGateTick = rawGateTick - delayTicks;
    earliestInputTick = rawGateTick - historySpanTicks;
    previousOutputCompensatedTick = rawGateTick - decimation - delayTicks;
    alignedMarginTicks = floor(motionRoundTripTicks) - (compensatedGateTick - startTick);
    minimalGate = previousOutputCompensatedTick < startTick + transmitBlankingTicks + guardTicks;
    guardSupported = earliestInputTick > startTick + transmitBlankingTicks;
    usableRecordEvidence(index) = struct( ...
        "recordIndex", recordIndex - 1, "startTick", uint64(startTick), ...
        "rawGateTick", uint64(rawGateTick), ...
        "compensatedGateTick", int64(compensatedGateTick), ...
        "earliestInputTick", int64(earliestInputTick), ...
        "previousOutputCompensatedTick", int64(previousOutputCompensatedTick), ...
        "motionBoundAlignedMarginTicks", int64(alignedMarginTicks), ...
        "minimalGate", minimalGate, "guardSupported", guardSupported);
end
if isempty(usableRecordEvidence)
    motionBoundAlignedMarginTicks = int64(-inf);
    gatesValid = false;
else
    alignedMargins = [usableRecordEvidence.motionBoundAlignedMarginTicks];
    motionBoundAlignedMarginTicks = min(alignedMargins);
    gatesValid = all([usableRecordEvidence.minimalGate]) && ...
        all([usableRecordEvidence.guardSupported]) && all(alignedMargins > 0);
end
timing = struct();
timing.decimationFactors = factors;
timing.delayTicks = uint64(delayTicks);
timing.delayOutputSamples = uint64(delayTicks / decimation);
timing.historySpanTicks = uint64(historySpanTicks);
timing.primingRequired = true;
timing.primingVerified = primingVerified;
timing.primingRecordIndices = primingIndices - 1;
timing.primingDurationsTicks = primingDurationsTicks;
timing.usableRecordEvidence = usableRecordEvidence;
timing.nominalRawMarginTicks = int64(nominalRawMarginTicks);
timing.motionBoundRawMarginTicks = int64(motionBoundRawMarginTicks);
timing.motionBoundAlignedMarginTicks = motionBoundAlignedMarginTicks;
timing.nearRangeMarginTicks = timing.nominalRawMarginTicks;
timing.finalPhaseModuloTicks = mod(delayTicks, decimation);
timing.scheduleRecordCount = schedule.recordCount;
timing.scanMidpointOffsetTicks = schedule.midpointOffsetTicks;
timing.motionElapsedSeconds = motionElapsedSeconds;
timing.minimumRangeM = minimumRangeM;
timing.nominalRoundTripTicks = nominalRoundTripTicks;
timing.motionRoundTripTicks = motionRoundTripTicks;
timing.adcRateHz = adcRateHz;
timing.speedOfLightMps = speedOfLightMps;
timing.nominalRangeM = nominalRangeM;
timing.radialSpeedBoundMps = radialSpeedBoundMps;
timing.transmitBlankingTicks = uint64(transmitBlankingTicks);
timing.guardTicks = uint64(guardTicks);
timing.accepted = scheduleValid && primingVerified && gatesValid && ...
    timing.finalPhaseModuloTicks == 0;
end

function value = fieldOr(data, name, fallback)
if isfield(data, name)
    value = double(data.(name));
else
    value = fallback;
end
end

function valid = validateSchedule(schedule)
valid = false;
required = ["recordCount", "prfsHz", "priSampleCounts", "usableCounts", ...
    "transitionGapTicks", "totalTicks", "midpointOffsetTicks", "capTicks", "records"];
if any(~isfield(schedule, required))
    return
end
expectedPrfs = [1700, 1900, 2150, 2450, 2700];
expectedPri = [88236, 78948, 69768, 61224, 55560];
expectedUsable = [22, 25, 28, 32, 35];
if ~isequal(double(schedule.prfsHz(:).'), expectedPrfs) || ...
        ~isequal(double(schedule.priSampleCounts(:).'), expectedPri) || ...
        ~isequal(double(schedule.usableCounts(:).'), expectedUsable) || ...
        double(schedule.recordCount) ~= 151 || numel(schedule.records) ~= 151 || ...
        double(schedule.totalTicks) ~= 10553388 || ...
        double(schedule.midpointOffsetTicks) ~= 5276694 || ...
        double(schedule.capTicks) ~= 10597950 || ...
        double(schedule.transitionGapTicks) ~= 106872
    return
end
currentTick = 0;
recordIndex = 0;
for groupIndex = 1:5
    recordIndex = recordIndex + 1;
    if ~validRecord(schedule.records(recordIndex), "priming", groupIndex, ...
            currentTick, expectedPri(groupIndex), false)
        return
    end
    currentTick = double(schedule.records(recordIndex).endTick);
    for usableIndex = 1:expectedUsable(groupIndex)
        recordIndex = recordIndex + 1;
        if ~validRecord(schedule.records(recordIndex), "usable", groupIndex, ...
                currentTick, expectedPri(groupIndex), false)
            return
        end
        currentTick = double(schedule.records(recordIndex).endTick);
    end
    if groupIndex < 5
        recordIndex = recordIndex + 1;
        if ~validRecord(schedule.records(recordIndex), "transition", groupIndex + 1, ...
                currentTick, 106872, true)
            return
        end
        currentTick = double(schedule.records(recordIndex).endTick);
    end
end
valid = recordIndex == 151 && currentTick == 10553388;
end

function valid = validRecord(record, role, prfIndex, startTick, duration, isTransition)
required = ["role", "prfIndex", "startTick", "endTick", "durationTicks", ...
    "sampleCount", "pulseSampleCount", "isTransition"];
valid = all(isfield(record, required)) && string(record.role) == role && ...
    double(record.prfIndex) == prfIndex && double(record.startTick) == startTick && ...
    double(record.endTick) == startTick + duration && double(record.durationTicks) == duration && ...
    double(record.sampleCount) == duration && double(record.pulseSampleCount) == duration && ...
    logical(record.isTransition) == isTransition;
end
