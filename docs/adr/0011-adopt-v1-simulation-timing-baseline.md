---
status: accepted
---
# Adopt the V1 simulation timing baseline

## Context

WP2 feasibility evidence identifies candidate floating-point MATLAB reference
baseline. Study analytic or idealized; does not establish complete DUT,
hardware, or real-time implementation. Independent numerical and document review
found no G1-blocking error; G1 adopts bounded simulation baseline.
See [WP2 feasibility
report](../research/radar-v1-feasibility.md), [coverage result](../../evidence/radar_v1_coverage_results.json),
[streaming result](../../evidence/streaming_feasibility_results.json),
[ideal range result](../../evidence/radar_v1_range_resolution_results.json), and
[ideal angle result](../../evidence/radar_v1_angle_feasibility_results.json).

## Decision

Use V1 simulation baseline parameters:

- 250 MHz bandwidth, 40 us pulsed LFM, and 156.25 MHz IF;
- 625 MS/s real 16-bit samples on 64 channels;
- five quantized PRIs, ADC samples: 367648, 328948, 290698, 255102,
  and 231482;
- 128 usable returns targeted per PRF, with 40 us transmit blanking and
  5 us guard.

Candidate reports range at common scan midpoint over 6.80–100.00 km;
internal generation and search extend to 100.05 km for motion.
WP4 must verify 128 usable returns, receive-window priming, and transitions
at G2; failure reopens G1.
Use 4× output-grid interpolation as initial WP4/WP6b range-processing
candidate; sampled ADC/DDC and detection performance remain unverified.
Use ≤0.1° per-axis tolerance only for WP6d's noiseless matched-manifold
angle-grid fixture, not noisy or operational angle accuracy.

## Rationale and limits

Five-PRF analytic echo-window study supports candidate reported range domain.
Executed streaming proxy completed 6.11 GB MAT exact round trip with bounded
sampled RSS, supporting bounded-memory evidence.
Single PRF cannot simultaneously provide native ±40 m/s velocity coverage
and unambiguous 100 km range. Ideal B250 4× finite sweep passed all 5760
studied phase/grid-offset cases; does not yet prove sampled end-to-end 1 m
separation. Ideal 16×4 array study supports signed boresight and off-axis
unit fixtures but not operational elevation coverage.

Unproven downstream work remains: full five-PRF streaming implementation,
noisy multi-target Doppler and range ambiguity unfolding, 128-return transition
schedule, full DUT and real-time throughput, end-to-end bounded-memory
streaming, and sampled end-to-end 1 m resolution. These are WP6e, WP4/G2,
and WP8 risks, not this ADR's claims.

Illustrative RF calculation assumes 10 kW peak power, 23 dBi transmit and
receive gains, 6 dB loss, 4 dB noise figure, and 290 K. Values are simulation
assumptions; do not commit hardware. ±45° sector and one-second update
remain provisional. Pd/Pfa reporting and gate treatment follow
[ADR 0010](0010-v1-pd-pfa-demonstration-gate.md).

## Consequences and review gate

WP4 may freeze timing and data-shape contracts around baseline;
WP6e and WP8 retain independent validation gates. If streaming or transition
evidence disproves baseline, G1 must reopen; requirements and architecture
records must be revised. Until then, this ADR does not change accepted
requirements in [ADR 0009](0009-radar-mvp-acceptance-and-ambiguity-requirements.md).
