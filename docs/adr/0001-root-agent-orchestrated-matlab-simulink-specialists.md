---
status: accepted
---

# Root-agent orchestration for MATLAB/Simulink specialists

We will use the root agent as the default planner and orchestrator for ten
repository-defined MATLAB/Simulink specialist roles: the six base roles
(`technical-writer`, `diagrammer`, `matlab-architect`,
`technical-writer-validator`, `matlab-implementer`, and `matlab-validator`) plus
`matlab-architect-deep`, `technical-writer-validator-deep`,
`simulink-implementer`, and `matlab-validator-deep`. The root agent owns
decomposition, sequencing, authority, and final decisions; specialists do not
spawn subagents, except that `technical-writer` may delegate Mermaid generation
to `diagrammer`. The root checks runtime availability before spawning a role and
selects deep variants when observable complexity or risk warrants them. The root
routes substantive Simulink topology, interface, configuration, and multi-step
MCP edits to `simulink-implementer`, while `matlab-implementer` handles MATLAB
code and simple local model edits. Exact models, effort settings, and tool
configuration remain in the role TOMLs. The operational routing rules live in
[AGENTS.md](../../AGENTS.md).

## Considered Options

- **One general-purpose agent:** Rejected because MATLAB/Simulink design,
  implementation, documentation, and validation have different reasoning and tool
  requirements.
- **Unrestricted specialist delegation:** Rejected because recursive delegation
  makes authority, cost, and completion difficult to control.
- **Root orchestration with bounded specialists:** Accepted because it preserves
  explicit seams, allows low-cost documentation work, reserves high reasoning for
  difficult technical work, and keeps mutation separate from independent review.

## Consequences

- Complex MATLAB/Simulink changes normally follow architecture, implementation,
  and independent validation stages.
- Trivial documents and trivial MATLAB/Simulink changes may omit their respective
  semantic validators when the root agent records the triage decision.
- `markdownlint-cli2` is required for touched Markdown, `mmdc` is required for
  Mermaid diagrams, and manifest JSON is validated separately without Markdown
  linting.
- The workflow depends on the root agent correctly classifying complexity and
  preserving the task/result handoff contract.
