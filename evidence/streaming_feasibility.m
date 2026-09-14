%% Streaming feasibility benchmark for one representative radar dwell
% This benchmark measures incremental v7.3 MAT-file I/O for full-entropy ADC
% samples and a bounded complex-double processing proxy. It is not a
% production stimulus generator and does not prove the full 24 GB vector or
% real-time hardware throughput.

clearvars

scriptFolder = fileparts(mfilename("fullpath"));
resultsPath = fullfile(scriptFolder, "streaming_feasibility_results.json");
temporaryMatPath = [tempname(tempdir) '.mat'];
cleanup = onCleanup(@() cleanupTemporaryFile(temporaryMatPath));

result = createInitialResult(temporaryMatPath, resultsPath);
stage = "initialization";

try
    stage = "configure benchmark";
    numberOfFastTimeSamples = 367648;
    numberOfChannels = 64;
    numberOfPulses = 128;
    randomSeed = uint32(20260914);
    pulseRepetitionFrequencyHz = 1700;
    sampleRateHz = 625e6;
    intermediateFrequencyHz = 156.25e6;
    decimationFactor = 2;
    candidateRequestedPrfHz = [1700, 1900, 2150, 2450, 2700];
    candidatePriSampleCounts = 2 * round(sampleRateHz ./ candidateRequestedPrfHz / 2);
    candidatePriSeconds = candidatePriSampleCounts / sampleRateHz;
    candidateActualPrfHz = 1 ./ candidatePriSeconds;
    radarConfigurationVersion = "radar-config-v1.0.0";
    targetScenarioVersion = "target-scenario-v1.0.0";

    result.configuration = struct( ...
        "numberOfFastTimeSamples", numberOfFastTimeSamples, ...
        "numberOfChannels", numberOfChannels, ...
        "numberOfPulses", numberOfPulses, ...
        "randomSeed", randomSeed, ...
        "pulseRepetitionFrequencyHz", pulseRepetitionFrequencyHz, ...
        "sampleRateHz", sampleRateHz, ...
        "intermediateFrequencyHz", intermediateFrequencyHz, ...
        "decimationFactor", decimationFactor, ...
        "radarConfigurationVersion", radarConfigurationVersion, ...
        "targetScenarioVersion", targetScenarioVersion);
    candidateFivePrfAcquisitionSeconds = numberOfPulses * sum(candidatePriSeconds);
    result.candidateTiming = struct( ...
        "requestedPrfHz", candidateRequestedPrfHz, ...
        "actualPrfHz", candidateActualPrfHz, ...
        "priSampleCounts", candidatePriSampleCounts, ...
        "usablePulsesPerPrf", numberOfPulses, ...
        "fivePrfAcquisitionSeconds", candidateFivePrfAcquisitionSeconds, ...
        "scope", "128 usable returns per PRF; excludes priming and quiet gaps");
    result.scope = "Representative 1700 Hz pulse slab dwell; full-entropy proxy only";
    result.dwellDurationSeconds = numberOfPulses / pulseRepetitionFrequencyHz;
    result.rawDwellBytes = double(numberOfFastTimeSamples) * ...
        double(numberOfChannels) * double(numberOfPulses) * 2;

    stage = "prepare deterministic slab";
    sampleIndex = int64((0:numberOfFastTimeSamples - 1).');
    writeStream = RandStream('mt19937ar', 'Seed', randomSeed);
    adc_prf01 = zeros(numberOfFastTimeSamples, numberOfChannels, 2, "int16");
    adc_prf01(:, :, 1) = createHighEntropySlab( ...
        writeStream, numberOfFastTimeSamples, numberOfChannels);
    adc_prf01(:, :, 2) = createHighEntropySlab( ...
        writeStream, numberOfFastTimeSamples, numberOfChannels);
    writeTimer = tic;
    save(temporaryMatPath, "adc_prf01", "radarConfigurationVersion", ...
        "targetScenarioVersion", "-v7.3");
    clear adc_prf01
    matFile = matfile(temporaryMatPath, "Writable", true);

    stage = "write pulse slabs";
    maxRssKb = NaN;
    rssSampleCount = 0;
    rssSamplingFailures = 0;
    for pulseIndex = 3:numberOfPulses
        slab = createHighEntropySlab( ...
            writeStream, numberOfFastTimeSamples, numberOfChannels);
        matFile.adc_prf01(:, :, pulseIndex) = slab;
        [rssKb, rssIsValid] = sampleResidentSetKilobytes();
        [maxRssKb, rssSampleCount, rssSamplingFailures] = updateRssSummary( ...
            maxRssKb, rssSampleCount, rssSamplingFailures, rssKb, rssIsValid);
    end
    result.timings.writeSeconds = toc(writeTimer);

    stage = "inspect MAT file";
    matFileInfo = whos("-file", temporaryMatPath);
    adcInfo = matFileInfo(strcmp({matFileInfo.name}, "adc_prf01"));
    if isempty(adcInfo)
        error("streaming_feasibility:MissingVariable", ...
            "The MAT-file does not contain adc_prf01.");
    end
    if ~isequal(adcInfo.size, [numberOfFastTimeSamples, numberOfChannels, numberOfPulses])
        error("streaming_feasibility:UnexpectedDimensions", ...
            "adc_prf01 dimensions do not match the benchmark contract.");
    end
    matFileBytes = dir(temporaryMatPath);
    result.matFileBytes = double(matFileBytes.bytes);
    result.compressionRatio = result.matFileBytes / result.rawDwellBytes;
    if result.matFileBytes <= 5e9
        error("streaming_feasibility:InsufficientEntropy", ...
            "Full-entropy MAT-file is unexpectedly smaller than 5 GB.");
    end
    result.matVariable = struct( ...
        "name", "adc_prf01", ...
        "class", string(adcInfo.class), ...
        "size", adcInfo.size);
    result.io = struct( ...
        "writeSlabShape", [numberOfFastTimeSamples, numberOfChannels], ...
        "readSlabShape", [numberOfFastTimeSamples, numberOfChannels], ...
        "initializationSlabCount", 2, ...
        "incrementalPulseWriteCount", numberOfPulses - 2, ...
        "pulseReadCount", numberOfPulses, ...
        "initializationNote", "v7.3 seed stores two slabs because MATLAB drops trailing singleton dimensions");

    stage = "read and process pulse slabs";
    readStream = RandStream('mt19937ar', 'Seed', randomSeed);
    localOscillator = exp(-1i * 2 * pi * intermediateFrequencyHz / sampleRateHz * ...
        double(sampleIndex));
    beamWeights = ones(numberOfChannels, 1) / numberOfChannels;
    numberOfDecimatedSamples = ceil(numberOfFastTimeSamples / decimationFactor);
    maxSpectrumMagnitude = 0;
    exactRoundTrip = true;
    maximumAbsoluteSampleError = 0;
    mismatchedPulseCount = 0;
    processTimer = tic;
    for pulseIndex = 1:numberOfPulses
        slab = matFile.adc_prf01(:, :, pulseIndex);
        expectedSlab = createHighEntropySlab( ...
            readStream, numberOfFastTimeSamples, numberOfChannels);
        pulseMatches = isequal(slab, expectedSlab);
        exactRoundTrip = exactRoundTrip && pulseMatches;
        if ~pulseMatches
            mismatchedPulseCount = mismatchedPulseCount + 1;
            sampleError = abs(double(slab) - double(expectedSlab));
            maximumAbsoluteSampleError = max(maximumAbsoluteSampleError, max(sampleError(:)));
        end

        normalizedSlab = double(slab) / 32768;
        mixedSlab = normalizedSlab .* localOscillator;
        decimatedSlab = mixedSlab(1:decimationFactor:end, :);
        beam = decimatedSlab * beamWeights;
        spectrum = fft(beam, numberOfDecimatedSamples, 1);
        maxSpectrumMagnitude = max(maxSpectrumMagnitude, max(abs(spectrum)));
        [rssKb, rssIsValid] = sampleResidentSetKilobytes();
        [maxRssKb, rssSampleCount, rssSamplingFailures] = updateRssSummary( ...
            maxRssKb, rssSampleCount, rssSamplingFailures, rssKb, rssIsValid);
    end
    result.timings.readProcessSeconds = toc(processTimer);
    result.timings.totalSeconds = result.timings.writeSeconds + ...
        result.timings.readProcessSeconds;
    result.timings.estimatedFiveDwellRuntimeSeconds = 5 * result.timings.totalSeconds;
    result.timings.estimatedFiveDwellRuntimeLabel = ...
        "Same-size linear 5x proxy for five identical representative dwells; not candidate five-PRF acquisition";
    result.timings.candidateFivePrfAcquisitionSeconds = candidateFivePrfAcquisitionSeconds;
    result.timings.processToRepresentativeDwellRatio = result.timings.readProcessSeconds / ...
        result.dwellDurationSeconds;

    result.roundTrip = struct( ...
        "exact", exactRoundTrip, ...
        "mismatchedPulseCount", mismatchedPulseCount, ...
        "maximumAbsoluteSampleError", maximumAbsoluteSampleError);
    result.processingProxy = struct( ...
        "description", "Offline complex-double DDC/decimate-by-2 and one-beam FFT performance proxy; not full DDC filtering or hardware throughput", ...
        "inputClass", "int16", ...
        "workingClass", "complex double", ...
        "decimatedFastTimeSamples", numberOfDecimatedSamples, ...
        "oneBeamChannelsCombined", numberOfChannels, ...
        "fftLength", numberOfDecimatedSamples, ...
        "maximumSpectrumMagnitude", maxSpectrumMagnitude);
    result.stimulus = struct( ...
        "generation", "Local mt19937ar RandStream per benchmark run", ...
        "globalRngModified", false, ...
        "samplesPerSlab", numberOfFastTimeSamples * numberOfChannels);
    result.rss = struct( ...
        "pid", feature("getpid"), ...
        "samplingCommand", "ps -o rss= -p <pid>", ...
        "maxSampledKilobytes", maxRssKb, ...
        "sampleCount", rssSampleCount, ...
        "samplingFailures", rssSamplingFailures);
    result.status = "passed";
    result.completedUtc = string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
    cleanupTemporaryFile(temporaryMatPath);
    result.cleanup = struct("temporaryMatPath", temporaryMatPath, ...
        "temporaryMatPresentAfterCleanup", isfile(temporaryMatPath));
    writeResultJson(resultsPath, result);
catch exception
    result.status = "failed";
    result.failure = struct( ...
        "stage", stage, ...
        "identifier", string(exception.identifier), ...
        "message", string(exception.message));
    cleanupTemporaryFile(temporaryMatPath);
    result.cleanup = struct("temporaryMatPath", temporaryMatPath, ...
        "temporaryMatPresentAfterCleanup", isfile(temporaryMatPath));
    result.completedUtc = string(datetime("now", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss'Z'"));
    writeResultJson(resultsPath, result);
    rethrow(exception)
end

clear cleanup

function result = createInitialResult(temporaryMatPath, resultsPath)
%CREATEINITIALRESULT Create the machine-readable benchmark result skeleton.
result = struct( ...
    "schemaVersion", "streaming-feasibility-v1", ...
    "status", "running", ...
    "temporaryMatPath", temporaryMatPath, ...
    "resultsPath", resultsPath, ...
    "matFileFormat", "-v7.3", ...
    "benchmarkScope", "Proxy benchmark; not a production generator", ...
    "failure", struct("stage", "", "identifier", "", "message", ""));
end

function slab = createHighEntropySlab(localStream, numberOfFastTimeSamples, numberOfChannels)
%CREATEHIGHENTROPYSLAB Generate one reproducible real int16 ADC slab.
slab = randi(localStream, [intmin('int16'), intmax('int16')], ...
    [numberOfFastTimeSamples, numberOfChannels], 'int16');
end

function [rssKb, isValid] = sampleResidentSetKilobytes()
%SAMPLERESIDENTSETKILOBYTES Read the MATLAB process RSS with ps.
processId = feature("getpid");
[commandStatus, commandOutput] = system(sprintf("ps -o rss= -p %d", processId));
rssKb = str2double(strtrim(commandOutput));
isValid = commandStatus == 0 && isfinite(rssKb);
if ~isValid
    rssKb = NaN;
end
end

function [maximumRssKb, sampleCount, failureCount] = updateRssSummary( ...
    maximumRssKb, sampleCount, failureCount, rssKb, isValid)
%UPDATERSSSUMMARY Update sampled process-memory measurements.
if isValid
    sampleCount = sampleCount + 1;
    if isnan(maximumRssKb) || rssKb > maximumRssKb
        maximumRssKb = rssKb;
    end
else
    failureCount = failureCount + 1;
end
end

function cleanupTemporaryFile(pathname)
%CLEANUPTEMPORARYFILE Remove the benchmark MAT-file if it exists.
if isfile(pathname)
    delete(pathname);
end
end

function writeResultJson(pathname, result)
%WRITERESULTJSON Write a compact machine-readable benchmark result.
fileId = fopen(pathname, "w");
if fileId < 0
    error("streaming_feasibility:ResultWriteFailed", ...
        "Unable to open result path for writing: %s", pathname);
end
fileCleanup = onCleanup(@() fclose(fileId));
jsonText = jsonencode(result);
fwrite(fileId, jsonText, "char");
end
