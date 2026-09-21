# WP4/G2 Recovery Plan

Date: 2026-09-21  
Baseline commit: `1d7295328958c29518c8647fff4c261bfcbe2f45`  
Status: G2 remains open; this note records the approved recovery workflow, not acceptance.

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

## Known blockers

The current evidence is insufficient because it contains symbolic or
non-resolvable manifest selectors, no numeric positive and negative
off-boresight beam fixtures, scalar-only DDC evidence rather than computable
response/coefficient evidence, incomplete deterministic aggregate cluster
outputs, and duplicated or stale normative clauses across documents.

Numerical fixture generation must not be assigned to `technical-writer`. The
MATLAB architecture and implementation roles own numerical definitions and
artifacts; the writer consumes real artifacts and records traceability.

## Phase progress

| Phase | Status | Evidence / gate |
| --- | --- | --- |
| 1. Documentation contract | Complete; `da1e301` | Validated |
| 2. Numerical fixture architecture | Complete; root-approved | Recorded below |
| 3. Executable evidence | Next; not started | MATLAB handoff below |
| 4. Independent validation | Pending | Requires Phase 3 artifacts |
| 5. Manifest and traceability | Pending | Requires validated artifacts |
| 6. Root completion gate | Pending | G2 remains open |

This plan is the detailed phase ledger and approved Phase 2 architecture record.
`CURRENT.md` is the concise current-state pointer. Phase completion does not
close G2 until executable evidence and independent validation pass.

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
`contracts/wp4/tests/TestWp4Fixtures.m`,
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
| TIM-001 | Decimation alignment, 372-tick delay, priming, and 54-tick near-range margin; `timing-gate.mat` | accept | `testTimingDelayAndNearRange` |
| DDC-001 | Coefficient-derived 1 kHz response; `ddc-design.mat` | accept | `testDdcResponse` |
| DDC-002 | Real mixer, unequal chunks, continuous state and /3,/4 phases; `ddc-streaming.mat` | accept | `testDdcStreamingState` |
| DDC-003 | Nonempty zero input produces shaped exact-zero output; `ddc-zero.mat` | accept | `testDdcZeroInput` |
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

The implementation result must identify exact artifact paths, test names,
tolerances, and reproducible generation commands. A stored summary value alone
does not satisfy the DDC gate.

### Phase 4 — Independently validate MATLAB evidence

Route the generated artifacts and acceptance matrix to `matlab-validator-deep`.
The validator inspects and tests; it does not repair files under a validation
assignment. Require independent checks of integer timing, beam sign and
off-boresight behavior, DDC ripple and at least 60 dB digital decimation-alias
rejection, fusion, clustering, and deterministic aggregate outputs. The
validator must also exercise valid, invalid, legal zero-result,
version-mismatch, dimension-mismatch, `draft.1` migration-adapter, and combined
diagnostic-precedence paths. Recompute expected numerical values from raw
inputs/coefficients under the independent-oracle policy.

Stop for a bounded design or implementation fix if any error remains. Proceed
only with a complete result packet and no unresolved error findings.

### Phase 5 — Finalize manifest and traceability documentation

Give the real generated artifact paths, test operations, and stable Phase 1
anchors to `technical-writer`. The writer finalizes the manifest and updates
current documentation without fabricating evidence. Route the finished complex
documentation to `technical-writer-validator-deep`; require resolved anchors,
correct agent/tool names, and traceability from each acceptance clause to an
executable artifact or an explicit accepted limitation. Apply the manifest
gate: use the approved schema, exact target path, and exact checker/tool names;
run JSON syntax and schema validation; then obtain root semantic review. Keep
G2 open and do not mark `CURRENT.md` passed in this phase.

### Phase 6 — Root completion gate

The root agent verifies that all requested artifacts exist, the relevant role
returned `complete`, Markdown lint and diff checks pass, MATLAB checks are
recorded, and no validator has unresolved errors. Only then may the root close
G2 and update `CURRENT.md`. If a required checker is unavailable, disclose it;
do not treat unavailability as a pass.

## Phase 3 implementation handoff

Start Phase 3 with this bounded packet. Generate and test temporary fixtures
first; stop for root authorization of the immutable generator-source commit,
then regenerate tracked fixtures from that exact revision.

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
    - "ref: contracts/wp4/ @ da1e301"
  constraints:
    - "Route to matlab-implementer; use MATLAB only and no Python orchestrator."
    - "Mutations are limited to contracts/wp4/."
    - "Replace the plan revision placeholder with its immutable commit before dispatch."
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
    - "contracts/wp4/"
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
