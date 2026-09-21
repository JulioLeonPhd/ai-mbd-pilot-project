function timing = evaluateReceiveTiming(schedule, design, spec)
%EVALUATERECEIVETIMING Evaluate integer decimation and near-range timing.
%   TIMING = RADARDEMO.TIMING.EVALUATERECEIVETIMING(SCHEDULE, DESIGN, SPEC)
%   reports the frozen 372-tick delay, 31 output samples, and priming margin.

arguments
    schedule struct
    design struct
    spec struct = struct()
end

if ~isfield(design, "delayTicks") || ~isfield(design, "decimationFactors")
    error("radardemo:timing:DesignFields", "The DDC design lacks timing fields.");
end
timing = struct();
timing.decimationFactors = design.decimationFactors;
timing.delayTicks = design.delayTicks;
timing.delayOutputSamples = design.delayOutputSamples;
timing.primingRequired = true;
timing.nearRangeMarginTicks = getField(spec, "nearRangeMarginTicks", 54);
timing.finalPhaseModuloTicks = mod(double(timing.delayTicks), prod(design.decimationFactors));
timing.scheduleRecordCount = schedule.recordCount;
timing.scanMidpointOffsetTicks = schedule.midpointOffsetTicks;
timing.accepted = timing.delayTicks == 372 && timing.delayOutputSamples == 31 && ...
    timing.finalPhaseModuloTicks == 0 && timing.nearRangeMarginTicks == 54;
end

function value = getField(data, name, fallback)
if isfield(data, name)
    value = data.(name);
else
    value = fallback;
end
end
