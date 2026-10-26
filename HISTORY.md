# Project history

## 2026-10-14 — Initial status migration snapshot

This snapshot preserves the original status during migration; creating it does not mark a new milestone.

Outgoing work package: No formal assignment recorded.
Outgoing gate: No formal assignment recorded.
Outgoing milestone: Per-PRI DDC implementation and validation within human-led development step 4.

<!-- markdownlint-disable MD025 -->
<!-- BEGIN verbatim CURRENT.md snapshot -->
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

<!-- END verbatim CURRENT.md snapshot -->
<!-- markdownlint-enable MD025 -->

## 2026-10-26 — DDC status evidence consolidation

Routine update within the per-PRI DDC milestone and human-led development step 4; no new work package or gate assignment.
The following passages were moved verbatim from `CURRENT.md`, preserving recorded implementation checks, earlier review status, and relative links.
They are historical status wording, not a new execution or approval record.

The earlier per-PRI implementation and its results remain historical `independent-pri-v1` version `1.0.0` evidence.
The pinned DDC-002 replay remains separate historical continuous-state evidence.
On 2026-10-15, the tracked `ddc-pri.mat` and its manifest record migrated to `independent-pri-v2` version `2.0.0`, scope `temporary-unit-evidence`, revision `working-tree`, fixture SHA `af4ed1be0ffe0db230d8e6f825014b8fd7bd7aae12940a286d155b1e4c6776f4`.
Of 25 tracked fixture artifacts, only `ddc-pri.mat` changed; the other 24 are unchanged, including all 23 historical artifacts and `ddc-response-pri.mat`.

Current v2 checks passed: DDC suite 40/40, WP4 suite 56/56, live analytic check, fresh strict fixture check 56/56 with `provenanceValid=true`, corrected tracked strict fixture check 56/56 with `provenanceValid=true`, and Code Analyzer with no issues in all six edited MATLAB files.
The v1 analytic baseline comparison fails at normalized error `0.500862525049793`, as expected for the uncorrected profile.
The prior v1 continuous-reference result remains `3.34852e-11` against the unchanged helper; the v2 regression divides compensated output by two before that helper.
Walkthrough passed 1/1; full-scan processed 147 PRIs, skipped four transition gaps, and produced 843,825 outputs.
Independent validation of this temporary-unit evidence passed on 2026-10-15 with no unresolved errors.
The reviewer independently ran analytic and historical comparisons 2/2, WP4 per-PRI 1/1, and tracked strict fixtures 56/56 with `provenanceValid=true`; the reviewer also verified profile v2 and the 24 unchanged fixture artifacts.
Full suites and Code Analyzer results were reviewed from upstream evidence, not rerun.
This does not record human approval or merge authorization.
The [per-PRI implementation plan](docs/plans/ddc-pri-processing.md) records the bounded tolerance and evidence scope.

Historical approval before the current refactor: The one-PRI walkthrough is approved, and the issue 6 coverage blocker and three standards warnings were resolved and independently validated. That approval predates the current chirp update and does not approve the current walkthrough.

The initial one-PRI walkthrough refactor is complete. It explains the public API boundary, processing chain, units, rates, dimensions, factor-two compensation, startup, timing, expected spectral movement, plots, and evidence limits.
Baseline and final `TestDdcWalkthrough` each passed 1/1. The implementation run processed 147 PRIs, skipped four transition gaps, produced 843,825 outputs, and reported 7,353 output samples with a 999.5 kHz spectral peak for one PRI. MATLAB Code Analyzer reported no issues in the edited MATLAB source.
Independent MATLAB validation of the preceding tone-based Live Script revision passed on 2026-10-17: `TestDdcWalkthrough` 1/1, including 147 PRIs, four transition gaps, and 843,825 outputs; MATLAB Code Analyzer returned `code_issues=[]`. This validates that revision's walkthrough check and analyzed source only; it does not establish full-CPI, end-to-end detection, hardware performance, or merge approval.
On 2026-10-17, the same-path `.m` walkthrough was converted to an R2025a+ plain-text Live Script with structured output tables, dB spectra, and docked figures. The exclusive final walkthrough check passed 1/1 and Code Analyzer returned `code_issues=[]`. MATLAB's dock container adjusted the requested `[1 1 1100 750]` figure position to `[1 1 1103 738]` on the validation host; exact dock-pane geometry is host-controlled.
The 999.5 kHz peak above belongs to the historical tone-based walkthrough. The previous chirp revision centered at 51 MHz and swept 48.5 to 53.5 MHz with one undesired 70 MHz interferer. `TestDdcWalkthrough` passed 1/1; early and late median frequency errors measured +0.04978 kHz and +0.028628 kHz, within the 2 kHz bound. The check also covered 147 PRIs, four transition gaps, and 843,825 outputs. Code Analyzer returned `code_issues=[]` for the walkthrough and test source. The single interferer demonstrates one rejection path only; the response metric provides broader alias-rejection evidence.
Independent MATLAB validation of the chirp revision passed 1/1 with zero failed or incomplete tests. The independent early and late median frequency errors were 49.780 Hz and 28.628 Hz; Code Analyzer reported no issues in both edited MATLAB files.
The preceding noiseless chirp revision was centered at 50 MHz and swept 47.5 to 52.5 MHz, yielding −2.5 to +2.5 MHz output around DC. `TestDdcWalkthrough` passed 1/1; early and late median frequency errors were +0.044415 kHz and −0.060731 kHz. Code Analyzer reported no issues in the walkthrough or test source. These are implementation checks; root review covered the local parameter change, diff, and reported test evidence. Human walkthrough review remains in progress.
The current stimulus adds 100 ADC-count RMS zero-mean Gaussian noise before quantization, using local `mt19937ar` seed 17. This is illustrative synthetic noise, not a calibrated receiver or hardware model; no SNR estimate is claimed. The final `TestDdcWalkthrough` passed 1/1; realized noise RMS was 99.7291 counts and peak absolute ADC input was 21,768.813 counts, below the 32,767-count `int16` limit. Mean early and late output-frequency errors over the original windows were −5.565 Hz and +89.961 Hz, within the 2 kHz bound. MATLAB Code Analyzer returned `code_issues=[]` for the walkthrough and test source. These are implementation checks; root review covered the local stimulus change, diff, and reported test evidence. Human walkthrough review remains in progress.
On 2026-10-17, Julio accepted [ADR 0024](docs/adr/0024-require-plain-text-matlab-live-script-walkthroughs.md), requiring every project walkthrough to be an executable plain-text R2025a+ MATLAB Live Script `.m` file. Companion Markdown remains supplementary. Existing nonconforming walkthroughs require conversion; no repository-wide audit, migration completion, or schedule is recorded.

## 2026-10-26 — Owner diagram acceptance and PR merge authorization

Julio stated that the architecture diagrams look good and instructed the agent to commit, push, and accept PR #17.
The reviewed diagrams were at PR head `460656c8c54118d5a2d52af20dc60e7eb45d42b3`; owner visual acceptance is distinct from independent technical verification.
The full-branch Standards and Spec reviews remained incomplete, with MATLAB source review blocked by Graphify's missing MATLAB extractor.
No fresh MATLAB execution, formal gate advancement, or complete receiver verification is established by this authorization.

The superseded active-status wording was:

> The handoff records Julio's satisfaction with the implementation and authorization to publish PR #17; neither constitutes merge authorization or approval of the separate architecture diagrams.
> The PR is now under code review against `main`; its Standards and Spec reviews are incomplete, with MATLAB source review blocked by Graphify's missing MATLAB extractor.
> PR code review is incomplete. Visual review of the redrawn architecture diagrams remains pending.
> Merge authorization is not recorded.
> Complete PR code review and the pending visual review before requesting merge authorization, then review the range-component boundary under human-led development step 5.
