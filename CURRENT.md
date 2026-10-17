# Current work

Per-PRI DDC processing is the active milestone within human-led development step 4.
No formal work-package or gate assignment is recorded.

Julio approved independent per-PRI processing, the sample-only API and responsibilities, and implementation.
On 2026-10-14, he approved fixed factor-two compensation on the final decimated output to restore real-cosine peak envelope amplitude, subject to FIR gain and phase response and residual image.
It keeps input units, doubles noise amplitude, and does not improve SNR or claim calibrated volts.
FIR coefficients and response metrics, delay, startup span, state, shapes, and API remain unchanged.

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

The one-PRI walkthrough is approved, and the issue 6 coverage blocker and three standards warnings were resolved and independently validated.

Before merge, refactor the executable walkthrough into a deliberately verbose human-review surface.
Make its processing chain, units, rates, dimensions, assumptions, factor-two compensation, startup handling, expected spectral movement, decimation, and evidence boundaries explicit.
Keep the public API as the execution boundary, but explain what each call represents and what the reader should observe instead of hiding the engineering story behind convenience calls.
Do not duplicate private production implementation in the walkthrough.

AI-infrastructure development is frozen until radar v1 under [ADR 0023](docs/adr/0023-freeze-ai-infrastructure-until-v1.md).
Product delivery takes priority; existing infrastructure may receive defect fixes or minimal maintenance only when needed to unblock or materially support v1.
The [v1 delivery action plan](docs/plans/v1-delivery-action-plan.md) records the working sequence.

Human implementation review, walkthrough refactor, and visual review of the redrawn architecture diagrams remain pending.
Merge authorization is not recorded.

Complete the walkthrough refactor and human implementation and visual reviews before authorising merge, then review the range-component boundary under human-led development step 5.
The DDC evidence does not establish full-receiver or hardware performance, and the historical WP4 continuous-state evidence remains separate from per-PRI acceptance evidence.

See [HISTORY.md](HISTORY.md) for archived status snapshots.
