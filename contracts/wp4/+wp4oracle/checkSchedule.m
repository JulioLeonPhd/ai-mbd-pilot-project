function diagnostic = checkSchedule(data)
%CHECKSCHEDULE Independently enforce the frozen five-group tick grammar.

diagnostic = wp4oracle.checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["recordCount", "prfsHz", "priSampleCounts", "usableCounts", ...
    "transitionGapTicks", "totalTicks", "capTicks", "midpointOffsetTicks", "records"];
diagnostic = wp4oracle.requireFields(data, required);
if ~diagnostic.accepted
    return
end
expectedPrfs = [1700, 1900, 2150, 2450, 2700];
expectedPri = [88236, 78948, 69768, 61224, 55560];
expectedUsable = [22, 25, 28, 32, 35];
if numel(data.prfsHz) ~= 5 || numel(data.priSampleCounts) ~= 5 || ...
        numel(data.usableCounts) ~= 5
    diagnostic = wp4oracle.failDiagnostic("DIMENSION_MISMATCH", "usableCounts", ...
        "Schedule arrays must have five entries.");
    return
end
if ~isequal(double(data.prfsHz(:).'), expectedPrfs) || ...
        ~isequal(double(data.priSampleCounts(:).'), expectedPri) || ...
        ~isequal(double(data.usableCounts(:).'), expectedUsable)
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", "usableCounts", ...
        "Schedule PRFs, PRI counts, and usable counts differ from the frozen grammar.");
    return
end
if data.recordCount ~= 151 || numel(data.records) ~= 151 || ...
        data.transitionGapTicks ~= 106872 || data.totalTicks ~= 10553388 || ...
        data.midpointOffsetTicks ~= 5276694 || data.capTicks ~= 10597950
    diagnostic = wp4oracle.failDiagnostic("TICK_DISCONTINUITY", "records", ...
        "Schedule totals do not match the frozen integer-tick grammar.");
    return
end
records = data.records;
roles = string({records.role});
invalidRole = find(~ismember(roles, ["priming", "usable", "transition"]), 1);
if ~isempty(invalidRole)
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", ...
        "records[" + string(invalidRole - 1) + "].role", ...
        "Unknown schedule role.");
    return
end
if sum(roles == "priming") ~= 5 || sum(roles == "usable") ~= 142 || ...
        sum(roles == "transition") ~= 4
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", "records", ...
        "Schedule role counts do not match five priming, usable, and transition groups.");
    return
end
currentTick = uint64(0);
recordIndex = 0;
for groupIndex = 1:5
    recordIndex = recordIndex + 1;
    diagnostic = checkRecord(records(recordIndex), recordIndex - 1, "priming", groupIndex, currentTick, ...
        uint64(expectedPri(groupIndex)));
    if ~diagnostic.accepted
        return
    end
    currentTick = records(recordIndex).endTick;
    for usableIndex = 1:expectedUsable(groupIndex)
        recordIndex = recordIndex + 1;
        diagnostic = checkRecord(records(recordIndex), recordIndex - 1, "usable", groupIndex, currentTick, ...
            uint64(expectedPri(groupIndex)));
        if ~diagnostic.accepted
            return
        end
        currentTick = records(recordIndex).endTick;
    end
    if groupIndex < 5
        recordIndex = recordIndex + 1;
        diagnostic = checkRecord(records(recordIndex), recordIndex - 1, "transition", groupIndex + 1, ...
            currentTick, uint64(106872));
        if ~diagnostic.accepted
            return
        end
        currentTick = records(recordIndex).endTick;
    end
end
if recordIndex ~= 151 || currentTick ~= uint64(10553388) || records(1).startTick ~= 0
    diagnostic = wp4oracle.failDiagnostic("TICK_DISCONTINUITY", "records", ...
        "Schedule record enumeration does not reach the exact final tick.");
else
    diagnostic = wp4oracle.passDiagnostic();
end
end

function diagnostic = checkRecord(record, pathIndex, expectedRole, expectedPrf, expectedStart, expectedDuration)
required = ["role", "prfIndex", "startTick", "endTick", "durationTicks", ...
    "sampleCount", "pulseSampleCount", "isTransition"];
diagnostic = wp4oracle.requireFields(record, required);
if ~diagnostic.accepted
    return
end
path = "records[" + string(pathIndex) + "]";
if string(record.role) ~= expectedRole || record.prfIndex ~= expectedPrf
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", path + ".role", ...
        "Record role or PRF index violates the group grammar.");
    return
end
if record.startTick ~= expectedStart || record.endTick ~= record.startTick + expectedDuration || ...
        record.durationTicks ~= expectedDuration
    diagnostic = wp4oracle.failDiagnostic("TICK_DISCONTINUITY", path + ".startTick", ...
        "Record interval is not a contiguous half-open interval.");
    return
end
if record.sampleCount ~= expectedDuration || record.pulseSampleCount ~= expectedDuration || ...
        logical(record.isTransition) ~= (expectedRole == "transition")
    diagnostic = wp4oracle.failDiagnostic("VALUE_OUT_OF_RANGE", path + ".sampleCount", ...
        "Record sample counts or transition flag violate the role contract.");
    return
end
diagnostic = wp4oracle.passDiagnostic();
end
