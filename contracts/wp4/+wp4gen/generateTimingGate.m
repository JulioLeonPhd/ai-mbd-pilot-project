function timingGate = generateTimingGate(schedule, options)
%GENERATETIMINGGATE Create integer timing and near-range evidence.

arguments
    schedule struct
    options struct
end

design = radardemo.ddc.createDesign(struct());
timingGate = radardemo.timing.evaluateReceiveTiming(schedule, design, struct());
timingGate.schemaName = "radar.wp4.timing-gate";
timingGate.schemaVersion = "1.0.0-draft.2";
timingGate.seed = options.Seeds.schedule;
timingGate = wp4gen.addProvenance(timingGate, options, options.Seeds.schedule, "timing");
end
