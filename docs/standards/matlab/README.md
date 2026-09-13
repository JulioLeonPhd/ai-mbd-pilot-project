# MATLAB standards bundle

This directory contains the MATLAB AI coding rules used by this repository. The
three rule files are preserved from the official
[matlab/rules repository](https://github.com/matlab/rules/tree/main) at pinned
commit
[62fa4af78cc429d2b90f1bb8259fad0bc08416eb](https://github.com/matlab/rules/commit/62fa4af78cc429d2b90f1bb8259fad0bc08416eb),
whose latest commit date was 2026-01-19.

## Rule files

- [matlab-coding-standards.md](matlab-coding-standards.md) covers naming,
  statements, formatting, comments, function and class authoring, and error
  handling.
- [live-script-generation.md](live-script-generation.md) covers the plain-text
  Live Script format. It requires MATLAB R2025a or newer.
- [matlab-performance-optimization.md](matlab-performance-optimization.md)
  covers profiling, vectorization, memory, parallelism, applications, JIT,
  and file I/O.
- [LICENSE.txt](LICENSE.txt) preserves the upstream CC BY 4.0 license and
  attribution notice.
- [SHA256SUMS](SHA256SUMS) records the hashes used to verify the pinned
  snapshots.

## MCP coverage

The MATLAB MCP currently exposes these related resources:

- Coding standards: guidelines://coding matches the pinned upstream rule.
- Live Script generation: guidelines://plain-text-live-code matches the pinned
  upstream rule.
- Performance optimization: no corresponding MCP resource; this repository
  copy supplies the missing coverage.

The MCP resources are useful at generation time, but they are runtime-provided
and may not be available in every review or CI environment. The pinned local
copies are the stable reference for this repository.

The MCP also exposes a check_matlab_code operation backed by MATLAB Code
Analyzer. Code Analyzer findings are valuable evidence, but that operation does
not implement every prose rule here and is not a complete standards-compliance
check.

## Application and precedence

For MATLAB and Simulink-associated MATLAB code:

1. Follow the project requirements, accepted ADRs, and task-specific interfaces.
2. Consult the local rule files above for coding and Live Script decisions.
3. Apply performance guidance after profiling identifies a real bottleneck.
4. Use the repository's agent workflow and validation gates in
   [AGENTS.md](../../AGENTS.md).

Performance guidance is advisory and context-dependent. In particular, do not
make vectorization, parallelism, single precision, MEX, or code generation
blanket requirements. Preserve the floating-point-to-fixed-point staging in
[ADR 0003](../../adr/0003-stage-floating-point-fixed-point-simulink.md), and do
not interpret performance or code-generation advice as contradicting the HDL
deferral in
[ADR 0008](../../adr/0008-defer-hdl-generation-and-cosimulation.md).
Quantitative speedups in the upstream performance file are illustrative, not
requirements; measure them on the target MATLAB release and hardware.

## Updating the bundle

When upstream rules change:

1. Review the upstream repository and select a commit rather than floating on
   an unrecorded branch head.
2. Refresh all three rule files and the license file together.
3. Verify the snapshot with `shasum -a 256 -c SHA256SUMS`.
4. Compare the coding and Live Script files with guidelines://coding and
   guidelines://plain-text-live-code, and record any substantive difference.
5. Update the pinned commit link and retrieval date in this README.
6. Run markdownlint-cli2 on every changed repository-authored Markdown file and
   review the diff. The root markdownlint-cli2 configuration excludes the three
   byte-for-byte upstream snapshots; verify those files with source hashes.

The local README is intentionally project-specific; the upstream README's
tool-specific setup examples are not copied here. The root
[AGENTS.md](../../../AGENTS.md) is the Codex entrypoint, and this directory is
the canonical tool-neutral rule corpus. The entrypoint points here rather than
duplicating the rules.

## Provenance

The rules are based on the
[MathWorks MATLAB Coding Guidelines](https://github.com/mathworks/MATLAB-Coding-Guidelines)
and the upstream repository states that the material is licensed under
[Creative Commons Attribution 4.0 International](https://creativecommons.org/licenses/by/4.0/).
The upstream rule text is retained verbatim; this README and the root
`AGENTS.md` add repository-specific usage guidance only. The root
markdownlint-cli2 configuration excludes the upstream snapshots because their
source formatting is part of the pinned snapshot and is not this repository's
Markdown style.
