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

## 2026-10-26 — DDC merge to range-component boundary review

Outgoing work package: No formal assignment recorded.
Outgoing gate: No formal assignment recorded.
Outgoing milestone: Per-PRI DDC processing within human-led development step 4.

Julio reported PR #17 merged and authorized the transition to range-component status and brief review on `component/range-processor`.
This starts a component-review milestone, not implementation authorization or formal gate advancement.

<!-- markdownlint-disable MD025 -->
<!-- BEGIN verbatim CURRENT.md snapshot -->
# Current work

Per-PRI DDC processing is the active milestone within human-led development step 4.
No formal work-package or gate assignment is recorded.

Julio approved independent per-PRI processing, the sample-only API and responsibilities, and implementation.
On 2026-10-14, he approved fixed factor-two compensation on the final decimated output to restore real-cosine peak envelope amplitude, subject to FIR gain and phase response and residual image.
It keeps input units, doubles noise amplitude, and does not improve SNR or claim calibrated volts.
FIR coefficients and response metrics, delay, startup span, state, shapes, and API remain unchanged.

The compensated `independent-pri-v2` implementation and its temporary-unit evidence passed the recorded implementation checks and independent numerical validation.
The [migration and verification ledger](docs/plans/ddc-pri-processing.md#independent-pri-v2-migration-and-verification-2026-10-15) records fixture identity, measured results, reviewer execution scope, and limitations.
Historical `independent-pri-v1` and pinned DDC-002 continuous-state evidence remain separate.

The current walkthrough demonstrates a noisy chirp through the public per-PRI API, including units, rates, amplitude compensation, startup, and caller-owned timing.
Its recorded walkthrough check passed 1/1 and Code Analyzer reported no issues; these are implementation checks, not end-to-end receiver evidence.
Earlier walkthrough results and superseded review wording are preserved in [history](HISTORY.md#2026-10-26--ddc-status-evidence-consolidation).
Julio confirmed the architecture diagrams look good on 2026-10-26 and authorized committing, pushing, and accepting PR #17.
The reviewed diagrams are those at PR head `460656c8c54118d5a2d52af20dc60e7eb45d42b3`; this closes owner visual review, not the incomplete full-branch Standards and Spec assessments.
MATLAB source review remains blocked by Graphify's missing MATLAB extractor; no fresh MATLAB execution is claimed.

[ADR 0024](docs/adr/0024-require-plain-text-matlab-live-script-walkthroughs.md) requires executable R2025a+ plain-text MATLAB Live Script `.m` walkthroughs; companion Markdown is supplementary.
No repository-wide walkthrough migration completion is recorded.

AI-infrastructure development is frozen until radar v1 under [ADR 0023](docs/adr/0023-freeze-ai-infrastructure-until-v1.md).
Product delivery takes priority; existing infrastructure may receive defect fixes or minimal maintenance only when needed to unblock or materially support v1.
The [v1 delivery action plan](docs/plans/v1-delivery-action-plan.md) records the working sequence.

Owner visual review and merge authorization are recorded; full-branch code review remains incomplete.
Complete the authorized PR publication and merge, retaining that limitation in the PR record, then review the range-component boundary under human-led development step 5.
The DDC evidence does not establish full-receiver or hardware performance, and the historical WP4 continuous-state evidence remains separate from per-PRI acceptance evidence.

See [HISTORY.md](HISTORY.md) for archived status snapshots.
<!-- END verbatim CURRENT.md snapshot -->
<!-- markdownlint-enable MD025 -->

## 2026-10-28 — Range-study active status update

Routine within-milestone update; no new formal work package or gate assignment.
The following outgoing active-status passages are preserved verbatim because the range-review focus changed after authorization of the study.

Range-component boundary review is the active milestone within human-led development step 5, on `component/range-processor`.
Julio authorized the status transition and range-processing brief review on 2026-10-26 after reporting PR #17 merged.
WP6b is the roadmap mapping; no formal work-package or gate assignment is recorded, and range implementation remains unauthorized. Range design decisions #19–#22 are approved; #23 remains open for acceptance-criteria resolution.

The following additional outgoing study-planning paragraphs are preserved verbatim before replacing them with the completed evidence status:

Julio approved the range-acceptance definitions now recorded in [ADR 0027](docs/adr/0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md). The independent mandatory gates, fixed unweighted reference, four-stream/per-PRI contracts, one-bin peak association, 3 dB valley, approved fixture matrix, and estimated post-compression SNR reference are settled; final correlation, coordinate, and complex gain/phase tolerances, common RCS, and numerical-study evidence remain pending. The high-input-SNR wording is reconciled in [RAD-V1-006](docs/requirements/radar-matlab-v1.md#RAD-V1-006): report input SNR separately, while the range-fixture criterion is at least 30 dB estimated post-compression SNR for the weaker target in each evaluated stream. This is not by itself proof of the WP8 two-report obligation.

The [Define range acceptance criteria](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23) decision remains open. The future-session study in [Establish numerical evidence for range acceptance](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24) is its prerequisite, not blanket production authorization. No study, simulation, production implementation, or acceptance evidence was produced in this session. After the study, Julio must review and approve remaining tolerances, then record a resolution comment before the decision can close; study completion alone does not advance a gate.

## 2026-11-13 — Range-acceptance evidence and production component review outgoing status

Outgoing work package: No formal assignment recorded.
Outgoing gate: No formal assignment recorded.
Outgoing milestone: Range-acceptance evidence and review of the authorized MATLAB `processPri` range-compression component within human-led development step 5 on `component/range-processor`.

This entry preserves the complete outgoing `CURRENT.md` verbatim before starting the OMP-native orchestration simplification milestone.

<!-- markdownlint-disable MD025 -->
<!-- BEGIN verbatim CURRENT.md snapshot -->
<!-- markdownlint-disable-next-line MD024 -->
# Current work

Range-acceptance evidence remains the active milestone within human-led development step 5 on `component/range-processor`.
On 2026-11-09, Julio selected a candidate ideal point-target scenario with actual echo RCS 200 m² at a 20 km midpoint; this records a scenario choice, not a representative aircraft RCS or production requirement. The [issue 24 approval record for the earlier reference-only study](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6474237580) remains applicable to that study; no formal work-package or gate assignment is recorded.
The exact candidate runner is archived at `evidence/range-20km-200m2/range_acceptance_study.m` with SHA-256 `c4ff98bb4b3d154e55ba6bb286a5e4457bdc6981044f6c00406b2b0d9405a707`; the same-basename copy is deliberately frozen for provenance, not a second production algorithm. On 2026-11-10, root replayed it in MATLAB R2026a Update 5 (PID 18062): all 384/384 stream evaluations passed, and recursive comparison against the candidate golden JSON found only the expected `report_path` leaf difference. Code Analyzer reported no issues. The generated nested JSON output was removed after comparison; see the durable replay section in the [evidence report](docs/research/range-acceptance-evidence.md#durable-candidate-replay).

The replay preserves its recorded repository root; exact path reproduction therefore requires that environment. A different checkout path requires an explicit root-path edit, changing the runner hash but not the physical constants. The 200 m² / 20 km candidate replaces the configured-interval midpoint and derived-RCS fixture only for the bounded current decision; the historical derivation and its labels remain unchanged.

The merged DDC baseline is independent per-PRI processing with the sample-only API and fixed factor-two final-output compensation.
Its recorded implementation checks and independent numerical validation passed; see the [DDC evidence ledger](docs/plans/ddc-pri-processing.md#independent-pri-v2-migration-and-verification-2026-10-15).
Julio accepted the architecture diagrams on 2026-10-26.
The full-branch Standards and Spec assessments remain incomplete; MATLAB source review was blocked by Graphify's missing MATLAB extractor.
These results do not establish full-receiver or hardware performance, and historical continuous-state evidence remains separate.

The range brief review uses the [WP6b acceptance criteria](docs/plans/radar-matlab-v1.md#wp6-unit-test-gates), [current data contracts](docs/contracts/radar-v1-data-contracts.md), and [approved responsibility boundaries](docs/adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md).
Range processing follows commanded-look azimuth beamforming and precedes separate pulse accumulation/range-migration handling and Doppler processing.
The four complex elevation streams and calibrated range-bin coordinates are baseline requirements; the batch range seam does not settle a streaming public API.
The decisions in issues #19–#22 define the approved processing contracts; Julio's separate 2026-11-12 authorization permits implementation only within the MATLAB `processPri` component.

Julio approved complete-window eligibility on 2026-10-26: lag `k` requires all 500 input samples from `k` through `k+499`, inclusive, to be valid; a contiguous valid interval `[a,b]` permits `a <= k <= b-499`. Zeros do not imply invalidity, and coordinate correction does not recover missing samples. See the [#21 partial resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425156364).
Julio also approved retaining the full lag grid with an authoritative validity mask, noting that omitting bins would complicate Simulink integration; see the [#21 output-representation resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425209343).
Invalid bins contain complex zero with false mask entries, as [approved by Julio](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425238650); valid bins may also contain zero, and consumers must respect the mask.
Julio approved an explicit caller-supplied Boolean input-validity mask aligned with the input samples; see the [#21 final resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425272561). The caller marks blanked, DDC-startup-invalid, and unavailable supplied samples invalid. Entire correlation windows must exist within the supplied PRI and contain only valid samples; FFT padding cannot create validity. Issue #21 is closed.
Julio approved per-stream Boolean masks in [#22](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/22#issuecomment-6425321892): input `[sample,4]` and output `[rangeBin,4]`, matching their complex sample arrays. Complete-window eligibility applies independently per stream.
Julio confirmed the complete public API after the grilling interview; see the [#22 final resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/22#issuecomment-6425810353). Issue #22 is closed. The approved entry point is `radardemo.rangeCompression.processPri(inputSamples, inputValid, cfg)`, returning complex samples and metadata containing only `valid` and `rangeBinCentersM`.

Julio approved the range-acceptance definitions in [ADR 0027](docs/adr/0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md), including independent gates, fixed unweighted reference, four-stream/per-PRI contracts, one-bin association, 3 dB valley, fixture matrix, and estimated post-compression SNR reference. On 2026-11-09 he also approved the binary64 correlation, guarded-phase, aligned-recovery, and coordinate budgets solely as engineering criteria for the 200 m² point-target candidate at the 20 km midpoint. They are not universal proven bounds, hardware acceptance, production authorization, or gate advancement. The historical derived common RCS remains unapproved.

The original reference-only study and independent numerical review are complete within their recorded scopes. The separate candidate result records 384/384 passing stream evaluations and the candidate-specific observations in the [candidate evidence JSON](evidence/range-20km-200m2-feasibility.json); an independent deep numerical review examined 96 unique cases / 384 gated evaluations from stored records and reported no errors or technical blocker within scope. The unchanged physical gates remain one-bin peak association, valid 3 dB valley, and 30 dB estimated post-compression SNR. RAD-V1-006's 30 dB condition remains distinct from WP8's two-report obligation.

Earlier study reports and historical JSON retain their original observations and approval labels; the later approval does not rewrite them. The root-side coordinate check covered 7,353 values per path in JS binary64 with maximum residual/budget ratios 0.062455592152661873 (ideal) and 0.06176666066598693 (sampled), zero violations; this was not a MATLAB rerun or stored pointwise MATLAB proof.

On 2026-11-12, Julio explicitly authorized production implementation of the approved MATLAB `processPri` range-compression component; this authorization is limited to that component and does not advance a gate or authorize Simulink, hardware acceptance, or broader receiver claims.
The active milestone remains range-acceptance evidence within human-led development step 5 on `component/range-processor`, with no formal work-package or gate assignment recorded.
The public API, implementation, focused tests, and executable walkthrough are present at `radardemo.rangeCompression.processPri`, `src/+radardemo/+rangeCompression/processPri.m`, `tests/rangeCompression/TestProcessPri.m`, and `examples/runRangeCompressionWalkthrough.m`.
In MATLAB R2026a Update 5 (PID 75572), the focused API suite passed 26/26 tests, and Code Analyzer reported no issues for the implementation, tests, walkthrough, or production acceptance runner.
The walkthrough executed with a maximum aligned complex residual of `1.8209e-14`; its narrative and equations were inspected as browser-rendered source-only content without embedded outputs, and its plot was separately observed.
The production runner `tests/rangeCompression/runRangeProductionAcceptance.m` completed with 96/96 records and 384/384 stream evaluations passing all fixture-scoped physical gates; correlation, validity, and peak self-checks passed.
All 32 coordinate records passed the tolerance check, with a maximum residual-to-budget ratio of `0.062455592152661873`; the runner report is `tests/rangeCompression/range-production-acceptance-results.json`.
The independent deep numerical review completed with no unresolved errors in its assigned scope after inspection of source, tests, oracle, runner, and regenerated JSON; root executed MATLAB, and the reviewer did not independently execute MATLAB.
Independent documentation review also found no errors within scope; human walkthrough/component review was the next step at that checkpoint and was not implied by those results.
The accepted contracts remain in [ADR 0025](docs/adr/0025-adopt-range-compression-numerical-and-validity-contract.md) and [ADR 0026](docs/adr/0026-adopt-per-pri-range-compression-api.md), with fixture-scoped criteria in [ADR 0027](docs/adr/0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md).
Simulink Boolean ports, boundary conversion, scheduling, and downstream ambiguity choices remain outside this authorization.
Historical reports and evidence retain their original observations and approval labels.

Julio authorized the walkthrough and portable teaching-skill revisions following his review.
The first revision had 13 numbered sections, pre-call analytical expectations, separate four-stream dB and I/Q panels, and explicit validity interpretation.
The final source executed successfully in MATLAB R2026a batch mode (PID 56148), preserving all three figures; aligned complex residual was `1.8209e-14`, and shape, mask, and zero-semantics assertions passed.
Code Analyzer reported no issues; all 31 equations passed KaTeX checks before and after HTML escaping, and the exported source-only HTML and actual figures were visually inspected.
Independent numerical, narrative, and portable-skill reviews found no unresolved errors; reviewers inspected sources rather than independently executing MATLAB.
At that check, fresh output embedding failed twice because nested Live Editor execution was unsupported; the source then contained no embedded outputs, and native Live Editor appearance remained unverified.
At that checkpoint, Julio's human walkthrough delivery review remained pending; the checks did not advance the milestone or gate, and the earlier production-suite evidence was not rerun.

Following Julio's delivery feedback, the walkthrough now has a fourteenth section identifying its local path-management helper, horizontal reference labels, requested 1000-by-900-pixel panel canvases, and explicit dimensionless amplitude/dB-reference labels.
Prior-run embedded outputs subsequently present in the file were preserved; they have not been refreshed for these presentation changes.
The portable skill now covers helper sections, honest synthetic units, readable annotations, and canvas-sizing limitations.
The presentation-only changes leave the public API and processing unchanged.
The final presentation source ran successfully in MATLAB R2026a batch mode (PID 66784): eight horizontal annotations, three retained figures, both requested canvas sizes, and aligned-response assertions passed.
Fresh exported magnitude and I/Q figures were visually inspected; Code Analyzer reported no issues, 32 inline expressions passed both KaTeX pipelines, and independent source review found no unresolved errors.
Julio subsequently approved the walkthrough, completing its human delivery review.
This approval applies to the walkthrough only; it does not establish component acceptance or advance a broader gate.
Julio subsequently also approved the MATLAB `processPri` range-compression component, completing its human component review.
Both the component and its walkthrough are now human-approved within the recorded MATLAB scope; this does not authorize Simulink integration, hardware acceptance, broader receiver claims, or advancement of an unassigned gate.

AI-infrastructure development remains frozen until radar v1 under [ADR 0023](docs/adr/0023-freeze-ai-infrastructure-until-v1.md).
[ADR 0024](docs/adr/0024-require-plain-text-matlab-live-script-walkthroughs.md) requires executable R2025a+ plain-text `.m` walkthroughs; no repository-wide migration completion is recorded.
See [HISTORY.md](HISTORY.md) for the complete outgoing DDC status and [delivery priorities](docs/plans/v1-delivery-action-plan.md) for the working sequence.
<!-- END verbatim CURRENT.md snapshot -->
<!-- markdownlint-enable MD025 -->
