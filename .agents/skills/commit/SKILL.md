---
name: commit
description: Create one scoped Git commit by delegating staging and commit execution through the active session's native task tool after the root agent has resolved commit context.
---

# Delegated commit finalization

Use this skill only as the root agent's finalization step. The root agent owns
the interpretation, scope, and authorization of the commit. A worker delegated
through the active session's native `task` tool owns the Git operations and
must not broaden the change.

Do not use this skill to push, tag, merge, rebase, reset, clean, or otherwise
rewrite history. Amending is prohibited unless the user explicitly authorizes
amending a named commit. Do not modify version files unless the root agent
explicitly includes them in the allowed scope.

## Prepare a bounded handoff

Complete these steps before delegating the worker:

1. Inspect the repository and determine what belongs in this commit. At
   minimum, inspect:
   - `git status --short`
   - `git diff --stat` and `git diff`
   - `git diff --cached --stat` and `git diff --cached`
   - the current branch and recent commit-message convention
2. Distinguish the requested changes from unrelated or pre-staged user changes.
3. Build a bounded packet containing:
   - the objective and human-facing context for this commit;
   - the exact allowed paths, plus explicit exclusions;
   - whether already-staged changes are in scope;
   - the current branch and any issue or work-item reference;
   - the notable behavior/API changes and their compatibility impact;
   - the root agent's resolved `SemVer impact`: `major`, `minor`, `patch`, or
     `none`;
   - requested checks and the expected result report.
4. Select and verify the configured Luna-capable `technical-writer` role for
   the worker. Its model is configured by the native role definition; do not
   supply a model or reasoning-effort override. If this requested routing is
   unavailable, return `blocked` rather than silently using a higher-default
   role.
5. Dispatch the worker with the active session's native `task` tool and a
   bounded packet in its `tasks` array, as shown below.

For example:

```yaml
i: "Delegate approved commit finalization"
context: "The root agent resolved scope and commit intent; preserve the low-cost Luna route by selecting the configured technical-writer role. The worker owns only the specified Git operations."
tasks:
  - name: CommitWorker
    agent: technical-writer
    task: |
      task:
        id: "commit-finalization"
        objective: "Create one commit for the approved change"
        context: "Why this change matters and what the commit should communicate"
        inputs:
          - "Current repository working tree on expected-branch"
        constraints:
          - "Allowed paths: [path/to/in-scope-file]; excluded paths: [path/to/unrelated-file]"
          - "Include staged changes: false; operation: new; target_commit: null"
          - "SemVer impact: minor; references: [issue or work-item reference]"
          - "Do not push, tag, change version files, use git add -A/. or git commit -a, bypass hooks, or rewrite history"
        acceptance_criteria:
          - "One commit on expected-branch contains only the authorized paths and intended content"
          - "Return the SHA, message, included paths, checks, and post-commit working-tree state"
          - "Validate the raw stored message has actual newlines and no unintended 0x5C 0x6E byte sequence"
        allowed_mutations:
          - "Git index and commit history, limited to the authorized commit"
          - "Creation and cleanup of the worker's temporary commit-message file only at the exact location or directory approved by the root agent in this packet (preferably outside the repository); no arbitrary temporary filesystem access"
        requested_checks:
          - "git diff --cached --check"
```

After preparing the packet:

1. Use only the native task API: it accepts `i`, `context`, and `tasks`; each
   task item accepts `task`, `name`, and optional `agent`. Do not pass
   `collaboration.*` calls or invent parameters such as `model`,
   `reasoning_effort`, or `fork_turns`.
2. Preserve the configured role routing. Ordinary tasks do not support model
   overrides; the `technical-writer` role's configured Luna model is selected
   by its `agent` name. Do not silently substitute a different model or role.
   If the native `task` tool or requested role routing is unavailable, return
   `blocked`; do not silently perform the commit in the root agent.
3. Include every fact the worker needs because it starts without the root
   conversation. Tell it to operate on the current branch and working tree,
   preserve other agents' edits, and return a structured result.
4. Resolve scope and compatibility impact before dispatch. Do not ask the
   worker to infer product intent from an ambiguous diff.
5. Set `operation: "new"` and `target_commit: null` for the normal workflow.
   Use `operation: "amend"` only when the user explicitly authorizes amending
   the named commit in `target_commit`.
6. Task results are delivered automatically. Wait only when blocked pending a
   result, and use a bounded follow-up task only when additional work is
   required. There is no separate close-agent step.

## Native task dispatch

The root agent remains the orchestrator. A delegated worker is the commit
executor; the root agent must not perform the commit itself. Dispatch it with
the active session's native `task` tool using the bounded packet above.

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
   requested. For `operation: "new"`, create exactly one new commit. For
   `operation: "amend"`, amend only the named `target_commit`; do not create a
   different commit. In either case, write the exact intended multiline
   message to a temporary file and invoke `git commit --file
   <temporary-file>` (with the appropriate amend option only for the named
   target). Do not construct a multiline message with `JSON.stringify`, shell
   escapes, or an inline representation that can preserve a literal backslash
   followed by `n` (the byte sequence `0x5C 0x6E`).
5. Report the commit SHA, message, paths included, checks, and any post-commit
   working-tree changes.

After committing, validate the raw stored message before reporting success,
for example with `git cat-file commit <sha>` or `git show --format=raw
--no-patch <sha>`. Confirm that intended line breaks are actual newlines and
that the message contains no unintended `0x5C 0x6E` byte sequence.

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
treating task dispatch or the commit command as proof:

1. Resolve the reported SHA with `git rev-parse`.
2. Inspect the committed message and paths with `git show --stat` and
   `git diff-tree --name-status`.
3. Confirm only allowed paths and intended content were committed.
4. Confirm the commit is on the expected branch and inspect `git status --short`
   for remaining changes.
5. Check that the message contains the applicable changelog category and the
   root-approved SemVer impact.

Report the SHA, message, included paths, remaining working-tree state, and any
warning or skipped check. If verification fails, do not create a compensating
commit automatically; return the discrepancy to the root agent for a new,
bounded decision.
