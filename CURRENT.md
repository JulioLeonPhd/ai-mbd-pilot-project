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

On 2026-09-29 Julio approved independent per-PRI DDC processing with fresh
local state for each complete physical PRI and closed the joint design discussion.
Implementation review and verification are pending Phase 0 interface and
evidence-migration decisions plus explicit go. The current DDC
code, walkthrough, diagrams, and G2 streaming evidence describe the former
continuous-state baseline. See [ADR 0022](docs/adr/0022-adopt-independent-pri-ddc-processing.md),
the [per-PRI implementation plan](docs/plans/ddc-pri-processing.md), and the
[joint walkthrough review](docs/examples/ddc-walkthrough-review.md).

Julio confirmed the architecture interview summary on 2026-09-26. Independent
review of [ADR 0019](docs/adr/0019-adopt-human-led-module-design-and-simulink-staging.md),
[ADR 0020](docs/adr/0020-adopt-pilot-adc-storage-and-sample-integrity.md), and
[ADR 0021](docs/adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md)
passed on 2026-09-26 with no unresolved semantic findings. The redrawn diagrams
still await Julio's visual review; this walkthrough does not record or imply
that review. On 2026-09-27 Julio confirmed proceeding to step 4 of the human-led
development plan. Julio approved renaming the live DDC entry point to
`processFrame` on 2026-09-28. Historical fixture provenance and serialized
`chunkLengths`/`maxChunkSamples` fields remain unchanged; no runtime alias is
required. The rename, five-file Code Analyzer run, focused walkthrough oracle,
streaming-equivalence, and state-reset checks passed on 2026-09-28. The full
WP4 MATLAB MCP suite completed on 2026-09-28 with 54 passed, 0 failed, and 0
incomplete in 84.2901 seconds. Julio closed the joint DDC design discussion on
2026-09-29. The new per-PRI implementation review and verification remain
pending Phase 0 interface/evidence decisions and explicit go; the current
walkthrough documents the historical continuous-state implementation. Then
select the next component question under step 5. WP6e's ambiguity method and
ordering remain open study items. Issue 3 separately tracks manifest
revision-provenance hardening.

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
