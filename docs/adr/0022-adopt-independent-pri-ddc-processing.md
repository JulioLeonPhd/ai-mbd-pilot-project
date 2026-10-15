---
status: accepted
accepted: 2026-09-29
implementation: in-progress
---
# Adopt independent per-PRI DDC processing

On 2026-09-29, Julio approved DDC call boundary processing one complete
physical PRI independently. MATLAB prepares complete ADC matrix before
DUT; each `processFrame` call receives exactly one physical PRI as real
floating-point `[N,C]` array. Existing filter design and 64-channel default
remain. Each PRI starts with fresh, local mixer, FIR, and decimation state;
callers do not carry DDC state between PRIs. Calls must be order-independent.
Full ADC timeline, physical input continuity, and global timestamps remain
continuous across PRI boundaries.

Supersedes only continuous-state-across-PRI clauses of ADRs 0019 and
0020, and derived streaming obligations from [ADR 0018](0018-freeze-wp4-g2-phase0-contract.md).
Does not change ADC gap rejection, storage, scan schedule, filter design,
fixed-point staging, or HDL deferral. At acceptance, continuous-state
MATLAB code, walkthrough, diagrams, and tests described prior baseline. Historical
G2 streaming evidence remains evidence for old baseline only.

## Timing and boundary behavior

Processing causal from physical PRI's first ADC tick, including
transmit blind interval. Current stages remain 25 taps at 150 MS/s with
decimation by 3, then 241 taps at 50 MS/s with decimation by 4, producing
12.5 MS/s complex samples. Cascade group delay: 372 ADC ticks, or 31
output periods (2.48 microseconds), compensated once in time/range
coordinates. Matched-filter delay separate. Full cascade memory: 744
ADC ticks, or 62 output periods (4.96 microseconds).

Confirmed MVP returns no flush or tail rows. Downstream range processing
owns complete-window validity, including startup, blanking, and PRI-end
truncation. Missing or blanked samples cannot be recreated by padding; downstream
validity logic handles affected pulse-compression/range observations,
with other PRFs available under existing fusion rules.

Five priming records and four transition gaps remain current schedule
for first refactor. 106872-tick gap: historical rounded value
derived from `2*100050/c + 40 us + 5 us`; not FIR-settling time. At
100 km, round-trip delay: 667.128 microseconds; with 370.4-microsecond
fastest PRI, echo starts 296.728 microseconds into next PRI. Removing or
shortening priming, adding prehistory, or changing gaps deferred.

## Confirmed Phase 0 contract — 2026-10-02

Julio confirmed `[output, metadata] = processFrame(adcPriSamples, design)`. Each
call receives one complete physical PRI as finite real `double` data `[N,C]`.
Mixer, FIR, and decimator state fresh and local per call; repeated or
reordered calls independent. Existing filter design and serial initial
implementation remain in force. No public continuation context.

Output complex `[N/12,C]`. Every produced row retained, including
startup; no appended zero input, flush, or tail. Metadata
sample-domain only: input/output sample counts, decimation factor,
group delay, and startup span. Descriptions do not approve exact field
spellings or types. Group delay: 372 ADC sample periods or 31 output sample
periods (2.48 microseconds); startup full-memory span: 744 ADC sample periods
or 62 output sample periods (4.96 microseconds). No global timestamp or range
coordinate included.

Caller owns PRI slicing, expected length and identity, global `startTick`
and `timeEpoch`, and timeline reconstruction. PRI length and start alignment to
12 ADC ticks remain input preconditions. Julio waived required DDC rejection
behavior for empty, incomplete, or misaligned calls in trusted MVP;
does not make such inputs valid physical PRI calls. Convert stored `int16`
samples to `double` per PRI. Transition gaps remain in timeline,
never passed as physical PRI calls.

DDC sample-only and range/system agnostic. Caller/integration applies
372-tick group-delay compensation exactly once when assigning coordinates.
Downstream range processing owns complete-window validity, including startup,
blanking, and PRI-end truncation. DDC creates no per-range validity masks.

For frozen 50 MHz mixer and 150 MHz ADC, every PRI start divisible by
12 ticks, local `n=0` mixing preserves global oscillator phase mathematically.
Large-global and small-local floating exponent evaluation need not be
bit-identical. Does not claim arbitrary-frequency or arbitrary-alignment
equivalence.

Narrow, versioned per-PRI evidence migration approved. Preserve DDC-002
as historical continuous-state witness replayable at
`58b3d3a80170d413aa88dd4408490e2056f49379`; do not relabel old G2 evidence or
make unrelated global schema-version change. Retain passband and alias
regressions. Describe independent oracle as combined-FIR convolution with
retained no-tail outputs, not DUT zero extension. Independent numerical review
accepts unchanged `5e-11` input-peak-normalized bound for bounded
five-PRI comparison; does not establish full-CPI, global-tick, or hardware
bound. Keep exact-zero and inactive-channel
invariants as separate acceptance checks. Compare historical continuous
output only at local raw offsets of at least 744 ADC ticks; startup
equivalence not required. Preserve one/64-channel coverage, isolation,
zero and impulse/chirp boundary cases, multitone/noise, shape, sample metadata,
caller timestamp/delay mapping, and call-order invariance. Report unit/oracle,
full-scan, and end-to-end scopes separately.

Source inspection of [DDC design](../../src/+radardemo/+ddc/createDesign.m)
and [receive timing evaluator](../../src/+radardemo/+timing/evaluateReceiveTiming.m),
then arithmetic, gives 372 ADC ticks group delay and 744 ADC ticks
startup memory. First range gate at raw tick 7128 depends on ADC support
6384 through 7128, beyond blanking end at tick 6000. Source-based
derivations, not new simulation results. Supports first gated
DDC sample only; not evidence for complete matched-filter window or
end-to-end detection. With no tail output, PRI-end truncation remains
downstream validity limitation.

Future Simulink multishot direction resets DDC state per PRI, keeps
startup transients in blind range. Model topology and execution mechanism
remain open. Behavioral/implementation-oriented staging, fixed-point stage,
and HDL deferral in ADRs 0003, 0008, and 0019 remain in force.

## Consequences and evidence

Initial implementation should be serial, demonstrate repeated,
reversed, and shuffled PRI calls produce same per-PRI results and metadata.
Parallel execution optional future evidence. Historical continuous processing
may serve as comparison only where local raw ADC tick at least 744
(zero-based output index 62). Group delay: 372 ticks (31 output periods);
full-memory comparison begins after 744 ticks (62 output periods).
Startup output not expected to match reference; approved output has
no padded-tail rows.

Bounded exploratory MATLAB batch on 2026-09-29 used existing code. For each
length `L` in `[88236,78948,69768,61224,55560,106872]`, generated two
consecutive periods in one channel as
`cos(2*pi*51e6/150e6*n)+0.2*randn(...)`, with local `mt19937ar` stream seeded
to 2919. Reset FIR state retaining global oscillator count matched
continuous processing exactly from local tick 744 onward; full state reset had
maximum difference `1.8327e-11` against `5e-11` probe threshold. Initial
FIR-reset differences ranged from `0.564` to `0.615`. Local-dependency check
found output tick `q` depends on input ticks `[q-744,q]`; first gated raw
tick 7128 has earliest contributing input tick 6384, after 6000-tick
blanking interval. Bounded manual evidence, not committed reusable
test, full 64-channel/full-scan result, or end-to-end detection verification.
Prior G2 streaming evidence remains tied to historical continuous-state
baseline.

Phase 0 interface and migration contract confirmed. Julio explicitly
authorized implementation on 2026-10-02. Per-PRI MATLAB implementation,
scoped core and WP4 suites, full-scan walkthrough, and fixture-preservation audit
passed. Independent numerical validation also passed after exact-zero and
inactive-channel oracle checks made explicit and verified. Bounded five-PRI
tolerance justified by independent numerical review; not full-CPI, global-tick,
or hardware error bound. Separately, pinned DDC-002 replay passed as historical
continuous-state evidence, not per-PRI acceptance.
Julio approved DDC walkthrough on 2026-10-08; implementation review and
merge-readiness work remain ongoing. Narrow evidence-schema migration
preferred to unrelated global schema version change.

## Amplitude compensation addendum — 2026-10-14

Julio approved fixed factor-two compensation on the final decimated output
after learning that a real cosine with peak amplitude `A` produces envelope
amplitude `A/2` in the complex DDC output. This restores real-tone peak
envelope amplitude subject to FIR gain and phase response and residual image;
it preserves input units, doubles noise amplitude, and does not improve SNR or
establish calibrated-volts accuracy.

The change leaves FIR coefficients and response metrics, 372/31-sample group
delay, 744/62-sample startup span, filter state, output shape, and API unchanged.
The current per-PRI evidence profile moves from
`independent-pri-v1` version `1.0.0` to `independent-pri-v2` version `2.0.0`;
the schema is unchanged. Only `ddc-pri.mat` migrates. Other fixtures, including
`ddc-response-pri.mat`, remain unchanged. The old profile remains replayable at
the pinned baseline revision above.

The prior v1 per-PRI versus continuous-helper comparison measured
`3.34852e-11` normalized error against the unchanged helper, within its reviewed
`5e-11` input-peak-normalized bound. The implemented v2 regression divides
compensated PRI output by two before that helper; the current direct oracle
includes factor two. These old comparison results remain attributed to v1.

On 2026-10-15, the tracked `ddc-pri.mat` and matching manifest record migrated
to v2 version `2.0.0`, scope `temporary-unit-evidence`, revision `working-tree`,
SHA `af4ed1be0ffe0db230d8e6f825014b8fd7bd7aae12940a286d155b1e4c6776f4`. Of
25 tracked fixture artifacts, only `ddc-pri.mat` changed; the other 24 remain
unchanged, including all 23 historical artifacts and `ddc-response-pri.mat`.
The DDC suite passed 40/40, WP4 passed 56/56, walkthrough passed 1/1, and the
full-scan run processed 147 PRIs, skipped four transition gaps, and produced
843,825 outputs. Fresh and tracked strict fixture checks each passed 56/56 with
`provenanceValid=true`; Code Analyzer returned no issues for the six edited
MATLAB files. The v1 analytic baseline failed with normalized error
`0.500862525049793`; the live v2 analytic check passed. Independent MATLAB
validation passed on 2026-10-15 with no unresolved errors: analytic and
historical comparisons 2/2, WP4 per-PRI 1/1, and tracked strict fixtures 56/56
with `provenanceValid=true`. The reviewer verified v2 profile identity and all
24 unchanged fixture artifacts; full-suite and Code Analyzer results were
reviewed from upstream evidence, not rerun. Validation is limited to this
temporary-unit evidence and does not record human implementation or merge
approval.
