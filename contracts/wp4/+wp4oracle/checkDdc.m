function diagnostic = checkDdc(data)
%CHECKDDC Independently regenerate the two-stage DDC response evidence.

diagnostic = checkVersion(data);
if ~diagnostic.accepted
    return
end
required = ["sampleRateHz", "adcRateHz", "intermediateRateHz", ...
    "outputRateHz", "decimationFactors", "stage1Numerator", ...
    "stage2Numerator", "passbandHz", "stopbandStartHz", ...
    "frequencyHz", "stage1Response", "stage2Response", ...
    "stage1AliasBranches", "stage2AliasBranches", "cascadeAliasBranches", ...
    "cascadeBranchPairs", "passbandRippleDb", "stage2AliasRejectionDb", ...
    "digitalAliasRejectionDb", "gridResolutionHz", "metricToleranceDb"];
diagnostic = requireFields(data, required);
if ~diagnostic.accepted
    return
end
if ~isequal([data.adcRateHz, data.intermediateRateHz, data.outputRateHz], ...
        [150e6, 50e6, 12.5e6]) || ~isequal(data.decimationFactors, [3, 4])
    diagnostic = failDiagnostic("VALUE_OUT_OF_RANGE", "decimationFactors", ...
        "DDC rates and factors differ from the frozen design.");
    return
end
if data.stopbandStartHz > 6.25e6
    diagnostic = failDiagnostic("DDC_STOPBAND_EDGE", "stopbandStartHz", ...
        "Stage two stopband starts later than 6.25 MHz.");
    return
end
if ~isTapVector(data.stage1Numerator, 25)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "stage1Numerator", ...
        "Stage one must contain 25 taps.");
    return
end
if ~isTapVector(data.stage2Numerator, 241)
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "stage2Numerator", ...
        "Stage two must contain 241 taps.");
    return
end
if any(~isfinite(data.stage1Numerator(:)))
    diagnostic = failDiagnostic("NONFINITE", "stage1Numerator[0]", ...
        "Stage one contains a nonfinite coefficient.");
    return
end
if any(~isfinite(data.stage2Numerator(:)))
    diagnostic = failDiagnostic("NONFINITE", "stage2Numerator[0]", ...
        "Stage two contains a nonfinite coefficient.");
    return
end
if ~isequal(size(data.frequencyHz), [50001, 1]) || data.gridResolutionHz ~= 1000
    diagnostic = failDiagnostic("DIMENSION_MISMATCH", "frequencyHz", ...
        "Response evidence must use the exact 1 kHz grid including endpoints.");
    return
end
if max(abs(data.stage1Numerator(:) - flipud(data.stage1Numerator(:)))) > 1e-13 || ...
        max(abs(data.stage2Numerator(:) - flipud(data.stage2Numerator(:)))) > 1e-13 || ...
        abs(sum(data.stage1Numerator(:)) - 1) > 1e-13 || ...
        abs(sum(data.stage2Numerator(:)) - 1) > 1e-13
    diagnostic = failDiagnostic("DDC_COEFFICIENT_SYMMETRY", "stage1Numerator", ...
        "FIR symmetry or DC normalization is outside the frozen tolerance.");
    return
end
expectedStage1 = fir1(24, 25e6 / (150e6 / 2), kaiser(25, 8.6));
expectedStage2 = fir1(240, 5.625e6 / (50e6 / 2), kaiser(241, 8.6));
if max(abs(data.stage1Numerator(:) - expectedStage1(:))) > 5e-15
    diagnostic = failDiagnostic("DDC_COEFFICIENT_MISMATCH", "stage1Numerator", ...
        "Stored stage-one coefficients cannot be independently regenerated.");
    return
end

expected = computeResponse(data);
if expected.passbandRippleDb > 0.1 + data.metricToleranceDb
    diagnostic = failDiagnostic("DDC_RIPPLE_EXCEEDED", "stage2Numerator", ...
        "Recomputed passband ripple exceeds 0.1 dB.");
    return
end
if expected.stage2AliasRejectionDb < 60 - data.metricToleranceDb || ...
        expected.digitalAliasRejectionDb < 60 - data.metricToleranceDb
    diagnostic = failDiagnostic("DDC_ALIAS_REJECTION", "stage2Numerator", ...
        "Recomputed full-cascade alias rejection is below 60 dB.");
    return
end
if max(abs(data.frequencyHz(:) - expected.frequencyHz(:))) > 0 || ...
        max(abs(data.stage1Response(:) - expected.stage1Response(:))) > 1e-12 || ...
        max(abs(data.stage2Response(:) - expected.stage2Response(:))) > 1e-12 || ...
        max(abs(data.stage1AliasBranches(:) - expected.stage1AliasBranches(:))) > 1e-12 || ...
        max(abs(data.stage2AliasBranches(:) - expected.stage2AliasBranches(:))) > 1e-12 || ...
        max(abs(data.cascadeAliasBranches(:) - expected.cascadeAliasBranches(:))) > 1e-12 || ...
        ~isequal(data.cascadeBranchPairs, expected.cascadeBranchPairs)
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "cascadeAliasBranches", ...
        "Stored response or branch evidence differs from independent recomputation.");
    return
end
if max(abs(data.stage2Numerator(:) - expectedStage2(:))) > 5e-15
    diagnostic = failDiagnostic("DDC_COEFFICIENT_MISMATCH", "stage2Numerator", ...
        "Stored stage-two coefficients cannot be independently regenerated.");
    return
end
scalarTolerance = 1e-9;
if abs(data.passbandRippleDb - expected.passbandRippleDb) > scalarTolerance || ...
        abs(data.stage2AliasRejectionDb - expected.stage2AliasRejectionDb) > scalarTolerance || ...
        abs(data.digitalAliasRejectionDb - expected.digitalAliasRejectionDb) > scalarTolerance
    diagnostic = failDiagnostic("NUMERICAL_MISMATCH", "digitalAliasRejectionDb", ...
        "Stored DDC scalar metrics differ from independent recomputation.");
    return
end
diagnostic = passDiagnostic();
end

function output = computeResponse(data)
frequencyHz = (-25e6:1000:25e6).';
stage1 = evaluateDtft(data.stage1Numerator, frequencyHz, data.adcRateHz);
stage2 = evaluateDtft(data.stage2Numerator, frequencyHz, data.intermediateRateHz);
stage1Offsets = -1:1;
stage2Offsets = -2:1;
stage1Branches = zeros(numel(frequencyHz), 3);
for index = 1:3
    stage1Branches(:, index) = evaluateDtft(data.stage1Numerator, ...
        frequencyHz + stage1Offsets(index) * data.intermediateRateHz, data.adcRateHz);
end
stage2Branches = zeros(numel(frequencyHz), 4);
for index = 1:4
    stage2Branches(:, index) = evaluateDtft(data.stage2Numerator, ...
        frequencyHz + stage2Offsets(index) * data.outputRateHz, data.intermediateRateHz);
end
cascade = zeros(numel(frequencyHz), 12);
pairs = zeros(12, 2);
column = 0;
for stage2Index = 1:4
    stage2Frequency = frequencyHz + stage2Offsets(stage2Index) * data.outputRateHz;
    stage2Value = evaluateDtft(data.stage2Numerator, stage2Frequency, data.intermediateRateHz);
    for stage1Index = 1:3
        column = column + 1;
        stage1Frequency = stage2Frequency + stage1Offsets(stage1Index) * data.intermediateRateHz;
        stage1Value = evaluateDtft(data.stage1Numerator, stage1Frequency, data.adcRateHz);
        cascade(:, column) = stage2Value .* stage1Value;
        pairs(column, :) = [stage2Offsets(stage2Index), stage1Offsets(stage1Index)];
    end
end
passband = abs(frequencyHz) <= 5e6;
stopband = abs(frequencyHz) >= data.stopbandStartHz;
passbandDb = 20 * log10(max(abs(stage2(passband)), realmin));
stage2StopbandDb = 20 * log10(max(abs(stage2(stopband)), realmin));
nonPrincipal = ~(pairs(:, 1) == 0 & pairs(:, 2) == 0);
cascadeDb = 20 * log10(max(abs(cascade(passband, nonPrincipal)), realmin));
output = struct("frequencyHz", frequencyHz, "stage1Response", stage1, ...
    "stage2Response", stage2, "stage1AliasBranches", stage1Branches, ...
    "stage2AliasBranches", stage2Branches, "cascadeAliasBranches", cascade, ...
    "cascadeBranchPairs", pairs, "passbandRippleDb", max(passbandDb) - min(passbandDb), ...
    "stage2AliasRejectionDb", max(passbandDb) - max(stage2StopbandDb), ...
    "digitalAliasRejectionDb", -max(cascadeDb(:)));
end

function response = evaluateDtft(coefficients, frequencies, sampleRate)
sampleIndex = (0:numel(coefficients) - 1).';
response = zeros(size(frequencies));
for frequencyIndex = 1:numel(frequencies)
    kernel = exp(-1i * 2 * pi * frequencies(frequencyIndex) / sampleRate * sampleIndex);
    response(frequencyIndex) = coefficients(:).' * kernel;
end
end

function output = isTapVector(value, lengthExpected)
output = (isvector(value) && numel(value) == lengthExpected);
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
        diagnostic = failDiagnostic("MISSING_FIELD", fields(index), "A required field is missing.");
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
