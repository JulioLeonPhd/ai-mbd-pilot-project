classdef TestDdcWalkthrough < matlab.unittest.TestCase
%TESTDDCWALKTHROUGH Check the one-PRI lesson and preserved full-scan example.

methods (TestClassSetup)
    function addSourcePath(testCase)
        repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
        testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
            fullfile(repositoryRoot, "src")));
    end
end

methods (Test)
    function testAcademicPriAndFullScanCheck(testCase)
        repositoryRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
        existingFigures = findall(groot, "Type", "figure");
        testCase.addTeardown(@() closeNewFigures(existingFigures));
        fullScanOutputDirectory = tempname;
        testCase.addTeardown(@() removeTemporaryDirectory( ...
            fullScanOutputDirectory));

        run(fullfile(repositoryRoot, "examples", "runDdcWalkthrough.m"));

        testCase.verifyEqual(startTick, 0);
        testCase.verifyEqual(sampleCount, 88236);
        testCase.verifyClass(adcPriSamples, "int16");
        testCase.verifySize(adcPriSamples, [88236, 1]);
        testCase.verifyEqual(adcPriSamples(1), int16(21500));
        testCase.verifySize(output, [7353, 1]);
        testCase.verifyFalse(isreal(output));
        testCase.verifyEqual( ...
            [metadata.groupDelayInputSamples, metadata.groupDelayOutputSamples, ...
            metadata.startupInputSamples, metadata.startupOutputSamples], ...
            [372, 31, 744, 62]);

        repeatedOutput = radardemo.ddc.processFrame(adcPriDouble, design);
        testCase.verifyEqual(repeatedOutput, output);

        steadyOutput = output(metadata.startupOutputSamples + 1:size(output, 1));
        fftLength = 2 ^ nextpow2(numel(steadyOutput));
        outputSpectrum = fftshift(fft(steadyOutput, fftLength)) / ...
            numel(steadyOutput);
        outputFrequencyHz = (-fftLength / 2:fftLength / 2 - 1).' * ...
            design.outputRateHz / fftLength;
        [~, peakIndex] = max(abs(outputSpectrum));
        testCase.verifyLessThanOrEqual( ...
            abs(outputFrequencyHz(peakIndex) - 1e6), 2e3);

        fullScan = runDdcScanCheck(fullScanOutputDirectory);
        testCase.verifyEqual( ...
            [fullScan.physicalPriCallCount, fullScan.skippedTransitionCount, ...
            fullScan.totalScanTicks, fullScan.outputSampleCount], ...
            [147, 4, 10553388, 843825]);
        expectedFigureNames = [ ...
            "ddc-stage1-alias-response.png", ...
            "ddc-stage2-alias-response.png", ...
            "ddc-cascade-alias-response.png", ...
            "ddc-passband-zoom.png"];
        testCase.verifyTrue(all(isfile(fullfile( ...
            fullScanOutputDirectory, expectedFigureNames))));
    end
end
end

function closeNewFigures(existingFigures)
newFigures = setdiff(findall(groot, "Type", "figure"), existingFigures);
close(newFigures);
end

function removeTemporaryDirectory(folder)
if isfolder(folder)
    rmdir(folder, "s");
end
end
