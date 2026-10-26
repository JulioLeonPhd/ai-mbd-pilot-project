# MATLAB standards bundle

This directory contains MATLAB AI coding rules used by this repository. The
three rule files are preserved from official
[matlab/rules repository](https://github.com/matlab/rules/tree/main) at pinned
commit
[62fa4af78cc429d2b90f1bb8259fad0bc08416eb](https://github.com/matlab/rules/commit/62fa4af78cc429d2b90f1bb8259fad0bc08416eb),
whose latest commit date was 2026-01-19.

## Rule files

- [matlab-coding-standards.md](matlab-coding-standards.md) covers naming,
  statements, formatting, comments, function and class authoring, and error
  handling.
- [live-script-generation.md](live-script-generation.md) covers plain-text
  Live Script format. It requires MATLAB R2025a or newer.
- [matlab-performance-optimization.md](matlab-performance-optimization.md)
  covers profiling, vectorization, memory, parallelism, applications, JIT,
  and file I/O.
- [LICENSE.txt](LICENSE.txt) preserves upstream CC BY 4.0 license and
  attribution notice.
- [SHA256SUMS](SHA256SUMS) records hashes used to verify pinned
  snapshots.

## MCP coverage

MATLAB MCP currently exposes these related resources:

- Coding standards: guidelines://coding matches pinned upstream rule.
- Live Script generation: guidelines://plain-text-live-code matches pinned
  upstream rule.
- Performance optimization: no corresponding MCP resource; this repository
  copy supplies missing coverage.

MCP resources are useful at generation time, but they are runtime-provided
and may not be available in every review or CI environment. pinned local
copies are stable reference for this repository.

MCP also exposes check_matlab_code operation backed by MATLAB Code
Analyzer. Code Analyzer findings are valuable evidence, but that operation does
not implement every prose rule here and is not complete standards-compliance
check.

## Application and precedence

For MATLAB and Simulink-associated MATLAB code:

1. Follow project requirements, accepted ADRs, and task-specific interfaces.
2. Consult local rule files above for coding and Live Script decisions.
3. Apply performance guidance after profiling identifies real bottleneck.
4. Use repository's agent workflow and validation gates in
   [AGENTS.md](../../../AGENTS.md).

Performance guidance is advisory and context-dependent. In particular, do not
make vectorization, parallelism, single precision, MEX, or code generation
blanket requirements. Preserve floating-point-to-fixed-point staging in
[ADR 0003](../../adr/0003-stage-floating-point-fixed-point-simulink.md), and do
not interpret performance or code-generation advice as contradicting HDL
deferral in
[ADR 0008](../../adr/0008-defer-hdl-generation-and-cosimulation.md).
Quantitative speedups in upstream performance file are illustrative, not
requirements; measure them on target MATLAB release and hardware.

## Updating the bundle

When upstream rules change:

1. Review upstream repository and select commit rather than floating on
   unrecorded branch head.
2. Refresh all three rule files and license file together.
3. Verify snapshot with `shasum -a 256 -c SHA256SUMS`.
4. Compare coding and Live Script files with guidelines://coding and
   guidelines://plain-text-live-code, and record any substantive difference.
5. Update pinned commit link and retrieval date in this README.
6. Run markdownlint-cli2 on every changed repository-authored Markdown file and
   review diff. root markdownlint-cli2 configuration excludes the three
   byte-for-byte upstream snapshots; verify those files with source hashes.

local README is intentionally project-specific; upstream README's
tool-specific setup examples are not copied here. root
[AGENTS.md](../../../AGENTS.md) is Codex entrypoint, and this directory is
canonical tool-neutral rule corpus. entrypoint points here rather than
duplicating rules.

## Provenance

rules are based on the
[MathWorks MATLAB Coding Guidelines](https://github.com/mathworks/MATLAB-Coding-Guidelines)
and upstream repository states that material is licensed under
[Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/).
upstream rule text is retained verbatim; this README and root
`AGENTS.md` add repository-specific usage guidance only. root
markdownlint-cli2 configuration excludes upstream snapshots because their
source formatting is part of pinned snapshot and is not this repository's
Markdown style.
