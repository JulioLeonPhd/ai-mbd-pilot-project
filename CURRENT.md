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
