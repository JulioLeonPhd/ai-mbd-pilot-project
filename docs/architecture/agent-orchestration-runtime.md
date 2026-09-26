# Deferred Agent Orchestration Runtime

## Purpose and status

This document describes a possible runtime boundary for the pilot's agentic
workflow. It is an architecture direction, not an implementation plan that is
currently authorized to add runtime code, schemas, or provider integration.
Runtime work remains deferred until prompt-driven orchestration creates a need
for persistence, replay, cross-process execution, or measurable cost and
latency control.

The pilot currently uses the root agent as the orchestrator. The root owns
decomposition, routing, authority, conflict resolution, and final acceptance.
Specialists receive bounded task packets and return bounded result packets;
specialists never spawn specialists. That flat rule remains an invariant of any
future runtime.

Julio owns architectural decisions: system decomposition, interfaces, algorithm
choices, state and timing behavior, and consequential requirement changes. The
root coordinates proposals, records Julio's decisions, and accepts evidence
against approved criteria; it does not approve architecture on Julio's behalf.
Agents may investigate and recommend alternatives, then proceed autonomously
with routine work inside an approved decision. Independent verification informs
human decisions and does not replace them.

The runtime advances the meta-project objective by making the workflow's
handoffs reproducible, inspectable, and measurable. It would turn lessons from
prompt-driven handoffs into an explicit, testable execution boundary without
making the pilot dependent on an opaque provider feature.

## Boundary and responsibilities

The runtime begins after the root has selected a specialist and ends when the
root receives a structurally validated result packet or an explicit failure
state. It owns
deterministic application behavior around a provider call, including:

- packet canonicalization and, when needed, serialization;
- prompt construction from stable and dynamic sections;
- revision and artifact-reference checks;
- dispatch, root-approved transport retries, timeout handling, and structural
  result validation;
- persistence, replay records, and application-owned telemetry.

The provider remains an external dependency. Provider-side prompt caching,
hidden context, token accounting, scheduling, and telemetry are opaque unless
the provider exposes them. The application may request or measure supported
controls, but must mark unsupported controls unavailable and must not claim a
cache hit, exact cache key, or hidden-token value that it cannot observe.

The runtime must not become a second orchestrator. It dispatches only the
root-selected specialist and must reject or surface attempts to create a
nested specialist call.

## Staged components

Implementation should be staged so each component has a useful acceptance
gate:

1. **Execution adapter:** a narrow provider-neutral call interface with model,
   tool, timeout, and cancellation metadata. Gate: a representative call can
   be recorded and replayed at the adapter boundary.
2. **Prompt builder:** an immutable stable prefix followed by a dynamic suffix.
   Gate: equivalent role and revision inputs produce identical application-owned
   prefix bytes, while task-specific data stays in the suffix.
3. **Packet and artifact layer:** canonical serialization, revision-pinned
   references, content hashes, and (only when persistence is introduced) the
   machine schemas described by the handoff plan. Gate: valid packets
   round-trip deterministically and invalid packets are rejected outside the
   model prompt.
4. **Run store:** durable task, call, result, and artifact metadata with
   retention and redaction policy. Gate: a run can be resumed or diagnosed
   without requiring the original conversational transcript. Replay records are
   non-live by default; redispatch is a separately authorized operation.
5. **Telemetry and controls:** correlated measurements, feature flags, cache
   controls where supported, and compatibility mode. Gate: unavailable
   measurements are explicit and a rollback restores the prompt-driven path.

These components are deliberately not schemas or runtime code today. Their
interfaces should first be validated with traces and small prototypes.

## Packet lifecycle

Julio has human clarity as an explicit objective for the project: readers should
be able to find the purpose, current capability, limitations, and next question,
and understand concrete examples and diagrams. Architecture diagrams must state
their purpose and audience, show required nodes and relationships, distinguish
implemented, accepted-but-unimplemented, and unresolved items where relevant,
and keep unresolved choices visible.

The root creates a task packet with a stable task ID, concise objective,
bounded context, inputs, constraints, acceptance criteria, allowed mutations,
and requested checks. The runtime then:

1. resolves and records input revisions or content hashes;
2. checks routing authority, allowed mutations, and compatibility mode;
3. builds the prompt and records its application-owned revisions;
4. dispatches root-selected specialist calls according to the root-approved
   execution plan; concurrency remains a separate policy and the runtime never
   selects, sequences, or nests specialists on its own;
5. validates the returned result packet and associates changed artifacts,
   findings, assumptions, and checks with the task;
6. returns the result to the root, which decides whether evidence meets the
   acceptance criteria, whether to retry or revise, or which bounded stage to
   route next. If a result proposes a choice at Julio's architecture boundary,
   the root obtains and records Julio's decision before dependent work proceeds.

Persistence is triggered when a packet must survive process termination, be
replayed across runs, cross a process or machine boundary, support audit or
resumption, or provide reliable cost/latency attribution. Before that trigger,
in-memory packet handling and the existing YAML-shaped contract remain the
source of behavior.

## Prompt construction and cache posture

The stable prefix contains only application-owned, revisioned material:
model/config identity, role instructions, invariant contract text, stable tool
definitions and order, encoding, and eventually canonical serialization rules.
The dynamic suffix contains the current packet, artifact revisions, findings,
requested checks, and other run-specific data. Full conversation is not passed
by default; it is included only when the packet records a specific reason for
missing context.

Stable-prefix equality is an application assertion about bytes under controlled
inputs. It is not a promise that a provider will reuse those bytes. Logical
invalidation is achieved by changing an application-owned revision; provider
cache deletion, retention, and breakpoint behavior remain provider-specific.

## Validation and failure semantics

Structural validation occurs before dispatch and after receipt. It checks packet
shape, authority, references, revisions, allowed mutations, result status, and
artifact traceability. A future schema must be versioned with each persisted
packet and must not be transmitted as prompt content.

Structural validation is not semantic acceptance or independent artifact
validation. Those decisions remain with the root and the configured validators.

The runtime maps failures deterministically:

- malformed packet or unusable returned result: `failed`;
- missing information the root or user can provide: `needs-input`;
- revision or hash mismatch: `needs-input`;
- unavailable service, tool, external state, or authority: `blocked`;
- legacy unpinned reference in compatibility mode: accepted with an explicit
  `integrity-unverified` warning; strict mode may reject it.

Only transport retries explicitly authorized by the root may occur inside the
runtime. They must be bounded, attributable, and safe for the requested mutation.
Semantic retries, revised prompts, rerouting, and continuation after a finding
remain root decisions. The runtime must not repeat a non-idempotent external
action without explicit idempotency authorization. Recorded replay is non-live
unless the root separately authorizes redispatch. A timeout or provider error is
not evidence that a specialist completed successfully.

## Telemetry, security, and privacy

Where exposed, record per-call input, cached-input, output, and tool-result
tokens; calls, retries, latency, success/failure, and cost. Correlate records
with task ID, role, packet revision, model/config revision, and artifact hash.
Do not infer unavailable measures or encode volatile provider pricing and model
numbers as normative requirements.

Persist the minimum data needed for replay and diagnosis. Telemetry is minimized
and redacted. Sensitive material indispensable for an authorized exact replay is
stored separately with encryption, access control, retention, and deletion
policy; if that material is removed or irreversibly redacted, exact replay is
explicitly unavailable. Authenticate cross-process callers, authorize allowed
mutations, and protect stored artifacts. Hashes provide integrity and
correlation; they are not a substitute for access control or confidentiality.

## Rollout and testing

Roll out in this order: baseline current handoffs; add prompt-builder traces;
introduce compatibility-mode serialization and validation when the persistence
trigger is met; then enable durable records and telemetry behind feature flags.
Each stage needs representative trivial, non-trivial
architect-to-implementer-to-validator, and documentation flows. Compare paired
baseline and candidate runs, with repeated trials, pinned controllable inputs,
packet-byte and prompt-size evidence, validation outcomes, clarification
requests, and all available telemetry.

The adoption evaluation follows the normative before/after method in the
[handoff optimisation plan](../plans/agent-handoff-token-optimisation.md): run at
least five repetitions per representative case, pin controllable settings,
alternate or randomize order, record seeds, report metric distributions and
unavailable measures, require no acceptance or validation regression, and require
a lower median end-to-end cost. Roll back by
disabling the new prompt builder or runtime validation flag and returning to the
last known-good packet revision; retain appropriately redacted diagnostics.

## Explicit non-goals

This architecture does not currently:

- implement an orchestrator, provider adapter, prompt cache, telemetry store,
  persistence service, or packet schema;
- change the task/result field names or status meanings in `AGENTS.md`;
- authorize specialists to spawn specialists or create a hierarchy of agents;
- guarantee provider cache hits, hidden-context visibility, or exact cost data;
- replace root-agent acceptance, specialist role definitions, or independent
  validation;
- define provider choice, pricing, concurrency policy, or a production security
  certification.

The runtime should be proposed for implementation only after its trigger,
acceptance gates, data-retention policy, and rollback path are agreed.
