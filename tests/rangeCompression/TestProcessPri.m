classdef TestProcessPri < matlab.unittest.TestCase
%TESTPROCESSPRI Verify the public independent-per-PRI range-compression seam.

properties (TestParameter)
    shortSampleCount = struct( ...
        "oneSample", 1, ...
        "oneLessThanReference", 499)
    invalidSampleCase = struct( ...
        "empty", struct("samples", {zeros(0, 4)}, "valid", {false(0, 4)}), ...
        "singlePrecision", struct("samples", {single(zeros(500, 4))}, ...
            "valid", {true(500, 4)}), ...
        "integerSamples", struct("samples", {int16(zeros(500, 4))}, ...
            "valid", {true(500, 4)}), ...
        "wrongStreamCount", struct("samples", {zeros(500, 3)}, ...
            "valid", {true(500, 3)}), ...
        "nonmatrix", struct("samples", {zeros(500, 4, 2)}, ...
            "valid", {true(500, 4, 2)}), ...
        "nonfiniteEvenWhenInvalid", struct("samples", {nan(500, 4)}, ...
            "valid", {false(500, 4)}))
    invalidValidityCase = struct( ...
        "numericMask", struct("valid", {ones(500, 4)}), ...
        "wrongSampleCount", struct("valid", {true(499, 4)}), ...
        "wrongStreamCount", struct("valid", {true(500, 3)}), ...
        "nonmatrix", struct("valid", {true(500, 4, 2)}))
    invalidConfigurationCase = struct( ...
        "notStructure", struct("configuration", {42}), ...
        "nonscalarStructure", struct("configuration", ...
            {repmat(struct("rangeOriginM", 0), 2, 1)}), ...
        "missingOrigin", struct("configuration", {struct()}), ...
        "unknownField", struct("configuration", ...
            {struct("rangeOriginM", 0, "extra", 1)}), ...
        "singleOrigin", struct("configuration", ...
            {struct("rangeOriginM", single(0))}), ...
        "complexOrigin", struct("configuration", ...
            {struct("rangeOriginM", complex(0, 1))}), ...
        "nanOrigin", struct("configuration", {struct("rangeOriginM", NaN)}), ...
        "infiniteOrigin", struct("configuration", ...
            {struct("rangeOriginM", Inf)}))
end

methods (TestClassSetup)
    function addSourcePath(testCase)
        repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
        testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
            fullfile(repositoryRoot, "src")));
    end
end

methods (Test)
    function testDirectCorrelationAndPerStreamValidity(testCase)
        samples = TestProcessPri.makeSamples(1100, 4);
        inputValid = true(size(samples));
        inputValid(3, 1) = false;
        inputValid(1:4, 2) = false;
        inputValid(612, 3) = false;
        inputValid(end - 1:end, 4) = false;
        originM = -31 * TestProcessPri.rangeSpacingM();
        [expected, expectedValid] = TestProcessPri.directOracle(samples, inputValid);
        [actual, metadata] = radardemo.rangeCompression.processPri( ...
            samples, inputValid, struct("rangeOriginM", originM));

        testCase.verifyEqual(size(actual), [size(samples, 1), 4]);
        testCase.verifyClass(actual, "double");
        testCase.verifyFalse(isreal(actual));
        testCase.verifyEqual(metadata.valid, expectedValid);
        testCase.verifyEqual(actual, expected, AbsTol=2e-12);
    end

    function testMaskEdgesGapsAndValidZero(testCase)
        sampleCount = 1600;
        inputValid = true(sampleCount, 4);
        inputValid(1:62, 2) = false;
        inputValid(1:625, 3) = false;
        inputValid(801, 4) = false;
        inputValid(1501:end, 4) = false;
        expectedValid = false(sampleCount, 4);
        expectedValid(1:1101, 1) = true;
        expectedValid(63:1101, 2) = true;
        expectedValid(626:1101, 3) = true;
        expectedValid(1:301, 4) = true;
        expectedValid(802:1001, 4) = true;
        samples = zeros(sampleCount, 4);
        [actual, metadata] = radardemo.rangeCompression.processPri( ...
            samples, inputValid, struct("rangeOriginM", 0));

        testCase.verifyEqual(metadata.valid, expectedValid);
        testCase.verifyTrue(all(actual(:) == 0));
        testCase.verifyFalse(isreal(actual));
        testCase.verifyTrue(all(metadata.valid(1:1101, 1)));
        testCase.verifyFalse(any(metadata.valid(sampleCount - 498:end, :), "all"));
    end

    function testShortInputReturnsComplexInvalidZeros(testCase, shortSampleCount)
        samples = zeros(shortSampleCount, 4);
        [actual, metadata] = radardemo.rangeCompression.processPri( ...
            samples, true(size(samples)), struct("rangeOriginM", -7.5));

        testCase.verifySize(actual, [shortSampleCount, 4]);
        testCase.verifyFalse(any(metadata.valid, "all"));
        testCase.verifyFalse(isreal(actual));
        testCase.verifyTrue(all(actual(:) == 0));
    end

    function testExactReferenceLengthHasOneValidLag(testCase)
        samples = zeros(500, 4);
        [actual, metadata] = radardemo.rangeCompression.processPri( ...
            samples, true(size(samples)), struct("rangeOriginM", 0));

        testCase.verifyTrue(all(metadata.valid(1, :)));
        testCase.verifyFalse(any(metadata.valid(2:end, :), "all"));
        testCase.verifyTrue(all(actual(:) == 0));
        testCase.verifyFalse(isreal(actual));
    end

    function testCoordinatesAndMetadataContract(testCase)
        sampleCount = 537;
        rangeOriginM = -31 * TestProcessPri.rangeSpacingM();
        samples = complex(zeros(sampleCount, 4));
        [actual, metadata] = radardemo.rangeCompression.processPri( ...
            samples, true(size(samples)), struct("rangeOriginM", rangeOriginM));
        expectedCoordinates = rangeOriginM + ...
            (0:sampleCount - 1).' * TestProcessPri.rangeSpacingM();

        testCase.verifySize(actual, [sampleCount, 4]);
        testCase.verifyClass(metadata.valid, "logical");
        testCase.verifySize(metadata.valid, [sampleCount, 4]);
        testCase.verifyClass(metadata.rangeBinCentersM, "double");
        testCase.verifySize(metadata.rangeBinCentersM, [sampleCount, 1]);
        testCase.verifyEqual(sort(string(fieldnames(metadata))), ...
            ["rangeBinCentersM"; "valid"]);
        testCase.verifyEqual(metadata.rangeBinCentersM, expectedCoordinates, ...
            AbsTol=1e-10);
        testCase.verifyEqual(metadata.rangeBinCentersM(1), rangeOriginM, AbsTol=0);
    end

    function testRepeatedCallsAreIndependent(testCase)
        firstSamples = TestProcessPri.makeSamples(700, 4);
        secondSamples = TestProcessPri.makeSamples(713, 4) .* (0.4 - 0.7i);
        firstMask = true(size(firstSamples));
        firstMask(90, 2) = false;
        secondMask = true(size(secondSamples));
        secondMask(12:18, 4) = false;
        cfg = struct("rangeOriginM", -100);
        [firstExpected, firstExpectedMetadata] = ...
            radardemo.rangeCompression.processPri(firstSamples, firstMask, cfg);
        [secondExpected, secondExpectedMetadata] = ...
            radardemo.rangeCompression.processPri(secondSamples, secondMask, cfg);
        [secondActual, secondMetadata] = ...
            radardemo.rangeCompression.processPri(secondSamples, secondMask, cfg);
        [firstActual, firstMetadata] = ...
            radardemo.rangeCompression.processPri(firstSamples, firstMask, cfg);

        testCase.verifyEqual(firstActual, firstExpected);
        testCase.verifyEqual(firstMetadata, firstExpectedMetadata);
        testCase.verifyEqual(secondActual, secondExpected);
        testCase.verifyEqual(secondMetadata, secondExpectedMetadata);
    end

    function testInputRejectionsUseStableIdentifier(testCase, invalidSampleCase)
        testCase.verifyError( ...
            @() radardemo.rangeCompression.processPri( ...
            invalidSampleCase.samples, invalidSampleCase.valid, ...
            struct("rangeOriginM", 0)), ...
            "radardemo:rangeCompression:InvalidInput");
    end

    function testValidityRejectionsUseStableIdentifier(testCase, invalidValidityCase)
        samples = zeros(500, 4);
        testCase.verifyError( ...
            @() radardemo.rangeCompression.processPri( ...
            samples, invalidValidityCase.valid, struct("rangeOriginM", 0)), ...
            "radardemo:rangeCompression:InvalidValidity");
    end

    function testConfigurationRejectionsUseStableIdentifier( ...
            testCase, invalidConfigurationCase)
        samples = zeros(500, 4);
        testCase.verifyError( ...
            @() radardemo.rangeCompression.processPri( ...
            samples, true(size(samples)), invalidConfigurationCase.configuration), ...
            "radardemo:rangeCompression:InvalidConfiguration");
    end

    function testPublicSignatureHasNoOptionalInputs(testCase)
        testCase.verifyEqual(nargin("radardemo.rangeCompression.processPri"), 3);
        testCase.verifyEqual(nargout("radardemo.rangeCompression.processPri"), 2);
    end
end

methods (Static, Access=private)
    function samples = makeSamples(sampleCount, streamCount)
        sampleIndex = (0:sampleCount - 1).';
        streamIndex = 1:streamCount;
        samples = complex( ...
            sin(sampleIndex / 19 + streamIndex / 7), ...
            cos(sampleIndex / 31 - streamIndex / 11));
    end

    function [expected, expectedValid] = directOracle(samples, inputValid)
        sampleCount = size(samples, 1);
        streamCount = size(samples, 2);
        referenceLength = 500;
        sampleRateHz = 12.5e6;
        bandwidthHz = 10e6;
        referenceTime = (0:referenceLength - 1).' / sampleRateHz;
        referencePhase = 2 * pi * (-bandwidthHz * referenceTime / 2 + ...
            bandwidthHz * referenceTime.^2 / (2 * 40e-6));
        conjugateReference = exp(-1i * referencePhase);
        expected = complex(zeros(sampleCount, streamCount));
        expectedValid = false(sampleCount, streamCount);
        for lag = 0:sampleCount - referenceLength
            for stream = 1:streamCount
                if all(inputValid(lag + 1:lag + referenceLength, stream))
                    expected(lag + 1, stream) = sum( ...
                        samples(lag + 1:lag + referenceLength, stream) .* ...
                        conjugateReference) / referenceLength;
                    expectedValid(lag + 1, stream) = true;
                end
            end
        end
    end

    function spacingM = rangeSpacingM()
        spacingM = 299792458 / (2 * 12.5e6);
    end
end
end