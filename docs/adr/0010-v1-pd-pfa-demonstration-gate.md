---
status: accepted
---
# Clarify the V1 Pd/Pfa demonstration gate

## Context

[ADR 0009](0009-radar-mvp-acceptance-and-ambiguity-requirements.md) establishes
Monte Carlo estimation of detection probability (Pd) and per-cell
false-alarm probability (Pfa), targets Pd ≥ 0.9 and Pfa ≤ 10^-6.
V1 needs bounded acceptance gate; waveform, link-budget, and
processing parameters remain subject to WP2 feasibility work.

## Decision

V1 statistical study shall run, report Pd and per-cell Pfa with
seed, trial count, confidence method, estimates, confidence bounds.
Numeric Pd and Pfa values in ADR 0009: demonstration targets, not
pass/fail gates for V1 reference. Any deviation shall be disclosed in
verification report; may motivate later requirements revision.

This ADR clarifies only V1 acceptance status of those two numeric targets.
All other ADR 0009 decisions and requirements remain accepted, including
100 km primary case, ambiguity cases, detection-list behavior.

## Consequences

V1 can close with reproducible statistical evidence even when feasibility work
shows target values need further design iteration. Future fixed-point,
Simulink, or mission-oriented versions may adopt numeric Pd/Pfa gates through
new decision or explicit requirements specification revision.
