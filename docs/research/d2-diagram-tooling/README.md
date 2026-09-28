# Diagram tool choice

Decision by Julio, 2026-09-28: use Mermaid for simple diagrams written in
Markdown when GitHub rendering is sufficient. Use PlantUML with a rendered SVG
for complex diagrams. Reserve D2 for especially complex architectural views
that need details such as ports, given that System Composer is unavailable.

The [context view comparison](comparison.md) and [data timing comparison](data-timing-comparison.md)
record the evaluation examples and observations that informed future tool
selection. They do not establish that D2 ports were tested. The earlier
provisional recommendation in the context comparison predates this decision
and is superseded by it.

For the existing PlantUML preview setup and render command, see the
[Radar V1 overview](../../architecture/radar-overview.md).

The [D2 setup note](../d2-diagram-tooling-setup-2026-09-28.md) records installation
options. The Markdown Preview Enhanced rendering test remains unverified; the
data timing comparison includes a native D2 block for that test.
