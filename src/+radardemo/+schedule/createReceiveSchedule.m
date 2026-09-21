function schedule = createReceiveSchedule(spec)
%CREATERECEIVESCHEDULE Create the frozen five-PRF receive schedule.
%   SCHEDULE = RADARDEMO.SCHEDULE.CREATERECEIVESCHEDULE(SPEC) creates
%   half-open integer-tick receive intervals from a schedule specification.
%   The ADC tick rate is 150 MHz and all schedule arithmetic uses uint64.

arguments
    spec struct = struct()
end

spec = applyDefaults(spec);
prfCount = numel(spec.prfsHz);
recordCount = sum(spec.usableCounts + 1) + prfCount - 1;
template = struct("role", "", "prfIndex", 0, "startTick", uint64(0), ...
    "endTick", uint64(0), "durationTicks", uint64(0), "sampleCount", uint64(0), ...
    "pulseSampleCount", uint64(0), "isTransition", false);
records = repmat(template, recordCount, 1);
currentTick = uint64(0);
recordIndex = 0;
for prfIndex = 1:prfCount
    roles = ["priming", repmat("usable", 1, spec.usableCounts(prfIndex))];
    for roleIndex = 1:numel(roles)
        recordIndex = recordIndex + 1;
        duration = uint64(spec.priSampleCounts(prfIndex));
        records(recordIndex) = makeRecord(roles(roleIndex), prfIndex, currentTick, duration, duration, false);
        currentTick = currentTick + duration;
    end
    if prfIndex < prfCount
        recordIndex = recordIndex + 1;
        duration = uint64(spec.transitionGapTicks);
        records(recordIndex) = makeRecord("transition", prfIndex + 1, currentTick, duration, duration, true);
        currentTick = currentTick + duration;
    end
end
schedule = struct();
schedule.schemaName = "radar.wp4.schedule";
schedule.schemaVersion = "1.0.0-draft.2";
schedule.recordCount = recordCount;
schedule.prfsHz = spec.prfsHz;
schedule.priSampleCounts = spec.priSampleCounts;
schedule.usableCounts = spec.usableCounts;
schedule.transitionGapTicks = spec.transitionGapTicks;
schedule.totalTicks = currentTick;
schedule.capTicks = uint64(10597950);
schedule.midpointOffsetTicks = uint64(5276694);
schedule.records = records;
end

function spec = applyDefaults(spec)
defaults = struct("prfsHz", [1700, 1900, 2150, 2450, 2700], ...
    "priSampleCounts", [88236, 78948, 69768, 61224, 55560], ...
    "usableCounts", [22, 25, 28, 32, 35], "transitionGapTicks", 106872);
names = fieldnames(defaults);
for index = 1:numel(names)
    if ~isfield(spec, names{index})
        spec.(names{index}) = defaults.(names{index});
    end
end
end

function record = makeRecord(role, prfIndex, startTick, duration, sampleCount, isTransition)
record = struct("role", char(role), "prfIndex", prfIndex, ...
    "startTick", startTick, "endTick", startTick + duration, ...
    "durationTicks", duration, "sampleCount", uint64(sampleCount), ...
    "pulseSampleCount", uint64(sampleCount), "isTransition", isTransition);
end
