# Per-PRI DDC implementation plan

**Status:** ADR 0022 records accepted direction and confirmed 2026-10-02
Phase 0 contract. Julio explicitly authorized implementation 2026-10-02.
The prior `independent-pri-v1` implementation, scoped tests, full-scan
walkthrough, fixture-preservation audit, and independent numerical validation
passed at their recorded revision. The pinned DDC-002 replay is separate
historical continuous-state evidence.
Julio approved DDC walkthrough 2026-10-08. Issue 6 cascade
stopband-coverage blocker fixed and independently validated 2026-10-10; three
standards-warning categories resolved and independently validated 2026-10-11.
Julio accepted the architecture diagrams and authorized PR #17 commit, push,
and merge on 2026-10-26; see [current status](../../CURRENT.md) for the incomplete
full-branch review scope. Dated review entries below retain their historical status.
On 2026-10-14 Julio approved fixed factor-two compensation on the final
decimated output. The v2 fixture migration and MATLAB checks listed below
passed on 2026-10-15; independent MATLAB validation passed as recorded below.
Range-processing boundary next component review.

## Approved amplitude update (2026-10-14)

A real cosine with peak amplitude `A` yields complex output envelope `A/2`;
multiply the final decimated output by two to restore peak envelope amplitude,
subject to FIR gain and phase response and residual image. This preserves input
units, doubles noise amplitude, does not improve SNR, and makes no calibrated-
volts claim. FIR coefficients and response metrics, 372/31-sample group delay,
744/62-sample startup span, state, shapes, and API remain unchanged.

The approved per-PRI evidence profile changes from `independent-pri-v1`
version `1.0.0` to `independent-pri-v2` version `2.0.0`; schema is unchanged.
Only `ddc-pri.mat` migrates. All other fixtures, including
`ddc-response-pri.mat`, remain unchanged. The old profile remains replayable at
the pinned baseline revision. Prior v1 per-PRI versus continuous-helper
comparison measured `3.34852e-11` normalized error against the unchanged helper,
within the reviewed `5e-11` input-peak-normalized bound. The implemented v2
regression divides compensated PRI output by two before that helper, and the
current direct oracle includes factor two. Prior tests and evidence below remain
attributed to the old revision; the current v2 results are recorded separately
in the migration and verification section.

## `independent-pri-v2` migration and verification (2026-10-15)

Tracked `ddc-pri.mat` and its manifest record now identify
`independent-pri-v2` version `2.0.0`, scope `temporary-unit-evidence`, revision
`working-tree`, fixture SHA
`af4ed1be0ffe0db230d8e6f825014b8fd7bd7aae12940a286d155b1e4c6776f4`. Of 25
tracked fixture artifacts, only `ddc-pri.mat` changed; the other 24 remain
unchanged, including all 23 historical artifacts and `ddc-response-pri.mat`.

The DDC suite passed 40/40, the WP4 suite passed 56/56, and the walkthrough
passed 1/1. The full-scan check processed 147 physical PRIs, skipped four
transition gaps, and produced 843,825 output samples. Fresh and tracked strict
fixture checks each passed 56/56 with `provenanceValid=true`; the tracked check
used the fixture root on the corrected invocation. Code Analyzer returned no
issues for `processFrame.m`, `TestDdcPriProcessing.m`, `TestWp4Fixtures.m`,
`checkDdcPri.m`, `generateDdc.m`, and `buildManifest.m`. The live v2 analytic
check passed; the uncompensated v1 analytic
baseline failed with normalized error `0.500862525049793`, as expected. The
historical v1 comparison result remains separate from these v2 checks.

Independent MATLAB validation passed on 2026-10-15 with no unresolved errors.
The reviewer independently ran analytic and historical comparisons 2/2, WP4
per-PRI 1/1, and tracked strict fixtures 56/56 with `provenanceValid=true`, and
verified v2 profile identity and all 24 unchanged fixture artifacts. Full suite
and Code Analyzer results were reviewed from upstream evidence, not rerun.
Validation is limited to this temporary-unit evidence; it does not establish
human approval, end-to-end detection, hardware performance, or merge approval.

## Phase 0: confirmed contract (2026-10-02)

Julio confirmed `[output, metadata] = processFrame(adcPriSamples, design)`.
Input: one complete physical PRI, finite real `double` `[N,C]`; mixer, FIR,
and decimator state fresh, call-local. Calls order-independent.
Output: complex `[N/12,C]`, retaining every produced row including
startup. Do not append zeros, flush filters, or return tail. Metadata:
scalar double fields `inputSampleCount`, `outputSampleCount`,
`decimationFactor`, `groupDelayInputSamples`, `groupDelayOutputSamples`,
`startupInputSamples`, and `startupOutputSamples`. Group delay: 372 ADC
sample periods or 31 output sample periods; startup full-memory span: 744 ADC
sample periods or 62 output sample periods.

Caller selects physical PRI, supplies correctly sized, 12-tick-
aligned slice, handles identity and global timing (`startTick`/`timeEpoch`),
reconstructs timeline. Input preconditions; no public
continuation context or global timestamp in DDC API or metadata.
Trusted MVP requires no DDC rejection behavior for empty, incomplete,
or misaligned calls; waiver does not make malformed data valid PRI.
Convert stored `int16` to `double` per PRI. Preserve transition gaps
in timeline; never pass as physical PRI calls.

DDC sample-only, range/system agnostic. Caller/integration applies
group-delay compensation exactly once when assigning coordinates. Downstream
range processing owns complete-window validity: startup, blanking,
PRI-end truncation. No per-range validity masks returned by DDC.

Fixed design accepts finite positive sample rates only when intermediate
rate equals ADC rate divided by 3 and output rate equals intermediate
rate divided by 4, within floating-point rate tolerance. Inconsistent rates
rejected; `/3` and `/4` may not silently use mismatched rate chain.

For frozen 50 MHz mixer, 150 MHz ADC, PRI starts divisible by 12
ticks, local `n=0` mixing preserves global phase mathematically; large-global
and small-local floating exponent evaluation need not be bit-identical. No
generalized frequency/alignment equivalence claimed.

Narrow versioned evidence migration approved. Keep DDC-002 historical
and replayable at `58b3d3a80170d413aa88dd4408490e2056f49379`; do not relabel
old G2 evidence or bump unrelated global schema. Keep passband and alias
regressions. Independent oracle represents combined-FIR convolution with
retained no-tail outputs, not DUT zero extension. Independent numerical review
accepts unchanged `5e-11` input-peak-normalized bound for bounded
five-PRI comparison. Observed `3.34852e-11` maximum leaves `1.65148e-11`
margin; not bound for full-CPI, global-tick, or hardware behavior.
Keep exact-zero and inactive-channel invariants separate acceptance checks.
Compare historical continuous processing only for local raw offsets at least
744 ADC ticks; startup equivalence not required. Retain channel, isolation,
zero/impulse/chirp boundary, multitone/noise, shape, sample-metadata, caller-
time-mapping, and call-order coverage. Keep unit/oracle, full-scan, and
end-to-end claims distinct.

Pinned fixture byte hashes for the recorded prior implementation:
`ddc-streaming.mat`
`2979d3d0c68c1deacbe097a202b2b3a125b2d7fd6aba19ef842d76bb98d6c616` and
`ddc-design.mat`
`541d89c6f98d4f292a2e8ca4504537440b591cea7348859c44d04276e6ab9a0d`.

Existing arithmetic establishes delay 372 ADC ticks, full startup memory 744
ADC ticks, first gated raw tick 7128 with support 6384..7128, after
blanking ends at 6000. Supports first gated DDC sample only, not
full matched-filter window or end-to-end detection. No-tail PRI-end truncation
remains downstream validity limitation. 2026-10-02 explicit go authorizes
scoped MATLAB implementation.
Does not authorize deferred Simulink topology or execution choices.

## Historical `independent-pri-v1` implementation evidence and validation

Prior `independent-pri-v1` core MATLAB MCP suite: 32 passed, 0 failed, 0 incomplete,
7.73 seconds. Covers all five PRI lengths at one and 64 channels against
combined 745-tap FFT convolution oracle, boundary stimuli, call-order and
caller-time behavior, metadata and shape, inconsistent-rate rejection, and
cascade 12 MHz stage-1 cutoff witness, rejected at 0.79347008136 dB cascade
ripple. Oracle error normalized by peak input amplitude.
Combined-oracle tests: maximum input-peak-normalized error
`1.12962634928e-15` across all five PRI lengths at one and 64 channels.
Test helper per-PRI versus continuous-reference comparison, after full memory:
largest error `3.08285e-11` absolute, `3.34852e-11` normalized,
reference amplitudes `0.911` to `0.927`. Independent numerical
review accepts unchanged `5e-11` input-peak-normalized bound for this
bounded comparison, `1.65148e-11` margin. Not bound for
full-CPI, global-tick, or hardware behavior; remains separate from
pinned full-CPI DDC-002 replay.

Full-scan integration walkthrough smoke completed in 8.7 seconds.
Processed 147 physical PRIs (5 priming, 142 usable), skipped four 106872-tick
transition gaps, retained full 10,553,388-tick contiguous `int16` timeline,
processed 10,125,900 physical input samples, produced 843,825 output
samples. `cascade-peak-v1` response metrics: 0.00146437058836 dB
cascade ripple, 87.7676669047 dB stage-2 alias rejection, 85.2548307898 dB
full-cascade alias rejection. Full-scan integration evidence; not
runtime evidence for one-PRI teaching script. Independent fresh WP4
generation with strict traceability
passed all 56 rows, including seven new per-PRI cases. Independent WP4
MATLAB suite passed 56/56 in 83.4439 seconds; independent direct DDC tests
passed 32/32 in 10.6756 seconds. Tracked strict checker passed 56/56 with
valid provenance, explicitly including working-tree evidence under mixed
acceptance-evidence and temporary-unit-evidence scopes. Six corruption
probes (real/imaginary perturbations at 1e-12 for one- and 64-channel zero cases
and inactive channel) all rejected with `NUMERICAL_MISMATCH`. New MAT
witness hashes unchanged; all 23 historical fixture hashes, 54 original
manifest rows, original global manifest metadata preserved. Bounded
unit/oracle and full-scan observations, not end-to-end detection or
hardware evidence.

Reproduce targeted MATLAB unit suite and full-scan integration check from
repository root with MATLAB available. Scan runner remains separate
from one-PRI teaching script in `docs/examples/ddc-walkthrough.md`:

```matlab
repoRoot = pwd;
addpath(fullfile(repoRoot, "src"));
addpath(fullfile(repoRoot, "tests", "ddc"));
testResults = runtests(fullfile(repoRoot, "tests", "ddc"));
assertSuccess(testResults);
runDdcScanCheck(fullfile(tempdir, "ddc-pri-scan"));
```

Reproduce WP4 fresh-generation and strict-traceability check from
project root through MATLAB MCP. Generated evidence declares generator
revision `working-tree`; temporary evidence, does not replace
pinned DDC-002 profile:

```matlab
addpath(fullfile(pwd, "src"));
addpath(fullfile(pwd, "contracts", "wp4"));
fixtureRoot = tempname("/private/tmp");
mkdir(fixtureRoot);
generation = generateWp4Fixtures(string(fixtureRoot), struct( ...
    "GeneratorRevision", "working-tree", ...
    "CreatedUtc", "2026-10-02T20:22:43Z"));
checked = checkWp4Fixtures(string(generation.manifestPath), ...
    struct("StrictTraceability", true));
responseData = load(fullfile(fixtureRoot, "ddc-response-pri.mat"), "-mat");
responseDiagnostic = wp4oracle.checkDdc( ...
    responseData.ddcDesign, "cascade-peak-v1");
priData = load(fullfile(fixtureRoot, "ddc-pri.mat"), "-mat");
priDiagnostic = wp4oracle.checkDdcPri(priData.ddcPri);
assert(checked.passed && checked.provenanceValid);
assert(responseDiagnostic.accepted && priDiagnostic.accepted);
```

Code Analyzer: no findings across 5 core and 9 WP4 MATLAB source
files; two oracle-fix files reanalyzed, also no findings.
Four MATLAB code fences in walkthrough and plan extracted,
analyzed: zero findings. Tracked fixture integration/preservation audit
passed. Pinned DDC-002 replay passed strict 1/1 at revision
`58b3d3a80170d413aa88dd4408490e2056f49379`. Independent numerical validation
passed after exact-zero and inactive-channel invariants added to oracle,
verified by six corruption probes. Per-PRI witnesses use new profile
identifiers; do not relabel historical G2 evidence. Issue #3 provenance
hardening remains separate.

## `independent-pri-v1` implementation record

Prior implementation steps complete:

1. Preserve and pin old continuous-state witness and source revision at
   `58b3d3a80170d413aa88dd4408490e2056f49379`.
2. Make mixer, FIR, decimation state local to each complete PRI in
   `src/+radardemo/+ddc/processFrame.m`. Approved implementation removes
   `initializeState.m` and public continuation-state argument; does not
   silently accept legacy arguments.
3. Adapt WP4 path: slice and call only physical priming and usable
   PRIs. Preserve global timestamps and transition gaps. Keep `int16` storage
   compact; convert each selected PRI to `double` at call boundary.
   Full-scan integration runner: `tests/ddc/runDdcScanCheck.m`; current
   teaching entry point `examples/runDdcWalkthrough.m` demonstrates one aligned
   PRI.
4. Add independent per-PRI oracle; migrate WP4 generator, checker,
   adapter, test integration: `+wp4gen/generateDdc.m`,
   `+wp4gen/buildManifest.m`, `+wp4oracle/checkArtifact.m`,
   `+wp4oracle/checkDdc.m`, new `+wp4oracle/checkDdcPri.m`,
   `adaptWp4Draft1.m`, `generateWp4Fixtures.m`, `checkWp4Fixtures.m`,
   `fixture-manifest.json`, and `tests/wp4/TestWp4Fixtures.m`. Add
   `ddc-pri.mat` and `ddc-response-pri.mat` witnesses. Preserve unchanged
   historical `+wp4oracle/checkDdcStreaming.m` and `checkDdcZero.m` checkers;
   keep DDC-002 replayable at pinned baseline.
5. Add individual `/3` and `/4` and cascade alias-response plots, passband
   zoom, per-PRI state-reset loop diagram for full-scan integration
   evidence. One-PRI teaching script provides input/output spectra,
   startup, passband, alias observations. Prefer `gramm` where suitable;
   keep filter and decimator distinct diagram blocks. Three-phase/polyphase
   mixing remains later optimization candidate.
6. Targeted regression, MATLAB Code Analyzer, independent deep validation
   passed; Julio approved DDC walkthrough 2026-10-08; implementation
   review and merge-readiness work remain ongoing.

## Prior `independent-pri-v1` validated acceptance criteria

Prior `independent-pri-v1` evidence: independent numerical review accepts unchanged `5e-11` input-peak-
normalized tolerance for bounded five-PRI comparison. Measured
`3.34852e-11` maximum leaves `1.65148e-11` margin. Not
full-CPI, global-tick, or hardware error bound. Validation covered all five PRI
lengths, one and 64 channels, channel isolation, exact zero, first/last-sample
impulses, 40-microsecond boundary chirps, multitone and seeded noise, output
shape, sample-domain metadata, caller time mapping, call-order invariance.
Alignment and expected length remain caller preconditions in trusted MVP.
Repeated, reversed, shuffled calls produce identical per-PRI results and
metadata.

Historical continuous reference compared only at local raw offsets
`>= 744` ADC sample periods (zero-based output index 62), after full cascade
memory; startup equivalence not required. Output has no padded tail.
Downstream range processing owns startup, blanking, PRI-end window validity.
Filter passband and alias-rejection regressions passed. Unit/oracle, full-scan,
end-to-end detection evidence remain distinct scopes.

## Merge-readiness review — 2026-10-08

Root reviewed `main` at `e76eb62dbe24dd03174187f224e409fdaad3e643` through
`10b6456794bf8f952c2ce3989791b9e3e8c8357d`. MATLAB source remained
unchanged during fresh checks.
Specification review found merge blocker: issue 6 requires cascade alias
rejection over approved stopband `|f| >= 6.25 MHz` through 25 MHz on
1 kHz grid, but `measureResponse` and `checkDdc` measure nonprincipal cascade
branches only over output `|f| <= 5 MHz`. Omits required stopband slices,
including 6.25–7.5 MHz. Update both metrics, add boundary regression,
repeat independent validation before merge. Bounded root diagnostic
measured 87.7679126746 dB direct principal-cascade attenuation in
6.25–7.5 MHz interval. Default filters pass bounded omitted-interval
diagnostic; finding concerns acceptance coverage,
not demonstrated filter failure.

Independent standards review: three warning categories: `checkCase`
in `checkDdcPri` and `saveBranchFigure` in `runDdcScanCheck` each have nine
inputs against documented six-input limit; `generateDdc` extends design
struct outside creating function; two stimulus helpers in `checkDdcPri`
avoidably nested. Resolve or explicitly disposition warnings.
Independent specification review reported alias-metric error above.
Independent reviews separate from Julio's 2026-10-08 walkthrough approval,
which does not approve merge or waive findings.

Root-run MATLAB MCP checks passed on source unchanged during
fresh checks: `TestDdcPriProcessing`
(32/0/0), `TestDdcWalkthrough` (1/0/0; 147 physical PRIs and 4 skipped gaps),
`TestWp4Fixtures` (56/0/0), Code Analyzer on all 29 existing changed
MATLAB files, no issues. Deleted `initializeState.m` excluded.
Strict checker passed 56/56; provenance-format consistency, WP3 conformance
(30 rows), Ruff, Pyright, handoff checks, Markdown lint also passed.
Historical fixture files byte-identical to `main`; original manifest
provenance preserved; derived test-method count 56.
DDC-002 historical replay not rerun. Branch three commits ahead of
`main`, nine local changes needing reviewed commit, no pull
request. Do not treat record as merge or publication authorization.

**Superseding status (2026-10-10):** Issue 6 stopband-coverage blocker
above resolved by implementation and independent evidence below.
2026-10-08 review remains historical finding record; status
does not authorize merge or complete Julio's implementation or diagram review.

## Issue 6 coverage resolution (2026-10-10)

Accepted `cascade-peak-v1` scalar remains smaller rejection implied by
larger amplitude-dB maximum: existing non-principal cascade branches
over output `|q| <= 5 MHz`, or direct principal-cascade response over
full input stopband. Production metric evaluates principal `H1*H2`;
independent oracle composes 745-tap FIR, evaluates direct DTFT;
regression tests compare against combined 745-tap FFT reference.
Exact full-grid contract and preserved historical-profile semantics:
[data contract](../contracts/radar-v1-data-contracts.md#DDC.cascade-profile).

Fresh MATLAB R2026a Update 5 evidence: frozen default accepted with
`0.00146437058836 dB` cascade ripple, `87.7676669047 dB` stage-2 rejection,
`85.2548307898 dB` full-cascade rejection. Direct full-stopband term:
`87.7679126746 dB`, limited at `-6.33 MHz`. Direct DTFT and combined-FIR
reference differed by at most `1.56761761258e-14` over 50,001-point grid,
including 37,502 stopband points and endpoints. Exact full grid required
for acceptance; custom-grid diagnostics return `accepted=false`.

Fixed `6.75 MHz` witness changed from `85.2548312142 dB` to
`46.0367047386 dB`; at `18.75 MHz`, from `85.2548308601 dB` to
`47.3497865285 dB`. Digital-scalar old-pass/new-fail witnesses only;
both also fail separate stage-2 metric, so do not describe overall
design acceptance. No stopband relaxation needed. Independent validation
also confirmed frozen-profile oracle accepts default, rejects
`1e-3 dB` scalar tamper as `NUMERICAL_MISMATCH` at
`digitalAliasRejectionDb`, leaves `stage2AliasRejectionDb` empty for
passband-only diagnostic grids.

- `src/+radardemo/+ddc/measureResponse.m`
  - SHA-256: `97f3c78f7af7c61d365d565d66e4458f1742b51223b13c430d29718a245b7264`
- `contracts/wp4/+wp4oracle/checkDdc.m`
  - SHA-256: `2459cb1506b432d4d1f290ce5c31dab1c689aa45f21d248733c1dcbcc62952da`
- `tests/ddc/TestDdcPriProcessing.m`
  - SHA-256: `3a81ee70e34e61d1cdb6f36707f5929b95703e1642626de5fc6a491bd6df0e64`
- `tests/wp4/TestWp4Fixtures.m`
  - SHA-256: `434f309cd1edc3360b08add951f7f7616347c2cbbd506e61d2a6ee97fe917f78`

All four Code Analyzer checks: zero issues. `TestDdcPriProcessing`
passed 39/39 in 26.8346 seconds; `TestWp4Fixtures` passed 56/56 in 85.5371
seconds. Strict fixture checking passed 56/56 with `provenanceValid=true`;
`checkWp4Fixtures` used `FixtureRoot` pointing to `contracts/wp4/fixtures`,
`StrictTraceability=true`.

Initial strict-check invocation omitted `FixtureRoot`, failed:
wrong directory; corrected invocation passed. Check includes
working-tree evidence at baseline `b7751985c8909865c8990023d5b3e991c331f327`,
so not committed acceptance-evidence promotion.

All 25 checked-in fixture hashes remained at baseline; all 23 historical
fixture files remain byte-identical to `main`; fixture manifest,
including provenance, unchanged. No fixture regeneration required:
default scalar unchanged. DDC-002 and full-scan checks
not rerun; no hardware checks performed. Prior DDC-002 and full-scan
evidence scopes unchanged. Independent numerical review found no
unresolved errors. Three standards-warning categories above remain
open: excessive helper inputs, extending design struct outside
creating function, avoidably nested stimulus helpers. Merge authorization
and Julio's visual review of redrawn architecture diagrams remain pending.

## Standards-warning resolution (2026-10-11)

The three standards-warning categories above were resolved and independently
validated in the working tree. The `checkCase` and `saveBranchFigure` helpers
now have six inputs; `generateDdc`
constructs its response fixture locally; and the `boundaryChirp` and
`multitoneNoise` stimulus helpers are file-local functions. No public interface,
algorithm, state, timing, or schema changed.

Independent validation passed 96/96 MATLAB tests with no failures or incomplete
tests: `TestDdcPriProcessing` 39/39, `TestDdcWalkthrough` 1/1, and
`TestWp4Fixtures` 56/56. Code Analyzer reported zero issues in all three changed
files. Response/PRI MAT structures matched the pre-edit baseline, including
1,465 recursive class, shape, and ordered-field checks; standalone scan metrics
matched exactly; the MATLAB path and pre-existing figure handles remained
unchanged. Tracked and fresh
strict fixture manifests each passed 56/56 with `provenanceValid=true`; all 25
fixture hashes remained unchanged. Validation applied to the working tree and
does not promote committed acceptance evidence.

Validated file SHA-256 values:

- `contracts/wp4/+wp4oracle/checkDdcPri.m`: `37d65fb72a5c74aeeccacf5bc238fed1e9aa033a8636c1d0a78d0e593337e026`
- `contracts/wp4/+wp4gen/generateDdc.m`: `922750df377c7f1f3af09e8f756ba79cb6aef55ae0614af5112c416c262ebee9`
- `tests/ddc/runDdcScanCheck.m`: `d248983f6417bd2b66425fa95bfee53c01b966635a7978bbafbf4153857ee88c`

Hardware, end-to-end, and historical DDC-002 replay checks were not rerun.
Merge authorization and Julio's implementation review and visual review of the
redrawn architecture diagrams remain pending.

## Deferred choices

**Filter/decimation optimization study — requested 2026-10-03, deferred until
the complete MATLAB receiver/reference implementation.** Julio requested
first MATLAB revision after implementation complete explore more
efficient filtering and decimation before Simulink work. Candidate exploration
may include CIC decimator followed by FIR anti-alias filter; not
approval to replace
current design. Compare complete cascade against 0.1 dB overall
passband-ripple and 60 dB alias-rejection budgets at final 12.5 MS/s complex
output. Preserve filtering before decimation; account for 6.25 MHz
stage-2 stopband constraint; compensation after downsampling cannot undo
aliasing already introduced. Current approved filter design remains
baseline until Julio reviews candidate evidence.

Filter redesign, parallel execution demonstration, priming or prehistory
removal, gap shortening, Simulink topology and execution mechanism, fixed-point
realization, HDL remain deferred. First implementation serial,
uses unchanged approved filter design.
