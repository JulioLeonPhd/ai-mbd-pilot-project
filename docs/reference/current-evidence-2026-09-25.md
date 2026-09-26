# Historical evidence snapshot — 25 September 2026

This is a dated snapshot of previously recorded evidence and replay details. It
does not describe current status; see [CURRENT.md](../../CURRENT.md).

## Last verified result

WP4/G2 Phase 1 documentation consolidation was independently validated and
committed in `da1e301`. Phase 2 numerical-fixture architecture is complete and
root-approved. Phase 3 implementation and precommit validation are complete;
the durable ledger is [the WP4/G2 recovery plan](../plans/wp4-g2-recovery-plan-2026-09-21.md).
Independent Phase 4 validation passed 54/54 strict manifest rows with
provenance, all 54 tests, timing and full-CPI streaming checks, and a clean
MATLAB Code Analyzer run. Phase 5 independent document review and the Phase 6
root gate passed; G2 is accepted. Issue #3 remains open for checker provenance
hardening; the current source/evidence pair was verified against Git and
deterministic replay.

On 2026-09-19, WP3 was independently accepted. The current checker passes 18
Python tests and 30 executable manifest rows. Ruff check/format, Markdown lint,
and `git diff --check` pass. Independent deep validation passed 24 semantic
probes plus malformed-input probes, with no implementation errors. The
normative cluster contract also passed independent semantic review.

The MATLAB checks recorded below are historical evidence from earlier work; they
were not rerun in this repair cycle. See the WP3 checker and manifest under
`contracts/wp3/`.

On 2026-09-14, WP2 completed and revised G1 passed for the bounded analytic and
ideal simulation candidate in [ADR 0014][adr0014].
WP0/G0 and WP1 were previously reviewed. MATLAB MCP ran the tracked coverage,
streaming, ideal range-resolution, and ideal angle studies; Code Analyzer found
no errors or warnings. Independent numerical and document reviews found no
unresolved errors. The revised G1 evidence is the [study](../../evidence/radar_v1_revised_g1_study.m)
and [results](../../evidence/radar_v1_revised_g1_results.json). The [V1 plan](../plans/radar-matlab-v1.md)
remains the work package source of truth.

WP3 now has accepted interface semantics for the five envelopes, canonical
examples, an architecture channel-map visual, a clock-epoch glossary entry,
replay provenance, and ignored/LFS vector storage rules: [data contracts](../contracts/radar-v1-data-contracts.md),
[architecture](../architecture/architecture.md), and [WP3 examples](../../contracts/wp3/examples/).
[The five-PRF decision and reopened CPI pulse-count rationale](../adr/0016-retain-five-prfs-and-reopen-cpi-pulse-count.md)
are recorded in ADR 0016. Phase 4 verified the frozen clustering seam and
schedule; downstream WP6e may still reject the approach and reopen G2. The
schedule is `[22,25,28,32,35]` usable pulses with 151
records, 150 MHz integer ticks, transition gap `106872`, total `10553388`
ticks, cap `10597950`, margin `44562`, midpoint offset `5276694`, 2.849920 ms
transitions, 70.355920 ms total, and 0.297080 ms margin.
Clustering is frozen as
one-cell Chebyshev adjacency within a look only, with no edge wrap, invalid
bridging, or cross-look deduplication; WP6e selects the ambiguity order and
method.
WP3 is independently accepted. WP4/G2 Phase 0 is frozen by
[ADR 0018](../adr/0018-freeze-wp4-g2-phase0-contract.md): integer-tick
schedule, DDC budget, receive dimensions, fusion, and clustering seams are
accepted as contracts.
WP4 Phase 4 now has 54/54 strict manifest rows with provenance, 54 passing
`matlab.unittest` methods, and clean MATLAB Code Analyzer results. Independent
validation confirmed guarded leading-edge timing on delay-compensated output
timestamps with 372 ADC-tick delay and raw/aligned margins 54/46/40 ticks.
The schedule has 151 records, five priming records, and 142 usable records.
Full-CPI DDC evidence covers one channel, 10,553,388 ticks, 150 PRI/transition
boundaries, and 2,189 chunks. It compares 19,480 observed output samples /
timestamps selected across startup, end, and boundary observation windows;
maximum absolute complex output-sample discrepancy against independent direct
convolution was `1.5e-15`. The zero-input fixture separately checks 64-channel
shape. This does not establish complete FIR precursor/waveform retention or detection
performance. Issues #4/#5 are closed; issue #3 tracks the checker limitation on
synthetic 40-hex revisions. Git verified the committed source/evidence pair.
The production-like floating-point reference is split between `src/+radardemo/`
domain modules and `contracts/wp4/` generator, oracle, and adapter code; the
test class is `tests/wp4/TestWp4Fixtures.m`. G2 passed the Phase 6 root gate.

The JSON subset, MAT example, MATLAB Code Analyzer, Ruff, Markdown lint, and
Mermaid render checks passed. Independent documentation and code reviews found
no unresolved errors, with a coverage warning retained for incomplete fixture
coverage.

## Active gate

Revised G1 passed for the bounded analytic and ideal candidate. WP3 is
independently accepted. WP4 Phases 4, 5, and 6 passed; G2 is accepted for the
WP3 data contracts and the frozen WP4 DSP/timing evidence. Downstream WP6e may
still reject the schedule and reopen G2 through a recorded decision.

## Blockers and retained risks

Authenticated `gh` access works outside the sandbox. The
[issue drafts](../plans/radar-matlab-v1-issue-drafts.md) are ready
but have not been published; issue publication does not block technical work.

Revised G1 adopted an analytic and ideal simulation baseline, not verified DUT,
hardware, or real-time performance. Phase 4 verified the 151-record schedule,
priming, timing margins, and post-CFAR 3-of-5 fusion. The timing evidence does
not establish full FIR precursor/waveform retention or detection performance;
downstream WP6e may reject the schedule and reopen G2. The 128-pulse setting
remains reopened by ADR 0016. The revised 10 MHz waveform and DDC rate claims
had bounded G1 analytic checks; Phase 4 additionally verified finite-filter
response, alias rejection, and one-channel streaming. Hardware and system
performance remain future measurements. The noisy multi-target ambiguity
method remains WP6e study work. Sampled end-to-end 50 m separation,
noisy angle accuracy and detection performance remain downstream measurements,
not V1 gates.
The ±45° sector and one-second update are provisional. The V1 ideal input is a
band-limited 45–55 MHz ADC input centered at 50 MHz with a 150 MS/s ADC; ENOB
and jitter are downstream sensitivity studies. The MVP generator emits direct ADC-rate
vectors without sampling RF or modeling analog downconversion; coherent phase
uses the exact ADR 0015 carrier invariant.

## Next ready packages

- Harden manifest revision provenance as tracked in issue #3. The current
  source/evidence pair at `0fe89d45` / `9675b2f2` was verified against Git and
  deterministic replay; its manifest `CreatedUtc` is `2026-09-24T13:56:08Z`.
- Keep the ambiguity-resolution candidate open for WP6e; do not freeze its
  order or method at G2.

## Session handoff

The detailed continuation note is [the WP4/G2 recovery plan](../plans/wp4-g2-recovery-plan-2026-09-21.md).

The accepted receive-processing decision is recorded in [ADR 0017](../adr/0017-adopt-v1-commanded-look-receive-processing-and-g2-schedule.md):
64 channels remain through DDC, commanded-azimuth beamforming sums 16 elements
per elevation row to four streams, and range/Doppler operate on those four
streams. The documentation bundle has passed independent semantic review.

Do not redo the completed documentation or WP3 repairs. The latest independent
WP3 result is the authoritative continuation point: WP3 is accepted with no
unresolved implementation errors. WP4 Phase 4 passed, Phase 5 passed deep
document review, and the Phase 6 root gate accepted G2. Issue #3 remains a
tracked checker-hardening task for future evidence.

### Current WP4 regenerated evidence replay

From the repository root, in MATLAB:

```matlab
repoRoot = pwd;
addpath(fullfile(repoRoot, "src"));
addpath(fullfile(repoRoot, "contracts", "wp4"));
R = "0fe89d45fa20a9f0f68ae6908855dbc61835b083";
createdUtc = "2026-09-24T13:56:08Z";
tmp = string(tempname);
generateWp4Fixtures(tmp, struct("FixtureScope", "acceptance-evidence", ...
    "GeneratorRevision", R, "GeneratorVersion", "wp4gen-1.0.0", ...
    "CreatedUtc", createdUtc));
tmpManifest = fullfile(tmp, "fixture-manifest.json");
tmpOptions = struct("FixtureRoot", tmp, "StrictTraceability", true);
tmpReport = checkWp4Fixtures(tmpManifest, tmpOptions);
trackedRoot = fullfile(repoRoot, "contracts", "wp4", "fixtures");
trackedManifest = fullfile(repoRoot, "contracts", "wp4", ...
    "fixture-manifest.json");
trackedOptions = struct("FixtureRoot", trackedRoot, ...
    "StrictTraceability", true);
trackedReport = checkWp4Fixtures(trackedManifest, trackedOptions);
assert(tmpReport.passed && tmpReport.provenanceValid, ...
    "Temporary regenerated fixture check failed.");
assert(trackedReport.passed && trackedReport.provenanceValid, ...
    "Committed fixture check failed.");
tempManifestData = jsondecode(fileread(tmpManifest));
trackedManifestData = jsondecode(fileread(trackedManifest));
assert(isequaln(tempManifestData, trackedManifestData), ...
    "Temporary and committed manifests differ.");
artifactNames = unique(string({tempManifestData.fixtures.artifact}));
artifactNames = artifactNames(strlength(artifactNames) > 0);
assert(numel(artifactNames) == 23, "Expected 23 physical artifacts.");
for k = 1:numel(artifactNames)
    artifact = artifactNames(k);
    [~, ~, extension] = fileparts(artifact);
    tempPath = fullfile(tmp, artifact);
    trackedPath = fullfile(trackedRoot, artifact);
    if strcmp(extension, ".json")
        tempData = jsondecode(fileread(tempPath));
        trackedData = jsondecode(fileread(trackedPath));
    else
        tempData = load(tempPath);
        trackedData = load(trackedPath);
    end
    assert(isequaln(tempData, trackedData), ...
        "Regenerated artifact differs: " + artifact);
end
testResults = runtests(fullfile(repoRoot, "tests", "wp4", ...
    "TestWp4Fixtures.m"));
assert(numel(testResults) == 54 && all([testResults.Passed]), ...
    "WP4 tests failed or did not return all 54 results.");
```

The committed generator source revision is pinned at
`0fe89d45fa20a9f0f68ae6908855dbc61835b083`; evidence is committed at
`9675b2f2de654d6701fc6001552c23318e0db87e`. Git independently verified the
pair. The manifest checker’s synthetic 40-hex revision limitation is tracked
as issue #3.
The timestamp is the source-commit timestamp selected for deterministic replay,
not the wall-clock generation time. Measured reference metrics are DDC ripple
`0.00067200911666936 dB`, stage-2 rejection `87.7676669047022 dB`, and full
cascade rejection `85.2548307898255 dB`.

## Evidence

- [Requirements](../requirements/radar-matlab-v1.md) and
  [V1 Pd/Pfa decision](../adr/0010-v1-pd-pfa-demonstration-gate.md)
- [WP2 feasibility report](../research/radar-v1-feasibility.md)
- [G1 simulation baseline decision](../adr/0011-adopt-v1-simulation-timing-baseline.md)
- [50 m separability and narrowband DDC candidate](../adr/0012-adopt-50m-separability-and-narrowband-ddc-candidate.md)
- [150 MS/s ADC, 50 MHz IF, and direct sampled stimulus](../adr/0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md)
- [Revised G1 analytic simulation baseline](../adr/0014-adopt-revised-v1-analytic-simulation-baseline.md)
- [Coverage script](../../evidence/radar_v1_coverage_study.m) and
  [result](../../evidence/radar_v1_coverage_results.json)
- [Streaming benchmark](../../evidence/streaming_feasibility.m) and
  [result](../../evidence/streaming_feasibility_results.json)
- [Range-resolution study](../../evidence/radar_v1_range_resolution_study.m) and
  [result](../../evidence/radar_v1_range_resolution_results.json)
- [Angle study](../../evidence/radar_v1_angle_feasibility.m) and
  [result](../../evidence/radar_v1_angle_feasibility_results.json)
- [WP3 data contracts](../contracts/radar-v1-data-contracts.md) and
  [examples/checker directory](../../contracts/wp3/examples/)
- [WP4/G2 recovery plan](../plans/wp4-g2-recovery-plan-2026-09-21.md)

[adr0014]: docs/adr/0014-adopt-revised-v1-analytic-simulation-baseline.md
