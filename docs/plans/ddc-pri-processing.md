# Per-PRI DDC implementation plan

**Status:** ADR 0022 records the accepted direction and confirmed 2026-10-02
Phase 0 contract. Julio explicitly authorized implementation on 2026-10-02.
The MATLAB implementation, scoped tests, full-scan walkthrough, pinned-history
replay, fixture-preservation audit, and independent numerical validation passed.
Julio approved the DDC walkthrough on 2026-10-08; implementation review and
merge-readiness work remain ongoing. The range-processing boundary is the next
component review.

## Phase 0: confirmed contract (2026-10-02)

Julio confirmed `[output, metadata] = processFrame(adcPriSamples, design)`. The
input is one complete physical PRI as finite real `double` `[N,C]`; mixer, FIR,
and decimator state is fresh and local for each call. Calls are independent of
order. The output is complex `[N/12,C]`, retaining every produced row including
startup. Do not append zeros, flush filters, or return a tail. Metadata uses
scalar double fields `inputSampleCount`, `outputSampleCount`,
`decimationFactor`, `groupDelayInputSamples`, `groupDelayOutputSamples`,
`startupInputSamples`, and `startupOutputSamples`. Group delay is 372 ADC
sample periods or 31 output sample periods; startup full-memory span is 744 ADC
sample periods or 62 output sample periods.

The caller selects the physical PRI, provides a correctly sized and 12-tick-
aligned slice, handles identity and global timing (`startTick`/`timeEpoch`),
and reconstructs the timeline. These are input preconditions; no public
continuation context or global timestamp is part of the DDC API or metadata.
The trusted MVP has no required DDC rejection behavior for empty, incomplete,
or misaligned calls; this waiver does not make malformed data a valid PRI.
Convert stored `int16` data to `double` per PRI. Preserve transition gaps in
the timeline and never pass them as physical PRI calls.

The DDC is sample-only and range/system agnostic. Caller/integration applies
group-delay compensation exactly once when assigning coordinates. Downstream
range processing owns complete-window validity, including startup, blanking,
and PRI-end truncation. No per-range validity masks are returned by the DDC.

The fixed design accepts finite positive sample rates only when the intermediate
rate equals the ADC rate divided by 3 and the output rate equals the intermediate
rate divided by 4, within floating-point rate tolerance. Inconsistent rates are
rejected; `/3` and `/4` may not silently use a mismatched rate chain.

For the frozen 50 MHz mixer at 150 MHz ADC and PRI starts divisible by 12
ticks, local `n=0` mixing preserves global phase mathematically; large-global
and small-local floating exponent evaluation need not be bit-identical. No
generalized frequency/alignment equivalence is claimed.

The narrow versioned evidence migration is approved. Keep DDC-002 historical
and replayable at `58b3d3a80170d413aa88dd4408490e2056f49379`; do not relabel
old G2 evidence or bump an unrelated global schema. Keep passband and alias
regressions. The independent oracle represents combined-FIR convolution with
retained no-tail outputs, not DUT zero extension. Independent numerical review
accepts the unchanged `5e-11` input-peak-normalized bound for the bounded
five-PRI comparison. The observed `3.34852e-11` maximum leaves `1.65148e-11`
margin; this is not a bound for full-CPI, global-tick, or hardware behavior.
Keep exact-zero and inactive-channel invariants as separate acceptance checks.
Compare historical continuous processing only for local raw offsets at least
744 ADC ticks; startup equivalence is not required. Retain channel, isolation,
zero/impulse/chirp boundary, multitone/noise, shape, sample-metadata, caller-
time-mapping, and call-order coverage. Keep unit/oracle, full-scan, and
end-to-end claims distinct.

The pinned fixture byte hashes are `ddc-streaming.mat`
`2979d3d0c68c1deacbe097a202b2b3a125b2d7fd6aba19ef842d76bb98d6c616` and
`ddc-design.mat`
`541d89c6f98d4f292a2e8ca4504537440b591cea7348859c44d04276e6ab9a0d`.

Existing arithmetic establishes delay 372 ADC ticks, full startup memory 744
ADC ticks, and first gated raw tick 7128 with support 6384..7128, after
blanking ends at 6000. This supports the first gated DDC sample only, not the
full matched-filter window or end-to-end detection. No-tail PRI-end truncation
remains a downstream validity limitation. The 2026-10-02 explicit go authorizes
the scoped MATLAB implementation. It
does not authorize deferred Simulink topology or execution choices.

## Implementation evidence and validation

The core MATLAB MCP suite reports 32 passed, 0 failed, and 0 incomplete in
7.73 seconds. It covers all five PRI lengths at one and 64 channels against a
combined 745-tap FFT convolution oracle, boundary stimuli, call-order and
caller-time behavior, metadata and shape, inconsistent-rate rejection, and the
cascade 12 MHz stage-1 cutoff witness, rejected at 0.79347008136 dB cascade
ripple. Oracle error is normalized by peak input amplitude.
The combined-oracle tests report maximum input-peak-normalized error
`1.12962634928e-15` across all five PRI lengths at one and 64 channels. The
test helper's per-PRI versus continuous-reference comparison, after full memory,
reported a largest error of `3.08285e-11` absolute, or `3.34852e-11` normalized
with reference amplitudes from `0.911` to `0.927`. Independent numerical
review accepts the unchanged `5e-11` input-peak-normalized bound for this
bounded comparison, with `1.65148e-11` margin. This is not a bound for
full-CPI, global-tick, or hardware behavior, and remains separate from the
pinned full-CPI DDC-002 replay.

The full-scan integration walkthrough smoke completed in 8.7 seconds. It
processed 147 physical PRIs (5 priming, 142 usable), skipped four 106872-tick
transition gaps, retained the full 10,553,388-tick contiguous `int16` timeline,
processed 10,125,900 physical input samples, and produced 843,825 output
samples. The `cascade-peak-v1` response metrics were 0.00146437058836 dB
cascade ripple, 87.7676669047 dB stage-2 alias rejection, and 85.2548307898 dB
full-cascade alias rejection. This is full-scan integration evidence; it is not
runtime evidence for the one-PRI teaching script. Independent fresh WP4
generation with strict traceability
passed all 56 rows, including seven new per-PRI cases. The independent WP4
MATLAB suite passed 56/56 in 83.4439 seconds; independent direct DDC tests
passed 32/32 in 10.6756 seconds. The tracked strict checker passed 56/56 with
valid provenance, explicitly including working-tree evidence under mixed
acceptance-evidence and temporary-unit-evidence scopes. The six corruption
probes (real/imaginary perturbations at 1e-12 for one- and 64-channel zero cases
and the inactive channel) all rejected with `NUMERICAL_MISMATCH`. New MAT
witness hashes are unchanged; all 23 historical fixture hashes, 54 original
manifest rows, and original global manifest metadata are preserved. These are
bounded unit/oracle and full-scan observations, not end-to-end detection or
hardware evidence.

Reproduce the targeted MATLAB unit suite and full-scan integration check from
the repository root with MATLAB available. The scan runner remains separate
from the one-PRI teaching script in `docs/examples/ddc-walkthrough.md`:

```matlab
repoRoot = pwd;
addpath(fullfile(repoRoot, "src"));
addpath(fullfile(repoRoot, "tests", "ddc"));
testResults = runtests(fullfile(repoRoot, "tests", "ddc"));
assertSuccess(testResults);
runDdcScanCheck(fullfile(tempdir, "ddc-pri-scan"));
```

Reproduce the WP4 fresh-generation and strict-traceability check from the
project root through MATLAB MCP. This generated evidence declares its generator
revision as `working-tree`; it is temporary evidence and does not replace the
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

Code Analyzer reported no findings across the 5 core and 9 WP4 MATLAB source
files; the two oracle-fix files were reanalyzed and also reported no findings.
The four MATLAB code fences in the walkthrough and this plan were extracted and
analyzed with zero findings. Tracked fixture integration/preservation audit
passed. Pinned DDC-002 replay passed strict 1/1 at revision
`58b3d3a80170d413aa88dd4408490e2056f49379`. Independent numerical validation
passed after exact-zero and inactive-channel invariants were added to the oracle
and verified by the six corruption probes. The per-PRI witnesses use new profile
identifiers; they do not relabel historical G2 evidence. Issue #3 provenance
hardening remains separate.

## Implementation record

The following approved implementation steps are complete:

1. Preserve and pin the old continuous-state witness and source revision at
   `58b3d3a80170d413aa88dd4408490e2056f49379`.
2. Make mixer, FIR, and decimation state local to each complete PRI in
   `src/+radardemo/+ddc/processFrame.m`. The approved implementation removes
   `initializeState.m` and the public continuation-state argument; it does not
   silently accept legacy arguments.
3. Adapt the WP4 path by slicing and calling only physical priming and usable
   PRIs. Preserve global timestamps and transition gaps. Keep `int16` storage
   compact and convert each selected PRI to `double` at the call boundary. The
   full-scan integration runner is `tests/ddc/runDdcScanCheck.m`; the current
   teaching entry point `examples/runDdcWalkthrough.m` demonstrates one aligned
   PRI.
4. Add an independent per-PRI oracle and migrate the WP4 generator, checker,
   adapter, and test integration: `+wp4gen/generateDdc.m`,
   `+wp4gen/buildManifest.m`, `+wp4oracle/checkArtifact.m`,
   `+wp4oracle/checkDdc.m`, new `+wp4oracle/checkDdcPri.m`,
   `adaptWp4Draft1.m`, `generateWp4Fixtures.m`, `checkWp4Fixtures.m`,
   `fixture-manifest.json`, and `tests/wp4/TestWp4Fixtures.m`. Add the
   `ddc-pri.mat` and `ddc-response-pri.mat` witnesses. Preserve the unchanged
   historical `+wp4oracle/checkDdcStreaming.m` and `checkDdcZero.m` checkers
   and keep DDC-002 replayable at its pinned baseline.
5. Add individual `/3` and `/4` and cascade alias-response plots, a passband
   zoom, and a per-PRI state-reset loop diagram for full-scan integration
   evidence. The one-PRI teaching script provides input/output spectra,
   startup, passband, and alias observations. Prefer `gramm` where suitable;
   keep filter and decimator as distinct diagram blocks. Three-phase/polyphase
   mixing remains a later optimization candidate.
6. Targeted regression, MATLAB Code Analyzer, and independent deep validation
   passed; Julio approved the DDC walkthrough on 2026-10-08, and implementation
   review and merge-readiness work remain ongoing.

## Validated acceptance criteria

Independent numerical review accepts the unchanged `5e-11` input-peak-
normalized tolerance for the bounded five-PRI comparison. The measured
`3.34852e-11` maximum leaves `1.65148e-11` margin. This criterion is not a
full-CPI, global-tick, or hardware error bound. Validation covered all five PRI
lengths, one and 64 channels, channel isolation, exact zero, first/last-sample
impulses, 40-microsecond boundary chirps, multitone and seeded noise, output
shape, sample-domain metadata, caller time mapping, and call-order invariance.
Alignment and expected length remain caller preconditions in this trusted MVP.
Repeated, reversed, and shuffled calls produce identical per-PRI results and
metadata.

The historical continuous reference was compared only at local raw offsets
`>= 744` ADC sample periods (zero-based output index 62), after full cascade
memory; startup equivalence was not required. The output has no padded tail.
Downstream range processing owns startup, blanking, and PRI-end window validity.
Filter passband and alias-rejection regressions passed. Unit/oracle, full-scan,
and end-to-end detection evidence remain distinct scopes.

## Merge-readiness review — 2026-10-08

Root reviewed `main` at `e76eb62dbe24dd03174187f224e409fdaad3e643` through
`10b6456794bf8f952c2ce3989791b9e3e8c8357d`. MATLAB source remained
unchanged during these fresh checks.
The specification review found a merge blocker: issue 6 requires cascade alias
rejection over the approved stopband `|f| >= 6.25 MHz` through 25 MHz on a
1 kHz grid, but `measureResponse` and `checkDdc` measure nonprincipal cascade
branches only over output `|f| <= 5 MHz`. This omits required stopband slices,
including 6.25–7.5 MHz. Update both metrics and add a boundary regression,
then repeat independent validation before merge. A bounded root diagnostic
measured 87.7679126746 dB direct principal-cascade attenuation in the
6.25–7.5 MHz interval. The default filters pass that bounded omitted-interval
diagnostic; the finding concerns acceptance coverage,
not a demonstrated filter failure.

Independent standards review reported three warning categories: `checkCase`
in `checkDdcPri` and `saveBranchFigure` in `runDdcScanCheck` each have nine
inputs against the documented six-input limit; `generateDdc` extends the design
struct outside its creating function; and two stimulus helpers in `checkDdcPri`
are avoidably nested. Resolve or explicitly disposition these warnings.
Independent specification review reported the alias-metric error above. These
independent reviews are separate from Julio's 2026-10-08 walkthrough approval,
which does not approve merge or waive the findings.

Root-run MATLAB MCP checks passed on source that remained unchanged during
these fresh checks: `TestDdcPriProcessing`
(32/0/0), `TestDdcWalkthrough` (1/0/0; 147 physical PRIs and 4 skipped gaps),
`TestWp4Fixtures` (56/0/0), and Code Analyzer on all 29 existing changed
MATLAB files with no issues. The deleted `initializeState.m` was excluded. The
strict checker passed 56/56; provenance-format consistency, WP3 conformance
(30 rows), Ruff, Pyright, handoff checks, and Markdown lint also passed.
Historical fixture files were byte-identical to `main`; original manifest
provenance was preserved and the derived test-method count is 56.
DDC-002 historical replay was not rerun. The branch is three commits ahead of
`main`, has nine local changes needing a reviewed commit, and has no pull
request. Do not treat this record as merge or publication authorization.

## Deferred choices

**Filter/decimation optimization study — requested 2026-10-03, deferred until
the complete MATLAB receiver/reference implementation.** Julio requested that
the first MATLAB revision after that implementation is complete explore more
efficient filtering and decimation before Simulink work. Candidate exploration
may include a CIC decimator followed by an FIR anti-alias filter; this is not
approval to replace
the current design. Compare the complete cascade against the 0.1 dB overall
passband-ripple and 60 dB alias-rejection budgets at the final 12.5 MS/s complex
output. Preserve filtering before decimation and account for the 6.25 MHz
stage-2 stopband constraint; compensation after downsampling cannot undo
aliasing already introduced. The current approved filter design remains the
baseline until Julio reviews candidate evidence.

Filter redesign, parallel execution demonstration, priming or prehistory
removal, gap shortening, Simulink topology and execution mechanism, fixed-point
realization, and HDL remain deferred. The first implementation is serial and
uses the unchanged approved filter design.
