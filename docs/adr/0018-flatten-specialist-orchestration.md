---
status: accepted
---

# Flatten specialist orchestration

We will keep all specialist orchestration at the root: specialists never spawn
other specialists. Mermaid diagramming is a reusable repository skill applied by
the agent that owns the artifact, not a `diagrammer` specialist role. This removes
the sole delegation exception from ADR 0001, reduces handoff overhead, and leaves
nine independently selectable specialist roles.

## Consequences

- The root remains the only agent that spawns specialists.
- Technical writers create and verify Mermaid diagrams with the `diagrammer`
  skill in their own task.
- Diagram purpose, constraints, rendering evidence, and findings remain in the
  owning task and result packets.
