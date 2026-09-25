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

## Ordered work

### 1. Establish the working agreement and branch rules

Update `AGENTS.md` to state the agreement above and align the affected
`.codex/agents/*.toml` specialist definitions with it. The initial branch is
`docs/human-led-workflow`. Create `architecture/radar-overview` and
`component/ddc-walkthrough` for their corresponding steps.

Branch by coherent component or change from the agreed integration branch.
Integrate a change before dependent work starts, or document its dependency.
Use worktrees when concurrent work needs separate checkouts. Branch names and
worktrees do not authorize automatic merges or pushes.

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

On `component/ddc-walkthrough`, build examples that call the existing MATLAB
implementation. Explain translation, filtering, decimation, signal shapes,
units, rates, mixer and filter behavior, and phase state. Include normal and
broken-state experiments, spectra, and timing diagrams. The walkthrough is for
learning first; use what it reveals to decide which refactors are needed, while
preserving useful namespaces.

Implementing the same behavior in Simulink is deferred until the MATLAB
behavior is clear and Julio chooses to proceed.

Completion: a reader can trace the existing DDC behavior and inspect
reproducible normal and broken-state evidence, with any proposed refactoring
left for an explicit decision.

### 5. Repeat the component workflow

Apply the reviewed architecture and DDC learning workflow to the next
component, selecting it with Julio. Open engineering tickets around a question
and expected behavior first. Record the evidence question, experiment, result,
and limits before adding traceability. Keep human decisions and agent
contributions truthful and distinct.

Completion: the next component has an agreed question and behavior, evidence
and limits, and explicit human decisions before implementation proceeds.

## Validation and completion gates

Lint every touched repository-authored Markdown file with
`markdownlint-cli2`. Independently review complex documents. Run
`uv run --frozen python scripts/check_agent_handoffs.py` when orchestration
guidance or specialist definitions change. Render the architecture diagram and
inspect its preview. Future MATLAB source changes require the applicable
MATLAB standards and Code Analyzer checks when available; future Simulink
changes follow the project’s routing and validation gates. Report unavailable
checks as unavailable, with the limitation stated.

This file records planned work. It does not claim that any of the five steps
have been implemented or accepted beyond the governing direction supplied for
this plan.
