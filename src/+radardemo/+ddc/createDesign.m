function design = createDesign(spec)
%CREATEDESIGN Create the floating-point two-stage receive DDC design.
%   DESIGN = RADARDEMO.DDC.CREATEDESIGN(SPEC) creates the 150/50/12.5 MHz
%   mixer and Kaiser FIR design. This reference has no clipping or saturation.

arguments
    spec struct = struct()
end

spec = applyDefaults(spec);
stage1 = fir1(24, spec.stage1CutoffHz / (spec.adcRateHz / 2), ...
    kaiser(25, spec.kaiserBeta));
stage2 = fir1(240, spec.stage2CutoffHz / (spec.intermediateRateHz / 2), ...
    kaiser(241, spec.kaiserBeta));
design = struct();
design.schemaName = "radar.wp4.ddc";
design.schemaVersion = "1.0.0-draft.2";
design.adcRateHz = spec.adcRateHz;
design.intermediateRateHz = spec.intermediateRateHz;
design.outputRateHz = spec.outputRateHz;
design.mixerFrequencyHz = spec.mixerFrequencyHz;
design.decimationFactors = [3, 4];
design.stage1Numerator = stage1(:).';
design.stage2Numerator = stage2(:).';
design.stage1Order = 24;
design.stage2Order = 240;
design.kaiserBeta = spec.kaiserBeta;
design.stage1CutoffHz = spec.stage1CutoffHz;
design.stage2CutoffHz = spec.stage2CutoffHz;
design.passbandHz = [-5e6, 5e6];
design.stopbandStartHz = 6.25e6;
design.metricToleranceDb = 1e-9;
design.delayTicks = 372;
design.delayOutputSamples = 31;
end

function spec = applyDefaults(spec)
defaults = struct("adcRateHz", 150e6, "intermediateRateHz", 50e6, ...
    "outputRateHz", 12.5e6, "mixerFrequencyHz", 50e6, "kaiserBeta", 8.6, ...
    "stage1CutoffHz", 25e6, "stage2CutoffHz", 5.625e6);
names = fieldnames(defaults);
for index = 1:numel(names)
    if ~isfield(spec, names{index})
        spec.(names{index}) = defaults.(names{index});
    end
end
end
