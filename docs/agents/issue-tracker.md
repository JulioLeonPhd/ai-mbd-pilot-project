# Issue tracker: GitHub

Issues and specs for this repo live as GitHub issues. Use the `gh` CLI for all operations.

## Authorization and execution

Run all `gh` issue-tracker commands outside the command sandbox through execution-environment escalation.
This outside-sandbox execution is authorized for all GitHub issue-tracker operations in this repository.
Repository authorization does not replace applicable platform permission; if escalation is unavailable or denied, report `blocked` rather than bypass it.

## Conventions

- **Create an issue**: `gh issue create --title "..." --body "..."`
- **Read an issue**: `gh issue view <number> --comments`
- **List issues**: `gh issue list --state open`
- **Comment on an issue**: `gh issue comment <number> --body "..."`
- **Apply / remove labels**: `gh issue edit <number> --add-label "..."` /
  `--remove-label "..."`
- **Close**: `gh issue close <number> --comment "..."`

Infer the repo from `git remote -v`; `gh` does this automatically when run
inside a clone.

## Pull requests as a triage surface

**PRs as a request surface: no.**

When a skill says to publish to the issue tracker, create a GitHub issue.

When a skill says to fetch the relevant ticket, run `gh issue view <number> --comments`.
