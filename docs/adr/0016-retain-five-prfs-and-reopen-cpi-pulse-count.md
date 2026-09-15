---
status: accepted
---

# Retain five PRFs and reopen the CPI pulse count

## Context

The revised G1 study showed that the five candidate PRFs (`1700, 1900, 2150,
2450, 2700` Hz) provide at least three guarded-valid PRFs throughout the
6.8–100 km domain. The provisional 128 usable pulses per PRF takes
approximately 307.063 ms including priming and transitions, while the
provisional broadside azimuth-cell time is 70.653 ms.

## Decision

Retain all five PRFs as the V1 processing set. Reopen usable pulses per CPI as
WP4/WP6e study work. Twenty-seven equal usable pulses per PRF (approximately
68.881 ms including the currently modelled overhead) is a timing-feasible
candidate, not an accepted performance setting.

Preserve five PRF layers through ambiguity projection/unfolding and per-PRF
CFAR. Apply non-coherent M-of-5 binary integration after CFAR, then pass fused
hypotheses to clustering. The full-domain baseline is 3-of-5; 4-of-5 is a
comparator or validity-mask-dependent option. CRT may generate noiseless
ambiguity candidates, but robust bounded hypothesis search must be validated
with noise, missed PRFs, and multiple targets.

## Alternatives and consequences

Four PRFs guarantee only two valid PRFs somewhere in the domain. The only
tested three-PRF subset guaranteeing two is `{1700, 2150, 2700}` and it has a
near-alias risk. Fewer PRFs can increase pulses per CPI, but reduce ambiguity
and missed-detection robustness. The five-PRF choice prioritizes coverage and
fusion redundancy; pulse count remains a measurable trade study. The 27-pulse
candidate timing is `27 × 2.35824 ms + 2.35824 ms + 4 ×
0.7124617544915022 ms = 68.880567 ms`; it is not accepted performance.

## Validation gate

WP4/WP6e shall select pulse allocation and processing order using Pd/Pfa,
velocity resolution, range migration, timing, noisy ambiguity, and ghost/
unresolved-hypothesis evidence. No 27-pulse or 128-pulse setting is a V1 pass
criterion until that evidence is accepted.

This decision supersedes only ADR 0014's statement that the analytic schedule
retains 128 usable returns per PRF as a G2 check; ADR 0014's other results and
historical decisions remain unchanged.
