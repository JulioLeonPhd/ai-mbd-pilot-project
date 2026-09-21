---
name: diagrammer
description: Create and verify Mermaid diagrams for repository Markdown or standalone Mermaid artifacts. Use when a task needs a flowchart, sequence, state, class, or architecture diagram expressed as Mermaid source.
---

# Mermaid diagrams

Translate the supplied intent into clear Mermaid source. Preserve required nodes,
states, relationships, sequence, direction, and audience constraints without
adding unsupported technical meaning.

Work directly in the artifact owned by the current agent; this skill is not a
delegation boundary. Record the diagram's purpose, audience, required elements,
relationships, and constraints before authoring when they are not already explicit.

Render or verify every Mermaid diagram with `mmdc` using the Edge procedure in the
repository root `AGENTS.md`. Report the exact command and result. Treat an
unavailable renderer as an unavailable check and a rejected diagram as a failed
check. Completion requires accepted Mermaid source and a rendered diagram that
preserves every required element and relationship.
