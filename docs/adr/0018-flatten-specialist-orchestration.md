---
status: accepted
---

# Flatten specialist orchestration

We will keep all specialist orchestration at the root: specialists never spawn
other specialists. Any agent, including root, may use the
`drawing-mermaid-diagrams` skill for authorized Mermaid work; existing mutation
limits still apply, and no Mermaid specialist handoff is needed. This removes
the sole delegation exception from ADR 0001 and reduces handoff overhead. At the
time of this decision, this left nine independently selectable specialist
roles; `AGENTS.md` is authoritative for the current specialist registry.

## Consequences

- The root remains the only agent that spawns specialists.
- Any agent, including root, may use the `drawing-mermaid-diagrams` skill for
  authorized Mermaid work; existing mutation limits still apply.
- Diagram purpose, constraints, rendering evidence, and findings remain in the
  owning task and result packets.
