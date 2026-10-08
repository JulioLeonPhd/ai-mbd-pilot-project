# Human-led MATLAB development plan

## Governing agreement

Julio owns architectural decisions. Agents may propose concrete alternatives,
diagrams, and experiments, then implement choices Julio approves. Independent
verification provides evidence; it does not constitute human approval.

Human approval is required for system decomposition, interfaces, algorithm
choices, state and timing behavior, and consequential requirement changes.
Routine implementation within an approved decision does not need a new
approval. Historical decisions remain the baseline until Julio explicitly
revises them. Tests and experiments provide evidence about behavior; they do
not establish that Julio approved a choice or understood it.

## Architecture interview completion gate

On 2026-09-26 Julio confirmed the complete Q1–Q22 summary; the interview is
complete. ADRs 0019–0021 consolidate the approved decisions and open studies.
Independent review of these ADRs passed on 2026-09-26 with no unresolved
semantic findings. This review is evidence and does not replace human review of
the redrawn diagrams. Resolve any future findings before dependent
implementation. Preserve existing ADR history and explicitly
supersede only clauses changed by confirmed decisions. Keep remaining questions
and studies open in the ADRs; do not treat their authorship as independent
approval.

## Current progress

Steps 1 and 2 are drafted and passed independent document review on 2026-09-26.
The top-level overview and three diagrams are in the main working tree at
`docs/architecture/radar-overview.md`; their PlantUML syntax/render checks and
preview inspection passed, and the documents passed independent review.
Julio's visual review of the redrawn views remains pending. Julio closed the
joint DDC design discussion on 2026-09-29 and confirmed the Phase 0 interface
and evidence migration on 2026-10-02, then explicitly authorized implementation.
The per-PRI core and WP4 suites and full-scan walkthrough pass. Pinned DDC-002
replay passed strict 1/1 at its historical revision, and all 23 historical
fixture hashes remain unchanged. Independent numerical validation passed,
including the exact-zero and inactive-channel oracle checks. Julio approved
the DDC walkthrough on 2026-10-08; implementation review and merge-readiness
work remain ongoing. Julio's visual review of the separate
redrawn architecture views remains unapproved; see [CURRENT.md](../../CURRENT.md).
The repeat-component workflow remains incomplete.

## Ordered work

### 1. Establish the working agreement and branch rules

Update `AGENTS.md` to state the agreement above and align the affected
`.codex/agents/*.toml` specialist definitions with it. The initial branch is
`docs/human-led-workflow`. Create `architecture/radar-overview` and
`component/ddc-walkthrough` for their corresponding steps.

Use a branch for each coherent component or change, based on the agreed
integration branch. Sequential guided work may use the main checkout; a branch
does not require a separate checkout. Use a worktree when concurrent work needs
isolation, preferably as a sibling of the repository rather than nested inside
it. Integrate a change before dependent work starts, or record its dependency.
Branches and worktrees do not authorize automatic merges or pushes.

Completion: the human decision boundary, approval points, and branch/dependency
rules are documented consistently in `AGENTS.md` and the affected specialist
definitions.

### 2. Improve the project overview and current-state references

Revise `README.md`, `CONTEXT.md`, and `CURRENT.md`:

- `README.md` explains the project purpose, learning goals, architecture
  diagram, current capability, a starting example, and human and agent roles.
- `CONTEXT.md` remains the domain glossary, starting with radar and DSP
  concepts. Preserve mathematical conventions. Move workflow vocabulary to an
  appropriate workflow reference rather than mixing it into domain terms.
- `CURRENT.md` stays concise: capabilities, limitations, and the next open
  question, with links to evidence and history.

Completion: readers can find project orientation, domain terms, and current
status in the appropriate document, with claims linked to their evidence.

### 3. Add a PlantUML radar architecture overview

Create a versioned PlantUML source and a browsable rendered preview. Show
context, processing, data, and timing views. Preserve the accepted processing
flow in which post-CFAR 3-of-5 fusion feeds clustering. Show WP6e
ambiguity-resolution ordering and method as unresolved. Mark each item as
implemented, accepted but unimplemented, or unresolved. Show the current
baseline before proposed changes, and have Julio review proposals before code
is restructured.

The environment observed on 2026-09-25 had MATLAB R2026a, Simulink, and DSP
installed. System Composer was absent from the installed toolbox report; this
does not establish a licensing status. Use PlantUML as the fallback. Inspect
Java, Graphviz, and available rendering support first, and install missing
dependencies when needed. MCP use is optional and should answer a demonstrated
need. Existing Mermaid diagrams may remain.

Completion: Julio has reviewed the top-level architecture; the source and
rendered preview are versioned and browsable; the diagram distinguishes
implementation status; and unresolved architecture is visible rather than
implied.

### 4. Build a guided DDC walkthrough on its own branch

On `component/ddc-walkthrough`, build examples that call the MATLAB
implementation. Pair the runnable example with an algorithm/functionality
diagram that traces its signal transformations and per-PRI state reset. Explain
translation, filtering, decimation, signal shapes, units, rates, mixer and
filter behavior, and phase state. Include normal and broken-state experiments,
spectra, and timing diagrams. The walkthrough is for learning first; use what
it reveals to decide which refactors are needed, while preserving useful
namespaces.

After the complete MATLAB receiver/reference implementation and module
interfaces are clear and reviewed, use the first MATLAB revision to explore
DDC filtering and decimation optimization before Simulink work. Julio gave this
direction on 2026-10-03; candidate filter structures remain proposals until he
reviews their evidence. Compare candidates against the approved 0.1 dB overall
ripple and 60 dB alias rejection budgets, preserving filtering before
decimation. A CIC decimator followed by an FIR anti-alias filter is one
candidate for study, not an accepted replacement. Then build a behavioral
Simulink version first. It should express the approved algorithms, interfaces,
fixed dimensions, signal timing, and meaningful buffering behavior;
it need not be cycle-accurate. A separate implementation-oriented Simulink
version may follow with more detailed hardware-oriented structure. HDL remains
deferred. Neither stage requires a one-to-one mapping from MATLAB functions to
Simulink internals.

Completion: a reader can run the DDC example, trace the implemented per-PRI
behavior, and inspect its oracle, response, and timing evidence. Preserve pinned
historical continuous-state evidence as a separate profile.

### 5. Repeat the component workflow

Apply the reviewed architecture and DDC learning workflow to the next
component, selecting it with Julio. Pair its runnable example with an
algorithm/functionality diagram that tells the same behavior story. Open
engineering tickets around a question and expected behavior first. Record the
evidence question, experiment, result, and limits before adding traceability.
Keep human decisions and agent contributions truthful and distinct.

Completion: the next component has an agreed question and behavior, evidence
and limits, and explicit human decisions before implementation proceeds.

## Deferred tasks

### DDC architecture review decisions

The DDC design choices below are approved and implemented in the MATLAB
reference. The historical implementation accepted variable frames with
continuous state. Julio approved independent per-PRI processing on 2026-09-29,
confirmed the sample-only API and responsibilities on 2026-10-02, and authorized
implementation that day. Scoped core and WP4 tests, the full-scan walkthrough,
pinned DDC-002 replay, and fixture-preservation audit passed. Independent
numerical validation passed, including exact-zero and inactive-channel checks.
Julio approved the DDC walkthrough on 2026-10-08; implementation review and
merge-readiness work remain ongoing. The historical G2 continuous-state
baseline remains separate. Future
Simulink models use fixed dimensions per configured model; execution choices
remain deferred. Channel count is configurable for tests, with 64 as the default.

**Settled:** Preserve raw ADC samples as `int16` on disk and in the loaded ADC
matrix. The caller converts each selected complete physical PRI to `double` at
the DDC call boundary. The same compact raw matrix can be reused by a future
Simulink path.

**Settled for the pilot:** ADC samples form a correctly sampled, contiguous
timeline. Reject missing samples or discontinuous ADC ticks; do not infer or
fill gaps. ADC timeline continuity and global ticks remain intact across frame,
pulse, and PRF boundaries. The former no-reset DDC state clause is superseded
by ADR 0022: each current DUT call starts fresh local state for one complete
physical PRI. This continuity rule does not determine what signal values
represent transmit blanking.

**Direction:** Express ADC voltage at the ADC input, after modeled receiver
gain or attenuation. The storage reader reconstructs quantized ADC-input
voltage from raw `int16` samples using a declared ADC conversion scale in
volts-per-LSB. This scale is metadata for code-to-voltage conversion, not a
channel calibration algorithm, and conversion does not silently undo receiver
gain. Choose the scale against the expected signal and clutter range from the
radar equation.

**Settled behavior requirement:** Use the same ideal receiver gain and ADC
conversion scale for all 64 channels. Hardware channel mismatch estimation,
correction, and calibration algorithms are outside the pilot scope. The future
generator clips/saturates samples to the representable ADC limits, reports
clipped sample counts per channel, and never rescales a scenario to fit. Check
normal scenarios for headroom and keep intentional overload scenarios distinct.

**Unresolved:** Numerical conversion scale, reference impedance, receiver gain,
and voltage/full-scale convention still need decisions. Future pre-ADC AGC/STC
effects belong in the stimulus or frontend model. No AGC controller design or
DUT boundary expansion is approved. The voltage units do not prescribe a future
Simulink arithmetic data type.

### DSP module boundaries and execution questions

**Settled:** Keep range processing, a combined pulse-accumulation and
range-migration handling responsibility, Doppler processing, CFAR, multi-PRF
fusion, clustering, range-ambiguity handling, Doppler unfolding, elevation
estimation, and detection reporting as separate module responsibilities. The
combined accumulation/migration responsibility is separate from the Doppler
module. Elevation estimation receives four complex elevation values from
selected range-Doppler candidates and outputs angle plus quality/validity
information; V1 uses commanded azimuth. Detection reporting follows clustering.
File I/O and evidence handling remain outside the production detection path.
Preserve the accepted order in which post-CFAR fusion feeds clustering. Keep
production processing isolated from test and fixture generation and provenance
concerns. HDL generation is a future architectural consideration; no
implementation or code-generation readiness is implied.

**Settled initial baseline:** The combined accumulation/migration module first
accumulates and prepares ensembles without range-migration compensation. Measure
that uncompensated behavior against applicable requirements. An ideal
truth-assisted compensation result may be used only as a test or oracle
benchmark; scenario truth is never a production DUT input.

**Settled:** The intermediate data operation is transposition/reordering
(corner turning), not matrix inversion. Pulse accumulation collects successive
pulses into the slow-time ensemble; corner turning changes data access order so
1-D FFTs or Doppler banks can process per-range sequences efficiently. These
are distinct responsibilities. Explain the relationship and terms using the
[domain glossary](../../CONTEXT.md).

**Unresolved:** The combined module's exact name, any later migration
compensation method, inputs, outputs, and any feedback or hypothesis
dependencies require explanation and study. Do not infer that compensation is
required. Its sequence relative to Doppler unfolding remains open.
Range-ambiguity handling is an approved responsibility; its method remains open.
Retain the 100 km coverage requirement while studying multi-PRF resolution,
waveform diversity, and whether reduced coverage is worth considering. A
coverage reduction requires Julio's explicit requirement decision. The idea of
using a selected instrumented range and pulse-to-pulse waveform diversity to
suppress unwanted correlations is a candidate study, not an approved algorithm.
Elevation validity/quality semantics also need definition.
Later Simulink design must state rates, buffering, latency, and
execution granularity for each boundary. Simulink supports sample- and
frame-based processing; fixed dimensions per configured model are settled, but
sample versus frame execution is not. The buffer owner and physical
implementation of the corner turn are open; buffering once per PRI is a
hypothesis, not an approved topology. The specific 1-D FFT/Doppler-bank method
is also open. Doppler unfolding remains a separate module, while its algorithm
and exact ordering remain undecided.

### Study physical ADC scaling and overload evidence

Dependency: complete Julio's architecture and module-interface review before
selecting numerical values or changing the stimulus, storage reader, or
contracts. Compare plausible scale choices against the expected signal range
and document assumptions and evidence for review.

Resolve whether antenna-element gain or array/beamforming gain is represented,
so gain is not counted twice. Define reference impedance, receiver gain, noise
convention and injection point, ADC full-scale span and volts-per-LSB, and
quantizer rounding and saturation behavior. Use the approved pilot scope without
adding clutter; treat AGC/STC only as future context. Preserve the approved
clipping policy: normal cases demonstrate headroom, intentional overload cases
remain separate, and clipped sample counts are reported per channel. Numerical
choices require evidence and Julio's review.

Completion: the physical conversion chain and numerical scale are documented
with evidence, normal-case headroom and overload behavior are reported without
scenario rescaling, and Julio has reviewed the proposed choices.

### Align pilot ADC producer and reader continuity checks

Dependency: confirm the architecture decisions above before changing producer,
reader, or contract behavior. The pilot path must enforce contiguous ADC ticks
and reject gaps without inserting samples. This storage/timeline task does not
require preserving inter-PRI DDC state; ADR 0022 defines the approved per-PRI
call boundary. Align the pilot producer and reader checks while
preserving broader storage support for ordered/windowed slabs. Keep historical
unit-only fixtures intact and classify them explicitly as outside the pilot
ADC continuity scope. Decide separately what waveform values represent
blanking; continuity does not approve zero-fill.

Completion: pilot producer and reader consistently accept contiguous ADC ticks
and reject missing or discontinuous ticks, with no inferred gap filling; tests
cover the pilot scope and preserve explicitly classified historical fixtures.

### Add direct public-interface tests for DSP modules

Dependency: complete Julio's architecture and MATLAB module-interface review.
Use the approved default of namespaced functions and explicit configuration
and state structs unless a reviewed decision changes it.

For each module, add unit tests that call its public interface directly with
controlled inputs and independently derived expected results. Map cases to
relevant requirement IDs and retain fixture or integration tests where they
answer broader workflow questions. Assess requirement verification separately
from structural code coverage; do not infer that a requirement is verified
because code is covered. Define coverage metrics and thresholds as a separate
decision before using them as a gate.

Completion: module behavior has direct interface tests mapped to applicable
requirements, fixtures/integration tests remain appropriate to broader cases,
and the test report distinguishes requirement evidence from code coverage.

### Align frame terminology in code and documentation

**Approved and implemented on 2026-09-28:** rename the live DDC entry point to
`processFrame` and use *frame* for the MATLAB processing blocks. No runtime
alias for `processChunk` is required. Preserve historical serialized names
`chunkLengths` and `maxChunkSamples`, and leave historical fixture evidence
unchanged; these are provenance fields, not live processing terminology.

Preserve numerical behavior, the then-current state continuity baseline, and
MATLAB's variable frame length support. ADR 0022 later superseded the DDC
inter-call boundary for future implementation. A future Simulink model uses
fixed dimensions per configured model; this terminology change does not choose
its frame size or timing policy.
The MATLAB Code Analyzer and focused DDC walkthrough/state-continuity checks
passed on 2026-09-28. The full WP4 MATLAB MCP suite completed on 2026-09-28
with 54 passed, 0 failed, and 0 incomplete in 84.2901 seconds. The joint design
discussion closed on 2026-09-29; Julio confirmed the Phase 0 contract and
authorized implementation on 2026-10-02. The per-PRI implementation, scoped
core and WP4 suites, full-scan walkthrough, pinned DDC-002 replay, and
independent numerical validation have passed. Julio approved the DDC
walkthrough on 2026-10-08; implementation review and merge-readiness work
remain ongoing. Visual review of the redrawn architecture
diagrams remains unapproved. Then select
the next component question under step 5.

Completion: the implementation and relevant checks pass, and the guide,
glossary, diagrams, and current status describe the same API and compatibility
boundary.

## Validation and completion gates

Lint every touched repository-authored Markdown file with
`markdownlint-cli2`. Independently review complex documents. Run
`uv run --frozen python scripts/check_agent_handoffs.py` when orchestration
guidance or specialist definitions change. Render the architecture diagram and
inspect its preview. Future MATLAB source changes require the applicable
MATLAB standards and Code Analyzer checks when available; future Simulink
changes follow the project’s routing and validation gates. Report unavailable
checks as unavailable, with the limitation stated.

This plan records work status as well as future tasks. Julio confirmed the
Q1–Q22 architecture summary on 2026-09-26. Steps 1 and 2 are drafted and passed
independent document review. The new ADRs record approved decisions and passed
independent semantic review on 2026-09-26. Step 3's overview is in the main
working tree; its three PlantUML views passed syntax/render checks and preview
inspection. The documents passed independent review; Julio's visual review of
the redrawn views remains pending. Steps 4 and 5 remain incomplete. Completion
still requires each step's stated acceptance criteria and required reviews.
