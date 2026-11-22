---
status: accepted
accepted: 2026-11-22
---

# Authorize a bounded Researcher role trial

## Context

[ADR 0023](0023-freeze-ai-infrastructure-until-v1.md) freezes AI
infrastructure development outside its stated exceptions. [ADR 0028](0028-permit-bounded-omp-native-orchestration-simplification.md)
authorizes a bounded six-role simplification, not a seventh role or nested
dispatch. The pre-trial [Researcher proposal](../research/omp-strong-researcher.md)
remains a record of the earlier proposal and alternatives; this decision does not
rewrite that history.

Julio explicitly approved a bounded seventh-role trial and the sole dispatch
exception from an assigned Researcher to bundled scout workers. This decision
records that approval; it does not claim the trial has been evaluated or
permanently adopted.

## Decision

Temporarily authorize the native `researcher` role and allow an assigned
Researcher to dispatch only bundled `scout` workers for bounded, read-only
primary-source collection. Researchers own one topic's evidence plan, source
evaluation, conflict analysis, and synthesis. Root may assign parallel
Researchers only to genuinely independent topics. Scouts collect and return
citations and observations; they do not synthesize or spawn.

The native Researcher default is `openai-codex/gpt-6.2-sol` at `xhigh`.
For extremely complex topics only, root may select the sole trial escalation,
`openai-codex/gpt-6.2-astra:high`, for the Researcher. It requires approval by
the available native tool and operator before dispatch; never apply it to a
scout. After launch, verify the task's actual resolved model and effort against
the approved selection. If selector availability or approval is absent, or the
launched resolution mismatches, block that assignment without substitution.

Researchers have no write authority and may not dispatch writers or any other
role. The Researcher returns cited findings and gaps to root; root alone assigns
the `technical-writer` and retains routing, sequencing, and acceptance. The
writer uses supplied findings and does not research. Independent validation
remains separate and required where the policy calls for it. Julio retains
consequential architecture authority.

Before each root dispatch, inspect `/agents` for all seven project roles,
confirming selected models, thinking levels, tools, and spawn declarations.
Before a Researcher dispatches a scout, use the native task route and verify the
bundled scout identity and absence of a task/identity collision using observable
native inventory and task information. If that route or evidence is unavailable,
return `blocked`; do not use another harness. A native child-name allowlist
limits permitted names, not identity provenance. Neither frontmatter nor these
instructions enforce identity, run count, cost, or filesystem access.

This configuration does not reproduce an operating-system sandbox. MCP,
extension, and custom tools may add capabilities. Scout assignments are
read-only by task policy, not by guaranteed platform enforcement; use applicable
platform controls where isolation is required.

## Trial closeout and rollback gate

After the initial smoke evidence and required checks are presented to Julio,
pause new trial research pending his human review. This is a review gate, not a
calendar expiry or permanent adoption. If Julio declines continuation, restore
the pre-trial role and dispatch baseline. If the required Researcher default or
dispatch boundaries fail, defer or remove the trial configuration and restore
that baseline. An unavailable or mismatched optional escalation blocks only
that assignment; it does not alone trigger trial rollback. Only Julio's explicit
continuation or adoption resumes the trial or makes it permanent.

The review should assess source provenance, conflicting evidence, inference,
uncertainty, and whether role boundaries were respected. No other
AI-infrastructure work is authorized by this decision, and ADR 0023 remains the
freeze baseline outside this precise scope.
