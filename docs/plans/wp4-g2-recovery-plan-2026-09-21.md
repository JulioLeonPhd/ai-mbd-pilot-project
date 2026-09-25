# WP4/G2 Recovery Plan

Date: 2026-09-21  
Baseline commit: `1d7295328958c29518c8647fff4c261bfcbe2f45`  
Status: G2 accepted by the Phase 6 root gate. Issue #3 remains open for future
checker provenance hardening; downstream WP6e may reopen G2 through a recorded
decision.

## Baseline and source of truth

The working tree was clean at the baseline commit. Frozen design intent and the
integer-tick schedule are recorded in [ADR 0018](../adr/0018-freeze-wp4-g2-phase0-contract.md).
The contract and existing WP4 materials are in
[the radar data contracts](../contracts/radar-v1-data-contracts.md) and
[`contracts/wp4/`](../../contracts/wp4/). The preceding transition context is
in [the WP3/WP4 handoff](../handoffs/wp3-wp4-handoff-2026-09-19.md) and [CURRENT.md](../../CURRENT.md).

Keep a strict distinction between frozen design intent and executable evidence:
the former is approved direction; the latter must be generated, independently
checked, and traceable before G2 can close.

## Baseline blockers (resolved by Phases 3–5)

At the initial baseline, evidence was insufficient because it contained
symbolic or non-resolvable manifest selectors, lacked numeric positive and
negative off-boresight beam fixtures, had scalar-only DDC evidence rather than
computable response/coefficient evidence, had incomplete deterministic
aggregate cluster outputs, and contained duplicated or stale normative
clauses. Phase 3 added executable fixtures and complete aggregate outputs;
Phase 4 independently validated the numerical and behavioral evidence; Phase 5
committed resolved manifest selectors and reconciled the normative clauses.
These baseline blockers are resolved for the frozen WP4 evidence. Issue #3
remains a nonblocking checker-hardening item.

Numerical fixture generation was assigned to MATLAB architecture and
implementation roles; the writer consumed the resulting artifacts and recorded
traceability. This records the original task boundary, not a current blocker.

## Phase progress

<!-- markdownlint-disable MD013 -->
| Phase | Status | Evidence / gate |
| --- | --- | --- |
| 1. Documentation contract | Complete; `da1e301` | Validated |
| 2. Numerical fixture architecture | Complete; root-approved | Recorded below |
| 3. Executable evidence | Complete; commits `cfd2bc1`, `cb95b92` | 23 artifacts; 54/54 rows; 54 tests |
| 4. Independent validation | Complete; passed | 54/54 strict rows with provenance; 54 tests; independent timing and streaming boundary validation; MATLAB Code Analyzer clean; issues #4/#5 closed |
| 5. Manifest and traceability | Complete; independent deep review passed | 54 rows use 20 distinct anchors; all resolve uniquely. Eight rows/selectors were updated in the committed manifest at source `0fe89d45` and evidence `9675b2f2`; five documents lint clean. |
| 6. Root completion gate | Complete; G2 accepted | MATLAB, provenance, document review, Markdown lint, Code Analyzer, and Mermaid checks passed. Issue #3 is a disclosed nonblocking checker-hardening task. |
<!-- markdownlint-enable MD013 -->

This plan is the detailed phase ledger and approved Phase 2 architecture record.
`CURRENT.md` is the concise current-state pointer. Phases 5 and 6 passed for
this evidence set. Issue #3 remains open for future checker hardening; Git
verified the source/evidence pair used for the gate.

## Ordered recovery workflow

Each phase is a stop/go gate. Do not begin the next phase until its evidence is
present and its validator has returned no unresolved error findings.

### Phase 1 — Consolidate the documentation contract

Route a bounded documentation task to `technical-writer`. The only writable
Phase 1 paths are:

- `docs/adr/0018-freeze-wp4-g2-phase0-contract.md`
- `docs/contracts/radar-v1-data-contracts.md`
- `docs/architecture/architecture.md`
- `docs/requirements/radar-matlab-v1.md`

`CURRENT.md` and every `contracts/wp4/` JSON file are read-only in this phase.
Remove duplicate or stale normative clauses and install literal HTML anchors on
the normative paragraphs. Allocate authority without inventing new design:
ADR 0018 owns decisions and rationale; the data contract owns envelopes, fields,
and testable invariants; architecture summarizes topology; requirements state
observable obligations. The later manifest will reference repository-relative
selectors in the form `path#anchor`. Preserve G2-open status and do not invent
numeric DSP or clustering fixtures.

Then route the result to `technical-writer-validator-deep`. Go only when the
validator confirms that the contract has one authoritative definition per rule,
anchors resolve, and the documents do not imply unverified evidence. Run
`markdownlint-cli2` on every touched Markdown file.

### Phase 2 — Design the numerical fixture architecture

Phase 2 is complete and root-approved. The selected architecture is MATLAB-only:
the generator and checker are MATLAB packages, with no Python orchestrator. The
generator owns deterministic fixture construction; the checker owns independent
recomputation and diagnostics. The generator and oracle remain structurally
independent: expected values are derived from raw inputs and coefficients, never
from stored summaries. The design covers the frozen integer-tick schedule,
continuous mixer/FIR/decimator state, deterministic /3 then /4 FIR stages,
direct-DTFT response checks, positive and negative 30-degree beam fixtures plus
boresight/zero cases, fusion and clustering recomputation, deterministic seeds
and tolerances, ordered diagnostic precedence, and explicit `draft.1`
migration adapters. A tied cluster maximum remains numeric-only; no winning
member identity is added to the schema.

The public interfaces are `report=generateWp4Fixtures(outputDirectory,options)`,
`report=checkWp4Fixtures(manifestPath,options)`, and
`[draft2,diagnostic]=adaptWp4Draft1(domain,draft1,context)`. The planned paths
are `contracts/wp4/generateWp4Fixtures.m`, `contracts/wp4/+wp4gen/`,
`contracts/wp4/checkWp4Fixtures.m`, `contracts/wp4/+wp4oracle/`,
`contracts/wp4/adaptWp4Draft1.m`,
and the historical test location `contracts/wp4/tests/TestWp4Fixtures.m`
(superseded by `tests/wp4/TestWp4Fixtures.m`),
`contracts/wp4/fixture-manifest.json`, and `contracts/wp4/fixtures/`.

The exact DDC design is mixer → 25-tap even-order-24 Kaiser beta 8.6 at
150 MHz → /3 → 241-tap even-order-240 Kaiser beta 8.6 at 50 MHz → /4,
with cutoffs 25 MHz and 5.625 MHz, 12.5 MHz output, and 372 ADC-tick /
31-output-sample delay. State is continuous and zero-initialized from scan
start, with no record resets; final phase ticks are congruent to 0 modulo 12.
The checker uses a direct DTFT on a 1 kHz grid and checks stage-1 alias branches.
Seeds are master 401002, schedule 401011, DDC 401021, beam 401031, fusion
401041, clustering 401051, and migration 401061. Structural comparisons are
exact; DDC gates use 1e-9 dB, FIR symmetry/DC 1e-13, streaming 5e-11, zero
exact, beam 1e-12, cluster means `1e-12+64*eps(1)*abs(expected)`, and
coefficient regeneration 5e-15. Diagnostics precede in this order: schema
version; required fields; type/finiteness; shape/cardinality; range/enums/
uniqueness/provenance; domain semantics.

The architect rejected a Python orchestrator, scalar-only DDC summaries, shared
generator/oracle helpers, release-sensitive optimized FIR design, a direct `/12`
stage, per-record state resets, normalized beam output, and implicit `draft.1`
acceptance. Acceptance-scope fixtures require a committed generator revision;
temporary working-tree fixtures are unit-only. The generator source must be
committed before tracked artifacts are regenerated from that exact revision.

#### Phase 2 acceptance matrix

Base fixture directory: `contracts/wp4/fixtures/`. Every row has a unique
manifest ID and a unique `matlab.unittest` method.

<!-- markdownlint-disable MD013 -->
| ID | Claim / artifact or selector | Expected | Test method |
| --- | --- | --- | --- |
| SCH-001 | Exact 151-record schedule; `schedule.json` | accept | `testScheduleValid` |
| SCH-002 | Mutate `records[23].startTick`; `schedule.json` | `TICK_DISCONTINUITY records[23].startTick` | `testScheduleTickDiscontinuity` |
| SCH-003 | First role is usable; `schedule.json` | `VALUE_OUT_OF_RANGE records[0].role` | `testScheduleRoleGrammar` |
| SCH-004 | Schema 2.0.0; `schedule.json` | `VERSION_MISMATCH schemaVersion` | `testScheduleVersionMismatch` |
| SCH-005 | Four usable counts; `schedule.json` | `DIMENSION_MISMATCH usableCounts` | `testScheduleDimensionMismatch` |
| SCH-006 | Schema 2.0.0 plus PRI zero; `schedule.json` | `VERSION_MISMATCH schemaVersion` | `testScheduleVersionPrecedence` |
| TIM-001 | Guarded leading-edge output timestamps with 372-tick delay compensation; priming and margins 54 nominal raw / 46 motion-bound raw / 40 motion-bound aligned; `timing-gate.mat` | accept | `testTimingDelayAndNearRange` |
| DDC-001 | Coefficient-derived 1 kHz response; `ddc-design.mat` | accept | `testDdcResponse` |
| DDC-002 | Full 10,553,388-tick CPI on one channel; 150 PRI/transition boundaries; 2,189 chunks; 19,480 observed output samples/timestamps across startup, end, and boundary windows; maximum absolute complex output-sample discrepancy vs independent direct convolution `1.5e-15` | accept | `testDdcStreamingState` |
| DDC-003 | Nonempty zero input produces shaped exact-zero output with 64-channel shape; `ddc-zero.mat` | accept | `testDdcZeroInput` |
| DDC-004 | Beta-2 same-length stage-2 coefficients; `ddc-ripple-invalid.mat` | `DDC_RIPPLE_EXCEEDED stage2Numerator` | `testDdcRippleDiagnostic` |
| DDC-005 | Beta-5 same-length stage-2 coefficients; `ddc-alias-invalid.mat` | `DDC_ALIAS_REJECTION stage2Numerator` | `testDdcAliasDiagnostic` |
| DDC-006 | Stopband start 6.251 MHz; `ddc-design.mat` mutation | `DDC_STOPBAND_EDGE stopbandStartHz` | `testDdcStopbandEdgeDiagnostic` |
| DDC-007 | Truncate stage-2 numerator; `ddc-design.mat` mutation | `DIMENSION_MISMATCH stage2Numerator` | `testDdcCoefficientDimension` |
| DDC-008 | Bad stopband edge plus ripple-invalid coefficients | `DDC_STOPBAND_EDGE stopbandStartHz` | `testDdcSemanticPrecedence` |
| DDC-009 | NaN coefficient; `ddc-design.mat` mutation | `NONFINITE stage2Numerator[0]` | `testDdcNonfiniteCoefficient` |
| BEAM-001 | Boresight, gain 16, four rows; `beam-boresight.mat` | accept | `testBeamBoresight` |
| BEAM-002 | Radar-left +30-degree matched manifold; `beam-positive-30deg.mat` | accept | `testBeamPositiveOffBoresight` |
| BEAM-003 | Radar-right -30-degree matched manifold; `beam-negative-30deg.mat` | accept | `testBeamNegativeOffBoresight` |
| BEAM-004 | Change command +30 to -30 without changing input/output | `NUMERICAL_MISMATCH output` | `testBeamSignInversion` |
| BEAM-005 | 63 input channels; boresight mutation | `DIMENSION_MISMATCH input` | `testBeamInputDimension` |
| BEAM-006 | Zero `[N,64]` input and zero `[N,4]` output; `beam-zero.mat` | accept | `testBeamZeroInput` |
| BEAM-007 | Wrong version plus 63 channels | `VERSION_MISMATCH schemaVersion` | `testBeamVersionPrecedence` |
| FUS-001 | Five valid, three passing; `fusion-cases.json#pass` | accept/pass/3 | `testFusionPass` |
| FUS-002 | Five valid, one passing; `fusion-cases.json#fail` | accept/fail/1 | `testFusionFail` |
| FUS-003 | One valid and passing layer; `fusion-cases.json#invalid` | accept/invalid/1 | `testFusionInvalidOutcome` |
| FUS-004 | Empty hypothesis list; `fusion-zero.json` | accept | `testFusionZeroHypotheses` |
| FUS-005 | Support outside validity; pass-case mutation | `VALUE_OUT_OF_RANGE supportMask` | `testFusionSupportSubset` |
| FUS-006 | One-element pass mask; pass-case mutation | `DIMENSION_MISMATCH passMask` | `testFusionMaskDimension` |
| FUS-007 | Threshold 2; pass-case mutation | `VALUE_OUT_OF_RANGE voteThreshold` | `testFusionThreshold` |
| FUS-008 | One-element pass mask plus threshold 2 | `DIMENSION_MISMATCH passMask` | `testFusionDiagnosticPrecedence` |
| CLU-001 | One hypothesis and complete aggregate; `clustering-single.json` | accept | `testClusterSingleAggregate` |
| CLU-002 | Two adjacent members, means/masks/IDs/union; `clustering-merge.json` | accept | `testClusterMergeAggregate` |
| CLU-003 | Permuted input gives identical canonical output; `clustering-order.json` | accept | `testClusterInputOrder` |
| CLU-004 | Opposite grid edges do not wrap; `clustering-no-wrap.json` | accept/two clusters | `testClusterNoWrap` |
| CLU-005 | Ineligible middle record does not bridge; `clustering-no-bridge.json` | accept/two clusters | `testClusterNoBridge` |
| CLU-006 | Identical cells in different looks stay separate; `clustering-cross-look.json` | accept/two clusters | `testClusterSameLook` |
| CLU-007 | Duplicate eligible cells remain two members in one component; `clustering-duplicate-cell.json` | accept | `testClusterDuplicateCell` |
| CLU-008 | `H=0,C=0`; `clustering-zero-empty.json` | accept | `testClusterZeroResult` |
| CLU-009 | `H>0,C=0`, all ineligible; `clustering-zero-ineligible.json` | accept | `testClusterAllIneligible` |
| CLU-010 | Tied maximum statistic; lowest ID is an internal tie-break and no winner ID is stored; `clustering-tie.json` | accept | `testClusterStatisticTie` |
| CLU-011 | Four-entry member validity mask; merge mutation | `DIMENSION_MISMATCH hypotheses[0].validityMask` | `testClusterMaskDimension` |
| CLU-012 | Wrong stored aggregate range mean; merge mutation | `NUMERICAL_MISMATCH clusters[0].rangeM` | `testClusterAggregateMismatch` |
| CLU-013 | Unknown aggregate member ID; merge mutation | `VALUE_OUT_OF_RANGE clusters[0].hypothesisIds[1]` | `testClusterUnknownMember` |
| CLU-014 | Bad member mask plus wrong aggregate mean | `DIMENSION_MISMATCH hypotheses[0].validityMask` | `testClusterDiagnosticPrecedence` |
| MIG-001 | Direct draft.1 schedule check | `VERSION_MISMATCH schemaVersion` | `testDraft1DirectRejection` |
| MIG-002 | Explicit schedule adapter | accept draft.2 | `testDraft1ScheduleAdapter` |
| MIG-003 | Explicit DDC adapter, response recomputed from context coefficients | accept draft.2 | `testDraft1DdcAdapter` |
| MIG-004 | Explicit fusion adapter | accept draft.2 | `testDraft1FusionAdapter` |
| MIG-005 | Explicit clustering adapter | accept draft.2 | `testDraft1ClusterAdapter` |
| MIG-006 | Missing commanded-look context | `MISSING_FIELD context.commandedLooks` | `testDraft1MissingLookContext` |
| MIG-007 | Ambiguous commanded-look mapping | `PROVENANCE_MISMATCH context.commandedLooks[1]` | `testDraft1AmbiguousLookContext` |
| META-001 | Every clause is `path#anchor`; IDs/artifacts/methods are unique and resolvable | accept | `testManifestTraceability` |
| META-002 | Generator has no oracle dependency and oracle has no generator/DSP-response dependency | accept | `testGeneratorOracleSeparation` |
<!-- markdownlint-enable MD013 -->

### Phase 3 — Generate executable evidence

Route the approved architecture to `matlab-implementer`. Follow the versioned
MATLAB standards bundle in `docs/standards/matlab/README.md` and
`docs/standards/matlab/matlab-coding-standards.md`. Implement the selected
MATLAB-only generator, checker, oracles, and migration adapters; do not add a
Python orchestrator. Generate the schedule, positive/negative off-boresight
beam fixtures, DDC coefficients and measurable response/alias evidence, fusion
inputs/outputs, and complete deterministic cluster aggregates.
Add focused `matlab.unittest` tests covering every Phase 2 matrix row,
including invalid, zero-result, version/dimension mismatch, migration, and
combined diagnostic precedence. Run the MATLAB Code Analyzer, resolving all
reported errors and warnings.

Completed in source commit `cfd2bc1897d5985fb192a2bc33f62a7715a8be40` and
immutable generator revision `cb95b925d2e91e4d8de4d7cff89d590dd172fc2e`.
The user-directed revised layout puts production-like floating-point domain
modules in `src/+radardemo/`; `contracts/wp4/+wp4gen/` contains fixture
generation, `+wp4oracle/` independent checks, and adapters, while
`tests/wp4/TestWp4Fixtures.m` contains the 54 acceptance methods. Precommit
validation recorded 23 physical artifacts, 54/54 strict rows, exactly 54
passing tests, clean Code Analyzer results for 32 `.m` files, and an independent
source review with no unresolved errors. Measured DDC ripple is
`0.00067200911666936 dB`; stage-2 rejection is `87.7676669047022 dB`; full
cascade rejection is `85.2548307898255 dB`.

Historical Phase 3 generated evidence used source revision
`cb95b925d2e91e4d8de4d7cff89d590dd172fc2e` and
`CreatedUtc=2026-09-21T20:44:03Z`. This is retained only as historical
provenance and is not the current replay procedure.

The current committed source/evidence pair is source
`0fe89d45fa20a9f0f68ae6908855dbc61835b083` and evidence
`9675b2f2de654d6701fc6001552c23318e0db87e`, with
`CreatedUtc=2026-09-24T13:56:08Z`. Git verified the pair. Use the canonical
replay and semantic comparison procedure in [CURRENT.md](../../CURRENT.md).
The manifest checker’s synthetic 40-hex revision limitation remains tracked
under issue #3.

### Phase 4 — Independently validate MATLAB evidence

**Status: passed.** Independent validation passed all 54 strict manifest rows
with provenance, all 54 tests, the timing metrics (54/46/40 ADC ticks), the
151-record schedule with five priming and 142 usable records, and full-CPI DDC
streaming over one channel and 150 PRI/transition boundaries. The replay
covered 2,189 chunks and 19,480 observed output samples/timestamps selected
across startup, end, and boundary observation windows. Maximum absolute
complex output-sample discrepancy against independent direct convolution was
`1.5e-15`; MATLAB Code Analyzer was clean. Issues #4 and #5 are closed. Phase 4
passed, and Phases 5 and 6 subsequently passed; the root accepted G2 for the
frozen WP4 evidence. Evidence scope does not establish complete FIR
precursor/waveform retention or detection performance.

The independent validator recomputed timing and DDC evidence, beam sign and
off-boresight behavior, finite-filter response and alias rejection, fusion,
clustering, and deterministic aggregate outputs. It exercised valid, invalid,
legal zero-result, version-mismatch, dimension-mismatch, `draft.1` migration,
and combined diagnostic-precedence cases, using independent recomputation from
raw inputs and coefficients. Phase 4 passed with no unresolved errors.

### Phase 5 — Finalize manifest and traceability documentation

**Status: passed.** The generated artifact paths, test operations, and stable
anchors are recorded in the committed manifest. All 54 rows resolve to 20
unique anchors; eight rows/selectors were updated. The five documents passed
Markdown lint and independent deep semantic review. Issue #3’s synthetic
40-hex revision limitation is disclosed and remains tracked; Git verified the
current source/evidence pair.

### Phase 6 — Root completion gate

**Status: passed.** The root verified the requested artifacts, completed role
results, passing Markdown and diff checks, recorded MATLAB checks, and no
unresolved validator errors. G2 is accepted for the frozen WP4 evidence.
GitHub issue #3 remains a nonblocking hardening task because the source/evidence
pair was verified against Git and deterministic replay. Downstream WP6e may
reopen G2 through a recorded decision.

## Historical Phase 3 implementation handoff (superseded)

The following packet records the original Phase 3 dispatch and is retained for
history only; it is not a current instruction. Phase 3 is complete. The current
scope is `src/+radardemo/**`, `contracts/wp4/` generator/oracle/adapters, and
`tests/wp4/**`; the old contracts-only mutation scope and revision placeholder
are superseded.

```yaml
task:
  id: "wp4-g2-phase3-executable-evidence"
  objective: >
    Implement the approved MATLAB-only architecture and generate executable
    WP4/G2 evidence
  context: >
    G2 is open. Phase 1 is committed at da1e301 and Phase 2 is root-approved.
  inputs:
    - "ref: docs/plans/wp4-g2-recovery-plan-2026-09-21.md @ <commit-containing-this-plan>"
    - "ref: docs/adr/0018-freeze-wp4-g2-phase0-contract.md @ da1e301"
    - "ref: docs/contracts/radar-v1-data-contracts.md @ da1e301"
    - "ref: contracts/wp4/ @ da1e301 (historical source layout)"
  constraints:
    - "Route to matlab-implementer; use MATLAB only and no Python orchestrator."
    - "Historical constraint: mutations were limited to contracts/wp4/."
    - "Historical requirement: replace the plan revision placeholder before dispatch."
    - >
      Preserve no-WP6e-method constraints and stop before tracked regeneration
      for root authorization.
    - >
      Retain G2-open status and avoid duplicating schedule values already
      authoritative in ADR 0018.
  acceptance_criteria:
    - "Generate and test the exact 54 Phase 2 matrix methods."
    - "Run MATLAB Code Analyzer with no unresolved errors or warnings."
    - "Pin the generator source revision before tracked fixture regeneration."
  allowed_mutations:
    - "contracts/wp4/ (historical; current scope also includes src/+radardemo/"
    - "and tests/wp4/)"
  requested_checks:
    - "MATLAB Code Analyzer on every created or edited .m file"
    - "All 54 matlab.unittest methods"
    - "Temporary generator and checker run before immutable-source commit"
    - "Tracked regeneration and semantic recheck from the committed revision"
```

## Suggested skills

- `handoff` — only when refreshing this note for another session.
- `specifying-mbd-algorithms` — when sharpening the numerical acceptance
  matrix or interfaces.
- `diagrammer` — only if a Mermaid diagram is added or changed.
- `docs/standards/matlab/README.md` and
  `docs/standards/matlab/matlab-coding-standards.md` — required MATLAB
  standards references during Phases 2–4.
- Applicable MATLAB testing and numerical-analysis skills during Phases 3–4.
