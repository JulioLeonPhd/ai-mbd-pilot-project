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

AI-infrastructure development is frozen until radar v1 under [ADR 0023](docs/adr/0023-freeze-ai-infrastructure-until-v1.md).
Product delivery takes priority; existing infrastructure may receive defect fixes or minimal maintenance only when needed to unblock or materially support v1.
The [v1 delivery action plan](docs/plans/v1-delivery-action-plan.md) records the working sequence.

Human implementation review and current walkthrough review are in progress. Visual review of the redrawn architecture diagrams remains pending.
Merge authorization is not recorded.

Complete the current walkthrough and visual reviews before authorising merge, then review the range-component boundary under human-led development step 5.
The DDC evidence does not establish full-receiver or hardware performance, and the historical WP4 continuous-state evidence remains separate from per-PRI acceptance evidence.

See [HISTORY.md](HISTORY.md) for archived status snapshots.
