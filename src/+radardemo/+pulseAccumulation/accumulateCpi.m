function ensemble = accumulateCpi(priResults, cpiContext)
%ACCUMULATECPI Assemble one complete CPI in scheduled pulse order.
%   ENSEMBLE = RADARDEMO.PULSEACCUMULATION.ACCUMULATECPI(PRIRESULTS,
%   CPICONTEXT) preserves complex [rangeBin,4] per-PRI samples, logical
%   validity, range centers in metres and uint64 150 MHz source ticks.
%   The output sample and validity axes are [rangeBin,pulse,elevation].
%   Context declares expectedPulseCount, azimuthLookIndex and prfNominalHz;
%   the caller remains responsible for membership and exact PRI spacing.

contextId = "radardemo:pulseAccumulation:InvalidContext";
slotId = "radardemo:pulseAccumulation:InvalidSlotsOrTicks";
rangeId = "radardemo:pulseAccumulation:IncompatibleRangeResults";
fields = ["azimuthLookIndex"; "expectedPulseCount"; "prfNominalHz"];
if ~isstruct(cpiContext) || ~isscalar(cpiContext) || ...
        ~isequal(sort(string(fieldnames(cpiContext))), fields)
    error(contextId, "Context must contain exactly the count, look index and nominal PRF.");
end
count = cpiContext.expectedPulseCount;
look = cpiContext.azimuthLookIndex;
prf = cpiContext.prfNominalHz;
if ~isPositiveInteger(count) || ~isPositiveInteger(look) || ...
        ~isa(prf, "double") || ~isscalar(prf) || ~isreal(prf) || ...
        ~isfinite(prf) || prf <= 0
    error(contextId, "Count and look must be positive double integers; PRF must be a positive finite double.");
end

if ~isstruct(priResults) || ~isvector(priResults) || isempty(priResults) || ...
        numel(priResults) ~= count || ~isfield(priResults, "slot") || ...
        ~isfield(priResults, "pulseStartTick")
    error(slotId, "Provide one record per slot, including slot and pulseStartTick fields.");
end
recordForSlot = zeros(count, 1);
ticks = zeros(count, 1, "uint64");
for recordIndex = 1:count
    slot = priResults(recordIndex).slot;
    tick = priResults(recordIndex).pulseStartTick;
    if ~isPositiveInteger(slot) || slot > count || ...
            ~isa(tick, "uint64") || ~isscalar(tick)
        error(slotId, "Each slot must be in range and each tick a uint64 scalar.");
    end
    if recordForSlot(slot) ~= 0
        error(slotId, "Each scheduled slot must occur exactly once.");
    end
    recordForSlot(slot) = recordIndex;
    ticks(slot) = tick;
end
if any(ticks(1:end-1) >= ticks(2:end))
    error(slotId, "Source ticks must increase strictly in scheduled slot order.");
end

if ~isfield(priResults, "rangeSamples") || ~isfield(priResults, "metadata")
    error(rangeId, "Each record must contain range samples and metadata.");
end
for slot = 1:count
    record = priResults(recordForSlot(slot));
    samples = record.rangeSamples;
    metadata = record.metadata;
    if ~isa(samples, "double") || ~ismatrix(samples) || isempty(samples) || ...
            size(samples, 2) ~= 4 || isreal(samples) || any(~isfinite(samples), "all") || ...
            ~isstruct(metadata) || ~isscalar(metadata) || ...
            ~isfield(metadata, "valid") || ~isfield(metadata, "rangeBinCentersM")
        error(rangeId, "Each range result must contain finite complex double [R,4] samples and metadata.");
    end
    valid = metadata.valid;
    grid = metadata.rangeBinCentersM;
    if ~islogical(valid) || ~ismatrix(valid) || ~isequal(size(valid), size(samples)) || ...
            ~isa(grid, "double") || ~isreal(grid) || ...
            ~isequal(size(grid), [size(samples, 1), 1]) || any(~isfinite(grid), "all")
        error(rangeId, "Validity and finite real range centers must match the sample dimensions.");
    end
    if slot == 1
        referenceGrid = grid;
    elseif ~isequal(grid, referenceGrid)
        error(rangeId, "All range-bin center vectors must match slot 1 exactly.");
    end
end

rangeCount = numel(referenceGrid);
rangeSamples = complex(zeros(rangeCount, count, 4));
valid = false(rangeCount, count, 4);
for slot = 1:count
    record = priResults(recordForSlot(slot));
    rangeSamples(:, slot, :) = reshape(record.rangeSamples, rangeCount, 1, 4);
    valid(:, slot, :) = reshape(record.metadata.valid, rangeCount, 1, 4);
end
if isreal(rangeSamples)
    rangeSamples = complex(rangeSamples);
end
ensemble = struct("rangeSamples", rangeSamples, "valid", valid, ...
    "rangeBinCentersM", referenceGrid, "pulseStartTicks", ticks);
end

function result = isPositiveInteger(value)
result = isa(value, "double") && isscalar(value) && isreal(value) && ...
    isfinite(value) && value > 0 && value <= flintmax && value == fix(value);
end
