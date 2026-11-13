---
status: accepted
accepted: 2026-11-13
---

# Permit bounded OMP-native orchestration simplification

## Context

[ADR 0023](0023-freeze-ai-infrastructure-until-v1.md) freezes AI-infrastructure development until radar v1, with only its stated maintenance allowance.

The [OMP-native orchestration simplification plan](../plans/omp-native-orchestration-simplification.md) defines a bounded exception following completion of the range-compressor release.

Julio confirmed the target choices on 2026-11-08; on 2026-11-13 he explicitly approved `approve_structural_simplification` and revised the success criterion, as recorded below.

The prerequisite is verified: GitHub [PR #26](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/pull/26) merged into `main` at 2026-11-13T10:29:25Z as merge commit `64ed326b06041973e7fff71272c77f525c4ee600`, and [release v0.9.0](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/releases/tag/v0.9.0) was published at 2026-11-13T10:43:29Z as a non-draft, non-prerelease release targeting `main`.

The earlier proposal required demonstrated net payback before radar v1. Julio's explicit 2026-11-13 decision removes that requirement; it does not claim measured savings or quantified improvement.

## Decision

Record a human-authorized, bounded exception to ADR 0023 for the specific simplification defined by the linked plan, and authorize its gated implementation work to proceed under that plan.

The exception is limited to replacing the OMP project-specialist inventory with the plan's six native roles, using exact native task-specific escalation, and retaining a direct single-agent Codex fallback without a parallel specialist topology or custom router.

The plan remains the detailed specification for implementation decisions, runtime and safety constraints, scenarios, acceptance evidence, effort accounting, and stop and rollback gates.

The original demonstrated pre-V1 payback criterion is superseded by Julio's explicit 2026-11-13 `approve_structural_simplification` decision. The approved success criterion is structural simplification without a payback test; no measured savings or quantified improvement is claimed.

Retain the target of two evenings of Julio's work and hard maximum of one week of human work effort, without translating evenings into hours. Count implementation, review, verification, retries, repairs, and rollback; distinguish elapsed waiting and unattended work.

The existing authority, task/result packets, safety boundaries, and independent review remain in force. Julio retains consequential architecture authority, and implementation evidence, independent validation, and human approval remain distinct.

Disposable routing probes completed for each of the six retained roles. Runtime-owned `session_init` records show each role has `spawns: ""` and only its declared built-in tool set, but additive mounted tools, including mutation-capable MCP tools on inspection-only roles, remain available; inspection-only status is not an enforced full-tool or operating-system boundary.

The ordinary and escalated public-dispatch probes used the same `matlab-architect` identity and resolved to `openai-codex/gpt-5.6-sol`/`high` and `openai-codex/gpt-6.1-sol`/`max`, respectively, under OMP 18.20.0. Both records reported `resolvedModelIsFallback=false` and native model/thinking-level change events.

Generic bundled task workers used for mechanical provider probes have native `spawns: "*"` and a `task` builtin; task instructions prohibited spawning and no children were spawned. Their probe selections resolved to `openai-codex/gpt-6.1-sol`/`medium` and `github-copilot/auto-mai-code-1.1-flash`/`high`; the latter actual provider response model was `mai-code-1.1-flash`, and runtime-owned records reported no fallback. This does not establish equal capability, quota independence, strict packet adherence, or reliability.

These are bounded observations only, not completion of remaining runtime acceptance scenarios or final cutover.

The bounded probes provide the required observed escalation evidence for this decision: both used the same role and the resolved selection matched the approved probe need. Preserve the known-good configuration until the remaining acceptance scenarios and final cutover are reviewed; if a stop condition is met, follow the plan's rollback or deferral path.

This exception does not thaw other AI-infrastructure work, satisfy runtime or migration acceptance, certify all runtime settings or permissions, approve final cutover, or complete radar v1. ADR 0023 remains the freeze baseline outside this precise scope.

## Rationale

The completed range-compressor PR and release satisfy the plan's entry prerequisite, allowing its bounded simplification to proceed without treating a pending milestone as complete.

Julio's new explicit decision changes only the success criterion: the project may simplify duplicated role machinery without first demonstrating pre-V1 payback. Effort accounting, the effort cap, correctness and safety, independent review, and rollback remain required.

Keeping the plan authoritative avoids duplicating and potentially drifting its detailed decisions, while this ADR records the specific freeze exception and the human-approved criterion revision.

Runtime evidence remains bounded to the recorded native probes. It does not establish all acceptance scenarios, final cutover, or measured benefit.

## Consequences

The plan may proceed through its remaining runtime checks and gated migration; preserve the known-good configuration until remaining acceptance and final cutover are reviewed.

The published release and Julio's authorization establish neither complete runtime behavior nor migration success or measured savings; remaining acceptance is pending.

No other infrastructure development is authorized by this ADR, and the freeze exit condition in ADR 0023 is unchanged.
