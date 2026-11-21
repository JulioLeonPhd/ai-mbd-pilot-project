# Task-specific agent guidance

## Documentation style

Do not enforce a fixed source width for prose. Prefer one sentence per source line and blank lines between paragraphs. Preserve code blocks, tables, and intentional line breaks; do not bulk-reflow existing text. Prefer tables for meaningful comparisons, mappings, or attributes; use bullets for parallel points, numbered lists for ordered steps, and prose for connected reasoning.

## Mathematical documentation

Write mathematical relationships as rendered TeX, preserving approved semantics. Use inline `$...$` for short symbols and separate-line `$$` delimiters for display equations. Define symbols, indices, ranges, units, and assumptions nearby; use tables for meaningful parameter/value/unit mappings. See [ADR 0025](../adr/0025-adopt-range-compression-numerical-and-validity-contract.md) for a style example.

Inside math, use TeX comparisons such as `\lt`, `\gt`, `\le`, and `\ge`; avoid raw angle brackets and HTML entities. HTML escaping before KaTeX parsing can turn angle brackets into literal entities and cause parse errors.

For every changed math document, render every inline and display expression using the available KaTeX renderer with `renderToString`, `throwOnError: true`, and the matching `displayMode`. Exclude code spans and fenced code during extraction. Repeat after HTML-escaping ampersands and angle brackets in each extracted expression to catch escaping-pipeline failures. Markdown lint does not verify rendering.

Run this command from the repository root to smoke-check renderer availability; it does not replace rendering every expression in the document:

```sh
node -e 'const katex = require("katex"); katex.renderToString(String.raw`x \lt y`, {throwOnError: true}); console.log("KaTeX smoke check passed");'
```

If KaTeX is unavailable, report rendering as unavailable. Do not install a dependency just for this check or claim visual-preview equivalence without an actual preview.

## Mermaid diagrams

Any agent, including root, may use the repository
[drawing-mermaid-diagrams skill](../../.agents/skills/drawing-mermaid-diagrams/SKILL.md)
when authoring a Mermaid diagram within its assigned artifact scope.
Documentation specialist routing does not restrict skill access; Mermaid needs
no specialist handoff. The artifact owner's task and allowed mutations still
govern the work. The local render gate remains required; Microsoft Edge and
full desktop Chrome are not prerequisites. Use `mmdc` 12.0.0 with Puppeteer
25.15.0 and Node.js >=22.13.0, using Puppeteer's managed headless shell with
the browser sandbox enabled. Prerequisites include a supported platform,
Puppeteer's required system libraries, and permission to execute the browser;
see [Puppeteer system requirements](https://pptr.dev/guides/system-requirements).

From the repository root, set `INPUT_FILE` to an existing Markdown document or
standalone `.mmd` file. For Markdown, independently enumerate all intended
Mermaid fences and set `EXPECTED_SVGS` to that positive count before running
this snippet. For an ambiguous Markdown document, extract each intended
definition to a standalone `.mmd` file and render those separately; do not rely
on the CLI's fence matching alone.

```sh
(
  set -eu
  : "${INPUT_FILE:?Set INPUT_FILE to a Markdown document or standalone .mmd \
file}"
  case "$INPUT_FILE" in
    /*) input="$INPUT_FILE" ;;
    *) input="$PWD/$INPUT_FILE" ;;
  esac
  test -r "$input"
  case "$input" in
    *.md|*.markdown)
      : "${EXPECTED_SVGS:?Set EXPECTED_SVGS to the independently enumerated \
positive Mermaid-fence count}"
      output_mode=markdown
      ;;
    *.mmd)
      EXPECTED_SVGS=1
      output_mode=svg
      ;;
    *)
      printf '%s\n' 'INPUT_FILE must end in .md, .markdown, or .mmd' >&2
      exit 2
      ;;
  esac
  case "$EXPECTED_SVGS" in
    ''|*[!0-9]*) printf '%s\n' \
      'EXPECTED_SVGS must be a positive integer' >&2; exit 2 ;;
  esac
  test "$EXPECTED_SVGS" -gt 0
  work="$(mktemp -d)"
  test -d "$work"
  cd "$work"
  unset PUPPETEER_BROWSER PUPPETEER_PRODUCT PUPPETEER_EXECUTABLE_PATH \
    PUPPETEER_CHROME_VERSION PUPPETEER_CHROME_HEADLESS_SHELL_VERSION \
    PUPPETEER_FIREFOX_VERSION PUPPETEER_SKIP_CHROME_DOWNLOAD \
    PUPPETEER_SKIP_CHROME_HEADLESS_SHELL_DOWNLOAD \
    PUPPETEER_DANGEROUS_NO_SANDBOX
  export PUPPETEER_CACHE_DIR="$work/cache"
  export PUPPETEER_SKIP_DOWNLOAD=true
  npm install --prefix "$work" --no-save --package-lock=false \
    @mermaid-js/mermaid-cli@12.0.0 puppeteer@25.15.0
  printf '%s\n' '{"headless":"shell"}' > "$work/.puppeteerrc.json"
  "$work/node_modules/.bin/puppeteer" browsers install chrome-headless-shell
  unset PUPPETEER_SKIP_DOWNLOAD
  "$work/node_modules/.bin/mmdc" --version
  if test "$output_mode" = markdown; then
    mkdir "$work/assets"
    "$work/node_modules/.bin/mmdc" -p "$work/.puppeteerrc.json" \
      -i "$input" -o "$work/output.md" -a "$work/assets"
    svg_count="$(find "$work/assets" -type f -name '*.svg' -size +0c \
      -print | wc -l | tr -d '[:space:]')"
  else
    "$work/node_modules/.bin/mmdc" -p "$work/.puppeteerrc.json" \
      -i "$input" -o "$work/output.svg"
    test -s "$work/output.svg"
    svg_count=1
  fi
  if test "$svg_count" -le 0 || test "$svg_count" -ne "$EXPECTED_SVGS"; then
    printf 'Expected %s nonempty SVG(s); found %s\n' \
      "$EXPECTED_SVGS" "$svg_count" >&2
    exit 1
  fi
  printf 'Rendered %s SVG(s); output directory: %s\n' "$svg_count" "$work"
)
```

The fresh temporary directory contains the install, Puppeteer cache, and
outputs; the source is only read. `PUPPETEER_SKIP_DOWNLOAD` prevents npm from
downloading a browser, then the explicit Puppeteer command installs the managed
shell into that same cache. The configured `headless: "shell"` selects the
managed shell. Do not set an executable override or add `--no-sandbox`; this
procedure does not grant permission to run outside the command sandbox or
bypass its restrictions.

For Markdown, inspect the generated Markdown and assets and manually map every
independently enumerated intended fence to exactly one resolving link and one
nonempty fresh SVG. This mapping is required even when the executable count
agrees; missing, extra, stale, or mismatched outputs fail the gate. The count
check is a regression against zero or count mismatch, not proof of
correspondence. The CLI recognizes fences with a regex rather than a Markdown
parser, so ambiguity or fence forms it may miss require standalone extraction
and per-diagram rendering.

Record the exact input, command, `mmdc` version, managed headless-shell version
shown by the fresh Puppeteer browser-install output, output location, and
result. A rejected matched diagram is a source/render failure; a missing
browser, system dependency, or execution permission is an environment failure
and must be reported as unavailable rather than accepted. Local export
establishes only the result from that local toolchain. For GitHub, inspect the
actual GitHub Markdown preview and its `info` diagram/version separately.

## Engineering walkthroughs

Treat executable walkthroughs as primary human-review surfaces for non-trivial engineering components, not minimal API examples. Be deliberately verbose when that improves engineering transparency: explain purpose, processing chain, important design choices, units, signal shapes, rates, state or reset behavior, expected transformations, limitations, and evidence boundaries without requiring readers to reverse-engineer namespaced implementation code.

Keep the component's public API as the execution boundary. Do not duplicate private production algorithms merely to expose internals; parallel implementations can drift. Explain the engineering meaning around each public call: show relevant configuration, derive or print important rates and dimensions, identify represented processing stages, calculate transparent expectations independently where useful, expose meaningful observations or plots, and explain what readers should see and why. If a public API is too opaque to explain honestly, improve the explanatory material or reconsider the API boundary rather than reaching into private implementation by default.

Walkthroughs complement rather than replace tests. They teach and support human architectural review; tests and independent evidence establish behavioral claims.

## Active status and history

Treat root `CURRENT.md` and `HISTORY.md` as optional, untracked, worktree-local logs. In a fresh checkout or worktree they may be absent; consult them when present, otherwise derive context from tracked plans, decisions, evidence, and the user request. Create them only when needed, without inventing chronology. Their contents are not Git-backed-up or synchronized; durable decisions and evidence belong in tracked documents, not solely in these logs. Before applying untracking in an existing checkout or worktree that still tracks these files, preserve local copies: checkout or merge may remove them, and no automatic migration or preservation is implied.

Keep `CURRENT.md` as a concise, newest-first checkpoint log for only the active milestone. Head each entry `### YYYY-MM-DD HH:mm — Short title`, using UTC consistently (omit seconds). Record meaningful checkpoints, not tool narration; use short prose and itemised lists without mandatory per-entry fields. The latest entry states the current position and next authorized step and owner, including relevant blockers or pending decisions, so work can continue without a separate handoff. Link detailed evidence. Distinguish approved, proposed, and verified status and state its scope; do not imply approval or gate movement, and explicitly supersede outdated information, including status, next step or owner, evidence, reviews, decisions, and blockers as applicable. Use Mermaid only when it expresses necessary relationships more compactly than prose or lists, following the Mermaid guidance above. Use `/skill:sitrep` in OMP when fuller synthesis is needed.
State explicitly when no formal work-package or gate assignment is recorded.

When a new work package or milestone starts, append the complete outgoing `CURRENT.md` to root `HISTORY.md` before replacing it. Give each full snapshot a date and the outgoing work package, gate, and milestone as recorded. Preserve outgoing content and relative links verbatim; never overwrite earlier history. Routine updates within the same work package or milestone do not add a full snapshot. Move historical material removed from `CURRENT.md` into an append-only history entry. The initial migration snapshot is dated, preserves the original file verbatim, and is identified as a migration rather than a new milestone.

## MATLAB MCP session ownership

| Endpoint | Preferred use | Ownership requirement |
| --- | --- | --- |
| `matlab-existing` | Human-guided model development, visual walkthroughs, and interactive debugging in a prepared session | Confirm the intended shared session and coordinate one owner; protect the human's workspace, paths, open models, and unsaved changes. |
| `matlab-disposable` | Automated checks, test execution, scratch experiments, and independent validation with explicit initialization | Record MATLAB version/root and working folder, initialize required project state, and preserve outputs before cleanup. |

`matlab-disposable` is an endpoint name, not a per-call reset, sandbox, or cleanup guarantee. A new MATLAB process may run startup scripts and retains state across calls while alive; it can still modify files shared with an interactive session. `nodesktop` does not guarantee UI commands open no windows. Do not rely on disconnect or crash cleanup without verifying the installed runtime's behavior. In `existing` mode, select/share the intended session explicitly; otherwise the most recently shared session is selected. Do not combine `existing` mode with MATLAB-root, initial-working-folder, or display-mode launch overrides.

Before concurrent MATLAB/Simulink execution, establish separate session ownership and deterministic task-to-endpoint routing. Worktrees, endpoint names, `new` mode, and executable copies alone do not establish isolation. If isolation is unverified, serialize calls to the shared endpoint; do not run implementation and independent validation concurrently in one mutable MATLAB session. Before claiming isolation, verify distinct MATLAB PIDs, correct request/response identity, and independent scratch state under overlapping calls. Any proposed multi-session switch must preserve required Simulink extension tools. Neither endpoint removes tool-call review, filesystem-risk controls, or applicable MathWorks license requirements.
Historical [pilot isolation research](../research/omp-matlab-mcp-session-isolation-2026-10-25.md) records observed collisions and one successful copied-executable trial; it is not an approved or production-validated isolation architecture.

## MATLAB standards and analysis

For MATLAB/Simulink-associated MATLAB code, read the versioned [MATLAB standards bundle](../standards/matlab/README.md), then apply relevant rules:

- Read [matlab-coding-standards.md](../standards/matlab/matlab-coding-standards.md) for MATLAB code and general coding decisions.
- Read [live-script-generation.md](../standards/matlab/live-script-generation.md) when creating or editing a plain-text Live Script.
- Read [matlab-performance-optimization.md](../standards/matlab/matlab-performance-optimization.md) when optimizing or investigating a performance bottleneck; profile first.

The bundle records which rules are also available from MATLAB MCP. Follow project requirements, accepted ADRs, and task-specific interfaces when they constrain general recommendations; preserve project-specific numerical and code-generation decisions. The MCP Code Analyzer is required when available but does not establish complete standards compliance. The bundle in `docs/standards/matlab` is the canonical tool-neutral rule corpus.

For every generated or edited MATLAB source file (`.m`, `.mlx`, or MATLAB code embedded in another artifact), invoke MATLAB Code Analyzer through MCP when available. Resolve all reported errors and warnings, then rerun after fixes. Record the analyzer operation and result as evidence. If MATLAB MCP or Code Analyzer is unavailable, report the check as unavailable and disclose the limitation; unavailable is not a pass.

The `gramm` plotting library is available as a `ggplot2`-style library; prefer it over MATLAB defaults when appropriate.

## Python environment and checks

From the repository root, activate `.venv` before running Python commands or installing packages. Use `uv`; do not invoke `pip` or `conda` alone:

```bash
source .venv/bin/activate # for Linux/macOS
```

Ruff is the canonical Python linter and formatter. From the repository root with `.venv` active, for every created or edited `.py` file run `uv run --frozen ruff check <path>` and `uv run --frozen ruff format --check <path>`. Apply appropriate fixes with `uv run --frozen ruff check --fix <path>` and `uv run --frozen ruff format <path>`, then review the diff.

Pyright is supplementary for Python in `contracts` and `scripts`. Preserve repository `pyrightconfig.json` basic mode unless the project explicitly adopts stricter typing. From the repository root with `.venv` active, when the dependency environment is available, run `uv run --frozen pyright contracts scripts`; report remaining diagnostics rather than treating the check as passed.

## Releases

For a requested release, from the repository root of a clean worktree run `uv run python scripts/release.py` using the [release script](../../scripts/release.py). Review the resulting changelog, release commit, and annotated SemVer tag. The script creates a local release only; push the commit and tag only when publication is requested.
