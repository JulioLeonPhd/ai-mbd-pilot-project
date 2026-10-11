# Current project status

## Capability

| Area | Status |
| --- | --- |
| Bounded analytic and ideal simulation baseline | Passed revised G1. |
| WP3 and WP4 | WP3 data contracts and WP4 DSP/timing evidence passed the G2 root gate. |
| Floating-point implementation | Partial production-like modules, fixture generation, an independent oracle, and adapters are present. The complete ADC-to-detection floating-point reference is not complete. |
| Fixed-point design and Simulink representation | Incomplete. |
| Hardware and real-time performance | The demonstrator has no verified hardware or real-time performance claim. |

## Limitations

| Evidence or topic | Scope and limitation |
| --- | --- |
| WP4 evidence | Verifies the 151-record schedule, priming and timing margins, post-CFAR 3-of-5 fusion, and one-channel full-CPI DDC streaming against an independent direct-convolution comparison over sampled observation windows. It does not establish complete FIR precursor/waveform retention or detection performance. |
| Schedule | WP6e may reject the schedule and reopen G2. |
| Open or downstream study items | The 128-pulse setting, noisy multi-target ambiguity method, sampled end-to-end 50 m separation, noisy angle accuracy, and detection performance remain open or downstream study items. WP6e's ambiguity method and ordering remain open study items. |
| Provisional settings | The ±45° sector and one-second update remain provisional. |

## Next open question

| Topic | Current status |
| --- | --- |
| Per-PRI DDC decision | Julio approved independent per-PRI DDC processing on 2026-09-29, confirmed the sample-only API and responsibilities on 2026-10-02, and then explicitly authorized implementation. |
| Implementation and numerical validation | The MATLAB implementation, scoped core and WP4 suites, full-scan walkthrough, pinned continuous-state DDC-002 replay, and fixture-preservation audit have passed. Preservation of all 23 historical fixture hashes was confirmed. Independent numerical validation passed, including the exact-zero and inactive-channel oracle checks. The bounded numerical tolerance and all evidence scopes are recorded in the [per-PRI implementation plan](docs/plans/ddc-pri-processing.md). |
| Walkthrough | The [one-PRI teaching walkthrough](docs/examples/ddc-walkthrough.md) is approved by Julio as of 2026-10-08. Full-scan integration evidence remains a separate check. |
| Issue 6 and standards warnings | The issue 6 cascade stopband-coverage blocker was fixed and independently validated on 2026-10-10. The three standards warnings were resolved and independently validated on 2026-10-11. See the [issue 6 resolution and evidence](docs/plans/ddc-pri-processing.md#issue-6-coverage-resolution-2026-10-10) and [standards-warning resolution](docs/plans/ddc-pri-processing.md#standards-warning-resolution-2026-10-11). |
| Pending reviews and authorization | Human implementation review and visual review of the separate redrawn architecture diagrams remain pending. Merge authorization is not recorded. |
| Next action | Then review the range-component boundary under step 5. |
| Evidence boundaries | Historical G2 streaming evidence remains continuous-state evidence only, not per-PRI acceptance evidence. Unit/oracle, full-scan, end-to-end, and hardware claims remain separate. Do not represent DDC results as full-receiver or hardware evidence. See [ADR 0022](docs/adr/0022-adopt-independent-pri-ddc-processing.md) and the [joint walkthrough review](docs/examples/ddc-walkthrough-review.md). |
| Separate tracking | Issue 3 separately tracks manifest revision-provenance hardening. |

### Dated milestones

|Date|Milestone and evidence|
|---|---|
|2026-09-26|Julio confirmed the architecture interview summary. Independent review of [ADR 0019](docs/adr/0019-adopt-human-led-module-design-and-simulink-staging.md), [ADR 0020](docs/adr/0020-adopt-pilot-adc-storage-and-sample-integrity.md), and [ADR 0021](docs/adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md) passed with no unresolved semantic findings. The redrawn diagrams still await Julio's visual review; this walkthrough does not record or imply that review.|
|2026-09-27|Julio confirmed proceeding to step 4 of the human-led development plan.|
|2026-09-28|Julio approved renaming the live DDC entry point to `processFrame`. Historical fixture provenance and serialized `chunkLengths`/`maxChunkSamples` fields remain unchanged; no runtime alias is required. The rename, five-file Code Analyzer run, focused walkthrough oracle, streaming-equivalence, and state-reset checks passed. The full WP4 MATLAB MCP suite completed with 54 passed, 0 failed, and 0 incomplete in 84.2901 seconds.|
|2026-09-29|Julio closed the joint DDC design discussion and approved independent per-PRI DDC processing.|
|2026-10-02|Julio confirmed the sample-only API and responsibilities, then explicitly authorized implementation.|
|2026-10-08|Julio approved the DDC walkthrough.|
|2026-10-10|The issue 6 cascade stopband-coverage blocker was fixed and independently validated.|
|2026-10-11|The three standards warnings were resolved and independently validated.|

## Evidence and history

- [WP4/G2 recovery plan](docs/plans/wp4-g2-recovery-plan-2026-09-21.md) — durable implementation and validation ledger.
- [Dated evidence handoff](docs/reference/current-evidence-2026-09-25.md) — prior verified results, issue context, replay procedure, pinned revisions, and detailed metrics.
- [Radar requirements](docs/requirements/radar-matlab-v1.md) and [V1 work-package plan](docs/plans/radar-matlab-v1.md) — normative scope and gates.
- [Evidence directory](evidence) — quantitative study sources and results.
