function timingGate = generateTimingGate(schedule, design, options)
%GENERATETIMINGGATE Create derived integer timing and near-range evidence.
arguments
    schedule struct
    design struct
    options struct
end
timingDesign = struct("adcRateHz", design.adcRateHz, ...
    "decimationFactors", design.decimationFactors, ...
    "stage1Numerator", design.stage1Numerator, ...
    "stage2Numerator", design.stage2Numerator);
timingSpec = struct("adcRateHz", design.adcRateHz, ...
    "speedOfLightMps", 299792458, "nominalRangeM", 6800, ...
    "radialSpeedBoundMps", 800 / 3.6, ...
    "transmitBlankingTicks", 6000, "guardTicks", 750);
timingGate = radardemo.timing.evaluateReceiveTiming(schedule, timingDesign, timingSpec);
timingGate.schemaName = "radar.wp4.timing-gate";
timingGate.schemaVersion = "1.0.0-draft.2";
timingGate.schedule = schedule;
timingGate.timingDesign = timingDesign;
timingGate.timingSpec = timingSpec;
timingGate.seed = options.Seeds.schedule;
timingGate = wp4gen.addProvenance(timingGate, options, options.Seeds.schedule, "timing");
end
