---
status: accepted
accepted: 2026-11-22
---

# Authorize a bounded technical writing trial

## Context

[ADR 0023](0023-freeze-ai-infrastructure-until-v1.md) freezes AI infrastructure
work until Radar V1. The previous generic writer trial did not show an opening
improvement on its single technical-report case and did not test research
reports. Julio authorized a bounded exception to test genre-specific guidance
rather than defer the work or adopt an unverified generic prompt change.

## Decision

Permit only the routing change and verification work in [spec #32][spec] and
its [routing][routing], [research-report][research], and
[technical-report][technical] tickets. The assigner names the artifact and
primary audience in the existing task context; the writer uses the matching
guidance or asks for the distinction needed to proceed. Keep the packet schema,
role inventory, model and effort, authorized write targets, evidence ownership,
and independent review unchanged. Preserve the delegation and research limits
in [ADR 0030](0030-adopt-bounded-researcher-writer-handoff.md).

This exception authorizes implementation for evaluation, not deployment.
Evaluate the two report genres independently against the baseline using frozen
reader questions and blinded review. Check numbered sections separately from
reader usefulness. Recommend candidate wording only where reader answers
improve without new material evidence errors or lost consequential caveats.
Otherwise retain the baseline for that genre. Julio decides any adoption.

ADR 0023 remains in force outside these tickets. This exception does not
change Radar V1 scope or authorize further infrastructure work.

[spec]: https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/32
[routing]: https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/33
[research]: https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/34
[technical]: https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/35
