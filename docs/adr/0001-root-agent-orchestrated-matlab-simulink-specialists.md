---
status: accepted
---

# Root-agent orchestration for MATLAB/Simulink specialists

We will use a root agent to orchestrate six focused specialist agents for the
MATLAB/Simulink workflow: `technical-writer`, `diagrammer`, `matlab-architect`,
`technical-writer-validator`, `matlab-implementer`, and `matlab-validator`. The
root agent owns decomposition, sequencing, authority, and final decisions;
specialists do not spawn subagents, except that `technical-writer` may delegate
Mermaid generation to `diagrammer`.

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
