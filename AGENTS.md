# Agent Orchestration Contract

> **Status:** Accepted. This file is the source of truth for routing, authority,
> task packets, workflow sequencing, and completion gates in the MATLAB/Simulink
> agentic workflow.

## Purpose and authority

Julio owns architecture decisions: system decomposition, interfaces, algorithm
choices, state and timing behavior, and consequential requirement changes.
Agents may investigate and propose alternatives with evidence, then implement
the choices Julio approves. Independent verification provides evidence; it does
not constitute human approval. Historical decisions remain the baseline until
Julio explicitly revises them. Routine implementation within an approved
decision may proceed autonomously. See the [human-led engineering
workflow](docs/agents/human-led-workflow.md) for component branches, dependency
rules, human clarity, ticket framing, and evidence attribution. For a learning
example, documentation should provide a runnable entry point, explain units,
signal shapes, and persistent state when relevant, and say what the reader
should observe. Diagrams should have a defined audience and purpose, expose
required relationships and implementation status, and make unresolved choices
visible.

The root agent owns task decomposition, sequencing, authority, conflict
resolution, and the final response. Specialists perform bounded work through the
interfaces below. Codex uses the project-scoped `.codex/agents/*.toml`
definitions; OMP uses the equivalent native `.omp/agents/*.md` definitions. Keep
both sets aligned with this contract and preserve their role-specific
instructions.

In OMP, dispatch every subagent through the active session's `task` tool so
execution remains visible in its subagents panel. Do not launch subagents
through a separate headless OMP process, shell command, or external agent CLI.
If the active session's `task` tool is unavailable, report `blocked` rather than
using another launcher.

The root agent is the default orchestrator and owns workflow coordination; Julio
owns architecture decisions and approves changes at the boundary above. Every
specialist receives a bounded task packet containing only the context needed for
the assignment; pass the full conversation only when the task requires it.
Specialists surface missing information, permissions, or tools as `needs-input`
or `blocked`; they do not silently expand scope. Mutation and validation are
separate stages. Validators inspect artifacts and requirements; they repair only
when the root agent assigns a new implementation task. A tool invocation is
evidence to collect, not proof of correctness. The root agent decides whether
acceptance criteria are satisfied.

Specialists work independently and never spawn subagents. Mermaid work is done
by the agent that owns the artifact using the repository `diagrammer` skill; it
is not a specialist handoff. Every `wait_agent` call uses a timeout of at least
10 minutes; such calls are non-blocking and may be interrupted by a response or
new user message.

## Documentation style

Do not enforce a fixed source width for prose. Prefer one sentence per source
line, with blank lines between paragraphs. Preserve code blocks, tables, and
intentional line breaks, and do not bulk-reflow existing text.

Prefer tables when content can be meaningfully tabulated, especially
comparisons, mappings, attributes, or status. Use bullets for parallel points
when they make concepts faster to grasp, numbered lists for ordered steps, and
prose for explanations that benefit from connected reasoning.

### Engineering walkthroughs

Treat executable walkthroughs as primary human-review surfaces for non-trivial
engineering components, not as minimal API examples.

Walkthroughs should be deliberately verbose when verbosity improves engineering
transparency. A competent engineer should be able to understand the component's
purpose, processing chain, important design choices, units, signal shapes,
rates, state or reset behaviour, expected transformations, limitations, and
evidence boundaries without first reverse-engineering namespaced implementation
code.

Keep the component's public API as the execution boundary. Do not duplicate
private production algorithms in a walkthrough merely to expose their internals,
because parallel implementations can drift. Instead, make the engineering
meaning around each public call explicit: show relevant configuration values,
derive or print important rates and dimensions, state which processing stages
the call represents, calculate transparent expectations independently where
useful, expose meaningful observations and plots, and explain what the reader
should see and why.

Do not hide the engineering story behind convenience calls. If a public API is
too opaque for a walkthrough to explain the component honestly, improve the
explanatory material or reconsider the API boundary rather than reaching into
private implementation by default.

Walkthroughs complement rather than replace tests. Walkthroughs teach and
support human architectural review; tests and independent evidence establish
behavioural claims.

## Active status and history

Keep root `CURRENT.md` limited to the active work package, gate, or milestone,
its approved decisions, verified result and evidence scope, pending human
decisions or reviews, and the next authorized step. Write short connected prose
that lets a reader returning after a week identify where work stands, what just
finished, what blocks progress, and the next action. State explicitly when no
formal work-package or gate assignment is recorded; verification never implies
human approval or advances a gate.

When a new work package or milestone starts, append the complete outgoing
`CURRENT.md` to root `HISTORY.md` before replacing it. Give each full snapshot a
date and the outgoing work package, gate, and milestone as recorded; preserve
the outgoing content and relative links verbatim, and never overwrite earlier
history. Routine updates within the same work package or milestone do not add a
full snapshot. Move any historical material removed from `CURRENT.md` into an
append-only history entry. The initial migration snapshot is dated, preserves
the original file verbatim, and is explicitly identified as a migration rather
than a new milestone.

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
independent validation is explicit. A change is usually trivial when it is
local, well understood, and has no new algorithm, interface, model topology,
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

Use `failed` when the assignment could not be completed, `blocked` when external
state or missing authority is required, and `complete` when the work is done
with any warnings disclosed.

### Handoff economy

Use the existing packet fields as a compact interface. Keep `task.id` stable for
the task lifecycle and make `task.objective` concise and outcome-focused. Keep
`task.context` bounded; inherit the full conversation only when that string
records `inherit-full-conversation: reason=<specific missing context>`.

Keep `task.inputs` as string entries. Prefer immutable revision-pinned
references in this form: `ref: repo-relative/path @ revision-or-hash
[#selector]`. A bare path or mutable label such as `@ working-tree` remains
compatible with the current contract, but the result reports an explicit
`integrity-unverified` warning. Put only assignment-specific requirements in
`constraints`, `acceptance_criteria`, `allowed_mutations`, and
`requested_checks`.

In a result, use the existing `status`, `summary`, `artifacts`, `changes`,
`checks`, `findings`, `assumptions`, and `handoff` fields: identify changed
artifacts, record evidence in `checks`, disclose findings and assumptions, and
state the next handoff. Keep source material referenced rather than repeated;
results contain no reasoning traces. Preserve every field name, type, and status
meaning in the packet contract above. If the active contract includes additional
result metadata such as `agent.id`, `agent.name`, `agent.model`, or
`agent.reasoning_effort`, preserve and report those fields as supplied. Use an
unknown value when metadata is unavailable; never invent an identifier or
execution detail.

## Specialist registry and conditional routing

Each runtime's native definition is authoritative for its execution settings:
Codex reads TOML; OMP discovers project Markdown from `.omp/agents`, not
`.codex/agents`. The role responsibilities remain equivalent across both sets.
The root agent selects the role before spawning it, records the role and
observable reason in the task packet, and checks that it is selectable in the
current session. The root remains the planner and orchestrator; there is no
separate plan agent or `simulink-architect`.

| Agent | Route when the task is... |
| --- | --- |
| `technical-writer` | Markdown or manifest JSON authoring |
| `matlab-architect` | Standard non-trivial MATLAB/Simulink design |
| `matlab-architect-deep` | Solver, timing, numerical, code-generation design |
| `technical-writer-validator` | Complex-document review |
| `technical-writer-validator-deep` | Safety or intricate architecture docs |
| `matlab-implementer` | MATLAB changes or simple, localized Simulink edits |
| `simulink-implementer` | Model topology, interfaces, or configuration |
| `matlab-validator` | Complex MATLAB/Simulink validation |
| `matlab-validator-deep` | Control, solver, safety, code generation |

All nine roles, including the three deep variants, have definitions for both
runtimes; runtime availability is session-dependent. Before spawning one, the
root confirms that it is selectable in the current session and reports a failure
when it is unavailable. For safety or complex design, the root does not silently
fall back to a lower-capability role. Astra is selected by the explicit deep
routes, not by standard roles.

Read both the matching [.codex/agents](.codex/agents/) TOML and
[.omp/agents](.omp/agents/) Markdown before changing or reviewing a specialist
definition. Keep their role instructions equivalent; their runtime-specific
settings are not interchangeable.

### OMP execution settings and safety limits

OMP definitions use concrete available provider/model selectors so a global
role's thinking suffix cannot override the original role-specific effort. They
do not interpret Codex model IDs as OMP selectors or change global model
settings.

| Roles | Codex model | OMP model selector | Thinking level |
| --- | --- | --- | --- |
| `technical-writer`, `matlab-implementer` | `gpt-6-luna` | `openai-codex/gpt-6-luna` | `high` |
| `matlab-architect` | `gpt-6.1-sol` | `openai-codex/gpt-6.1-sol` | `high` |
| `technical-writer-validator`, `simulink-implementer`, `matlab-validator` | `gpt-6.1-sol` | `openai-codex/gpt-6.1-sol` | `medium` |
| `matlab-architect-deep`, `matlab-validator-deep` | `gpt-6-astra` | `openai-codex/gpt-6-astra` | `high` |
| `technical-writer-validator-deep` | `gpt-6-astra` | `openai-codex/gpt-6-astra` | `medium` |

These correspond to the current `@smol` Luna, `@default` Sol, and `@slow` Astra
model families, but deliberately do not inherit those aliases' effort suffixes.
OMP settings or launch-time policy can override model and effort; record
observed execution metadata in results and recheck availability after
configuration changes.

Every OMP definition denies child spawning with `spawns: ""` and instructs the
specialist not to delegate through any other mechanism. Architects and
validators allow only the built-in `read`, `grep`, `glob`, and `web_search`
tools; writers and implementers additionally allow `write`, `edit`, `bash`, and
`eval`. MCP, extension, and custom tools remain additive, so an allowlist is not
a complete capability or filesystem boundary. Inspection-only roles must not use
those tools to mutate artifacts; requested checks that need writes or
unavailable tools return to the root for a separately authorized task. Writable
roles remain limited to their task's `allowed_mutations`. OMP agent frontmatter
has no equivalent of the TOML `sandbox_mode` setting: neither Codex's
`read-only` nor `workspace-write` OS sandbox is reproduced. These instructions
and built-in restrictions reduce exposure but do not enforce OS isolation or
external-service permissions; use platform controls when those guarantees are
required.

From the worktree root, inspect `/agents` for all nine project roles and confirm
their selected models, thinking levels, tools, and denied child spawning before
dispatch. The repository checker below validates the committed frontmatter
subset, inventory, role-instruction alignment, and declared restrictions; it
does not prove native discovery, actual model routing, MCP authorization, or
sandbox enforcement.

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
2. Resolve `needs-input` results and obtain Julio's explicit decision on
   architecture choices that cross his approval boundary. The root coordinates
   the decision and records it; the root does not substitute its own approval.
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
2. Have the assigned writer use the repository `diagrammer` skill directly for
   required Mermaid work, recording its purpose, audience, nodes or states,
   relationships, and constraints.
3. Integrate Mermaid source and run `markdownlint-cli2` on every touched
   repository-authored Markdown file. Byte-for-byte third-party Markdown
   snapshots may be excluded by the root configuration, but must be verified
   against their pinned source hashes.
4. When `mmdc` is needed to render a Mermaid diagram, run it outside the command
   sandbox with Microsoft Edge as the Puppeteer executable:

   ```sh
   EDGE_BIN='/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
   PUPPETEER_EXECUTABLE_PATH="$EDGE_BIN" mmdc -i <input.md> -o <output.md> \
     -a <asset-directory>
   ```

   This repository rule authorizes the documented rendering procedure; it does
   not grant platform permission to run outside the sandbox. Request the
   required command escalation in the execution environment. Do not add
   `--no-sandbox`. Use temporary output paths unless rendered output is a
   deliverable. If Edge is unavailable or the render fails, report the check as
   unavailable or failed rather than passing it.
5. For a complex document, route the finished artifact and source context to
   `technical-writer-validator`, or to `technical-writer-validator-deep` for
   safety guidance or intricate architecture documentation; request revisions
   for unresolved error findings.

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
and complex MATLAB/Simulink changes require independent validation with no
unresolved error findings. The final response names changed artifacts and
collected evidence.

Run `uv run --frozen python scripts/check_agent_handoffs.py` after changing
`AGENTS.md`, `.codex/agents/*.toml`, `.omp/agents/*.md`, the `diagrammer` skill,
or agent orchestration architecture documents. Completion requires every
reported check to pass; an unavailable required checker is a disclosed
limitation, not a pass.

## MATLAB MCP session selection and ownership

Use the configured endpoints according to the task:

| Endpoint | Preferred use | Ownership requirement |
| --- | --- | --- |
| `matlab-existing` | Human-guided model development, visual walkthroughs, and interactive debugging in a prepared session. | Confirm the intended shared session and coordinate one owner; protect the human's workspace, paths, open models, and unsaved changes. |
| `matlab-disposable` | Automated checks, test execution, scratch experiments, and independent validation with explicit initialization. | Record the MATLAB version/root and working folder, initialize required project state, and preserve outputs before cleanup. |

`matlab-disposable` is a configured endpoint name, not a per-call reset, sandbox, or cleanup guarantee.
A new MATLAB process may run startup scripts and retains state across calls while alive; it can still modify the same files as the interactive session.
`nodesktop` does not guarantee that UI commands open no windows.
Do not rely on disconnect or crash cleanup without verifying the installed runtime's behavior.
For `existing` mode, select/share the intended session explicitly; the most recently shared session is otherwise selected.
Do not combine `existing` mode with MATLAB-root, initial-working-folder, or display-mode launch overrides.

Before concurrent MATLAB/Simulink execution, establish separate session ownership and deterministic task-to-endpoint routing.
Worktrees, endpoint names, `new` mode, and executable copies alone do not establish isolation.
If isolation has not been verified, serialize calls to the shared endpoint; do not run implementation and independent validation concurrently in the same mutable MATLAB session.
Verify distinct MATLAB PIDs, correct request/response identity, and independent scratch state under overlapping calls before claiming isolation.
The [pilot isolation research](docs/research/omp-matlab-mcp-session-isolation-2026-10-25.md) records observed collisions and one successful copied-executable trial; that trial is not an approved or production-validated isolation architecture.
Any proposed multi-session switch must preserve the required Simulink extension tools.
Neither endpoint removes tool-call review, filesystem-risk controls, or applicable MathWorks license requirements.

## MATLAB coding standards

Codex automatically loads this `AGENTS.md`; it does not discover MATLAB rules
from arbitrary `.github/instructions` files. For any MATLAB or Simulink-
associated MATLAB code change, open the versioned [MATLAB standards
bundle](docs/standards/matlab/README.md), then apply the relevant rule file:

- Open
  [matlab-coding-standards.md](docs/standards/matlab/matlab-coding-standards.md)
  for MATLAB code and general coding decisions.
- Open
  [live-script-generation.md](docs/standards/matlab/live-script-generation.md)
  when creating or editing a plain-text Live Script.
- Open
  [matlab-performance-optimization.md](docs/standards/matlab/matlab-performance-optimization.md)
  when optimizing or investigating a performance bottleneck; profile first.

The bundle records which rules are also available from the MATLAB MCP. Follow
project requirements, accepted ADRs, and task-specific interfaces when they
constrain a general recommendation. Preserve project-specific numerical and
code-generation decisions. The MCP Code Analyzer check is required when
available, but is not a complete standards-compliance check. The bundle in
`docs/standards/matlab` is the canonical tool-neutral rule corpus.

For every generated or edited MATLAB source file (`.m`, `.mlx`, or MATLAB code
embedded in another artifact), invoke the MATLAB Code Analyzer through the MCP
when that capability is available. Resolve all reported errors and warnings
before reporting completion, and rerun the analyzer after fixes. Record the
analyzer operation and result as validation evidence. If the MATLAB MCP or Code
Analyzer operation is unavailable, record the check as unavailable and disclose
that limitation; an unavailable check is not a pass.

### Plotting

We have `gramm` available as a `ggplot2` style plotting library. Prefer using it
when appropriate instead of the MATLAB default plotting functions.

## Python usage

Always activate the virtual environment `.venv` before running Python commands or installing packages. This repo uses `uv`; do not invoke pip or conda alone.

Activate the `.venv` by:

```bash
source .venv/bin/activate # for Linux/macOS 
```

## Python linting

Ruff is the canonical linter and formatter for Python scripts. Whenever creating
or editing a `.py` file, run `uv run --frozen ruff check <path>` and `uv run
--frozen ruff format --check <path>` before reporting completion. Apply Ruff
fixes with `uv run --frozen ruff check --fix <path>` and `uv run --frozen ruff
format <path>` when appropriate, then review the diff.

Pylance/Pyright provides supplementary static type checking for Python code in
`contracts` and `scripts`. The repository-level `pyrightconfig.json` keeps this
check at `basic` mode because Python is used for project tooling and contract
validation rather than as the primary project language. Preserve that scope and
mode unless the project explicitly adopts stricter Python typing. When the
dependency environment is available, run `uv run --frozen pyright contracts
scripts` for the corresponding command-line check; report any remaining
diagnostics rather than treating the check as passed.

## Repository context

```text
AGENTS.md
.codex/agents/*.toml        # Codex project-scoped specialist definitions
.omp/agents/*.md           # OMP-native equivalents, with explicit safety limits
.agents/skills/            # repository skills
```

## Agent skills

### Releases

When the user requests a release, run `uv run python scripts/release.py` from a
clean worktree. Review the resulting changelog, release commit, and annotated
SemVer tag before reporting completion. The script creates a local release only;
push the commit and tag when the user requests publication.

### Issue tracker

GitHub Issues for `JulioLeonPhd/ai-mbd-pilot-project`, using the `gh` CLI.
Because GitHub API access can fail inside the command sandbox, always run `gh`
CLI commands outside the sandbox using the execution environment's escalation
mechanism. This outside-sandbox execution is authorized for all GitHub
issue-tracker operations in this repository. See `docs/agents/issue-tracker.md`
for command conventions.

### Triage labels

The five default canonical labels: `needs-triage`, `needs-info`,
`ready-for-agent`, `ready-for-human`, and `wontfix`. See
`docs/agents/triage-labels.md`.

### Domain docs

Single-context layout: root `GLOSSARY.md` and system-wide decisions in
`docs/adr/`. See `docs/agents/domain.md`.
