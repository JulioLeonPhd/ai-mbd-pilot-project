# Agent handoff token optimisation plan

## Outcome and governing decision

Optimise specialist handoffs around the existing task/result packet contract in
`AGENTS.md`. Keep the semantic contract, routing authority, status meanings, and
completion gates in `AGENTS.md` during phase 1. Do not add a standalone JSON
Schema yet: there is no persistent packet serialisation or mechanical
orchestrator validation to own one. Add schemas under `contracts/` only when
packets are serialised persistently and an orchestrator validates them outside
the model prompt; at that point the schema becomes the machine contract while
`AGENTS.md` remains the behavioural contract. When the trigger is met, place
the machine schemas at `contracts/agent-handoff/task.schema.json` and
`contracts/agent-handoff/result.schema.json`.

This plan separates instructions from enforcement. `AGENTS.md` governs agent
behaviour; role TOMLs contain only role-specific differences; future runtime
code owns canonical serialisation, content hashes, cache controls, and
telemetry. Prompt caching cannot be enforced through `AGENTS.md`.

## Phase 1: compact, stable handoffs

1. **Clarify packet usage in `AGENTS.md` (root agent owns the change).** Add a
   short “handoff economy” subsection beside “Task and result packets”. It must
   preserve every existing field and status, while requiring:

   - a stable task id and concise objective;
   - immutable revision-pinned references in existing `inputs` string entries
     using `ref: repo-relative/path @ revision-or-hash [#selector]`; bare paths
     and mutable labels such as `@ working-tree` remain compatible but are
     reported as integrity-unverified;
   - only constraints and acceptance criteria that apply to this assignment;
   - result packets containing changed artifacts, evidence, findings,
     assumptions, and the next handoff, without reasoning traces or repeated
     source text;
   - full-conversation inheritance only when the existing `context` string
     records `inherit-full-conversation: reason=<specific missing context>`.

   Completion criterion: the subsection names the existing packet fields and
   adds usage rules without changing their names, types, or status semantics.

2. **Define prompt construction for the orchestrator (runtime owner, if
   introduced).** Build each specialist prompt as an immutable stable prefix
   followed by a dynamic suffix containing the current packet, artifact
   revisions, and requested checks. Keep role instructions and invariant
   contract text in the prefix; keep run-specific paths, findings, and results
   in the suffix. App-owned stable-prefix inputs are model/config identity, role
   instruction bytes and revision, invariant contract bytes and revision,
   stable tool definitions and order, UTF-8/LF encoding, and (once available)
   canonical serialisation. Exclude opaque provider-owned hidden content from
   byte-equality claims. Never promise cache hits: provider caches may be
   opaque.

   Completion criterion: an implementation test or trace shows identical
   stable-prefix bytes for equivalent role/revision inputs and dynamic data is
   excluded from that prefix.

3. **Reduce role-prompt duplication (root agent owns TOML edits, if needed).**
   Compare `.codex/agents/*.toml` with `AGENTS.md`; remove duplicated global
   workflow rules from role TOMLs and retain only model, sandbox, tools, and
   role-specific responsibilities. Keep exact remaining role names. Mermaid work
   uses the repository `diagrammer` skill directly rather than a specialist
   handoff.

   Completion criterion: each retained TOML instruction is demonstrably
   role-specific, and global contract text has one authoritative source.

## Phase 2: runtime enforcement and measurement

1. **Introduce packet serialisation only when needed (runtime owner).** When
   persistent packets, replay, or cross-process transport is introduced, add a
   canonical serialiser and deterministic field ordering. Record schema and
   packet revisions, content-addressed artifact identifiers, and hashes of
   referenced inputs. Add the two `contracts/agent-handoff/*.schema.json`
   schemas at the same time and validate packets before dispatch and after
   receipt; do not transmit the schemas in agent prompts.

   Completion criterion: invalid packets are rejected outside the model prompt,
   valid packets round-trip deterministically, and the schema version is
   recorded with each packet.

2. **Add cache and telemetry controls (runtime owner).** Reuse immutable
   revision-pinned references and bound packet size. Expose cache-key,
   breakpoint, invalidation, and retention controls only where the provider
   supports them; mark unsupported controls unavailable. App-owned prefix
   revisions provide logical invalidation by deliberate mismatch, not cache
   deletion. Measure, where the platform exposes them:
   input tokens, cached-input tokens, output tokens, tool-result tokens, agent
   calls, retries, latency, success/failure, and cost. Attribute measurements to
   task id, role, packet revision, and artifact hash; do not encode provider
   pricing or volatile model numbers as normative requirements.

   Completion criterion: one run produces correlated per-call records for all
   available measures and explicitly marks unavailable measures rather than
   inferring them.

## Migration, validation, and rollback

Migrate in this order: baseline current handoffs; add the phase-1 guidance;
run representative root → architect → implementer → validator flows; then
introduce serialisation, schemas, and telemetry only when their trigger is met.
Keep a compatibility mode that accepts the current packet shape while the new
runtime is trialled. Roll back by disabling the new prompt builder or runtime
validation feature flag and reverting to the last known-good packet revision;
retain artifacts and measurements for diagnosis. Use this deterministic mapping
for packet and handoff failures:

- Malformed packet → `failed`.
- Missing information the root or user can supply → `needs-input`.
- Hash or revision mismatch → `needs-input`.
- Unavailable external state, service, tool, or authority → `blocked`.
- Legacy unpinned reference in compatibility mode → accepted with an explicit
  integrity-unverified warning; strict future runtimes reject it under their
  validated contract.

Completion criterion: the migration checklist records baseline, enabled,
rollback, and failure-path results for each staged change.

## Before/after evaluation

Run at least one trivial change, one non-trivial
architect→implementer→validator flow, and one documentation flow. Use paired
baseline/candidate runs, at least five repetitions per case, pinned
repository/model/tool configuration where controllable, alternating or
randomised order, and recorded seeds/settings. Compare packet bytes and
estimated prompt size plus the exposed telemetry for input, cached input, output,
tool-result tokens, agent calls, retries, latency, success, and cost. Also check
artifact traceability, validator coverage, blocked/failed outcomes, and any
increase in clarification requests. Report distributions and unavailable
metrics without claiming unsupported statistical certainty. Adoption requires
no acceptance/validation regression and a lower median end-to-end cost.

Completion criterion: the comparison report includes a baseline and candidate
run, per-metric evidence, and a decision to adopt, revise, or roll back.

## Acceptance gate

The root agent accepts Phase 1 when the changed instructions are traceable to
this plan, existing task/result packets remain compatible, no full conversation
is passed by default, and the handoff-economy and role-prompt changes are
verified. If a prompt builder or other runtime is introduced, its stable-prefix/
dynamic-suffix construction must also be demonstrated, and every exposed metric
must have an explicit unavailable marker when unsupported. Runtime-specific
acceptance criteria do not apply while that runtime is absent.
The complex-document review remains independent: the technical-writer-
validator checks the finished plan against `AGENTS.md`, ADR 0001, and ADR 0018;
it does not repair the plan silently.
