%[text] # Pulse Accumulation: One Scheduled CPI
%[text] Assemble synthetic per-PRI range results into one slow-time ensemble and see why a duplicate slot is rejected.
%%
%[text] ## 1. Purpose and prerequisites
%[text] Use MATLAB R2025a or newer with Base MATLAB. With the repository root as Current Folder, run `run("examples/runPulseAccumulationWalkthrough.m")`, or open this file in Live Editor and select Run. All inputs are synthetic; no data, hardware, or toolboxes are required.
%[text] Range compression precedes this stateless batch call; each record contains its complex range samples and metadata unchanged. Accumulation only orders the records by scheduled slot. It performs no correlation, stream combining, interpolation, or Doppler processing. Re-running constructs a fresh batch; no signal state requires resetting.
repositoryRoot = pwd;
if ~isfolder(fullfile(repositoryRoot, "src"))
    repositoryRoot = fileparts(repositoryRoot);
end
%%
%[text] ## 2. Describe the declared context and synthetic records
%[text] The caller declares three scheduled pulses for commanded look 2 at nominal PRF 1000 Hz. Each record has two range-bin centers in metres and four consistently ordered elevation streams. Synthetic complex amplitudes are dimensionless, not calibrated measurements. Ticks count 150 MHz ADC clock periods from the radar clock epoch.
context = struct("expectedPulseCount", 3, "azimuthLookIndex", 2, "prfNominalHz", 1000);
metadata = struct("valid", true(2, 4), "rangeBinCentersM", [100; 112]);
records = repmat(struct("slot", 1, "pulseStartTick", uint64(0), ...
    "rangeSamples", complex(zeros(2, 4)), "metadata", metadata), 1, 3);
records(1).rangeSamples = complex([0 13 15 17; 0 14 16 18], [0 1 1 1; 0 1 1 1]);
records(1).metadata.valid(2, 1) = false;
records(2).slot = 2;
records(2).pulseStartTick = uint64(150000);
records(2).rangeSamples = complex([21 23 25 27; 22 24 26 28], 2*ones(2, 4));
records(2).metadata.valid = false(2, 4);
records(3).slot = 3;
records(3).pulseStartTick = uint64(310000);
records(3).rangeSamples = complex([31 33 35 37; 32 34 36 38], 3*ones(2, 4));
arrival = records([3 1 2]);
%[text] The arrival sequence is 3, 1, 2, but the expected output pulse axis is 1, 2, 3. In stream 1, slot 1 contains a valid zero at 100 m and an invalid zero at 112 m. Slot 2 is present even though its whole mask is false.
%%
%[text] ## 3. Assemble and inspect the result
%[text] The public call accepts a struct vector of exactly one record per slot and a scalar context. It validates context, slot coverage and increasing source ticks before checking the finite complex samples, matching logical masks and exactly equal range grids. The helper only manages the source path around that public call.
ensemble = accumulateWithRepositoryPath(repositoryRoot, arrival, context);
disp(ensemble.rangeSamples(:, :, 1))
disp(ensemble.valid(:, :, 1))
disp(ensemble.rangeBinCentersM)
disp(ensemble.pulseStartTicks)
%[text] Samples and masks have axes range bin, pulse, elevation, here size 2-by-3-by-4. The displayed stream 1 rows correspond to 100 m and 112 m, and its columns should be slots 1, 2, 3: the first row is 0, 21+2i, 31+3i. The first two values in the first column are both zero, but their mask entries are true and false respectively. The range vector is unchanged and ticks are returned as a uint64 column in scheduled order.
%%
%[text] ## 4. Reject a duplicate slot
%[text] Changing slot 3 to slot 2 leaves the record count at three but duplicates one scheduled slot and omits another. The public call should reject the whole batch with `radardemo:pulseAccumulation:InvalidSlotsOrTicks`; no partial ensemble is returned.
rejected = arrival;
rejected(1).slot = 2;
try
    accumulateWithRepositoryPath(repositoryRoot, rejected, context);
    error("radardemo:walkthrough:ExpectedRejection", "The duplicate slot was not rejected.");
catch exception
    if ~strcmp(exception.identifier, "radardemo:pulseAccumulation:InvalidSlotsOrTicks")
        rethrow(exception)
    end
    disp(string(exception.identifier))
end
%%
%[text] ## 5. Timing and evidence limits
%[text] The returned ticks are 0, 150000 and 310000: their gaps are 150000 and 160000 ticks. They increase but are not uniform. Nominal PRF does not establish the configured integer PRI tick count, and successful accumulation does not establish uniform-spacing Doppler readiness. The caller must check exact spacing against that configured count and establish CPI, look, PRF and source membership; consistent stream meanings are also caller responsibilities.
%[text] This walkthrough illustrates the contract, not independent correctness evidence, receiver integration or V1 gate acceptance. The separate `tests/pulseAccumulation/TestAccumulateCpi.m` suite exercises the public boundary; this script does not run it.
%%
%[text] ## 6. Local helper
%[text] This walkthrough helper temporarily adds the repository `src` directory, calls the public API, and restores the original MATLAB path on return or error. It does not implement the assembly algorithm.
function ensemble = accumulateWithRepositoryPath(root, records, context)
originalPath = path;
restorePath = onCleanup(@() path(originalPath));
addpath(fullfile(root, "src"));
ensemble = radardemo.pulseAccumulation.accumulateCpi(records, context);
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
