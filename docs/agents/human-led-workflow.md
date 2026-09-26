# Human-led engineering workflow

## Decision authority

Julio owns architecture decisions: system decomposition, interfaces, algorithm
choices, state and timing behavior, and consequential requirement changes.
Agents may investigate, present concrete alternatives with evidence, and
implement choices Julio approves. Independent verification provides evidence;
it is not human approval. Historical decisions remain the baseline until Julio
explicitly revises them. Routine implementation within an approved design may
proceed autonomously.

## Human clarity

Engineering artifacts should help a human reader understand why a decision or
experiment matters. State the intended reader and question. For a learning
example, provide a runnable entry point, explain important units, signal shapes,
and persistent state, and say what output or observation the reader should
interpret. Use a diagram when its purpose and audience are clear; include the
nodes, relationships, and implementation-status distinctions required to
answer that question, and keep unresolved choices visible.

Raise a decision for Julio when it would change an approved architecture,
interface, algorithm, externally visible behavior, state or timing semantics,
or a consequential requirement. Record the decision and its rationale in the
appropriate decision record before dependent implementation proceeds.

## Component work and branches

Work in coherent component or change branches from the agreed integration
branch. The human-led development plan uses `docs/human-led-workflow` for this
documentation work, `architecture/radar-overview` for the architecture overview,
and `component/ddc-walkthrough` for the DDC walkthrough. Integrate a change
before dependent work starts, or record its dependency. Sequential guided work
may use the main checkout; a branch does not require a separate checkout. Use a
worktree when concurrent work needs isolation, preferably as a sibling of the
repository rather than nested inside it. A branch or worktree does not
authorize an automatic merge or push.

Before implementation, make the component boundary, approved behavior,
acceptance evidence, and unresolved decisions clear. Agents can complete
routine implementation and checks within that boundary. Route changes that
cross an approval boundary back to Julio before proceeding.

## Module quality

Use namespaced MATLAB functions with explicit configuration and state structs,
including for stateful DDC modules. Consider a class only when a concrete case
shows that it simplifies the design or better enforces an invariant; get
architectural review before changing this default. Keep implementations lean
and readable.

Test each module directly through its public interface using controlled inputs
and independently derived expected results. Map tests to relevant requirement
IDs so they support requirement verification; also retain fixture and
integration tests where appropriate. Requirement verification and structural
code coverage answer different questions. Coverage metrics and thresholds
remain future decisions, and this guidance does not claim existing tests cover
every requirement. A future Simulink component may organize its internals
differently from the MATLAB module while preserving approved interfaces and
behavior.

## Tickets and evidence

Open an engineering ticket around a question and expected behavior. State what
observation would answer the question and which behavior is in scope. Record
the evidence question, experiment or check, result, and limitations before
adding traceability links. Keep records truthful: label human decisions as
human decisions and agent analysis or implementation as agent contributions.
Tests and experiments establish observations, not human understanding or
approval.

## References

- [Agent orchestration contract](../../AGENTS.md) — task routing, specialist
  responsibilities, and completion gates.
- [Human-led development plan](../plans/human-led-development.md) — ordered
  work and step-specific acceptance criteria.
- [Domain glossary](../../CONTEXT.md) — radar and DSP vocabulary.
