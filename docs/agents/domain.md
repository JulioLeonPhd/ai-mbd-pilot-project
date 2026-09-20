# Domain docs

How the engineering skills should consume this repo's domain documentation.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in.

If any of these files don't exist, proceed silently. The domain-modeling skill
creates them lazily when terms or decisions actually get resolved.

## File structure

This is a single-context repo:

- `CONTEXT.md` contains the project glossary.
- `docs/adr/` contains system-wide decisions.

## Use the glossary's vocabulary

When your output names a domain concept, use the term as defined in
`CONTEXT.md`. If the needed concept is missing, note the gap for domain modeling.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding it.
