---
status: accepted
accepted: 2026-09-29
implementation: pending
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
fixed-point staging, or HDL deferral. The current continuous-state MATLAB code,
walkthrough, diagrams, and tests describe the prior implementation baseline;
they are not evidence that this accepted decision is implemented. Historical
G2 streaming evidence remains evidence for that old baseline only.

## Timing and boundary behavior

Processing is causal from the physical PRI's first ADC tick, including its
transmit blind interval. The current stages remain 25 taps at 150 MS/s with
decimation by 3, then 241 taps at 50 MS/s with decimation by 4, producing
12.5 MS/s complex samples. Their cascade group delay is 372 ADC ticks, or 31
output periods (2.48 microseconds), and is compensated once in time/range
coordinates. Matched-filter delay is separate. The full cascade memory is 744
ADC ticks, or 62 output periods (4.96 microseconds).

An implementation may append a causal zero-flush extension to expose retained
FIR tail output. Such padding is not acquired input, does not repair missing or
blanked ADC samples, and must not be represented as physical overlap or as
equivalent to samples from the next PRI. Missing or blanked samples cannot be
recreated by padding: affected pulse-compression/range observations are marked
invalid for that PRF, and other PRFs remain available under existing fusion
rules. The exact range-window validity mapping and its owner remain open for
Phase 0.

The five priming records and four transition gaps remain the current schedule
for the first refactor. The 106872-tick gap is the historical rounded value
derived from `2*100050/c + 40 us + 5 us`; it is not FIR-settling time. At
100 km, round-trip delay is 667.128 microseconds, so with a 370.4-microsecond
fastest PRI an echo starts 296.728 microseconds into the next PRI. Removing or
shortening priming, adding prehistory, or changing gaps is deferred.

## Open Phase 0 interface decisions

The exact function signature, output shape, timing metadata, tail representation,
and ownership of window metadata remain to be resolved in Phase 0 before code
implementation. A proposed interface is `[output,metadata] =
processFrame(adcPri,design,priContext)`, with identity, expected length, start
tick, and common epoch in `priContext`; this is a proposal, not an approved API.
Input length and start tick must align to 12 ADC ticks relative to the common
epoch. Existing physical PRIs already align. Output tick and compensated offset
conventions, including signed offsets that avoid unsigned underflow, need an
explicit contract. One proposed representation concatenates `N/12` acquired
outputs with 62 tail rows; its tail corresponds to raw ticks `N` through
`N+732` after appending 744 zero input samples. Proposed compensated offsets
are `12*k - 372` and must be signed. These are Phase 0 proposals, not approved
output semantics. DDC-versus-range ownership is also unresolved: Phase 0 must
present the proposed split (DDC reports processing/padding provenance;
downstream range integration defines acquired/blanked pulse-compression-window
validity) for Julio's choice before implementation.

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
Startup output and padded tail are not expected to match that reference.

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

Implementation is pending explicit Julio go-ahead after Phase 0 resolves the
interface and migration contract. Future work must preserve the historical
DDC-002 witness and replay it at its pinned baseline; it must not relabel that
evidence as acceptance of per-PRI behavior. A narrow evidence-schema migration
is preferred to an unrelated global schema-version change.
