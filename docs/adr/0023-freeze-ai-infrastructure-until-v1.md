---
status: accepted
---

# Freeze AI infrastructure development until v1

## Context

The repository has enough agent orchestration, specialist roles, skills, contracts, and validation machinery to support continued radar v1 development.

Further AI-infrastructure refinement now competes with the primary purpose of the project: developing and demonstrating AI-native Model-Based Design engineering capability by delivering the radar demonstrator.

The project should learn from using the existing infrastructure during product delivery rather than continue expanding it speculatively.

## Decision

Freeze development of repository AI infrastructure until radar v1 is complete.

Until that exit condition is reached:

- do not add agents or specialist roles;
- do not add orchestration layers or handoff mechanisms;
- do not add agent-facing abstractions, contracts, skills, or workflow machinery unless required to unblock or materially support radar v1;
- permit defect fixes and minimal maintenance when existing AI infrastructure blocks or materially impairs radar v1 work;
- direct development effort towards radar engineering, human understanding, verification, Model-Based Design, and delivery;
- prefer simplification over expansion when existing machinery causes avoidable friction.

Product architecture decisions, requirements, component implementation, verification, walkthroughs, required development tooling, and maintenance of existing project records are not frozen by this decision.

## Rationale

The AI infrastructure is sufficiently capable for the next phase of the project.

Additional infrastructure investment before v1 has diminishing value and increases repository complexity, review burden, and distance from the engineering problem.

The AI system exists to support engineering work. It is not the product.

The freeze creates an evidence-gathering period. Friction encountered while delivering v1 becomes concrete input for a post-v1 architecture review.

## Consequences

Radar and product progress take priority over AI-infrastructure progress until v1.

Existing AI infrastructure remains available and continues to govern work where applicable.

Infrastructure limitations should be recorded when encountered, but they should not trigger redesign unless they block or materially impair v1 delivery.

After v1, review the infrastructure using observed friction and demonstrated value. Remove or simplify mechanisms that did not earn their complexity before considering additions.

## Exit condition

Radar demonstrator v1 is complete.

The first AI-infrastructure activity after that milestone is a retrospective and simplification review, not automatic resumption of infrastructure expansion.
