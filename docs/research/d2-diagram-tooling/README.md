# Diagram tool choice

Decision by Julio, 2026-09-28: use Mermaid for simple diagrams written in
Markdown when GitHub rendering is sufficient. Use PlantUML with rendered SVG
for complex diagrams. Reserve D2 for especially complex architectural views
that need details such as ports, given that System Composer is unavailable.

The [context view comparison](comparison.md) and [data timing comparison](data-timing-comparison.md)
record evaluation examples and observations that informed future tool
selection. They do not establish that D2 ports were tested. earlier
provisional recommendation in context comparison predates this decision
and is superseded by it.

For existing PlantUML preview setup and render command, see the
[Radar V1 overview](../../architecture/radar-overview.md).

The [D2 setup note](../d2-diagram-tooling-setup-2026-09-28.md) records installation
options. Markdown Preview Enhanced rendering test remains unverified; the
data timing comparison includes native D2 block for that test.
