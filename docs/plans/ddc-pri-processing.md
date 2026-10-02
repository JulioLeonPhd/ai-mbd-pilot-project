# Per-PRI DDC implementation plan

**Status:** ADR 0022 records the accepted direction and confirmed 2026-10-02
Phase 0 contract. Implementation awaits Julio's separate explicit go. This
plan does not authorize MATLAB or Simulink changes.

## Phase 0: confirmed contract (2026-10-02)

Julio confirmed `[output, metadata] = processFrame(adcPriSamples, design)`. The
input is one complete physical PRI as finite real `double` `[N,C]`; mixer, FIR,
and decimator state is fresh and local for each call. Calls are independent of
order. The output is complex `[N/12,C]`, retaining every produced row including
startup. Do not append zeros, flush filters, or return a tail. Metadata describes
input/output sample counts, decimation factor, group delay, and startup span in
sample-domain terms; exact field names and types are not human-approved. Group
delay is 372 ADC sample periods or 31 output sample periods; startup full-memory
span is 744 ADC sample periods or 62 output sample periods.

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

For the frozen 50 MHz mixer at 150 MHz ADC and PRI starts divisible by 12
ticks, local `n=0` mixing preserves global phase mathematically; large-global
and small-local floating exponent evaluation need not be bit-identical. No
generalized frequency/alignment equivalence is claimed.

The narrow versioned evidence migration is approved. Keep DDC-002 historical
and replayable at `58b3d3a80170d413aa88dd4408490e2056f49379`; do not relabel
old G2 evidence or bump an unrelated global schema. Keep passband and alias
regressions. The independent oracle represents combined-FIR convolution with
retained no-tail outputs, not DUT zero extension. `5e-11` remains a proposed
tolerance pending numerical justification. Compare historical continuous
processing only for local raw offsets at least 744 ADC ticks; startup
equivalence is not required. Retain channel, isolation, zero/impulse/chirp
boundary, multitone/noise, shape, sample-metadata, caller-time-mapping, and
call-order coverage. Keep unit/oracle, full-scan, and end-to-end claims distinct.

Existing arithmetic establishes delay 372 ADC ticks, full startup memory 744
ADC ticks, and first gated raw tick 7128 with support 6384..7128, after
blanking ends at 6000. This supports the first gated DDC sample only, not the
full matched-filter window or end-to-end detection. No-tail PRI-end truncation
remains a downstream validity limitation. Phase 0 does not authorize
implementation; obtain Julio's separate explicit go before changing MATLAB or
Simulink.

## Implementation sequence after Julio's go

1. Preserve and pin the old continuous-state witness and source revision at
   `58b3d3a80170d413aa88dd4408490e2056f49379`.
2. Make mixer, FIR, and decimation state local to each complete PRI in
   `src/+radardemo/+ddc/processFrame.m` and
   `src/+radardemo/+ddc/initializeState.m`. Remove
   public continuation state only after the interface is approved; do not
   silently ignore legacy arguments.
3. Adapt the complete pre-generated ADC matrix in
   `examples/runDdcWalkthrough.m` and the WP4 path by slicing and calling only
   physical priming and usable PRIs. Preserve global timestamps and transition
   gaps. Keep `int16` storage compact and convert each selected PRI to `double`
   at the call boundary.
4. Add an independent per-PRI oracle and narrowly migrate `contracts/wp4/`
   artifacts: `+wp4gen/generateDdc.m`, `+wp4gen/buildManifest.m`,
   `generateWp4Fixtures.m`, `fixture-manifest.json`, `checkWp4Fixtures.m`,
   `+wp4oracle/checkArtifact.m`, `+wp4oracle/checkDdcStreaming.m`, and
   `+wp4oracle/checkDdcZero.m`; update `tests/wp4/TestWp4Fixtures.m`. Replace
   carried-state and reset-is-defect assertions for the new profile while
   keeping historical DDC-002 evidence replayable at its pinned baseline.
5. Update `examples/runDdcWalkthrough.m` and its documentation/plots. Add
   individual and cascade alias-response plots, a passband zoom, and a
   per-PRI state-reset loop diagram. Prefer `gramm` where suitable; keep filter
   and decimator as distinct diagram blocks. Three-phase/polyphase mixing
   remains a later optimization candidate.
6. Run targeted regression, MATLAB Code Analyzer, and independent deep
   validation. Resolve error findings and repeat validation before acceptance.

## Required implementation evidence

Use an independently derived combined-FIR convolution oracle and compare the
retained no-tail output rows after local mixing. The proposed normalized
tolerance is `5e-11`; justify it against oracle numerical behavior rather than
treating it as an approved relaxation. Cover all five PRI lengths, one and 64
channels, channel isolation, exact zero, first/last-sample impulses, and
40-microsecond chirps near boundaries, and multitone plus seeded noise. Check
exact output shape,
sample-domain metadata, caller timestamp/delay mapping, and call-order
invariance across the physical PRI set. Alignment and expected length are
caller preconditions; do not require DDC-specific rejection behavior for empty,
incomplete, or misaligned calls in this trusted MVP. Repeated, reversed, and
shuffled calls must produce identical per-PRI results and metadata.

Compare the old continuous reference only at local raw offsets `>= 744` ADC
sample periods (zero-based output index 62), after full cascade memory. Do not
require startup equivalence. Keep startup transient in the blind range. There
are no padded-tail rows. Downstream range processing handles startup, blanking,
and PRI-end window validity. Retain filter passband and
alias-rejection regressions. Report unit/oracle, full-scan, and end-to-end
detection evidence as distinct scopes.

## Deferred choices

Filter redesign, parallel execution demonstration, priming or prehistory
removal, gap shortening, Simulink topology and execution mechanism, fixed-point
realization, and HDL remain deferred. The first implementation is serial and
uses the unchanged approved filter design.
