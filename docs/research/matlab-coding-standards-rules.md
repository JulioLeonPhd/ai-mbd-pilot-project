# Official MATLAB coding rules inventory

<!-- markdownlint-disable MD013 -->

> Snapshot date: 2026-09-13. Primary-source inventory of the `main` branch of
> [`matlab/rules`](https://github.com/matlab/rules/tree/main), with the linked
> MathWorks Coding Guidelines repository consulted for the enforceable Code
> Analyzer layer.

## Executive finding

[`matlab/rules`](https://github.com/matlab/rules/tree/main) is an AI instruction
pack, not a static-analysis or CI distribution. Its `main` tree contains six
root-level files: `.gitattributes`, `LICENSE.txt`, `README.md`, and three rule
Markdown files. The tree lists no workflow, schema, test, or check-runner
artifact.

The enforceable/checkable layer is a separate, explicitly linked repository:
[`mathworks/MATLAB-Coding-Guidelines`](https://github.com/mathworks/MATLAB-Coding-Guidelines).
That repository distinguishes Rules from optional Best Practices, documents
Code Analyzer detection, and ships the accompanying
[`codeAnalyzerConfiguration.json`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/codeAnalyzerConfiguration.json).

Recommendation: integrate two deliberate planes. Give AI agents the selected
`matlab/rules` Markdown files, and run MATLAB Code Analyzer independently using
the matching official guideline release/configuration. Treat performance advice,
Live Script formatting, Simulink/MBD policy, and anything marked not detectable
as advisory unless this repository adds and owns a separate check.
([`main` tree](https://github.com/matlab/rules/tree/main); [`codeAnalyzerConfiguration.json`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/codeAnalyzerConfiguration.json))

## Upstream `matlab/rules` layout

| Path | Role stated by upstream |
| --- | --- |
| [`README.md`](https://raw.githubusercontent.com/matlab/rules/main/README.md) | Rule catalog, tool-specific setup, examples, contribution guidance, provenance, and license statement. |
| [`matlab-coding-standards.md`](https://raw.githubusercontent.com/matlab/rules/main/matlab-coding-standards.md) | MATLAB naming, statements/expressions, formatting, comments, function/class authoring, and error-handling guidance. |
| [`live-script-generation.md`](https://raw.githubusercontent.com/matlab/rules/main/live-script-generation.md) | Plain-text MATLAB Live Script generation guidance. |
| [`matlab-performance-optimization.md`](https://raw.githubusercontent.com/matlab/rules/main/matlab-performance-optimization.md) | Performance guidance for profiling, vectorization, memory, parallel/GPU work, apps, JIT, and file I/O. |
| [`.gitattributes`](https://github.com/matlab/rules/blob/main/.gitattributes) | Repository attribute file containing `* text=auto` for text/LF normalization; no rule semantics are described in the README. |
| [`LICENSE.txt`](https://github.com/matlab/rules/blob/main/LICENSE.txt) | Repository license file containing the CC BY 4.0 text and copyright notice. |

The repository page identifies `main` as the displayed branch and reports nine
commits for this small root-level tree. On the snapshot date, a read-only
`git ls-remote` query resolved `main` to
[`62fa4af78cc429d2b90f1bb8259fad0bc08416eb`](https://github.com/matlab/rules/commit/62fa4af78cc429d2b90f1bb8259fad0bc08416eb).
No version file, schema, workflow, or release artifact is listed in that tree;
the rendered repository page also has an empty Releases section, and the
upstream tag listing returned no tags. These are properties of the observed
upstream snapshot, so integration should recheck the tree and release page
before each update: [`main` tree](https://github.com/matlab/rules/tree/main),
[releases](https://github.com/matlab/rules/releases), and
[tags](https://github.com/matlab/rules/tags).

## AI-facing content

### `matlab-coding-standards.md`

The file is prose for “generating MATLAB code” and reviewing code quality; it
does not contain formal `Type`, `Detection`, `History`, or Code Analyzer check
metadata. Its exact top-level sections are:

- `Naming Guidelines`
- `Statements and Expressions Guidelines`
- `Formatting Guidelines`
- `Code Comments Guidelines`
- `Function Authoring Guidelines`
- `Class Authoring Guidelines`
- `Error Handling Guidelines`
- `Additional Guidelines`

The concrete prescriptions include 32-character limits for variables/functions,
`lowerCamelCase`/`UpperCamelCase` naming conventions, no multiple statements on
one line, no command syntax in functions/methods, no floating-point `==`/`~=`,
platform-independent path handling, no more than five nesting levels, array
preallocation, no loop-iterator mutation, four-space indentation, lines of at
most 120 characters, function H1/help documentation, at most six inputs and
four outputs, public-interface argument validation, restrictive class access,
informative errors, and avoidance of `eval`, `evalin`, `assignin`, `cd`,
`addpath`, `rmpath`, and `throwAsCaller`. The source also says to fix all Code
Analyzer warnings, but it does not say which warnings or how to run them:
[`matlab-coding-standards.md`](https://raw.githubusercontent.com/matlab/rules/main/matlab-coding-standards.md).

### `live-script-generation.md`

This is an AI generation/format rule, not a checker. Its exact sections are
`Required MATLAB Release`, `Format Rules`, `Script Template Structure`, `Usage
Guidelines`, `Example Request Format`, `Benefits of Plain Text Format`, and
`Example Structure`. It requires MATLAB R2025a or newer and prescribes
`%[text]` documentation blocks, `%%` sections, Markdown inside text blocks,
LaTeX conventions, implicit figures, trailing backslashes for Markdown lists,
one preferred output per code block, and a closing appendix containing
`[appendix]{"version":"1.0"}` plus `[metadata:view]` layout metadata:
[`live-script-generation.md`](https://raw.githubusercontent.com/matlab/rules/main/live-script-generation.md).

The `"version":"1.0"` value is Live Code appendix metadata in the example; it
is not a release/version declaration for the `matlab/rules` repository.
([`live-script-generation.md`](https://raw.githubusercontent.com/matlab/rules/main/live-script-generation.md); [`main` tree](https://github.com/matlab/rules/tree/main))

### `matlab-performance-optimization.md`

This file is advisory optimization guidance. Its exact sections are `Profiling
and Benchmarking`, `Vectorization Guidelines`, `Memory Management`, `Parallel
Computing`, `App Designer Performance`, `JIT Compiler Optimization`, `File I/O
Performance`, and `Quick Reference: Common Anti-Patterns`. It recommends
measure-before-optimizing, `timeit`/Profiler use, vectorization where suitable,
preallocation, data-type and copy-on-write awareness, `parfor`/`parfeval`/
`backgroundPool`, GPU residency, responsive App Designer callbacks, JIT-friendly
patterns, and appropriate MAT/CSV/Parquet/binary I/O. The file contains no Code
Analyzer IDs or CI instructions:
[`matlab-performance-optimization.md`](https://raw.githubusercontent.com/matlab/rules/main/matlab-performance-optimization.md).

## How upstream expects agents to consume the rules

The README documents copying or referencing the Markdown files for Cursor
(`.cursor/rules`), Windsurf (`.windsurf/rules`), Claude Code (`CLAUDE.md` with
`@` references), and GitHub Copilot (`.github/copilot-instructions.md` or a
path-scoped `.github/instructions/matlab.instructions.md` applying to
`**/*.m`/`**/*.mlx`). It recommends modular files, references rather than
duplication, central updates, explicit context, and asking the AI to validate
compliance. These are agent-instruction integration mechanisms; none is a CI
exit-status contract:
[`README.md`](https://raw.githubusercontent.com/matlab/rules/main/README.md).

## Formal Code Analyzer layer linked by upstream

### Rules versus Best Practices

The linked MathWorks guidelines explicitly define Rules as requirements for
compliance and Best Practices as optional recommendations. They state that
Code Analyzer detects only a subset of the Rules, that some Rules are not yet
detected, and that optional Best Practice checks are generally disabled. The
Detection field identifies the Code Analyzer check that can be disabled or
modified in a local configuration:
[`MATLAB-Coding-Guidelines.md`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/MATLAB-Coding-Guidelines.md).

### Exact guideline rules and detection names

The following are the formal rule/check names exposed by the linked guideline
document. Names in backticks are exact Code Analyzer/configuration names.

| Guideline rule | Type/status | Detection named by the official document |
| --- | --- | --- |
| `Variable name length` | Rule | `naming.variable.maxLength` |
| `Variable name casing` | Rule | `naming.variable.regularExpression` |
| `Name length for functions and other programming interface elements` | Rule | `naming.class.maxLength`, `naming.function.maxLength`, `naming.localFunction.maxLength`, `naming.method.maxLength`, `naming.nestedFunction.maxLength`, `naming.property.maxLength`, `naming.event.maxLength`, `naming.enumeration.maxLength` |
| `Function name casing` | Rule | `naming.function.casing`, `naming.localFunction.casing`, `naming.nestedFunction.casing` |
| `Class name casing` | Rule | Not currently detected |
| `Method name casing` | Rule | `naming.method.casing` |
| `Property name casing` | Rule | `naming.property.casing` |
| `Event name casing` | Rule | `naming.event.casing` |
| `Nesting of Control Statements` | Rule | `MNCSN` |
| `Iterator modification` | Rule | `FXSET` |
| `Line length` | Rule | `LLMNC` |
| `Number of function inputs` | Rule | `FCNIL` |
| `Number of function outputs` | Rule | `FCNOL` |
| `Comma separated outputs` | Rule | `NCOMMA` |
| `File name` under Function Authoring | Rule | `FNDEF` |
| `File name` under Class Authoring | Rule | `MCFIL` |

All rule titles, types, detection statuses, and names in this table come from
the official guideline document:
[`MATLAB-Coding-Guidelines.md`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/MATLAB-Coding-Guidelines.md).

The guideline also names built-in warnings for some Best Practices: `GVMIS`
for global variables and `AGROW` for array growth. Those entries are described
as Code Analyzer warnings rather than guideline detections. Many whitespace,
documentation, API-design, class-design, error-message, and performance
recommendations are explicitly `Not detectable` or `Not currently detected` in
the official document. The detection examples and statuses are in the
[guideline document](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/MATLAB-Coding-Guidelines.md).

### Exact configuration keys and defaults

The official configuration declares `guidelineVersion: "1.0.0"`,
`schemaVersion: "1.1.0"`, and `baseConfiguration: "factory"`. Its top-level
`checks` keys are:

| Configuration key(s) | Default in the official file | Meaning/parameters |
| --- | --- | --- |
| `MNCSN` | Enabled | `limit: 5`; nesting of loop/conditional statements. |
| `LLMNC` | Enabled | `limit: 120`; code/comment line length. |
| `FCNIL` | Enabled | `limit: 6`; function input count. |
| `FCNOL` | Enabled | `limit: 4`; function output count. |
| `DAFPV` | Disabled | Persistent variables. |
| `DAFCVC` | Disabled | Character-vector cell arrays. |
| `DAFCF` | Disabled | Command-form function calls. |
| `DAFCO`, `DAFBR`, `DAFRT` | Disabled | `continue`, `break`, and `return` in loops. |
| `DAFNF` | Disabled | Nested functions. |
| `DAFVI` | Disabled | `varargin` for Name-Value arguments. |
| `CTCH` | Disabled | `try`/`catch` usage. |
| `disallow.eval` | Disabled | Custom `functionCall` rule for `eval`. |
| `disallow.workspace` | Disabled | Custom `functionCall` rule for `evalin` and `assignin`. |
| `disallow.pathFunction` | Disabled | Custom `functionCall` rule for `cd`, `addpath`, and `rmpath`. |
| `disallow.throwAsCaller` | Disabled | Custom `functionCall` rule for `throwAsCaller`. |

The enabled/disabled states and parameters in the table are copied from the
official configuration:
[`codeAnalyzerConfiguration.json`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/codeAnalyzerConfiguration.json).

The same file's exact `naming` configuration keys are
`variable.maxLength`, `variable.regularExpression`, `class.maxLength`,
`function.maxLength`, `localFunction.maxLength`, `nestedFunction.maxLength`,
`method.maxLength`, `property.maxLength`, `event.maxLength`,
`enumeration.maxLength`, `function.casing`, `localFunction.casing`,
`nestedFunction.casing`, `method.casing`, `property.casing`, and
`event.casing`. The configured values are a 32-character maximum for all listed
identifier categories; lowerCamelCase/lowercase for functions, local
functions, nested functions, and methods; UpperCamelCase for properties and
events; and the variable regular expression
`(^[a-z][a-zA-Z0-9]*$)|(^[A-Z][a-z0-9]*$)`:
[`codeAnalyzerConfiguration.json`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/codeAnalyzerConfiguration.json).

The configuration file is named `.json` but the observed source contains `//`
comments. Consumers should confirm the MATLAB configuration format/parser rather
than assuming that a generic strict-JSON parser accepts the file:
[`codeAnalyzerConfiguration.json`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/codeAnalyzerConfiguration.json).

## Version and release mechanism

### `matlab/rules`

The observed `matlab/rules` `main` tree has no repository version field,
`CHANGELOG`, workflow, or schema artifact in its listed contents; the remote
tag query returned no tags. The GitHub page exposes branch/tag navigation but
no release entry in the rendered Releases section. Therefore, a vendored copy
should record the exact commit SHA obtained at update time; the branch name
alone is not a reproducible version reference. Recheck
[the tree](https://github.com/matlab/rules/tree/main),
[tags](https://github.com/matlab/rules/tags), and
[releases](https://github.com/matlab/rules/releases) when updating.

### Linked enforceable guidelines

The official linked guideline release is
[v1.0.0, dated 2025-09-17](https://github.com/mathworks/MATLAB-Coding-Guidelines/releases/tag/v1.0.0).
Its README maps guideline Version 1.0 to MATLAB R2025a and higher and says each
version contains `codeAnalyzerConfiguration.json`,
`MATLAB-Coding-Guidelines.md`, and `RevisionHistory.md`:
[`README.md`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/README.md).
The release page records the release commit as `8a2d686` and six commits to
`main` since that release. For deterministic enforcement, pin the guideline
release/tag and separately pin the AI rule-pack commit.

## Relationship to the official MATLAB MCP

The official MATLAB MCP Server README documents `check_matlab_code` as a
read-only static analysis tool that returns style, potential-error, deprecated-
function, performance, and best-practice diagnostics. It also exposes the
resources `matlab_coding_guidelines` at `guidelines://coding` and
`plain_text_live_code_guidelines` at
`guidelines://plain-text-live-code`, with the latter explicitly requiring
R2025a or newer. This makes the MCP useful as an agent-time validation bridge,
but the upstream `matlab/rules` repository does not itself invoke the tool or
define a CI policy:
[`matlab-mcp-server/README.md`](https://github.com/matlab/matlab-mcp-server/blob/main/README.md).

## Licensing and attribution for vendoring

The `matlab/rules` README says the work is based on the MathWorks MATLAB Coding
Guidelines and MATLAB Prompts and is licensed under the Creative Commons
Attribution 4.0 International License. The current `LICENSE.txt` begins
`MATLAB AI Coding Rules © 2025 by The MathWorks, Inc.` and includes the full CC
BY 4.0 text:
[`README.md`](https://raw.githubusercontent.com/matlab/rules/main/README.md),
[`LICENSE.txt`](https://github.com/matlab/rules/blob/62fa4af78cc429d2b90f1bb8259fad0bc08416eb/LICENSE.txt).

For CC BY 4.0 material, the license deed requires appropriate credit, a link to
the license, and an indication of changes, without implying endorsement; it
also prohibits additional legal or technological restrictions on permitted
uses: [CC BY 4.0 deed](https://creativecommons.org/licenses/by/4.0/).

Vendoring implication: retain the upstream `LICENSE.txt`, preserve provenance
links to `matlab/rules`, MATLAB Coding Guidelines, and MATLAB Prompts, and mark
any local edits to copied rule text. Keep third-party rule text in a clearly
identified rules/notice area rather than silently presenting it as locally
authored policy. This is an integration recommendation based on the upstream
license statement and CC BY terms, not legal advice.

## Recommendation-relevant gap inventory

| Gap in `matlab/rules` | Consequence for this MATLAB/Simulink MBD repository | Recommended treatment | Source basis |
| --- | --- | --- | --- |
| No workflow, schema, test, or checker artifact in the tree. | Copying the Markdown files alone cannot fail a pull request or produce a reproducible compliance report. | Add a repository-owned CI/validation layer around the official Code Analyzer configuration; keep the AI files as guidance, not as the gate itself. | [`main` tree](https://github.com/matlab/rules/tree/main); [`codeAnalyzerConfiguration.json`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/codeAnalyzerConfiguration.json) |
| Prose rule pack does not preserve formal Rule/Best Practice types, Detection fields, or check IDs. | Agents may overstate advisory guidance as enforceable, and reviewers cannot map an AI finding directly to a Code Analyzer result. | Keep the formal guideline release/configuration alongside the AI pack and use the exact check names above in reports and exceptions. | [`matlab-coding-standards.md`](https://raw.githubusercontent.com/matlab/rules/main/matlab-coding-standards.md); [`MATLAB-Coding-Guidelines.md`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/MATLAB-Coding-Guidelines.md) |
| Many formatting, API-design, class-design, error-message, performance, and Live Script recommendations are not detectable by the official Code Analyzer; `matlab/rules` adds no checker. | Compliance remains partly review- or agent-dependent. | Label such items advisory and create focused repository checks only where the project needs a hard gate. | [`MATLAB-Coding-Guidelines.md`](https://raw.githubusercontent.com/mathworks/MATLAB-Coding-Guidelines/main/MATLAB-Coding-Guidelines.md); [`matlab-performance-optimization.md`](https://raw.githubusercontent.com/matlab/rules/main/matlab-performance-optimization.md) |
| No Simulink/MBD-specific rule file is listed. | The pack does not address model topology, sample times, solver settings, fixed-point staging, requirements traceability, model tests, code generation, or safety/process controls relevant to this repository. | Layer local Simulink/MBD policies and model validation on top of the MATLAB code rules; do not infer model compliance from `check_matlab_code`. | [`main` tree](https://github.com/matlab/rules/tree/main); [`matlab-mcp-server/README.md`](https://github.com/matlab/matlab-mcp-server/blob/main/README.md) |
| No release/version metadata for `matlab/rules`. | A floating `main` reference can change AI behavior without a reviewable version change. | Pin and record the AI-pack commit SHA; update it through an explicit review. Pin the formal guideline tag separately. | [current `main` commit](https://github.com/matlab/rules/commit/62fa4af78cc429d2b90f1bb8259fad0bc08416eb); [tags](https://github.com/matlab/rules/tags); [releases](https://github.com/matlab/rules/releases) |
| CC BY attribution is required for vendored rule text. | A copied rule file without provenance/changes notice is incomplete redistribution metadata. | Preserve `LICENSE.txt`, source links, and a local modification notice. | [`README.md`](https://raw.githubusercontent.com/matlab/rules/main/README.md); [`LICENSE.txt`](https://github.com/matlab/rules/blob/62fa4af78cc429d2b90f1bb8259fad0bc08416eb/LICENSE.txt); [CC BY 4.0 deed](https://creativecommons.org/licenses/by/4.0/) |

## Handoff

Use this note as the inventory baseline for the implemented integration. The
repository vendors a pinned copy of the three AI files under
`docs/standards/matlab`; Codex reaches them through the root `AGENTS.md`, which
is the repository's agent entrypoint. Keep the MATLAB release and official
`codeAnalyzerConfiguration.json` version aligned when updating the bundle; this
research note and the standards documentation do not modify application source.

<!-- markdownlint-enable MD013 -->
