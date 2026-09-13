# Agent Orchestration Contract

> **Status:** Accepted. This file is the source of truth for routing, authority,
> task packets, workflow sequencing, and completion gates in the MATLAB/Simulink
> agentic workflow.

## Purpose and authority

The root agent owns task decomposition, sequencing, authority, conflict
resolution, and the final response. Specialists perform bounded work through the
interfaces below. Their project-scoped TOML files define their descriptions,
models, sandbox policies, and operating instructions; keep those files aligned
with this contract.

The root agent is the default orchestrator. Every specialist receives a bounded
task packet containing only the context needed for the assignment; pass the full
conversation only when the task requires it. Specialists surface missing
information, permissions, or tools as
`needs-input` or `blocked`; they do not silently expand scope. Mutation and
validation are separate stages. Validators inspect artifacts and requirements;
they repair only when the root agent assigns a new implementation task. A tool
invocation is evidence to collect, not proof of correctness. The root agent
decides whether acceptance criteria are satisfied.

The planned delegation exception is `technical-writer` requesting Mermaid work
from `diagrammer`. Document any delegation exception in this file before
implementing it. Specialists otherwise work independently and never spawn
subagents. Every `wait_agent` call uses a timeout of at least 10 minutes; such
calls are non-blocking and may be interrupted by a response or new user message.

## Complexity triage

Before routing a document, classify it as `trivial` or `complex`. Invoke
`technical-writer-validator` for complex documents or when independent review is
explicitly requested. A document is usually trivial when it is short,
single-purpose, based on approved content, and adds no novel technical claim,
architecture, safety guidance, multi-step procedure, or substantial
cross-reference. Classify it as complex when it explains non-trivial
MATLAB/Simulink behavior, architecture, safety or operational guidance, a
multi-step workflow, interacting references, or concepts whose misunderstanding
could cause incorrect implementation. If uncertain, classify as complex and
record the reason in the task packet. A Mermaid diagram may still be requested
for a trivial document; diagram use alone does not require semantic validation.

Before routing implementation results, classify MATLAB/Simulink changes as
`trivial` or `complex`. Invoke `matlab-validator` for complex changes or when
independent validation is explicit. A change is usually trivial when it is local,
well understood, and has no new algorithm, interface, model topology,
sample-time or solver interaction, safety implication, code-generation concern,
or cross-file behavioral change. A behavioral, architectural, numerical,
interface, topology, configuration, execution, safety, or code-generation change
is complex. If uncertain, classify as complex and record the reason. For trivial
changes, the root agent performs a lightweight review using implementation
evidence, a diff or model inspection, and any requested smoke check.

## Task and result packets

Every specialist task has this shape:

```yaml
task:
  id: "stable-task-id"
  objective: "One concrete outcome"
  context: "Only the context needed for this assignment"
  inputs:
    - "paths, requirements, model names, or source references"
  constraints:
    - "scope, compatibility, style, and safety constraints"
  acceptance_criteria:
    - "observable condition that must be true"
  allowed_mutations:
    - "paths or external resources this agent may change"
  requested_checks:
    - "checks the root agent wants this agent to perform"
```

Every specialist result has this shape:

```yaml
result:
  status: "complete | needs-input | blocked | failed"
  summary: "Short description of the outcome"
  artifacts:
    - "created or modified paths, model elements, or reports"
  changes:
    - "material changes made, or 'none'"
  checks:
    - name: "check name"
      status: "passed | failed | skipped | unavailable"
      evidence: "command, report, or concise observation"
  findings:
    - severity: "error | warning | note"
      location: "path, model element, or section"
      description: "Actionable finding"
  assumptions:
    - "assumptions that could affect the result"
  handoff: "recommended next step for the root agent"
```

Use `failed` when the assignment could not be completed, `blocked` when
external state or missing authority is required, and `complete` when the work is
done with any warnings disclosed.

## Specialist registry and conditional routing

The TOML file is authoritative for each specialist's description and execution
settings. The root agent selects the role before spawning it, records the role
and observable reason in the task packet, and checks that any future variant is
selectable in the current session. The root remains the planner and
orchestrator; there is no separate plan agent or `simulink-architect`.

| Agent | Route when the task is... |
| --- | --- |
| `technical-writer` | Markdown or manifest JSON authoring |
| `diagrammer` | Mermaid diagram-specific work delegated by `technical-writer` |
| `matlab-architect` | Standard non-trivial MATLAB/Simulink design |
| `matlab-architect-deep` | Solver, timing, numerical, code-generation design |
| `technical-writer-validator` | Complex-document review |
| `technical-writer-validator-deep` | Safety or intricate architecture docs |
| `matlab-implementer` | MATLAB changes or simple, localized Simulink edits |
| `simulink-implementer` | Model topology, interfaces, or configuration |
| `matlab-validator` | Complex MATLAB/Simulink validation |
| `matlab-validator-deep` | Control, solver, safety, code generation |

The four variant TOMLs are present in this repository; runtime availability is
session-dependent. Before spawning one,
the root confirms that it is selectable in the current session and reports a
failure when it is unavailable. For safety or complex design, the root does not
silently fall back to a lower-capability role. Astra is reserved for exceptional
manual escalation and is not a configured default role.

Read the matching [.codex/agents](.codex/agents/) TOML before changing or
reviewing a specialist definition. The TOMLs preserve specialist-specific tools,
responsibilities, constraints, and completion details that do not belong in this
routing contract.

## Workflow sequencing

### Trivial MATLAB/Simulink change

1. Classify the change and record the reason.
2. Route a bounded implementation task as appropriate, usually to
   `matlab-implementer`.
3. Review the diff or model inspection and perform requested smoke checks.
4. Omit `matlab-validator` unless independent validation was requested or the
   change is reclassified as complex.

Completion requires the requested implementation, evidence, and lightweight
review to be recorded.

### Non-trivial MATLAB/Simulink change

1. Route the task to `matlab-architect`, or to `matlab-architect-deep` when
   solver, timing, numerical, or code-generation difficulty is observable.
2. Resolve `needs-input` results and approve the architecture.
3. Route the approved packet to `matlab-implementer`, or to
   `simulink-implementer` for substantive Simulink topology, interfaces,
   configuration, or multi-step MCP editing.
4. Route the resulting artifacts and acceptance criteria to `matlab-validator`,
   or to `matlab-validator-deep` for control, solver, numerical, safety, or
   code-generation validation.
5. If validation reports errors, decide whether to revise the design or assign a
   bounded fix, then repeat validation.
6. Route implementation notes to `technical-writer` when documentation is
   needed.

Completion requires an approved architecture, coherent implementation,
independent validation with no unresolved errors, and disclosed warnings or
limitations.

### Documentation change

1. Supply `technical-writer` with the approved brief, sources, and target paths.
2. Have `technical-writer` delegate required diagram-specific work to
   `diagrammer`, passing its purpose, audience, nodes or states, relationships,
   and constraints.
3. Integrate Mermaid source and run `markdownlint-cli2` on every touched Markdown
   file.
4. For a complex document, route the finished artifact and source context to
   `technical-writer-validator`, or to
   `technical-writer-validator-deep` for safety guidance or intricate
   architecture documentation; request revisions for unresolved error findings.

Completion requires traceable artifacts, a passing Markdown lint check, and the
required independent review for complex documents.

### Manifest JSON creation

1. Supply the approved schema, target path, exact agent and tool names, and
   required values to `technical-writer`.
2. Have the writer run the specified JSON syntax and schema checker.
3. Review manifest semantics and activate the agent only after the manifest
   satisfies this contract.

Manifest-only tasks do not require Markdown linting. An unavailable checker is
reported as unavailable, never passed.

### Validation-only request

Route the artifact, requirements, and requested checks directly to the relevant
validator. The validator returns findings and evidence; repair requires a new
bounded implementation assignment.

## Root-agent completion gate

The root agent may report completion when every requested artifact exists at its
expected path or model location, the relevant specialist returned `complete`,
required checks passed or an explicit limitation was accepted by the user, and
all warnings, assumptions, and skipped checks are disclosed. Complex documents
and complex
MATLAB/Simulink changes require independent validation with no unresolved error
findings. The final response names changed artifacts and collected evidence.

## Repository context

```text
AGENTS.md
.codex/agents/*.toml       # project-scoped specialist definitions
.agents/skills/             # repository skills
```

## Agent skills

### Issue tracker

Read [docs/agents/issue-tracker.md](docs/agents/issue-tracker.md) before creating,
reading, listing, commenting on, labeling, or closing a GitHub issue, or whenever
a skill says to publish or fetch tracker content. The repository tracker is
GitHub Issues for `JulioLeonPhd/ai-mbd-pilot-project`; use `gh` from this clone.

### Triage labels

Read [docs/agents/triage-labels.md](docs/agents/triage-labels.md) before applying
or interpreting tracker labels, including a skill's named triage role. Use its
canonical role-to-label mapping.

### Domain docs

Read [docs/agents/domain.md](docs/agents/domain.md), [CONTEXT.md](CONTEXT.md),
and the relevant [docs/adr](docs/adr/) entries before exploring a domain topic,
drafting requirements or tests, or proposing a design change. Use the glossary
terms and surface any conflict with an ADR.
