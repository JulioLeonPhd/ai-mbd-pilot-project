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
route; if the active tool is unavailable, return `blocked`. Root owns dispatch,
sequencing, and acceptance. The only specialist delegation exceptions are an
assigned `researcher` dispatching the bundled `scout` for bounded, read-only
primary-source collection, or dispatching the project `technical-writer` for a
requested Markdown report under the rules below. Scouts do not spawn.
Use the active host's native waiting control; this contract sets no timeout.

Specialist delegation is denied by default and allowed only by the role's native
child allowlist. Specialists work independently and never spawn subagents except
that Researcher may dispatch the bundled scout and technical-writer within this
contract. Generic workers must be explicitly instructed not to spawn child tasks.

The researcher-to-writer handoff is limited to a requested Markdown report.
Root records the exact report target in the Researcher task's `constraints` and
leaves the Researcher's `allowed_mutations` empty. The Researcher passes only
that target in the writer task's `allowed_mutations`. The Researcher sends the
writer cited findings and synthesis; the writer authors from supplied material
and does not research. Missing evidence returns to the assigning Researcher, or
to root when root assigned the writer. Before either child dispatch, verify
through observable native inventory and task information that the identity is
the bundled `scout` or project `technical-writer`, respectively, the task route
is the active native route, and there is no identity/task collision. If
identity, route, or collision status cannot be established, return `blocked`;
do not use another harness. A child-name allowlist does not prove identity
provenance. Neither this routing policy nor native declarations establish
filesystem isolation.

Architects and validators are inspection-only. Writable roles remain limited to
their task's `allowed_mutations`; repairs or checks requiring writes need a
separately bounded, authorized writer or implementer assignment. The seven
native `.omp/agents/*.md` files are authoritative for per-role tool and spawn
declarations. MCP, extension, and custom tools may add capabilities, so role
declarations do not establish filesystem isolation. OMP frontmatter does not
reproduce an operating-system sandbox; use applicable platform controls when
those guarantees are required.

Any agent, including root, may use the repository
`drawing-mermaid-diagrams` skill when authoring a Mermaid diagram within its
assigned artifact scope. This is not a specialist handoff.

## Specialist registry and conditional routing

| Agent | Route when the task is... |
| --- | --- |
| `matlab-architect` | Non-trivial MATLAB/Simulink design, including solver, timing, numerical, and code-generation concerns |
| `matlab-implementer` | MATLAB changes or simple, localized Simulink edits |
| `matlab-validator` | Complex MATLAB/Simulink validation, including control, solver, numerical, safety, and code-generation concerns |
| `researcher` | Evidence-dependent research and synthesis; may hand cited findings to `technical-writer` for an authorized Markdown report |
| `simulink-implementer` | Model topology, interfaces, or configuration |
| `technical-writer` | Markdown or manifest JSON authoring from supplied material; not evidence collection |
| `technical-writer-validator` | Complex-document review, including safety or intricate architecture documentation |

OMP discovers the seven project roles from `.omp/agents`; they are the only
specialist identities. Codex uses the direct fallback above. Before changing or
reviewing an OMP specialist, read its matching `.omp/agents` definition. The
defaults stay in those native role files; do not cache or change them here.

ADR 0030 adopts ongoing per-role delegation only for the Researcher and its two
permitted child edges: bundled `scout` and project `technical-writer` under the
conditions above. It does not authorize other roles to delegate. ADR 0029
retains the Researcher defaults, approved escalation tier, and selector gates;
the post-trial pause and root-only writer route are superseded. Restore ADR
0029's named pre-trial role and dispatch baseline only if native evidence
confirms a wrong required Researcher default or a delegation-boundary violation.
An unverified preflight or route prerequisite, or unavailable or mismatched
optional Astra escalation, blocks only that assignment and does not trigger
restoration.
The Researcher has no write authority, cannot author the report itself, and
cannot dispatch validators or any other role.

Before each root OMP dispatch, use the active session's native `/agents`
inventory to confirm all seven project roles, their project sources, and
selected models. Check declared thinking levels, tools, and spawn permissions
in the role files from those sources. Declarations and static checks do not
prove effective runtime permissions or execution.

Dispatch only through the active session's `task` tool. At launch, record the
resolved model and thinking level where observable. If a required value is
unverified or mismatched, block the assignment and do not accept its output.

Before a Researcher dispatches a child, verify the native identity, active task
route, and absence of an identity/task collision through observable inventory
and task information. For scout, confirm bundled provenance; for writer, confirm
the project `technical-writer` identity. If any condition cannot be established,
return `blocked`; do not use another harness.

Root alone selects and applies an approved per-task selector to the Researcher
when needed; never apply the Researcher selector to a scout. Check selector
availability and approval before dispatch, then observe and record the launched
task's resolved model and effort. If a required selection is unavailable or
mismatched, block that assignment without substitution. Preserve supplied
execution metadata in results; report unavailable metadata as `unknown`.

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
| Documentation | Route authoring-only work directly to `technical-writer` when the approved brief and evidence are sufficient; document format does not determine who researches. When a Markdown report needs evidence, root assigns a `researcher` one topic and may batch independent topics. The researcher owns source evaluation and synthesis, may inspect primary sources directly, and may dispatch only bundled `scout` workers for bounded, read-only primary-source collection or the project `technical-writer` when a Markdown report is requested. Root puts the exact report target in the Researcher task's `constraints` and leaves its `allowed_mutations` empty; the writer's `allowed_mutations` contains only that target. The researcher sends cited findings and synthesis to the writer, which drafts from supplied findings and does not research. Missing evidence returns to the assigning Researcher, or root if root assigned the writer. Scouts return citations and observations and do not spawn. For Mermaid authoring, any agent, including root, may use the repository `drawing-mermaid-diagrams` skill within its assigned artifact scope; no specialist handoff is needed. Run `markdownlint-cli2` on every touched repository-authored Markdown file; exclude a third-party Markdown snapshot only when it is byte-for-byte verified against its pinned source hash. Route complex documents or explicitly requested independent review to `technical-writer-validator` through root; the Researcher does not dispatch validators. Assign revisions to the writer. | Traceable artifacts, passing Markdown lint, and required independent review without unresolved errors. |
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
`drawing-mermaid-diagrams` skill, or agent orchestration architecture
documents. It MUST pass
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
| Creating or rendering Mermaid | [Mermaid diagrams](docs/agents/task-guidance.md#mermaid-diagrams) and the [drawing-mermaid-diagrams skill](.agents/skills/drawing-mermaid-diagrams/SKILL.md) |
| Updating `CURRENT.md`, `HISTORY.md`, or milestone status | [Active status and history](docs/agents/task-guidance.md#active-status-and-history) |
| Making any MATLAB/Simulink MCP call | [MATLAB MCP session ownership](docs/agents/task-guidance.md#matlab-mcp-session-ownership) |
| Editing MATLAB or Simulink-associated MATLAB code | [MATLAB standards and analysis](docs/agents/task-guidance.md#matlab-standards-and-analysis); read the standards bundle and applicable rule files |
| Running Python or editing Python code | [Python environment and checks](docs/agents/task-guidance.md#python-environment-and-checks) |
| Preparing a release | [Releases](docs/agents/task-guidance.md#releases) |
| Defining an engineering artifact's human audience or question; architecture decisions, component boundaries/branches, tickets, evidence, or human walkthrough reviews | [Human-led engineering workflow](docs/agents/human-led-workflow.md) |
| GitHub issue-tracker operations | [Issue tracker](docs/agents/issue-tracker.md) |
| Selecting or applying triage labels | [Triage labels](docs/agents/triage-labels.md) |
| Using domain terms or reviewing system decisions | [Domain docs](docs/agents/domain.md) |
