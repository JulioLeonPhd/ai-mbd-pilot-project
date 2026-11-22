# Mermaid authoring and rendering: findings and proposal

## Purpose and status

This note distinguishes diagram authoring, syntax parsing, terminal rendering,
file export, and target-host preview. It proposes a portable authoring skill
and a separately scoped local render procedure.

The proposals are not approved policy changes. In particular, changing a
repository gate or required check needs Julio's approval; this note does not
edit repository policy or the diagrammer skill.

## Findings

| Activity | What it establishes | What it does not establish |
| --- | --- | --- |
| Authoring | Whether the source expresses the intended question, audience, elements, and relationships. | Syntax validity or rendered appearance. |
| Terminal rendering | OMP's native Mermaid renderer produces browser-free ASCII/Unicode output for a supported subset: flow, state, sequence, class, ER, and XY diagrams. [OMP native Mermaid source](https://github.com/can1357/oh-my-pi/blob/main/crates/natives/src/mermaid/mod.rs#L1-L11) | C4 or Gantt support, SVG/PNG/PDF export, full Mermaid.js compatibility, or GitHub preview fidelity. |
| Parsing | Whether a selected Mermaid parser accepts source. Mermaid documents `mermaid.parse` syntax validation without rendering; rejection or `false` is failure. [Mermaid syntax validation](https://mermaid.js.org/config/usage.html#syntax-validation-without-rendering) | Browser layout, exported-file correctness, accessibility, or the target host's renderer/version. |
| Local rendering/export | Whether `mmdc` converts source to a file with its Mermaid and browser environment. Its CLI supports SVG, PNG, PDF, and Markdown conversion to SVG references. [Mermaid CLI 12.0.0 source](https://github.com/mermaid-js/mermaid-cli/blob/db1ceebbe529d7975474eb0d0e9c23e9dc57cd37/src/index.js) | Whether a separate host uses the same Mermaid version, configuration, fonts, or layout. |
| Actual host preview | Whether the intended host displays the diagram acceptably in its real Markdown context. GitHub's `info` diagram reports the Mermaid version GitHub uses. [GitHub diagram documentation](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams#checking-your-version-of-mermaid) | Other hosts' behavior or validity of every possible source/configuration. |

`mmdc` is needed for the current local render gate or its file-export workflow,
not intrinsically for syntax validation or GitHub's own rendering. For
syntax-only validation, extract each intended definition,
`await mermaid.parse(source)`, and treat either rejection or a resolved `false`
as failure; inspecting the Promise without awaiting it can falsely pass. This
does not establish renderability. Bare Node is not a universal substitute:
Mermaid's flowchart parser calls DOMPurify for labels
([pinned flowchart source](https://github.com/mermaid-js/mermaid/blob/98a0945418c76238f15df2afaddbba4272656c3b/packages/mermaid/src/diagrams/flowchart/flowDb.ts#L195-L207)),
while the standalone Langium parser implements selected grammars
([pinned parser source](https://github.com/mermaid-js/mermaid/blob/98a0945418c76238f15df2afaddbba4272656c3b/packages/parser/src/parse.ts)).
Browser-free SVG renderers such as
[beautiful-mermaid](https://github.com/lukilabs/beautiful-mermaid#supported-diagrams)
have different syntax, layout, and output evidence; no additional dependency
is proposed here.
OMP's built-in browser is a separate page-navigation and inspection tool, not a
Mermaid exporter. It uses an Eval prelude that requires enablement and execution
approval; its app-executable and CDP choices select a browser backend.
[OMP browser modes](https://github.com/can1357/oh-my-pi/blob/main/docs/tools/browser.md#browser-modes)
OMP's Chromium launcher can inherit `PUPPETEER_EXECUTABLE_PATH`, so do not set
it globally. An external browser MCP is also separate and may be filtered when
the built-in browser prelude is callable.
[OMP browser launch](https://github.com/can1357/oh-my-pi/blob/main/packages/coding-agent/src/tools/browser/launch.ts#L335-L360),
[OMP MCP configuration](https://github.com/can1357/oh-my-pi/blob/main/docs/mcp-config.md#a-browser-mcp-server-is-configured-but-never-loads)

## Local smoke observations supplied by root

These are reported observations, not checks run for this note:

- `mmdc` 12.0.0 with no executable override produced an SVG containing both
  expected labels.
- `mmdc` 12.0.0 with `PUPPETEER_EXECUTABLE_PATH` set to cached Playwright
  revision 1254 `chrome-headless-shell` produced an SVG containing both
  expected labels.
- `mmdc -p <config>` with `{"headless":"shell"}` and no executable override
  produced an SVG containing both expected labels.
- Default Markdown mode emitted two nonempty SVGs and two links.
- Installed Puppeteer 25.15.0 resolved Chrome for Testing 155.0.8059.84.

For `mmdc` 12.0.0, `headless: "shell"` is already the default. Explicitly
setting it repeats the default; it does not create a second managed-browser
mode. With Chrome selected and no executable override, Puppeteer 25.15.0
resolves `chrome-headless-shell`. `headless: true` with managed full Chrome is
a distinct, unverified mode.
[mmdc 12.0.0 defaults](https://github.com/mermaid-js/mermaid-cli/blob/db1ceebbe529d7975474eb0d0e9c23e9dc57cd37/src/index.js#L462-L475),
[Puppeteer 25.15.0 executable resolution](https://github.com/puppeteer/puppeteer/blob/puppeteer-v25.15.0/packages/puppeteer-core/src/node/BrowserLauncher.ts#L620-L657)

Puppeteer, not Playwright, controls the cached browser used by `mmdc`.
Playwright revision 1254 maps to shell build 158.0.8127.18; Puppeteer 25.15.0
pins 155.0.8059.84 for both managed Chrome builds. This establishes a version
difference, not what binary was actually used in the reported override smoke.
Puppeteer warns that overriding the executable path is at the caller's risk.
Keep any override optional and limited to one invocation; record the actual
binary, version, and platform if relying on it.
[Playwright browser manifest](https://github.com/microsoft/playwright/blob/21effe64659e209ee40e7271723c949d131ebc39/packages/playwright-core/browsers.json#L4-L17),
[Puppeteer 25.15.0 revisions](https://github.com/puppeteer/puppeteer/blob/puppeteer-v25.15.0/packages/puppeteer-core/src/revisions.ts),
[Puppeteer launch options](https://pptr.dev/api/puppeteer.launchoptions)

These cases support removing Edge as a prerequisite for the reported local
workflow, but do not establish clean-machine reproducibility, compatibility
with other browser revisions, all Mermaid syntax, or target-host equivalence.

## Authoring and visual acceptance

- Start with the reader's question, audience, required nodes or states,
  relationships, and constraints. Choose a flowchart for branches or
  dependencies, a sequence diagram for ordered messages, a state diagram for
  event-driven transitions, and a scoped C4 view for architecture structure.
  These are useful matches, not syntax rules.
  [Sequence messages](https://mermaid.js.org/syntax/sequenceDiagram.html#messages),
  [state transitions](https://mermaid.js.org/syntax/stateDiagram.html#transitions),
  [C4 notation](https://c4model.com/diagrams/notation)
- Label what arrows mean, including branch conditions or transition triggers.
  Do not let one visual style silently switch between data flow, authority, and
  timing. Choose LR or TD to match the reader's path and available width. An
  edge connecting a node inside a subgraph to a node outside it makes the
  subgraph inherit the parent direction.
  [Flowchart subgraph direction](https://mermaid.js.org/syntax/flowchart.html#direction-in-subgraphs)
- Keep labels concise, grouping meaningful, and color restrained; split an
  overloaded diagram when it serves multiple questions. SimpleMermaid's
  examples and node-count advice are heuristics, not Mermaid limits.
  [SimpleMermaid use cases](https://www.simplemermaid.com/guides/use-cases.html),
  [best practices](https://www.simplemermaid.com/guides/best-practices.html)
- For C4-style diagrams, use explicit element types, scoped titles, concise
  descriptions, and labeled one-way relationships. Identify technologies and
  protocols where relevant; do not use color as the only carrier of meaning.
  C4 recommendations are not Mermaid syntax requirements. Mermaid C4's layout
  depends on statement order and it does not support legends; provide a text
  key when needed.
  [C4 notation](https://c4model.com/diagrams/notation),
  [Mermaid C4](https://mermaid.js.org/syntax/c4.html)
- Compare the rendered deliverable—and, when relevant, the actual host preview—
  with intended nodes, arrows, labels, and boundaries. At the intended width and
  theme, check clipping, overlap, legibility, and contrast. Check the accessible
  name and description on the delivery surface; `accTitle` and `accDescr` add
  SVG metadata but do not prove accessibility. Complex diagrams need their
  essential relationships in adjacent text. `mmdc` Markdown conversion can use
  generic alt text `diagram`.
  [Mermaid accessible title and description](https://mermaid.js.org/config/accessibility.html#accessible-title-and-description),
  [mmdc Markdown conversion](https://github.com/mermaid-js/mermaid-cli/blob/db1ceebbe529d7975474eb0d0e9c23e9dc57cd37/src/index.js#L1071-L1085),
  [W3C complex images](https://www.w3.org/WAI/tutorials/images/complex/),
  [C4 checklist](https://c4model.com/diagrams/checklist)

## Proposed compact `drawing-mermaid-diagrams` skill

Draft only; it is portable authoring guidance, separate from repository
installation and rendering policy.

```markdown
---
name: drawing-mermaid-diagrams
description: >-
  Author a Mermaid diagram when a reader needs its purpose, audience, nodes or
  states, and relationships made clear.
---

# Drawing Mermaid diagrams

Before writing source, state the diagram's purpose, audience, required nodes or
states, relationships, and constraints.
Choose a diagram type that fits those relationships: flowchart for branches or
dependencies, sequence for ordered messages, state diagram for event-driven
transitions, or scoped C4 for architecture.
Label arrow meaning, including branch conditions and transition triggers;
choose direction for the reader's path and available width.
Use concise labels, meaningful grouping, and restrained color. Split diagrams
that answer different questions.
For C4, state scope and element types, label relationships, and disclose
Mermaid C4's statement-order and legend limitations.
Add an accessible title and description when supported, but also check the
delivery surface's accessible name and description. Put essential relationships
in adjacent text for complex diagrams; never rely on color alone.
Keep diagram source with the artifact it describes.
Treat parsing, local rendering/export, visual inspection, and actual host
preview as separate evidence; report which were performed.
```

## Proposed isolated local procedure

This is a separate proposal for the current local render procedure, not an
approved policy change. It uses `mmdc` 12.0.0 and Puppeteer 25.15.0 as direct
package pins. It does not claim a fully reproducible dependency tree: the
proposal has no lockfile, and transitive dependencies are not pinned.

Prerequisites: Node.js >=22.13.0; a supported browser platform with Puppeteer's
required system libraries/dependencies; and permission to execute the browser
in the environment.
[mmdc 12.0.0 package metadata](https://registry.npmjs.org/@mermaid-js%2fmermaid-cli/12.0.0),
[Puppeteer system requirements](https://pptr.dev/guides/system-requirements)

From a shell, run this in a fresh temporary work directory. The subshell fails
fast, validates and resolves `INPUT_MD` before changing directories, and
contains its environment changes. It clears inherited browser selection,
executable, and version overrides documented by Puppeteer's configuration
source. It uses the same controlled cache and Puppeteer config for browser
installation and render; the config selects the managed shell, also the
`mmdc` 12 default.
[Puppeteer 25.15.0 configuration environment](https://github.com/puppeteer/puppeteer/blob/4a920517deccd49ad430b6ee3973cead7d002a61/packages/puppeteer/src/getConfiguration.ts)

```sh
(
  set -eu
  : "${INPUT_MD:?Set INPUT_MD to the Markdown file to convert}"
  case "$INPUT_MD" in
    /*) input="$INPUT_MD" ;;
    *) input="$PWD/$INPUT_MD" ;;
  esac
  test -r "$input"
  work="$(mktemp -d)" || exit 1
  test -d "$work"
  cd "$work"
  unset PUPPETEER_BROWSER PUPPETEER_PRODUCT PUPPETEER_EXECUTABLE_PATH \
    PUPPETEER_CHROME_VERSION PUPPETEER_CHROME_HEADLESS_SHELL_VERSION \
    PUPPETEER_FIREFOX_VERSION
  export PUPPETEER_CACHE_DIR="$work/cache"
  export PUPPETEER_SKIP_DOWNLOAD=true
  npm install --prefix "$work" --no-save --package-lock=false \
    @mermaid-js/mermaid-cli@12.0.0 puppeteer@25.15.0
  printf '%s\n' '{"headless":"shell"}' > "$work/.puppeteerrc.json"
  "$work/node_modules/.bin/puppeteer" browsers install chrome-headless-shell
  unset PUPPETEER_SKIP_DOWNLOAD
  "$work/node_modules/.bin/mmdc" \
    -p "$work/.puppeteerrc.json" \
    -i "$input" -o "$work/output.md" -a "$work/assets"
)
```

`PUPPETEER_SKIP_DOWNLOAD` prevents the package install from downloading a
browser; the explicit Puppeteer command installs the managed shell into the
configured cache. `-p` selects launch options, not a browser installation.
Review the generated Markdown and assets. For Markdown conversion,
independently enumerate every intended Mermaid fence and require exactly one
fresh, nonempty asset and one resolving link per intended fence. Zero matches,
a count mismatch, or missing/stale assets cannot pass. A rejected matched
diagram is a render failure; a missing browser or permission is an environment
failure. The CLI recognizes fences using a regex rather than a Markdown parser:
valid tilde fences can be missed and Mermaid examples nested in larger fences
can be mistaken for diagrams. When fences are ambiguous, directly extract each
specifically intended definition and render it as standalone Mermaid input
instead.
[mmdc Markdown path](https://github.com/mermaid-js/mermaid-cli/blob/db1ceebbe529d7975474eb0d0e9c23e9dc57cd37/src/index.js#L973-L1087),
[mmdc CLI entry](https://github.com/mermaid-js/mermaid-cli/blob/db1ceebbe529d7975474eb0d0e9c23e9dc57cd37/src/cli.js#L3-L8),
[GFM fenced code blocks](https://github.github.com/gfm/#fenced-code-blocks)

Report exact input, command, output, and result. A successful local export
establishes only that local toolchain's result. For GitHub, inspect the actual
GitHub Markdown preview and its `info` diagram/version separately. Do not add
`--no-sandbox`; stay within execution-environment boundaries and report
unavailable rendering as unavailable.

At the time of research, repository guidance required Microsoft Edge for the
`mmdc` smoke. For the current policy, see the
[Mermaid rendering procedure](../agents/task-guidance.md#mermaid-diagrams) and
the [drawing-mermaid-diagrams skill](../../.agents/skills/drawing-mermaid-diagrams/SKILL.md).

## Evidence limits and provenance

The smoke results and installed versions above are root-supplied observations;
raw command transcripts and pinned environment manifests were not inputs to
this authoring task. The direct package pins in the proposed recipe do not pin
transitive dependencies. The recipe is not reported as run; clean-machine
installation, browser launch, OMP backend behavior, and actual GitHub visual
or accessibility behavior remain unverified. The research input and repository
guidance were supplied as mutable working-tree/session references, so their
integrity is **unverified**. Some upstream links point to mutable branches or
live documentation. No claim is made that all diagram types, Mermaid syntax,
browser combinations, or target hosts were exercised.

## Implementation smoke for issues #29 and #30

The adopted guidance was exercised in fresh temporary install and browser-cache
directories on macOS arm64 with Node.js 26.13.0, npm 11.20.0, `mmdc` 12.0.0,
Puppeteer 25.15.0, and managed `chrome-headless-shell` 155.0.8059.84.
For each command below, `procedure.sh` was the shell block from the adopted
Mermaid guidance.

- `INPUT_FILE=accepted.md EXPECTED_SVGS=1
  PUPPETEER_EXECUTABLE_PATH=/nonexistent/alternate sh procedure.sh`:
  a backtick-fenced report review flowchart produced `output.md` and a
  nonempty `assets/output-1.svg`; the link resolved, the two labeled branches
  were legible, and the Markdown image alt text and SVG title and description
  conveyed the intended relationships.
- `INPUT_FILE=missed.md EXPECTED_SVGS=1 sh procedure.sh`:
  a tilde-fenced flowchart was missed by the CLI, which wrote `output.md`. The
  gate rejected the zero SVG count and exited 1.
- `INPUT_FILE=fallback.mmd EXPECTED_SVGS=2
  PUPPETEER_DANGEROUS_NO_SANDBOX=true
  NODE_OPTIONS=--require=/path/to/observe-launch.cjs sh procedure.sh`:
  the standalone flowchart produced a nonempty `output.svg`. The smoke-only
  Node preload observed the managed shell spawn, with neither the override
  variable nor the `--no-sandbox` argument present.

Native OMP advertised `skill:drawing-mermaid-diagrams`. No GitHub preview or
cross-platform render was checked.

## Sources

- [Mermaid usage and syntax validation](https://mermaid.js.org/config/usage.html#syntax-validation-without-rendering)
- [Mermaid accessibility](https://mermaid.js.org/config/accessibility.html)
- [Mermaid C4 syntax](https://mermaid.js.org/syntax/c4.html)
- [Mermaid CLI 12.0.0 source](https://github.com/mermaid-js/mermaid-cli/tree/db1ceebbe529d7975474eb0d0e9c23e9dc57cd37)
- [GitHub Mermaid diagrams](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-diagrams#checking-your-version-of-mermaid)
- [Puppeteer headless modes](https://pptr.dev/guides/headless-modes)
- [Puppeteer installation](https://pptr.dev/guides/installation)
- [Playwright browser management](https://playwright.dev/docs/browsers)
