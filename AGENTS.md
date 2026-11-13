# Agent Orchestration Contract

> **Status:** Accepted. This file is the source of truth for authority, routing,
> task packets, workflow sequencing, and completion gates in the MATLAB/Simulink
> agentic workflow.

## Authority and safety

Julio owns architecture decisions: system decomposition, interfaces, algorithm
choices, state and timing behavior, and consequential requirement changes.
Agents may investigate and propose alternatives with evidence, then implement
choices Julio approves. Historical decisions remain the baseline until Julio
revises them; routine work within an approved decision may proceed autonomously.
Independent verification provides evidence, not human approval.

The root agent owns task decomposition, routing, sequencing, conflict resolution,
acceptance, and the final response. Specialists perform bounded work from task
packets. Codex has no project specialist inventory: its direct fallback performs
authorized source or document work and requested checks directly. The specialist
result gate applies only when a specialist is dispatched; any required
independent review remains separate and unavailable review blocks completion.

Every specialist receives only the context needed for its assignment and does
not silently expand scope. Missing task information or a decision from the root
is `needs-input`; unavailable external state, tools, permission, or authority is
`blocked`. Validators return findings and evidence only. Repairs or checks that
require writes go to a writer or implementer through a separately bounded,
authorized assignment. A tool invocation is evidence to collect, not proof of
correctness; the root decides whether acceptance criteria are satisfied.

In OMP, dispatch only through the active session's `task` tool. A separate
headless OMP process, shell command, or external agent CLI is not a dispatch
route; if the active tool is unavailable, return `blocked`. Root alone
dispatches. Use the active host's native waiting control; this contract sets no
timeout.

When assigning a generic worker to bounded reconnaissance, source-evidence
collection, mechanical comparison, or prescribed checks, explicitly instruct it
not to spawn child tasks. Specialists work independently and never spawn subagents.
This assignment policy is not runtime enforcement: bundled native workers may
expose task or child-spawning capability, even though all six project-role
definitions set `spawns: ""` and forbid delegation by other means.

Architects and validators are inspection-only. Writable roles remain limited to
their task's `allowed_mutations`; repairs or checks requiring writes need a
separately bounded, authorized writer or implementer assignment. The six native
`.omp/agents/*.md` files are authoritative for per-role tool and spawn
declarations. MCP, extension, and custom tools may add capabilities, so role
declarations do not establish filesystem isolation. OMP frontmatter does not
reproduce an operating-system sandbox; use applicable platform controls when
those guarantees are required.

Mermaid work belongs to the artifact owner using the repository `diagrammer`
skill; it is not a specialist handoff.

## Specialist registry and conditional routing

| Agent | Route when the task is... |
| --- | --- |
| `technical-writer` | Markdown or manifest JSON authoring |
| `matlab-architect` | Non-trivial MATLAB/Simulink design, including solver, timing, numerical, and code-generation concerns |
| `technical-writer-validator` | Complex-document review, including safety or intricate architecture documentation |
| `matlab-implementer` | MATLAB changes or simple, localized Simulink edits |
| `simulink-implementer` | Model topology, interfaces, or configuration |
| `matlab-validator` | Complex MATLAB/Simulink validation, including control, solver, numerical, safety, and code-generation concerns |

OMP discovers the six project roles from `.omp/agents`; they are the only
specialist identities. Codex uses the direct fallback above. Before changing or
reviewing an OMP specialist, read its matching `.omp/agents` definition. The
defaults stay in those native role files; do not cache or change them here.

Before each OMP dispatch, inspect the native `/agents` inventory for all six project roles.
Confirm their selected models, thinking levels, tools, and denied child spawning; static checker success is not native-discovery or execution proof.
Verify the selected role and active session's `task` tool are available, then record the role and observable reason in the bounded task packet.
For higher-capability work, use the same responsibility identity with an exact approved native per-task selector only when supported and permitted.
Compare observed resolved capability with the approved task need.
If a required role, tool, selector, permission, or capability is unavailable, unapproved, or insufficient, return `blocked` to the root; never silently fall back.
Preserve supplied execution metadata in results; report unavailable metadata as `unknown`.

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

Keep `task.id` stable for the task lifecycle and `task.objective` concise and
outcome-focused. Keep `task.context` bounded; inherit the full conversation only
when the context records `inherit-full-conversation: reason=<specific missing
context>`. Keep `task.inputs` as string entries. Prefer immutable references in
the form `ref: repo-relative/path @ revision-or-hash [#selector]`. A bare path
or mutable label such as `@ working-tree` remains compatible, but the result
must report `integrity-unverified`. Put assignment-specific requirements in
`constraints`, `acceptance_criteria`, `allowed_mutations`, and `requested_checks`.

Every specialist result has this shape:

```yaml
agent:
  name: "agent-name (e.g. technical-writer)"
  model: "model used"
  reasoning_effort: "reasoning effort used"
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

Use the existing fields; identify changed artifacts, record evidence in
`checks`, disclose findings and assumptions, and state the next handoff. Keep
source material referenced rather than repeated; results contain no reasoning
traces. Preserve any additional supplied metadata, including `agent.id`,
`agent.name`, `agent.model`, and `agent.reasoning_effort`; use `unknown` rather
than inventing an identifier or execution detail.

| Status | Meaning |
| --- | --- |
| `needs-input` | Required task information or a decision from the root is missing. |
| `blocked` | Required external state, tool, permission, or authority is unavailable. |
| `failed` | Execution or assignment failure is not resolved by those pending prerequisites. |
| `complete` | The bounded work is delivered and warnings are disclosed. |

## Workflow and completion

Before routing a document or MATLAB/Simulink change, classify it as `trivial`
or `complex`; record the reason for either MATLAB/Simulink classification and
for complex documents.
A document is usually trivial when it is
short, single-purpose, based on approved content, and adds no novel technical
claim, architecture, safety guidance, multi-step procedure, or substantial
cross-reference. Treat non-trivial MATLAB/Simulink behavior, architecture,
safety or operational guidance, multi-step workflows, interacting references,
and concepts whose misunderstanding could cause incorrect implementation as
complex. If uncertain, classify as complex. A Mermaid diagram alone does not
require semantic validation.

A MATLAB/Simulink change is usually trivial when local and well understood, with
no new algorithm, interface, model topology, sample-time or solver interaction,
safety implication, code-generation concern, or cross-file behavioral change.
Behavioral, architectural, numerical, interface, topology, configuration,
execution, safety, or code-generation changes are complex; if uncertain,
classify as complex.

| Work | Route and required sequence | Completion evidence |
| --- | --- | --- |
| Trivial MATLAB/Simulink | Assign an appropriate implementer, usually `matlab-implementer`; root reviews implementation evidence, a diff or model inspection, and requested smoke checks. Omit `matlab-validator` unless independent validation is requested or the change becomes complex. | Requested implementation, evidence, and lightweight review recorded. |
| Complex MATLAB/Simulink | Route design to `matlab-architect`; resolve `needs-input` and obtain Julio's explicit decision for choices crossing his boundary. Then assign `matlab-implementer`, or `simulink-implementer` for substantive model topology, interfaces, configuration, or multi-step MCP edits. Route results and criteria to `matlab-validator`; revise design or assign a bounded fix for errors, then repeat validation. Route implementation notes to `technical-writer` when needed. | Approved architecture, coherent implementation, independent validation without unresolved errors, and disclosed warnings or limitations. |
| Documentation | Give `technical-writer` the approved brief, sources, and target paths. Use the repository diagrammer skill directly for Mermaid. Run `markdownlint-cli2` on every touched repository-authored Markdown file; exclude a third-party Markdown snapshot only when it is byte-for-byte verified against its pinned source hash. Route complex documents or explicitly requested independent review to `technical-writer-validator`; assign revisions to the writer. | Traceable artifacts, passing Markdown lint, and required independent review without unresolved errors. |
| Manifest JSON | Give `technical-writer` the approved schema, target path, exact agent/tool names, and required values. Run the specified JSON syntax and schema checker; review semantics and activate only after the manifest satisfies the contract. | Valid manifest and disclosed checker result. Markdown lint is not required; an unavailable checker is not a pass. |
| Validation-only | Send the artifact, requirements, and requested checks to the relevant validator. Validators return findings and evidence only; repair requires a new bounded implementation assignment. | Findings and evidence; no repair is performed under the inspection assignment. |
| Codex direct fallback | When no project specialist is dispatched, perform authorized source/document work and requested checks directly. Apply the same repository standards and platform controls. A specialist-result requirement applies only to a dispatched specialist. | Required work and checks are complete. Do not substitute self-review for required independent review; if that review is unavailable, return `blocked`. |

Complex documents require independent `technical-writer-validator` review;
complex MATLAB/Simulink changes require independent `matlab-validator` review.
Independent review is also required when explicitly requested. A validator
returns findings, not approval; unresolved errors require revision and
revalidation.

Keep MATLAB calls serialized until separate session isolation is verified; do
not run implementation and independent validation concurrently in one mutable
session. Read [MATLAB MCP session ownership](docs/agents/task-guidance.md#matlab-mcp-session-ownership)
for endpoint setup and isolation evidence.

The root may report completion when every requested artifact exists at its
expected path, the relevant dispatched specialists returned `complete`, and required
checks pass or an explicit limitation is accepted by the user. The final response
names changed artifacts and collected evidence. Disclose all
warnings, assumptions, and skipped checks. Complex changes require independent
validation with no unresolved error findings. This contract's handoff checker is
a strict gate: run `uv run --frozen python scripts/check_agent_handoffs.py`
from the worktree root after changing `AGENTS.md`, `.omp/agents/*.md`, the
diagrammer skill, or agent orchestration architecture documents. It MUST pass
before completion; user acceptance of another limitation cannot waive it. An
unavailable or failed checker means the gate is incomplete.

## Required references

Before the relevant action, read the named section or source below. Read other
sections only when the task crosses their branch.

| Trigger | Required reference |
| --- | --- |
| Writing or editing prose documentation | [Documentation style](docs/agents/task-guidance.md#documentation-style) |
| Writing or editing a math document | [Mathematical documentation](docs/agents/task-guidance.md#mathematical-documentation) |
| Creating or reviewing an engineering walkthrough | [Engineering walkthroughs](docs/agents/task-guidance.md#engineering-walkthroughs) |
| Creating or rendering Mermaid | [Mermaid diagrams](docs/agents/task-guidance.md#mermaid-diagrams) and the [diagrammer skill](.agents/skills/diagrammer/SKILL.md) |
| Updating `CURRENT.md`, `HISTORY.md`, or milestone status | [Active status and history](docs/agents/task-guidance.md#active-status-and-history) |
| Making any MATLAB/Simulink MCP call | [MATLAB MCP session ownership](docs/agents/task-guidance.md#matlab-mcp-session-ownership) |
| Editing MATLAB or Simulink-associated MATLAB code | [MATLAB standards and analysis](docs/agents/task-guidance.md#matlab-standards-and-analysis); read the standards bundle and applicable rule files |
| Running Python or editing Python code | [Python environment and checks](docs/agents/task-guidance.md#python-environment-and-checks) |
| Preparing a release | [Releases](docs/agents/task-guidance.md#releases) |
| Defining an engineering artifact's human audience or question; architecture decisions, component boundaries/branches, tickets, evidence, or human walkthrough reviews | [Human-led engineering workflow](docs/agents/human-led-workflow.md) |
| GitHub issue-tracker operations | [Issue tracker](docs/agents/issue-tracker.md) |
| Selecting or applying triage labels | [Triage labels](docs/agents/triage-labels.md) |
| Using domain terms or reviewing system decisions | [Domain docs](docs/agents/domain.md) |
