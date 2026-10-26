---
status: accepted
accepted: 2026-10-17
---

# Require plain-text MATLAB Live Script walkthroughs

## Context

Project walkthroughs teach and demonstrate MATLAB engineering behavior.
A plain-text Live Script keeps executable code and explanatory narrative together in a reviewable, version-controlled `.m` file.

## Decision

Every project walkthrough must be an executable plain-text MATLAB Live Script in a `.m` file, compatible with MATLAB R2025a or newer.
Do not use binary `.mlx` files or ordinary MATLAB scripts as walkthroughs.

Companion Markdown may explain and link to a walkthrough, but does not replace the executable Live Script.
Walkthroughs retain their runnable entrypoint and teach through the public API, explaining engineering purpose, units, shapes, state, observations, and evidence limits where relevant.

Existing walkthroughs that do not meet this decision require conversion.
This ADR records no repository-wide audit or migration completion, and sets no migration schedule.

## Rationale

Plain-text Live Scripts keep narrative, code, and displayed results together while remaining reviewable in Git.
A consistent format gives each walkthrough one clear execution and teaching surface.

## Consequences

New and revised walkthroughs use Live Script markup and the `.m` format.
Authors and reviewers follow the versioned [Live Script generation standard](../standards/matlab/live-script-generation.md), including its MATLAB R2025a minimum.
Companion documentation remains useful for context and navigation, while the Live Script owns the executable lesson.
