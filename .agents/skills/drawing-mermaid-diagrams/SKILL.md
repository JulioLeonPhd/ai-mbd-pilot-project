---
name: drawing-mermaid-diagrams
description: Author or revise Mermaid diagrams when a reader needs a question, audience, elements, and relationships expressed visually.
---

# Drawing Mermaid diagrams

Any agent, including root, may use this skill when authoring a Mermaid diagram
within its assigned artifact scope; this is not a specialist handoff. Identify
the diagram's purpose and audience, the reader's question, required nodes or
states and relationships, and any constraints. Preserve supplied intent; do
not add unsupported technical meaning. Work directly in the artifact you are
authorized to edit, and keep source with the artifact it describes.

Choose notation for the relationship being explained: use a flowchart for
branches or dependencies, a sequence diagram for ordered messages, a state
diagram for event-driven transitions, or a scoped C4 view for architecture.
These are matches, not syntax rules. Choose direction to follow the reader's
path and fit the available width. Keep one diagram focused on one question; use
concise labels and meaningful grouping, and split diagrams that combine
distinct questions.

Label arrows so their meaning is explicit, including branch conditions and
transition triggers. Do not let one visual style imply different meanings such
as data flow, authority, or timing. For C4, state scope and element types, label
one-way relationships, and identify relevant technologies or protocols.
Mermaid C4 layout depends on statement order and does not support legends;
supply a text key when one is needed.

Add an accessible title and description when supported (`accTitle` and
`accDescr` add SVG metadata). Inspect the delivery surface's accessible name
and description as well; SVG metadata alone does not establish accessibility.
Never use color as the only carrier of meaning. For complex diagrams, state the
essential relationships in adjacent text.

Treat these as distinct evidence: parsing establishes syntax acceptance; local
rendering/export establishes output from that toolchain; visual inspection
establishes appearance in inspected output; and host preview establishes
appearance in that host only. When the target host renders Mermaid itself,
inspect its actual preview; if unavailable, report it unavailable. Inspect the
rendered deliverable at its intended width and theme for missing or unexpected
elements, arrow meaning, clipping, overlap, legibility, and contrast. Report
which evidence you collected; do not imply one proves another.

When repository guidance mandates Mermaid rendering, follow its
[Mermaid procedure](../../../docs/agents/task-guidance.md#mermaid-diagrams) and
report the exact command and result. This skill does not replace that procedure.
For other contexts, use available tools without installing browsers or tools;
report unavailable checks as unavailable.
