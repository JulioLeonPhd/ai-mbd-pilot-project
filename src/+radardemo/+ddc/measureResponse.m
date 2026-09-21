function metrics = measureResponse(design, gridSpec)
%MEASURERESPONSE Measure the staged DDC response on an exact frequency grid.
%   METRICS = RADARDEMO.DDC.MEASURERESPONSE(DESIGN, GRIDSPEC) evaluates
%   direct DTFTs for both FIR stages. Each final-output alias branch uses
%   its own stage-2 input coordinate and corresponding stage-1 preimage.

arguments
    design struct
    gridSpec struct = struct()
end

gridSpec = applyDefaults(gridSpec);
frequencyHz = (gridSpec.startHz:gridSpec.stepHz:gridSpec.stopHz).';
stage1Response = directDtft(design.stage1Numerator, frequencyHz, design.adcRateHz);
stage2Response = directDtft(design.stage2Numerator, frequencyHz, design.intermediateRateHz);

stage1BranchOffsets = -1:1;
stage2BranchOffsets = -2:1;
stage1Branches = zeros(numel(frequencyHz), numel(stage1BranchOffsets));
for branchIndex = 1:numel(stage1BranchOffsets)
    branchFrequency = frequencyHz + stage1BranchOffsets(branchIndex) * ...
        design.intermediateRateHz;
    stage1Branches(:, branchIndex) = directDtft(design.stage1Numerator, ...
        branchFrequency, design.adcRateHz);
end
stage2Branches = zeros(numel(frequencyHz), numel(stage2BranchOffsets));
for branchIndex = 1:numel(stage2BranchOffsets)
    branchFrequency = frequencyHz + stage2BranchOffsets(branchIndex) * ...
        design.outputRateHz;
    stage2Branches(:, branchIndex) = directDtft(design.stage2Numerator, ...
        branchFrequency, design.intermediateRateHz);
end

% Pair every stage-2 output alias with every stage-1 preimage. Columns
% follow stage-2 offset first, then stage-1 offset, including (0, 0).
cascadeBranches = zeros(numel(frequencyHz), 12);
branchPairs = zeros(12, 2);
column = 0;
for stage2Index = 1:numel(stage2BranchOffsets)
    stage2Frequency = frequencyHz + stage2BranchOffsets(stage2Index) * ...
        design.outputRateHz;
    stage2ResponseAtBranch = directDtft(design.stage2Numerator, ...
        stage2Frequency, design.intermediateRateHz);
    for stage1Index = 1:numel(stage1BranchOffsets)
        column = column + 1;
        stage1Frequency = stage2Frequency + stage1BranchOffsets(stage1Index) * ...
            design.intermediateRateHz;
        stage1ResponseAtBranch = directDtft(design.stage1Numerator, ...
            stage1Frequency, design.adcRateHz);
        cascadeBranches(:, column) = stage2ResponseAtBranch .* ...
            stage1ResponseAtBranch;
        branchPairs(column, :) = [stage2BranchOffsets(stage2Index), ...
            stage1BranchOffsets(stage1Index)];
    end
end

passband = abs(frequencyHz) <= abs(design.passbandHz(2));
stopband = abs(frequencyHz) >= design.stopbandStartHz;
principalCascadeResponse = stage1Response .* stage2Response;
principalPassband = abs(principalCascadeResponse(passband));
passbandMagnitude = abs(stage2Response(passband));
passbandDb = 20 * log10(max(passbandMagnitude, realmin));
stage2StopbandDb = 20 * log10(max(abs(stage2Response(stopband)), realmin));
nonPrincipal = ~(branchPairs(:, 1) == 0 & branchPairs(:, 2) == 0);
cascadeAliasDb = 20 * log10(max(abs(cascadeBranches(passband, nonPrincipal)), realmin));
metrics = struct();
metrics.frequencyHz = frequencyHz;
metrics.stage1Response = stage1Response;
metrics.stage2Response = stage2Response;
metrics.stage1AliasBranches = stage1Branches;
metrics.stage2AliasBranches = stage2Branches;
metrics.cascadeAliasBranches = cascadeBranches;
metrics.cascadeBranchPairs = branchPairs;
metrics.principalCascadeResponse = principalCascadeResponse;
metrics.principalPassbandGain = max(principalPassband);
metrics.principalPassbandValid = all(isfinite(principalPassband)) && ...
    metrics.principalPassbandGain > 1e-6 && ...
    abs(sum(design.stage1Numerator(:)) - 1) <= 1e-13 && ...
    abs(sum(design.stage2Numerator(:)) - 1) <= 1e-13 && ...
    max(abs(design.stage1Numerator(:) - flipud(design.stage1Numerator(:)))) <= 1e-13 && ...
    max(abs(design.stage2Numerator(:) - flipud(design.stage2Numerator(:)))) <= 1e-13;
metrics.passbandRippleDb = max(passbandDb) - min(passbandDb);
metrics.stage2AliasRejectionDb = max(passbandDb) - max(stage2StopbandDb);
% FIRs are DC-normalized, so the full-cascade attenuation is reported
% against the normalized maximum passband amplitude (0 dB). This keeps the
% branch metric independent of the small passband-ripple peak.
metrics.digitalAliasRejectionDb = -max(cascadeAliasDb(:));
metrics.gridResolutionHz = gridSpec.stepHz;
metrics.metricToleranceDb = design.metricToleranceDb;
metrics.accepted = metrics.passbandRippleDb <= 0.1 + design.metricToleranceDb && ...
    metrics.stage2AliasRejectionDb >= 60 - design.metricToleranceDb && ...
    metrics.digitalAliasRejectionDb >= 60 - design.metricToleranceDb && ...
    metrics.principalPassbandValid && ...
    design.stopbandStartHz <= 6.25e6;
end

function gridSpec = applyDefaults(gridSpec)
defaults = struct("startHz", -25e6, "stopHz", 25e6, "stepHz", 1000);
names = fieldnames(defaults);
for index = 1:numel(names)
    if ~isfield(gridSpec, names{index})
        gridSpec.(names{index}) = defaults.(names{index});
    end
end
end

function response = directDtft(coefficients, frequencyHz, sampleRateHz)
sampleIndex = 0:numel(coefficients) - 1;
response = zeros(size(frequencyHz));
for index = 1:numel(frequencyHz)
    response(index) = sum(coefficients(:).' .* exp(-1i * 2 * pi * ...
        frequencyHz(index) / sampleRateHz * sampleIndex));
end
end
