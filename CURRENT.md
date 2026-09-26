# Current project status

## Capability

The bounded analytic and ideal simulation baseline passed revised G1. WP3 data
contracts and WP4 DSP/timing evidence passed the G2 root gate. Partial
production-like floating-point modules, fixture generation, an independent
oracle, and adapters are present; the complete ADC-to-detection floating-point
reference is not complete. Fixed-point design and a Simulink representation
remain incomplete. The demonstrator has no verified hardware or real-time
performance claim.

## Limitations

WP4 evidence verifies the 151-record schedule, priming and timing margins,
post-CFAR 3-of-5 fusion, and one-channel full-CPI DDC streaming against an
independent direct-convolution comparison over sampled observation windows. It
does not establish complete FIR precursor/waveform retention or detection
performance. WP6e may reject the schedule and reopen G2. The 128-pulse setting,
noisy multi-target ambiguity method, sampled end-to-end 50 m separation, noisy
angle accuracy, and detection performance remain open or downstream study
items. The ±45° sector and one-second update remain provisional.

## Next open question

Julio confirmed the architecture interview summary on 2026-09-26. Independent
review of [ADR 0019](docs/adr/0019-adopt-human-led-module-design-and-simulink-staging.md),
[ADR 0020](docs/adr/0020-adopt-pilot-adc-storage-and-sample-integrity.md), and
[ADR 0021](docs/adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md)
passed on 2026-09-26 with no unresolved semantic findings. The redrawn diagrams
still await Julio's visual review. Then use the
[top-level radar overview](docs/architecture/radar-overview.md) and DDC learning
walkthrough to guide component work. WP6e's ambiguity method and ordering remain
open study items. Issue 3 separately tracks manifest revision-provenance
hardening.

## Evidence and history

- [WP4/G2 recovery plan](docs/plans/wp4-g2-recovery-plan-2026-09-21.md) — durable
  implementation and validation ledger.
- [Dated evidence handoff](docs/reference/current-evidence-2026-09-25.md) — prior
  verified results, issue context, replay procedure, pinned revisions, and
  detailed metrics.
- [Radar requirements](docs/requirements/radar-matlab-v1.md) and
  [V1 work-package plan](docs/plans/radar-matlab-v1.md) — normative scope and
  gates.
- [Evidence directory](evidence) — quantitative study sources and results.
