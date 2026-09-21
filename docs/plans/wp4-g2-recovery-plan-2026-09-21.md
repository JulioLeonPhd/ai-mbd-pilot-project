# WP4/G2 Recovery Plan Handoff

Date: 2026-09-21  
Baseline commit: `1d7295328958c29518c8647fff4c261bfcbe2f45`  
Status: G2 remains open; this note records the approved recovery workflow, not acceptance.

## Baseline and source of truth

The working tree was clean at the baseline commit. Frozen design intent and the
integer-tick schedule are recorded in [ADR 0018](../adr/0018-freeze-wp4-g2-phase0-contract.md).
The contract and existing WP4 materials are in
[the radar data contracts](../contracts/radar-v1-data-contracts.md) and
[`contracts/wp4/`](../../contracts/wp4/). The preceding transition context is
in [the WP3/WP4 handoff](wp3-wp4-handoff-2026-09-19.md) and [CURRENT.md](../../CURRENT.md).

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

Route an implementation-free design task to `matlab-architect-deep`. Specify
generator and checker interfaces, fixture ownership, independent-oracle policy,
deterministic seeds and tolerances, and the exact acceptance matrix for
schedule, beam steering, DDC, fusion, and clustering. The checker shall be a
MATLAB checker for numerical fixture semantics; a thin Python manifest
orchestrator is optional only if needed. If Python is selected, create a
separate bounded Python implementation task (not `matlab-implementer`) with
Ruff check/format and applicable Pyright checks. In all cases the checker
computes expected results from inputs and coefficients; it never trusts stored
summary values.

The architecture must decide finite-filter stage allocation and order,
coefficient representation, deterministic design procedure, and an independent
response calculation. Its matrix must cover numerical domains plus valid,
invalid, zero-result where legal, version-mismatch, dimension-mismatch,
`draft.1` migration-adapter, and combined diagnostic-precedence cases.
The architect must not edit implementation artifacts in this phase.

Go only when the architecture identifies how expected values are independently
derived and how each acceptance claim maps to a generated artifact and test.

### Phase 3 — Generate executable evidence

Route the approved architecture to `matlab-implementer`. Follow the versioned
MATLAB standards bundle in `docs/standards/matlab/README.md` and
`docs/standards/matlab/matlab-coding-standards.md`. Implement the selected
MATLAB checker and assign any selected Python orchestrator to its separate
Python implementation task. Generate the schedule, positive/negative
off-boresight beam fixtures, DDC coefficients and measurable response/alias
evidence, fusion inputs/outputs, and complete deterministic cluster aggregates.
Add focused `matlab.unittest` tests covering every Phase 2 matrix row,
including invalid, zero-result, version/dimension mismatch, migration, and
combined diagnostic precedence. Run the MATLAB Code Analyzer, resolving all
reported errors and warnings; Python work must run its assigned Ruff and
Pyright checks.

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

## First task for the next session

Start Phase 1 with this bounded packet:

```yaml
task:
  id: "wp4-g2-phase1-contract-consolidation"
  objective: >
    Consolidate WP4/G2 normative documentation and install resolvable anchors
  context: >
    G2 is open. Preserve ADR 0018 design intent; repair documentation
    traceability before numerical implementation.
  inputs:
    - "ref: docs/adr/0018-freeze-wp4-g2-phase0-contract.md @ 1d7295328958c29518c8647fff4c261bfcbe2f45"
    - "ref: docs/contracts/radar-v1-data-contracts.md @ 1d7295328958c29518c8647fff4c261bfcbe2f45"
    - "ref: contracts/wp4/ @ 1d7295328958c29518c8647fff4c261bfcbe2f45"
    - "ref: CURRENT.md @ 1d7295328958c29518c8647fff4c261bfcbe2f45"
  constraints:
    - "Documentation only; do not create numerical fixtures or MATLAB implementation."
    - "Writable paths are exactly the four Phase 1 documentation paths listed above."
    - "CURRENT.md and contracts/wp4 JSON files are read-only."
    - >
      Retain G2-open status and avoid duplicating schedule values already
      authoritative in ADR 0018.
  acceptance_criteria:
    - "Duplicate/stale normative clauses are resolved or explicitly subordinated."
    - "Manifest-facing anchors resolve to stable clauses."
    - "Technical-writer-validator-deep reports no unresolved error findings."
  allowed_mutations:
    - "docs/adr/0018-freeze-wp4-g2-phase0-contract.md"
    - "docs/contracts/radar-v1-data-contracts.md"
    - "docs/architecture/architecture.md"
    - "docs/requirements/radar-matlab-v1.md"
  requested_checks:
    - "markdownlint-cli2 on every touched Markdown file"
    - "Anchor/link resolution"
```

## Suggested skills

- `handoff` — only when refreshing this note for another session.
- `specifying-mbd-algorithms` — when sharpening the numerical acceptance
  matrix or interfaces.
- `diagrammer` — only if a Mermaid diagram is added or changed.
- `docs/standards/matlab/README.md` and
  `docs/standards/matlab/matlab-coding-standards.md` — required MATLAB
  standards references during Phases 2–4.
- Applicable MATLAB testing and numerical-analysis skills during Phases 2–4;
  use Python tooling skills only if Phase 2 selects a Python orchestrator.
