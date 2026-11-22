---
status: accepted
accepted: 2026-11-22
---

# Adopt genre-specific report guidance

## Context

[ADR 0031](0031-authorize-bounded-technical-writing-trial.md) authorized a
bounded evaluation of research and technical report guidance, not adoption or
deployment. The integrated [research-report trial](../research/writer-research-report-trial.md)
scored the candidate 4/4 and baseline 3/4; it recommended the candidate to Julio
but recorded no approval. The [technical-report trial](../research/writer-technical-report-trial.md)
scored the baseline higher for the Mermaid case (3/4 to 2/4) and tied it for the
architecture case (3/3 each). It recommended retaining baseline technical
report guidance on those frozen reader answers.

Julio reviewed and accepted both candidates with the refinements below. His
technical-report preference is a human decision despite those frozen scores;
it does not revise, replace, or reinterpret either trial record. The integrated
records are preserved at commit `c564a52abe`.

## Decision

Adopt the research-report and technical-report guidance in the shared
[Writing genres](../agents/task-guidance.md#writing-genres) guidance, with these
refinements:

- **Research reports:** Use the accepted candidate structure. Assign numbered
  references in order of first citation and reuse each number on later mentions.
  Link each visible bracketed citation directly to the source URL in its
  matching numbered bibliography entry, preserving the printed numeric label.
  Preserve the distinction between evidence and the assigning Researcher's
  recommendation.
- **Technical reports:** Use the accepted candidate structure and support
  material claims with source references. Prefer tables when they clarify
  architecture-style parallel exposition. This table preference records
  Julio's judgment, not a trial result or a universal requirement.

This decision supersedes ADR 0031's evaluation-only status and the technical
trial's recommendation to retain baseline guidance solely for these two report
genres in the shared project guidance. It does not change the trials' frozen
scores, observations, limitations, or historical candidate text.

The exception to the AI-infrastructure freeze in [ADR 0023](0023-freeze-ai-infrastructure-until-v1.md)
remains limited to putting these accepted, refined report branches into the
shared guidance. It does not authorize external deployment or other
infrastructure work. All other ADR 0031 boundaries remain: preserve the task
schema, writer role and model settings, audience and evidence ownership, write
target authorization, and independent-review routing. Julio retains authority
for further changes.

## Consequences

The shared writer guidance may use the accepted research and technical report
branches with the refinements above. The trial records remain historical
records of what their frozen fixtures and readers showed; they are not updated
to imply that the technical candidate won its comparison or that either
candidate demonstrated a general quality gain.
