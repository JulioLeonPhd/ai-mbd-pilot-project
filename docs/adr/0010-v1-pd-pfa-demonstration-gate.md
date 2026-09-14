---
status: accepted
---

# Clarify the V1 Pd/Pfa demonstration gate

## Context

[ADR 0009](0009-radar-mvp-acceptance-and-ambiguity-requirements.md) establishes
Monte Carlo estimation of probability of detection (Pd) and per-cell
probability of false alarm (Pfa), with targets of Pd ≥ 0.9 and Pfa ≤ 10^-6.
The V1 plan needs a bounded acceptance gate while waveform, link-budget, and
processing parameters remain subject to WP2 feasibility work.

## Decision

For V1, the statistical study shall run and report Pd and per-cell Pfa with
the seed, trial count, confidence method, estimates, and confidence bounds.
The numeric Pd and Pfa values in ADR 0009 are demonstration targets and are not
pass/fail gates for the V1 reference. Any deviation shall be disclosed in the
verification report and may motivate a later requirements revision.

This ADR clarifies only the V1 acceptance status of those two numeric targets.
All other decisions and requirements in ADR 0009 remain accepted, including
the 100 km primary case, ambiguity cases, and detection-list behavior.

## Consequences

V1 can close with reproducible statistical evidence even when feasibility work
shows that the target values need further design iteration. Future fixed-point,
Simulink, or mission-oriented versions may adopt numeric Pd/Pfa gates through a
new decision or an explicit revision to the requirements specification.
