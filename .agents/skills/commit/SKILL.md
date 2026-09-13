---
name: commit
description: "Create one scoped Git commit by delegating staging and commit execution to a gpt-5.6-luna subagent after the root agent has analyzed the change and supplied commit context."
---

# Delegated commit finalization

Use this skill only as the root agent's finalization step. The root agent owns
the interpretation, scope, and authorization of the commit. The spawned worker
owns the Git operations and must not broaden the change.

Do not use this skill to push, tag, merge, rebase, amend, reset, clean, or
otherwise rewrite history. Do not modify version files unless the root agent
explicitly includes them in the allowed scope.

## Prepare the bounded handoff

Before spawning the worker, inspect the repository and determine what belongs in
this commit. At minimum, inspect:

- `git status --short`
- `git diff --stat` and `git diff`
- `git diff --cached --stat` and `git diff --cached`
- the current branch and recent commit-message convention

Distinguish the requested changes from unrelated or pre-staged user changes.
Pass a bounded packet containing:

- the objective and human-facing context for this commit;
- the exact allowed paths, plus explicit exclusions;
- whether already-staged changes are in scope;
- the current branch and any issue or work-item reference;
- the notable behavior/API changes and their compatibility impact;
- the root agent's resolved `SemVer impact`: `major`, `minor`, `patch`, or
  `none`;
- requested checks and the expected result report.

Use a compact task packet such as:

```yaml
task:
  objective: "Create one commit for the approved change"
  context: "Why this change matters and what the commit should communicate"
  allowed_paths: ["path/to/in-scope-file"]
  excluded_paths: ["path/to/unrelated-file"]
  include_staged_changes: false
  branch: "expected-branch"
  semver_impact: "minor"
  references: ["issue or work-item reference"]
  requested_checks: ["git diff --cached --check"]
```

If the scope or compatibility impact is unresolved, resolve it before spawning;
do not ask the worker to infer product intent from an ambiguous diff.

## Spawn the commit worker

Call `multi_agent_v1__spawn_agent` with:

```yaml
agent_type: worker
model: gpt-5.6-luna
reasoning_effort: low
fork_context: false
```

Put the bounded packet in the initial message. The worker starts without the
root conversation, so include every fact it needs. Tell it to operate on the
current branch and working tree, preserve other agents' edits, and return the
commit SHA plus a compact structured result. Wait for that worker's result and
close it with `multi_agent_v1__close_agent` when finished.

If the spawn or worker-management tools are unavailable, return `blocked`; do
not silently perform the commit in the root agent.

The worker must:

1. Re-check the working tree against the packet before staging anything.
2. Stop with `needs-input` or `blocked` if an unexpected staged change,
   out-of-scope path, empty diff, branch mismatch, or other ambiguity makes a
   safe commit impossible. It must not use `git add -A`, `git add .`,
   `git commit -a`, `--no-verify`, or history-rewriting commands to work around
   the problem.
3. Stage only the explicitly allowed paths, while preserving in-scope staged
   content as directed by the packet.
4. Run the requested checks, including `git diff --cached --check` when
   requested, then create exactly one new commit without amending another
   commit or pushing anywhere.
5. Report the commit SHA, message, paths included, checks, and any post-commit
   working-tree changes.

## Commit-message rules

Use the categories from [Keep a Changelog 1.0.0](https://keepachangelog.com/en/1.0.0/):
`Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security`. Prefer the
repository's established prefix style; when no convention exists, use one
category followed by a colon and a concise human-facing summary:

```text
Added: support delegated commit finalization

- Describe the notable user or maintainer-facing change.
- Mention a breaking, deprecated, removed, or security-sensitive effect when relevant.

SemVer impact: minor
```

Keep a Changelog defines human-facing changelog categories, not a required Git
subject syntax. The category prefix and curated body are the commit-message
mapping used here; do not present a raw Git log or fabricate a release heading.

The message should curate the meaningful change, not dump file names or a raw
Git log. Group body bullets by the applicable changelog categories when more
than one category is genuinely needed. Use the root agent's compatibility
decision and [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html):

- `major`: incompatible public API or other explicitly breaking release impact;
- `minor`: new backward-compatible public functionality or a public deprecation;
- `patch`: backward-compatible bug fix;
- `none`: no release-impacting product change, such as purely internal or
  repository-maintenance work.

For a `0.y.z` project, follow its documented release policy; do not silently
invent a version bump. The `SemVer impact` line communicates the classification
and does not authorize changing a version file or creating a tag.

## Root-agent verification

After the worker reports success, independently verify the result rather than
treating the spawn or commit command as proof:

- resolve the reported SHA with `git rev-parse`;
- inspect the committed message and paths with `git show --stat` and
  `git diff-tree --name-status`;
- confirm only allowed paths and intended content were committed;
- confirm the commit is on the expected branch and inspect `git status --short`
  for remaining changes;
- check that the message contains the applicable changelog category and the
  root-approved SemVer impact.

Report the SHA, message, included paths, remaining working-tree state, and any
warning or skipped check. If verification fails, do not create a compensating
commit automatically; return the discrepancy to the root agent for a new,
bounded decision.
