# Issue tracker: GitHub

Issues and specs live in GitHub Issues for
`JulioLeonPhd/ai-mbd-pilot-project`. Use the `gh` CLI from this clone.

## Operations

- Create: `gh issue create --title "..." --body-file <file>`
- Read: `gh issue view <number> --comments`
- List: `gh issue list --state open`
- Comment: `gh issue comment <number> --body-file <file>`
- Label: `gh issue edit <number> --add-label "..."`
- Close: `gh issue close <number>`

When a skill says to publish to the issue tracker, create a GitHub issue.
When it says to fetch a ticket, read the corresponding GitHub issue.

## Pull requests as a triage surface

**PRs as a request surface: no.**
