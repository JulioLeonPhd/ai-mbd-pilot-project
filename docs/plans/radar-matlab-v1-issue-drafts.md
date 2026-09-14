# Radar MATLAB V1 issue drafts

<!-- markdownlint-disable MD013 -->

These drafts correspond to the work packages in the V1 plan. They are prepared
for GitHub Issues but have not been published. Authenticated `gh` access was
verified outside the sandbox on 2026-09-14. The labels below are proposed
tracker labels, not published issue state.

## WP0 — Baseline and tracking

**Status:** Completed; GitHub publication pending.

**Deliverable:** Establish the plan, `CURRENT.md`, package issue drafts, and
gate/status conventions.

**Acceptance criteria:**

- The saved V1 plan and `CURRENT.md` exist and cross-reference each other.
- Every package has an issue-ready draft with predecessor edges.
- G0 status and the next ready work are recorded in `CURRENT.md`.

## WP1 — Requirements

**Blocked by:** WP0; numerical parameters remain subject to WP2 feasibility

**Deliverable:** Versioned requirements specification, evidence matrix, and V1
Pd/Pfa decision record.

**Acceptance criteria:**

- Requirements have stable IDs and link to planned verification evidence.
- Accepted requirements are separated from provisional goals.
- The ADR 0009 V1 Pd/Pfa clarification is recorded without changing other
  accepted requirements.

**Proposed label:** `ready-for-agent`

## WP2 — Quantitative feasibility

**Blocked by:** WP0

**Deliverable:** MATLAB MCP studies covering link budget, waveform and sampling,
PRF ambiguity, beam/angle, and timing.

**Acceptance criteria:**

- Each study records assumptions, units, inputs, outputs, and reproducible
  evidence.
- Feasible baseline parameters and unavailable-toolbox dependencies are listed.
- WP1 receives a documented G1 decision or an explicit unresolved decision.

**Proposed label:** `ready-for-agent`

## WP3 — Data contracts

**Blocked by:** G1

**Deliverable:** Versioned configuration, scenario, MAT test-vector,
intermediate-processing, and detection-list contracts with examples.

**Acceptance criteria:**

- Contracts define dimensions, units, coordinate/sign conventions, versions, and
  invalid-input behavior.
- Examples validate against each contract.
- Every WP6 stage has a fixture-compatible intermediate contract.

**Proposed label:** `needs-triage`

## WP4 — DSP architecture

**Blocked by:** G1

**Deliverable:** Frozen DSP stage order, interfaces, data shapes/rates,
verification seams, and required diagrams.

**Acceptance criteria:**

- Architecture covers the DUT boundary and every processing stage.
- Mermaid diagrams show data flow and timing/PRF/blanking relationships.
- Independent review finds no unresolved contract or topology errors at G2.

**Proposed label:** `needs-triage`

## WP5 — Stimulus and fixtures

**Blocked by:** G2; WP3 and WP4

**Deliverable:** Seeded JSON-driven generator and reproducible MAT fixtures for
primary and edge cases.

**Acceptance criteria:**

- Re-running a seed reproduces identical fixture content.
- Fixtures conform to the versioned contracts.
- Primary, two-target, folded, and invalid-input cases are represented.

**Proposed label:** `needs-triage`

## WP6 — Reference processing

**Blocked by:** G2; WP6 subpackages below

**Deliverable:** Independently tested floating-point processing stages and a
selected ambiguity-resolution method.

**Acceptance criteria:**

- Every subpackage passes its focused unit-test gate and reports analyzer
  evidence.
- Stage outputs conform to intermediate contracts.
- WP6f integrates the selected method documented by WP6e.

**Proposed label:** `needs-triage`

## WP6a — DDC and decimation

**Blocked by:** G2; WP3 and WP4

**Deliverable:** DDC and decimation implementation with unit tests.

**Acceptance criteria:**

- Known tones meet agreed output rate, frequency, amplitude, and phase checks.
- Dimensions and complex/real conventions match the contract.
- Anti-alias behavior is covered by a focused test.

**Proposed label:** `needs-triage`

## WP6b — Range processing

**Blocked by:** WP6a; G2 contracts

**Deliverable:** Calibrated range processing with unit tests.

**Acceptance criteria:**

- Known LFM echoes map to the expected range bins.
- An ideal high-SNR fixture preserves two peaks separated by 1 m.
- Output dimensions and calibration metadata conform to the contract.

**Proposed label:** `needs-triage`

## WP6c — Single-PRF Doppler processing

**Blocked by:** WP6b; G2 timing decisions

**Deliverable:** Single-PRF Doppler processing with unit tests.

**Acceptance criteria:**

- Known approaching and receding velocities map to correct bins and signs.
- Native unambiguous velocity limits are reported and tested at or above ±40
  m/s.
- Boundary and zero-Doppler behavior is documented.

**Proposed label:** `needs-triage`

## WP6d — Receive angle processing

**Blocked by:** G2; WP3 and WP4

**Deliverable:** Simultaneous azimuth/elevation receive beamforming with unit
tests.

**Acceptance criteria:**

- Synthetic 16×4 data returns correct boresight.
- Specified off-axis azimuth/elevation signs are verified.
- Output dimensions and angle conventions conform to the contract.

**Proposed label:** `needs-triage`

## WP6e — Range/velocity ambiguity study

**Blocked by:** G2; WP2 PRF feasibility evidence

**Deliverable:** Executable comparison of ambiguity-resolution candidates and a
decision record documenting successes and failed candidates.

**Acceptance criteria:**

- Folded cases through ±800 km/h, range aliases, competing targets, and
  inconsistent measurements are evaluated.
- Candidate assumptions and failure evidence are reproducible.
- One candidate passes the selection cases. If none passes, dependent work
  stops; the root records failed-candidate evidence in the report and
  `CURRENT.md`, reopens the affected G1/G2 gate, routes WP2/WP4/contract or ADR
  revision as needed, reruns the corresponding independent review, and resumes
  only after the gate passes.

**Proposed label:** `needs-triage`

## WP6f — Ambiguity-resolution implementation

**Blocked by:** WP6e selection gate

**Deliverable:** Implementation of the selected ambiguity-resolution method with
  unit tests.

**Acceptance criteria:**

- Synthetic per-PRF candidate lists resolve agreed folded cases.
- Alias boundaries and ambiguous-input behavior are tested and documented.
- Output conforms to the intermediate and detection contracts.

**Proposed label:** `needs-triage`

## WP7 — Detection and reports

**Blocked by:** G2

**Deliverable:** CA-CFAR, near-zero-Doppler handling, clustering, and detection
report formatting.

**Acceptance criteria:**

- Synthetic fixtures verify detections, misses, clutter-band handling, and
  clustering.
- Detection-list fields, units, and signs conform to the contract.
- Focused tests pass independently of WP6 implementation.

**Proposed label:** `needs-triage`

## WP8 — Integration and verification

**Blocked by:** WP5, WP6a–WP6f, and WP7

**Deliverable:** Seeded end-to-end runs and independent numerical verification.

**Acceptance criteria:**

- The primary fixture uses a 10 m² target at 100 km at the common scan midpoint
  approximately 800 km/h, with motion and range migration across the CPI; 1 m
  two-target, velocity-separated, and unfolded cases run reproducibly.
- Contract, sign, invalid-input, and detection-list checks pass.
- Monte Carlo Pd/Pfa estimates include seeds, trials, method, estimates, and
  confidence bounds.

**Proposed label:** `needs-triage`

## WP9 — Documentation and handoff

**Blocked by:** G4

**Deliverable:** Reproduction guide, evidence index, limitations, updated
`CURRENT.md`, and fixed-point/Simulink handoff.

**Acceptance criteria:**

- Documentation links to implementation and verification evidence.
- Markdown linting and Mermaid rendering pass.
- Independent semantic review finds no unresolved documentation errors.

**Proposed label:** `needs-triage`
