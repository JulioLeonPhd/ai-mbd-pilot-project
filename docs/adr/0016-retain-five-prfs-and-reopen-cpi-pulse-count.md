---
status: accepted
---
# Retain five PRFs and reopen the CPI pulse count

## Context

Revised G1 study showed five candidate PRFs (`1700, 1900, 2150,
2450, 2700` Hz) provide at least three guarded-valid PRFs throughout
6.8–100 km domain. Provisional 128 usable pulses per PRF takes
approximately 307.063 ms including priming and transitions; provisional
broadside azimuth-cell time: 70.653 ms.

## Decision

Retain all five PRFs as V1 processing set. Reopen usable pulses per CPI as
WP4/WP6e study work. Twenty-seven equal usable pulses per PRF (approximately
68.881 ms including currently modelled overhead): timing-feasible
candidate, not accepted performance setting.

Preserve five PRF layers through ambiguity projection/unfolding and per-PRF
CFAR. Apply non-coherent M-of-5 binary integration after CFAR; pass fused
hypotheses to clustering. Full-domain baseline: 3-of-5; 4-of-5:
comparator or validity-mask-dependent option. CRT may generate noiseless
ambiguity candidates; robust bounded hypothesis search must be validated
with noise, missed PRFs, and multiple targets.

## Alternatives and consequences

Four PRFs guarantee only two valid PRFs somewhere in domain. Only
tested three-PRF subset guaranteeing two: `{1700, 2150, 2700}`; has
near-alias risk. Fewer PRFs can increase pulses per CPI, but reduce ambiguity
and missed-detection robustness. Five-PRF choice prioritizes coverage and
fusion redundancy; pulse count remains measurable trade study. 27-pulse
candidate timing: `27 × 2.35824 ms + 2.35824 ms + 4 ×
0.7124617544915022 ms = 68.880567 ms`; not accepted performance.

## Validation gate

WP4/WP6e shall select pulse allocation and processing order using Pd/Pfa,
velocity resolution, range migration, timing, noisy ambiguity, and ghost/
unresolved-hypothesis evidence. No 27-pulse or 128-pulse setting is V1 pass
criterion until evidence accepted.

Decision supersedes only ADR 0014's statement that analytic schedule
retains 128 usable returns per PRF as G2 check; ADR 0014's other results and
historical decisions remain unchanged.
