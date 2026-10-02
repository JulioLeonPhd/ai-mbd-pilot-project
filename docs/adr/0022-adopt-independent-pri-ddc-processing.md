---
status: accepted
accepted: 2026-09-29
implementation: in-progress
---

# Adopt independent per-PRI DDC processing

On 2026-09-29, Julio approved a DDC call boundary that processes one complete
physical PRI independently. MATLAB prepares the complete ADC matrix before the
DUT; each `processFrame` call receives exactly one physical PRI as a real
floating-point `[N,C]` array. The existing filter design and 64-channel default
remain. At each PRI start, mixer, FIR, and decimation state is fresh and local;
callers do not carry DDC state between PRIs. Calls must be order-independent.
The full ADC timeline, physical input continuity, and global timestamps remain
continuous across PRI boundaries.

This supersedes only the continuous-state-across-PRI clauses of ADRs 0019 and
0020, and derived streaming obligations from [ADR 0018](0018-freeze-wp4-g2-phase0-contract.md).
It does not change ADC gap rejection, storage, scan schedule, filter design,
fixed-point staging, or HDL deferral. At acceptance, the continuous-state
MATLAB code, walkthrough, diagrams, and tests described the prior baseline. Historical
G2 streaming evidence remains evidence for that old baseline only.

## Timing and boundary behavior

Processing is causal from the physical PRI's first ADC tick, including its
transmit blind interval. The current stages remain 25 taps at 150 MS/s with
decimation by 3, then 241 taps at 50 MS/s with decimation by 4, producing
12.5 MS/s complex samples. Their cascade group delay is 372 ADC ticks, or 31
output periods (2.48 microseconds), and is compensated once in time/range
coordinates. Matched-filter delay is separate. The full cascade memory is 744
ADC ticks, or 62 output periods (4.96 microseconds).

The confirmed MVP returns no flush or tail rows. Downstream range processing
owns complete-window validity, including startup, blanking, and PRI-end
truncation. Missing or blanked samples cannot be recreated by padding; affected
pulse-compression/range observations are handled by downstream validity logic,
with other PRFs remaining available under existing fusion rules.

The five priming records and four transition gaps remain the current schedule
for the first refactor. The 106872-tick gap is the historical rounded value
derived from `2*100050/c + 40 us + 5 us`; it is not FIR-settling time. At
100 km, round-trip delay is 667.128 microseconds, so with a 370.4-microsecond
fastest PRI an echo starts 296.728 microseconds into the next PRI. Removing or
shortening priming, adding prehistory, or changing gaps is deferred.

## Confirmed Phase 0 contract — 2026-10-02

Julio confirmed `[output, metadata] = processFrame(adcPriSamples, design)`. Each
call receives one complete physical PRI as finite real `double` data `[N,C]`.
Mixer, FIR, and decimator state is fresh and local to each call; repeated or
reordered calls are independent. The existing filter design and serial initial
implementation remain in force. There is no public continuation context.

The output is complex `[N/12,C]`. Every produced row is retained, including
startup; there is no appended zero input, flush, or tail. Metadata is
sample-domain only and reports input/output sample counts, decimation factor,
group delay, and startup span. These descriptions do not approve exact field
spellings or types. Group delay is 372 ADC sample periods or 31 output sample
periods (2.48 microseconds); startup full-memory span is 744 ADC sample periods
or 62 output sample periods (4.96 microseconds). No global timestamp or range
coordinate is included.

The caller owns PRI slicing, expected length and identity, global `startTick`
and `timeEpoch`, and timeline reconstruction. PRI length and start alignment to
12 ADC ticks remain input preconditions. Julio waived required DDC rejection
behavior for empty, incomplete, or misaligned calls in the trusted MVP; this
does not make such inputs valid physical PRI calls. Convert stored `int16`
samples to `double` per PRI. Transition gaps remain in the timeline and are
never passed as physical PRI calls.

The DDC is sample-only and range/system agnostic. Caller/integration applies
the 372-tick group-delay compensation exactly once when assigning coordinates.
Downstream range processing owns complete-window validity, including startup,
blanking, and PRI-end truncation. The DDC creates no per-range validity masks.

For the frozen 50 MHz mixer and 150 MHz ADC, with every PRI start divisible by
12 ticks, local `n=0` mixing preserves global oscillator phase mathematically.
Large-global and small-local floating exponent evaluation need not be
bit-identical. This does not claim arbitrary-frequency or arbitrary-alignment
equivalence.

The narrow, versioned per-PRI evidence migration is approved. Preserve DDC-002
as a historical continuous-state witness replayable at
`58b3d3a80170d413aa88dd4408490e2056f49379`; do not relabel old G2 evidence or
make an unrelated global schema-version change. Retain passband and alias
regressions. Describe the independent oracle as combined-FIR convolution with
retained no-tail outputs, not DUT zero extension. Independent numerical review
accepts the unchanged `5e-11` input-peak-normalized bound for the bounded
five-PRI comparison; it does not establish a full-CPI, global-tick, or hardware
bound. Keep exact-zero and inactive-channel
invariants as separate acceptance checks. Compare historical continuous
output only at local raw offsets of at least 744 ADC ticks; startup
equivalence is not required. Preserve one/64-channel coverage, isolation,
zero and impulse/chirp boundary cases, multitone/noise, shape, sample metadata,
caller timestamp/delay mapping, and call-order invariance. Report unit/oracle,
full-scan, and end-to-end scopes separately.

Source inspection of the [DDC design](../../src/+radardemo/+ddc/createDesign.m)
and [receive timing evaluator](../../src/+radardemo/+timing/evaluateReceiveTiming.m),
followed by arithmetic, gives 372 ADC ticks of group delay and 744 ADC ticks of
startup memory. The first range gate at raw tick 7128 depends on ADC support
6384 through 7128, beyond the blanking end at tick 6000. These are source-based
derivations, not results of new simulations. This supports the first gated
DDC sample only; it is not evidence for a complete matched-filter window or
end-to-end detection. With no tail output, PRI-end truncation remains a
downstream validity limitation.

The future Simulink multishot direction resets DDC state for each PRI and keeps
startup transients in the blind range. Model topology and execution mechanism
remain open. The behavioral/implementation-oriented staging, fixed-point stage,
and HDL deferral in ADRs 0003, 0008, and 0019 remain in force.

## Consequences and evidence

The initial implementation should be serial and demonstrate that repeated,
reversed, and shuffled PRI calls produce the same per-PRI results and metadata.
Parallel execution is optional future evidence. Historical continuous processing
may be used as a comparison only where local raw ADC tick is at least 744
(zero-based output index 62). Group delay is 372 ticks (31 output periods),
while full-memory comparison begins after 744 ticks (62 output periods).
Startup output is not expected to match that reference; the approved output has
no padded-tail rows.

A bounded exploratory MATLAB batch on 2026-09-29 used existing code. For each
length `L` in `[88236,78948,69768,61224,55560,106872]`, it generated two
consecutive periods in one channel as
`cos(2*pi*51e6/150e6*n)+0.2*randn(...)`, with a local `mt19937ar` stream seeded
to 2919. Reset FIR state while retaining global oscillator count matched
continuous processing exactly from local tick 744 onward; full state reset had
maximum difference `1.8327e-11` against the `5e-11` probe threshold. Initial
FIR-reset differences ranged from `0.564` to `0.615`. A local-dependency check
found output tick `q` depends on input ticks `[q-744,q]`; the first gated raw
tick 7128 has earliest contributing input tick 6384, after the 6000-tick
blanking interval. This is bounded manual evidence, not a committed reusable
test, full 64-channel/full-scan result, or end-to-end detection verification.
The prior G2 streaming evidence remains tied to its historical continuous-state
baseline.

The Phase 0 interface and migration contract are confirmed. Julio explicitly
authorized implementation on 2026-10-02. The per-PRI MATLAB implementation,
scoped core and WP4 suites, full-scan walkthrough, pinned DDC-002 replay, and
fixture-preservation audit passed. Independent numerical validation also passed
after the exact-zero and inactive-channel oracle checks were made explicit and
verified. The bounded five-PRI tolerance is justified by independent numerical
review; it is not a full-CPI, global-tick, or hardware error bound. Preserve
DDC-002 as historical continuous-state evidence, not per-PRI acceptance. The
implementation is ready for Julio's implementation and walkthrough review. A
narrow evidence-schema migration is preferred to an unrelated global schema
version change.
