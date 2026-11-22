---
status: accepted
accepted: 2026-11-22
---

# Adopt bounded Researcher-to-writer handoff

## Context

[ADR 0018](0018-flatten-specialist-orchestration.md) established root-only
specialist orchestration. Its root-only delegation rule conflicts with the
bounded Researcher-to-scout exception recorded in
[ADR 0029](0029-authorize-bounded-researcher-trial.md). ADR 0029 authorized a
Researcher trial, paused new trial research pending Julio's review, and reserved
the writer route to root.

Julio approved continuing the Researcher role and adopting the ongoing
Researcher-to-scout and Researcher-to-technical-writer policy defined here.
This decision makes no additional runtime or validation claims.

## Decision

Supersede ADR 0018 only as to root-only specialist delegation. Supersede ADR
0029 only as to the trial-only pause and root-only writer route. This is an
ongoing authorization for the Researcher role and only its two child edges in
this ADR, not a blanket authorization for delegation by other roles.

An assigned Researcher may dispatch the project `technical-writer` only when a
Markdown report is requested. Root records the exact report target in the
Researcher task's `constraints` and leaves its `allowed_mutations` empty. The
Researcher passes only that target in the writer task's `allowed_mutations`.
The Researcher supplies cited findings and synthesis from its assigned topic;
the writer drafts from that handoff and does not research. Root may continue to
assign authoring-only work directly to the writer. If evidence needed for a
report is missing, a Researcher-assigned writer returns the gap to the assigning
Researcher; a writer assigned by root returns it to root.

The Researcher remains inspection-only: it cannot write the report itself,
change the authorized artifact scope, dispatch validators, or dispatch any role
other than bundled `scout` and project `technical-writer`. The writer has no
children. Root retains task decomposition, artifact authorization, dispatch
sequencing, independent-review commissioning, conflict resolution, acceptance,
and final reporting. The Researcher may not delegate review to a validator.

Both Researcher child routes use the active native task route. Before dispatch,
verify observable native inventory and task information for the expected bundled
scout or project writer identity, active route, and absence of identity/task
collision. If these cannot be established, return `blocked`; do not use another
harness. The native child-name allowlist is not proof of identity provenance.
These controls and role declarations do not provide operating-system or
filesystem isolation.

Preserve the Researcher's native `openai-codex/gpt-6.2-sol` / `xhigh` default
and ADR 0029's approved optional escalation tier, root-controlled selector
approval, and post-launch resolution check. Restore ADR 0029's named pre-trial
role and dispatch baseline only if native evidence confirms a wrong required
Researcher default or a delegation-boundary violation. An unverified preflight
or route prerequisite, or unavailable or mismatched optional Astra escalation,
blocks only that assignment and does not trigger restoration.
Do not change other role defaults, providers, specialist identities, or spawn
declarations. This bounded handoff does not broaden the AI-infrastructure freeze
in [ADR 0023](0023-freeze-ai-infrastructure-until-v1.md) or alter the six-role
simplification scope in
[ADR 0028](0028-permit-bounded-omp-native-orchestration-simplification.md). Any
further delegation edge requires Julio's approval.

## Consequences

Research and authorship may be performed by separate specialists without
routing report synthesis back through root for redispatch. Root remains the
owner of the report target and acceptance; the writer's task is a subset of the
Researcher's root-authorized assignment. Authoring-only work remains directly
routable to the writer, and complex-document validation remains an independent
root-commissioned assignment.
