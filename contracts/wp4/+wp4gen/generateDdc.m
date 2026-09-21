function ddc = generateDdc(options)
%GENERATEDDC Record production DDC design, stream, and zero fixtures.

arguments
    options struct
end

design = radardemo.ddc.createDesign(struct());
metrics = radardemo.ddc.measureResponse(design, struct());
design.frequencyHz = metrics.frequencyHz;
design.sampleRateHz = design.adcRateHz;
design.stage1Response = metrics.stage1Response;
design.stage2Response = metrics.stage2Response;
design.stage1AliasBranches = metrics.stage1AliasBranches;
design.stage2AliasBranches = metrics.stage2AliasBranches;
design.cascadeAliasBranches = metrics.cascadeAliasBranches;
design.cascadeBranchPairs = metrics.cascadeBranchPairs;
design.principalCascadeResponse = metrics.principalCascadeResponse;
design.principalPassbandGain = metrics.principalPassbandGain;
design.principalPassbandValid = metrics.principalPassbandValid;
design.passbandRippleDb = metrics.passbandRippleDb;
design.stage2AliasRejectionDb = metrics.stage2AliasRejectionDb;
design.digitalAliasRejectionDb = metrics.digitalAliasRejectionDb;
design.gridResolutionHz = metrics.gridResolutionHz;
design.seed = options.Seeds.ddc;
design = wp4gen.addProvenance(design, options, options.Seeds.ddc, "ddc");

sampleCount = 2400;
sampleIndex = (0:sampleCount - 1).';
inputSignal = cos(2 * pi * 50e6 / 150e6 * sampleIndex) + ...
    0.1 * cos(2 * pi * 2e6 / 150e6 * sampleIndex);
inputSignal = repmat(inputSignal, 1, 1);
chunkLengths = [317, 911, 503, sampleCount - 317 - 911 - 503];
state = radardemo.ddc.initializeState(design, 1);
outputChunks = cell(numel(chunkLengths), 1);
offset = 0;
for index = 1:numel(chunkLengths)
    chunk = inputSignal(offset + (1:chunkLengths(index)), :);
    [chunkOutput, state] = radardemo.ddc.processChunk(chunk, state, design);
    outputChunks{index} = chunkOutput;
    offset = offset + chunkLengths(index);
end
expectedOutput = vertcat(outputChunks{:});
streaming = struct();
streaming.schemaName = "radar.wp4.ddc-streaming";
streaming.schemaVersion = "1.0.0-draft.2";
streaming.input = inputSignal;
streaming.chunkLengths = chunkLengths;
streaming.expectedOutput = expectedOutput;
streaming.expectedLength = numel(expectedOutput);
streaming.tolerance = 5e-11;
streaming.seed = options.Seeds.ddc;
streaming = wp4gen.addProvenance(streaming, options, options.Seeds.ddc, "ddc-streaming");

zero = struct();
zero.schemaName = "radar.wp4.ddc-zero";
zero.schemaVersion = "1.0.0-draft.2";
zero.input = zeros(240, 64);
zeroState = radardemo.ddc.initializeState(design, 64);
[zero.output, zeroState] = radardemo.ddc.processChunk(zero.input, zeroState, design);
zero.output = complex(zero.output);
zero.decimationFactors = design.decimationFactors;
zero.tolerance = 0;
zero.expectedInputShape = [240, 64];
zero.expectedOutputShape = [20, 64];
zero.finalState = zeroState;
zero.seed = options.Seeds.ddc;
zero = wp4gen.addProvenance(zero, options, options.Seeds.ddc, "ddc-zero");
ddc = struct("design", design, "streaming", streaming, "zero", zero);
end
