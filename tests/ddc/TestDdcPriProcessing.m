classdef TestDdcPriProcessing < matlab.unittest.TestCase
%TESTDDCPRIPROCESSING Verify the public independent-per-PRI DDC interface.

properties (TestParameter)
    priCase = struct( ...
        "pri88236c1", struct("sampleCount", 88236, "channelCount", 1), ...
        "pri88236c64", struct("sampleCount", 88236, "channelCount", 64), ...
        "pri78948c1", struct("sampleCount", 78948, "channelCount", 1), ...
        "pri78948c64", struct("sampleCount", 78948, "channelCount", 64), ...
        "pri69768c1", struct("sampleCount", 69768, "channelCount", 1), ...
        "pri69768c64", struct("sampleCount", 69768, "channelCount", 64), ...
        "pri61224c1", struct("sampleCount", 61224, "channelCount", 1), ...
        "pri61224c64", struct("sampleCount", 61224, "channelCount", 64), ...
        "pri55560c1", struct("sampleCount", 55560, "channelCount", 1), ...
        "pri55560c64", struct("sampleCount", 55560, "channelCount", 64))
    priLength = struct( ...
        "pri88236", 88236, ...
        "pri78948", 78948, ...
        "pri69768", 69768, ...
        "pri61224", 61224, ...
        "pri55560", 55560)
    inconsistentRateSpec = struct( ...
        "adcRate", struct("spec", struct("adcRateHz", 160e6)), ...
        "intermediateRate", struct("spec", struct("intermediateRateHz", 49e6)), ...
        "outputRate", struct("spec", struct("outputRateHz", 12e6)))
end

methods (TestClassSetup)
    function addSourcePath(testCase)
        repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
        testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
            fullfile(repositoryRoot, "src")));
    end
end

methods (Test)
    function testCombinedFirConvolutionOracle(testCase, priCase)
        design = radardemo.ddc.createDesign(struct());
        input = TestDdcPriProcessing.makeMultitoneNoise( ...
            priCase.sampleCount, priCase.channelCount, 4901 + priCase.sampleCount);
        [actual, metadata] = radardemo.ddc.processFrame(input, design);
        expected = TestDdcPriProcessing.combinedFirOracle(input, design);
        normalizedError = TestDdcPriProcessing.normalizedError( ...
            actual, expected, max(abs(input), [], "all"));

        testCase.verifySize(actual, ...
            [priCase.sampleCount / 12, priCase.channelCount]);
        testCase.verifyEqual(metadata, TestDdcPriProcessing.expectedMetadata( ...
            priCase.sampleCount, size(actual, 1), design));
        testCase.verifyLessThanOrEqual(normalizedError, 5e-11);
    end

    function testZeroInputAndExactOutputShape(testCase, priLength)
        design = radardemo.ddc.createDesign(struct());
        input = zeros(priLength, 1);
        [actual, metadata] = radardemo.ddc.processFrame(input, design);

        testCase.verifySize(actual, [priLength / 12, 1]);
        testCase.verifyEqual(real(actual), zeros(priLength / 12, 1));
        testCase.verifyEqual(imag(actual), zeros(priLength / 12, 1));
        testCase.verifyEqual(metadata, TestDdcPriProcessing.expectedMetadata( ...
            priLength, size(actual, 1), design));
    end

    function testFirstAndLastSampleImpulses(testCase, priLength)
        design = radardemo.ddc.createDesign(struct());
        input = zeros(priLength, 1);
        input(1) = 1.0;
        input(end) = -0.75;
        [actual, ~] = radardemo.ddc.processFrame(input, design);
        expected = TestDdcPriProcessing.combinedFirOracle(input, design);

        testCase.verifyLessThanOrEqual( ...
            TestDdcPriProcessing.normalizedError( ...
            actual, expected, max(abs(input), [], "all")), 5e-11);
    end

    function testFortyMicrosecondBoundaryChirps(testCase)
        design = radardemo.ddc.createDesign(struct());
        input = TestDdcPriProcessing.makeBoundaryChirps(55560, design.adcRateHz);
        [actual, ~] = radardemo.ddc.processFrame(input, design);
        expected = TestDdcPriProcessing.combinedFirOracle(input, design);

        testCase.verifySize(actual, [55560 / 12, 1]);
        testCase.verifyLessThanOrEqual( ...
            TestDdcPriProcessing.normalizedError( ...
            actual, expected, max(abs(input), [], "all")), 5e-11);
    end

    function testChannelIsolation(testCase)
        design = radardemo.ddc.createDesign(struct());
        activeChannel = 17;
        input = zeros(88236, 64);
        input(:, activeChannel) = TestDdcPriProcessing.makeMultitoneNoise( ...
            88236, 1, 6421);
        [actual, ~] = radardemo.ddc.processFrame(input, design);

        testCase.verifyEqual(actual(:, 1:activeChannel - 1), ...
            zeros(size(actual, 1), activeChannel - 1));
        testCase.verifyEqual(actual(:, activeChannel + 1:end), ...
            zeros(size(actual, 1), 64 - activeChannel));
    end

    function testRepeatedReversedAndShuffledCallOrder(testCase)
        design = radardemo.ddc.createDesign(struct());
        [baselineOutput, baselineMetadata, repeatedOutput, repeatedMetadata, ...
            reversedOutput, reversedMetadata, shuffledOutput, shuffledMetadata] = ...
            TestDdcPriProcessing.compareCallOrders(design);

        testCase.verifyEqual(repeatedOutput, baselineOutput);
        testCase.verifyEqual(reversedOutput, baselineOutput);
        testCase.verifyEqual(shuffledOutput, baselineOutput);
        testCase.verifyEqual(repeatedMetadata, baselineMetadata);
        testCase.verifyEqual(reversedMetadata, baselineMetadata);
        testCase.verifyEqual(shuffledMetadata, baselineMetadata);
    end

    function testHistoricalContinuousComparisonAfterFullMemory(testCase)
        design = radardemo.ddc.createDesign(struct());
        normalizedErrors = TestDdcPriProcessing.compareHistoricalAfterMemory(design);

        testCase.verifyLessThanOrEqual(normalizedErrors, 5e-11);
    end

    function testCallerOwnsGlobalTickAndDelayMapping(testCase)
        design = radardemo.ddc.createDesign(struct());
        input = zeros(88236, 1);
        [output, metadata] = radardemo.ddc.processFrame(input, design);
        globalStartTick = uint64(2136300);
        firstOutputTick = globalStartTick - uint64(metadata.groupDelayInputSamples);
        lastOutputTick = globalStartTick + ...
            uint64(metadata.outputSampleCount - 1) * ...
            uint64(metadata.decimationFactor) - ...
            uint64(metadata.groupDelayInputSamples);

        testCase.verifyEqual(size(output, 1), 7353);
        testCase.verifyEqual(firstOutputTick, uint64(2135928));
        testCase.verifyEqual(lastOutputTick, uint64(2224152));
        testCase.verifyFalse(isfield(metadata, "startTick"));
        testCase.verifyFalse(isfield(metadata, "timeEpoch"));
    end

    function testLegacyContinuationSignatureIsRemoved(testCase)
        testCase.verifyEqual(nargin("radardemo.ddc.processFrame"), 2);
        testCase.verifyEqual(exist("radardemo.ddc.initializeState", "file"), 0);
    end

    function testNominalSampleRatesAreAccepted(testCase)
        design = radardemo.ddc.createDesign(struct());

        testCase.verifyEqual( ...
            [design.adcRateHz, design.intermediateRateHz, design.outputRateHz], ...
            [150e6, 50e6, 12.5e6]);
    end

    function testInconsistentSampleRateSpecsAreRejected(testCase, inconsistentRateSpec)
        testCase.verifyError( ...
            @() radardemo.ddc.createDesign(inconsistentRateSpec.spec), ...
            "radardemo:ddc:InconsistentSampleRates");
    end

    function testCascadeResponseAcceptanceAndProfile(testCase)
        design = radardemo.ddc.createDesign(struct());
        metrics = radardemo.ddc.measureResponse(design, struct());

        testCase.verifyTrue(metrics.accepted);
        testCase.verifyEqual(metrics.responseMetricProfile, "cascade-peak-v1");
        testCase.verifyEqual(metrics.frequencyHz([20001, 30001]), [-5e6; 5e6]);
        testCase.verifyLessThanOrEqual(metrics.passbandRippleDb, 0.1);
        testCase.verifyGreaterThanOrEqual(metrics.digitalAliasRejectionDb, 60);
        testCase.verifyGreaterThanOrEqual(metrics.stage2AliasRejectionDb, 60);
        testCase.verifyEqual(metrics.digitalAliasRejectionDb, 85.2548308, AbsTol=2e-6);
    end

    function testStageOneOnlyTwelveMegahertzWitnessFails(testCase)
        design = radardemo.ddc.createDesign(struct());
        design.stage1Numerator = fir1(24, 12e6 / (design.adcRateHz / 2), ...
            kaiser(25, design.kaiserBeta));
        witness = radardemo.ddc.measureResponse(design, struct());

        testCase.verifyFalse(witness.accepted);
        testCase.verifyEqual(witness.passbandRippleDb, 0.793470, AbsTol=5e-4);
    end
end

methods (Static, Access=private)
    function input = makeMultitoneNoise(sampleCount, channelCount, seed)
        stream = RandStream("mt19937ar", Seed=seed);
        sampleIndex = (0:sampleCount - 1).';
        channelPhase = (0:channelCount - 1) * pi / 17;
        firstTone = 0.65 * cos(2 * pi * 51e6 / 150e6 * sampleIndex + channelPhase);
        secondTone = 0.19 * cos(2 * pi * 56.8e6 / 150e6 * sampleIndex - channelPhase);
        input = firstTone + secondTone + 0.025 * randn(stream, sampleCount, channelCount);
    end

    function input = makeBoundaryChirps(sampleCount, sampleRateHz)
        chirpSampleCount = round(40e-6 * sampleRateHz);
        chirpIndex = (0:chirpSampleCount - 1).';
        chirpTime = chirpIndex / sampleRateHz;
        startFrequencyHz = 47.5e6;
        frequencySlopeHzPerSecond = 5e6 / (40e-6);
        phase = 2 * pi * (startFrequencyHz * chirpTime + ...
            0.5 * frequencySlopeHzPerSecond * chirpTime.^2);
        chirpSamples = 0.8 * cos(phase);
        input = zeros(sampleCount, 1);
        input(1:chirpSampleCount) = chirpSamples;
        input(end - chirpSampleCount + 1:end) = chirpSamples;
    end

    function output = combinedFirOracle(input, design)
        % Compose h1(z) and h2(z^3), then convolve and retain only N rows.
        stage2Upsampled = zeros(1, ...
            (numel(design.stage2Numerator) - 1) * design.decimationFactors(1) + 1);
        stage2Upsampled(1:design.decimationFactors(1):end) = design.stage2Numerator;
        cascadeNumerator = conv(design.stage1Numerator, stage2Upsampled);
        sampleCount = size(input, 1);
        channelCount = size(input, 2);
        outputSampleCount = sampleCount / prod(design.decimationFactors);
        output = complex(zeros(outputSampleCount, channelCount));
        sampleIndex = (0:sampleCount - 1).';
        mixer = exp(-1i * 2 * pi * design.mixerFrequencyHz / ...
            design.adcRateHz * sampleIndex);
        mixed = input .* mixer;
        fftLength = 2 ^ nextpow2(sampleCount + numel(cascadeNumerator) - 1);
        numeratorSpectrum = fft(cascadeNumerator, fftLength).';
        channelBlockSize = 8;
        for firstChannel = 1:channelBlockSize:channelCount
            lastChannel = min(firstChannel + channelBlockSize - 1, channelCount);
            channelRange = firstChannel:lastChannel;
            convolved = ifft(fft(mixed(:, channelRange), fftLength, 1) .* ...
                numeratorSpectrum, [], 1);
            causalOutput = convolved(1:sampleCount, :);
            output(:, channelRange) = causalOutput( ...
                1:prod(design.decimationFactors):end, :);
        end
    end

    function errorValue = normalizedError(actual, expected, referenceAmplitude)
        errorValue = max(abs(actual - expected), [], "all") / ...
            max(referenceAmplitude, realmin);
    end

    function metadata = expectedMetadata(inputSampleCount, outputSampleCount, design)
        metadata = struct();
        metadata.inputSampleCount = double(inputSampleCount);
        metadata.outputSampleCount = double(outputSampleCount);
        metadata.decimationFactor = double(prod(design.decimationFactors));
        metadata.groupDelayInputSamples = double(design.delayTicks);
        metadata.groupDelayOutputSamples = double(design.delayOutputSamples);
        metadata.startupInputSamples = double(design.stage1Order + ...
            design.stage2Order * design.decimationFactors(1));
        metadata.startupOutputSamples = metadata.startupInputSamples / ...
            metadata.decimationFactor;
    end

    function [outputs, metadata] = processInOrder(design, inputs, order)
        outputs = cell(1, numel(inputs));
        metadata = cell(1, numel(inputs));
        for index = 1:numel(order)
            recordIndex = order(index);
            [outputs{recordIndex}, metadata{recordIndex}] = ...
                radardemo.ddc.processFrame(inputs{recordIndex}, design);
        end
    end

    function [baselineOutput, baselineMetadata, repeatedOutput, repeatedMetadata, ...
            reversedOutput, reversedMetadata, shuffledOutput, shuffledMetadata] = ...
            compareCallOrders(design)
        sampleCounts = [88236, 78948, 69768, 61224, 55560];
        inputs = cell(1, numel(sampleCounts));
        for index = 1:numel(sampleCounts)
            inputs{index} = TestDdcPriProcessing.makeMultitoneNoise( ...
                sampleCounts(index), 1, 7000 + index);
        end
        baselineOrder = 1:5;
        [baselineOutput, baselineMetadata] = TestDdcPriProcessing.processInOrder( ...
            design, inputs, baselineOrder);
        [repeatedOutput, repeatedMetadata] = TestDdcPriProcessing.processInOrder( ...
            design, inputs, [baselineOrder, baselineOrder]);
        [reversedOutput, reversedMetadata] = TestDdcPriProcessing.processInOrder( ...
            design, inputs, 5:-1:1);
        [shuffledOutput, shuffledMetadata] = TestDdcPriProcessing.processInOrder( ...
            design, inputs, [3, 1, 5, 2, 4]);
    end

    function normalizedErrors = compareHistoricalAfterMemory(design)
        % Historical comparison source: processFrame at 58b3d3a80170d413aa88dd4408490e2056f49379.
        sampleCounts = [88236, 78948, 69768, 61224, 55560];
        inputs = cell(1, numel(sampleCounts));
        for index = 1:numel(sampleCounts)
            inputs{index} = TestDdcPriProcessing.makeMultitoneNoise( ...
                sampleCounts(index), 1, 9100 + index);
        end
        normalizedErrors = zeros(1, numel(sampleCounts));
        state = TestDdcPriProcessing.initializeHistoricalState(design);
        for index = 1:numel(sampleCounts)
            [continuousOutput, state] = ...
                TestDdcPriProcessing.historicalContinuousFrame( ...
                inputs{index}, state, design);
            [priOutput, ~] = radardemo.ddc.processFrame(inputs{index}, design);
            settledFirstRow = design.delayOutputSamples * 2 + 1;
            normalizedErrors(index) = ...
                TestDdcPriProcessing.normalizedError( ...
                priOutput(settledFirstRow:end, :), ...
                continuousOutput(settledFirstRow:end, :), ...
                max(abs(inputs{index}), [], "all"));
        end
    end

    function state = initializeHistoricalState(design)
        state = struct();
        state.stage1Delay = zeros(design.stage1Order, 1);
        state.stage2Delay = zeros(design.stage2Order, 1);
        state.inputSampleCount = uint64(0);
        state.stage1Phase = uint8(0);
        state.stage2Phase = uint8(0);
    end

    function [output, state] = historicalContinuousFrame(input, state, design)
        sampleCount = size(input, 1);
        sampleIndex = double(state.inputSampleCount) + (0:sampleCount - 1).';
        mixer = exp(-1i * 2 * pi * design.mixerFrequencyHz / ...
            design.adcRateHz * sampleIndex);
        mixed = input .* mixer;
        [stage1Output, state.stage1Delay] = filter( ...
            design.stage1Numerator, 1, mixed, state.stage1Delay, 1);
        firstStageIndex = 1 + mod(3 - double(state.stage1Phase), 3);
        stage1Samples = stage1Output(firstStageIndex:3:end, :);
        state.stage1Phase = uint8(mod(double(state.stage1Phase) + sampleCount, 3));
        [stage2Output, state.stage2Delay] = filter( ...
            design.stage2Numerator, 1, stage1Samples, state.stage2Delay, 1);
        firstOutputIndex = 1 + mod(4 - double(state.stage2Phase), 4);
        output = stage2Output(firstOutputIndex:4:end, :);
        state.stage2Phase = uint8(mod( ...
            double(state.stage2Phase) + size(stage1Samples, 1), 4));
        state.inputSampleCount = state.inputSampleCount + uint64(sampleCount);
    end
end
end
