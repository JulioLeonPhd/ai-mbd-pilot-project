classdef TestAccumulateCpi < matlab.unittest.TestCase
%TESTACCUMULATECPI Verify the public CPI assembly boundary.

methods (TestClassSetup)
    function addSourcePath(testCase)
        root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
        testCase.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(root, "src")));
    end
end

methods (Test)
    function testShuffledBatchPreservesValuesAndTicks(testCase)
        [records, context] = TestAccumulateCpi.batch();
        actual = radardemo.pulseAccumulation.accumulateCpi(records([3 1 2]), context);
        expectedSamples = complex(zeros(501, 3, 4));
        expectedSamples(1:2, :, 1) = [0 0 31; 0 0 32] + 1i*[0 0 3; 0 0 3];
        expectedSamples(1:2, :, 2) = [13 0 33; 14 0 34] + 1i*[1 0 3; 1 0 3];
        expectedSamples(1:2, :, 3) = [15 0 35; 16 0 36] + 1i*[1 0 3; 1 0 3];
        expectedSamples(1:2, :, 4) = [17 0 37; 18 0 38] + 1i*[1 0 3; 1 0 3];
        expectedValid = false(501, 3, 4);
        expectedValid(1:2, [1 3], :) = true;
        expectedValid(2, 1, 1) = false;
        base = bitshift(uint64(1), 53) + uint64(3);
        testCase.verifyEqual(actual.rangeSamples, expectedSamples, AbsTol=0);
        testCase.verifyFalse(isreal(actual.rangeSamples));
        testCase.verifySize(actual.rangeSamples, [501 3 4]);
        testCase.verifyEqual(actual.valid, expectedValid);
        testCase.verifyClass(actual.valid, "logical");
        testCase.verifyEqual(actual.rangeBinCentersM, 100 + (0:500)'*(299792458/(2*12.5e6)), AbsTol=0);
        testCase.verifyEqual(actual.pulseStartTicks, [base; base+uint64(1); base+uint64(5)]);
        testCase.verifyClass(actual.pulseStartTicks, "uint64");
    end

    function testSingletonAtZeroTick(testCase)
        [records, context] = TestAccumulateCpi.batch();
        records = records(1);
        records.pulseStartTick = uint64(0);
        context.expectedPulseCount = 1;
        actual = radardemo.pulseAccumulation.accumulateCpi(records, context);
        testCase.verifySize(actual.rangeSamples, [501 1 4]);
        testCase.verifySize(actual.valid, [501 1 4]);
        testCase.verifyEqual(reshape(actual.rangeSamples, 501, 4), records.rangeSamples, AbsTol=0);
        testCase.verifyEqual(reshape(actual.valid, 501, 4), records.metadata.valid);
        testCase.verifyEqual(actual.rangeBinCentersM, records.metadata.rangeBinCentersM, AbsTol=0);
        testCase.verifyEqual(actual.pulseStartTicks, uint64(0));
    end

    function testSparseSamplesAndMask(testCase)
        [records, context] = TestAccumulateCpi.batch();
        records = records(3);
        records.slot = 1;
        context.expectedPulseCount = 1;
        expectedSamples = records.rangeSamples;
        expectedValid = records.metadata.valid;
        records.rangeSamples = sparse(expectedSamples);
        records.metadata.valid = sparse(expectedValid);
        actual = radardemo.pulseAccumulation.accumulateCpi(records, context);
        testCase.verifyEqual(reshape(actual.rangeSamples, 501, 4), expectedSamples, AbsTol=0);
        testCase.verifyFalse(isreal(actual.rangeSamples));
        testCase.verifyEqual(reshape(actual.valid, 501, 4), expectedValid);
        testCase.verifyClass(actual.valid, "logical");
    end

    function testAllInvalidComplexZeros(testCase)
        [records, context] = TestAccumulateCpi.batch();
        records = records(1);
        records.rangeSamples = complex(zeros(501, 4));
        records.metadata.valid = false(501, 4);
        context.expectedPulseCount = 1;
        actual = radardemo.pulseAccumulation.accumulateCpi(records, context);
        testCase.verifySize(actual.rangeSamples, [501 1 4]);
        testCase.verifyFalse(isreal(actual.rangeSamples));
        testCase.verifyEqual(actual.rangeSamples, complex(zeros(501, 1, 4)), AbsTol=0);
        testCase.verifyEqual(actual.valid, false(501, 1, 4));
    end

    function testContextRejections(testCase)
        [records, context] = TestAccumulateCpi.batch();
        id = "radardemo:pulseAccumulation:InvalidContext";
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(records, 1), id);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(records, rmfield(context, "prfNominalHz")), id);
        bad = context; bad.extra = 1;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(records, bad), id);
        bad = context; bad.expectedPulseCount = 1.5;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(records, bad), id);
        bad = context; bad.azimuthLookIndex = 0;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(records, bad), id);
        bad = context; bad.prfNominalHz = Inf;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(records, bad), id);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi([], bad), id);
    end

    function testSlotAndTickRejections(testCase)
        [records, context] = TestAccumulateCpi.batch();
        id = "radardemo:pulseAccumulation:InvalidSlotsOrTicks";
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi([], context), id);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(records(1:2), context), id);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(rmfield(records, "slot"), context), id);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(rmfield(records, "pulseStartTick"), context), id);
        bad = records; bad(3).slot = 2;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(3).slot = 4;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(3).slot = single(3);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).pulseStartTick = double(bad(2).pulseStartTick);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).pulseStartTick = bad(1).pulseStartTick;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad([3 1 2]), context), id);
        bad = records; bad(3).pulseStartTick = bad(1).pulseStartTick;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
    end

    function testRangeRejections(testCase)
        [records, context] = TestAccumulateCpi.batch();
        id = "radardemo:pulseAccumulation:IncompatibleRangeResults";
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(rmfield(records, "rangeSamples"), context), id);
        bad = records; bad(2).rangeSamples = real(bad(2).rangeSamples);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).rangeSamples(1) = NaN;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).rangeSamples = complex(zeros(2, 3));
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).metadata.valid = double(bad(2).metadata.valid);
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).metadata = rmfield(bad(2).metadata, "valid");
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).metadata.rangeBinCentersM(2) = Inf;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(2).metadata.rangeBinCentersM = bad(2).metadata.rangeBinCentersM';
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
        bad = records; bad(3).metadata.rangeBinCentersM(2) = 113;
        testCase.verifyError(@() radardemo.pulseAccumulation.accumulateCpi(bad, context), id);
    end

    function testLateMismatchLeavesCallerOutputUnchanged(testCase)
        [records, context] = TestAccumulateCpi.batch();
        records(3).metadata.rangeBinCentersM(2) = 113;
        sentinel = "unchanged";
        output = sentinel;
        try
            output = radardemo.pulseAccumulation.accumulateCpi(records, context);
            testCase.assertFail("Expected a range mismatch error.");
        catch exception
            testCase.verifyEqual(string(exception.identifier), ...
                "radardemo:pulseAccumulation:IncompatibleRangeResults");
        end
        testCase.verifyEqual(output, sentinel);
    end
end

methods (Static, Access=private)
    function [records, context] = batch()
        base = bitshift(uint64(1), 53) + uint64(3);
        metadata = struct("valid", false(501, 4), ...
            "rangeBinCentersM", 100 + (0:500)'*(299792458/(2*12.5e6)));
        metadata.valid(1:2, :) = true;
        records = repmat(struct("slot", 1, "pulseStartTick", base, ...
            "rangeSamples", complex(zeros(501, 4)), "metadata", metadata), 1, 3);
        records(1).rangeSamples(1:2, :) = [0 13 15 17; 0 14 16 18] + 1i*[0 1 1 1; 0 1 1 1];
        records(1).metadata.valid(2, 1) = false;
        records(2).slot = 2;
        records(2).pulseStartTick = base + uint64(1);
        records(2).metadata.valid = false(501, 4);
        records(3).slot = 3;
        records(3).pulseStartTick = base + uint64(5);
        records(3).rangeSamples(1:2, :) = [31 33 35 37; 32 34 36 38] + 3i;
        context = struct("expectedPulseCount", 3, "azimuthLookIndex", 1, "prfNominalHz", 1000);
    end
end
end
