# Per-PRI DDC implementation plan

**Status:** ADR 0022 records the accepted direction. Implementation awaits
Phase 0 decisions and Julio's explicit go. This plan does not authorize MATLAB
or Simulink changes.

## Phase 0: freeze interface and evidence migration

Resolve the exact `processFrame` signature, output shape, timing metadata,
zero-flush tail representation, and ownership of pulse-compression window
validity. `[output,metadata] = processFrame(adcPri,design,priContext)` is only a
candidate. The approved boundary is one complete physical PRI as real floating
point `[N,C]`; `N` and `startTick` align to 12 ADC ticks relative to the common
epoch. Specify expected length and identity checks, and acquired versus padded
row provenance. One proposed output concatenates `N/12` acquired rows and 62
tail rows: append 744 zero input samples, yielding proposed tail raw ticks
`N..N+732`. Proposed compensated coordinates are signed `12*k - 372`. These
shape and coordinate details are proposals, not approved contract. Also resolve
the proposed ownership split: DDC reports processing/padding provenance;
downstream range integration defines acquired/blanked pulse-compression-window
validity. Julio must choose or revise these details in Phase 0 before
implementation. Confirm adapter handling of gaps: preserve gap intervals and
timestamps without passing a gap as a physical PRI.

Choose a narrow, versioned evidence migration. Keep the historical DDC-002
witness recorded and replayable at its pinned continuous-state revision; do not
relabel it as per-PRI acceptance. Preserve current passband and alias-budget
regressions. A global version bump is not assumed.

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
   gaps. Keep `int16` storage compact and convert each selected PRI to floating
   point at the agreed processing boundary.
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

Use an independently derived combined-FIR convolution oracle after global
mixing and local zero extension. The proposed normalized tolerance is `5e-11`;
justify it against oracle numerical behavior rather than treating it as an
approved relaxation. Cover all five PRI lengths, one and 64 channels, channel
isolation, exact zero, first/last-sample impulses, 40-microsecond chirps near
boundaries, and multitone plus seeded noise. Check exact shape, ticks, tail
metadata, 31-period group-delay compensation, all PRF phases, invalid/incomplete
PRIs, and lengths/start ticks not aligned to 12 (including a 3-tick case).
Repeated, reversed, and shuffled calls must produce identical per-PRI results
and metadata.

Compare the old continuous reference only at acquired samples with local raw
ADC ticks `>= 744` (zero-based output index 62), excluding every padded-tail
row. This is after full cascade memory. Do not require startup or padded-tail
equivalence. Keep startup transient in the blind range. Padding
cannot make an unavailable physical sample valid. Retain filter passband and
alias-rejection regressions. Report unit/oracle, full-scan, and end-to-end
detection evidence as distinct scopes.

## Deferred choices

Filter redesign, parallel execution demonstration, priming or prehistory
removal, gap shortening, Simulink topology and execution mechanism, fixed-point
realization, and HDL remain deferred. The first implementation is serial and
uses the unchanged approved filter design.
