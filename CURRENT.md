# Current work

Range-component boundary review is the active milestone within human-led development step 5, on `component/range-processor`.
Julio authorized the status transition and range-processing brief review on 2026-10-26 after reporting PR #17 merged.
WP6b is the roadmap mapping; no formal work-package or gate assignment, new range architecture decision, or range implementation authorization is recorded.

The merged DDC baseline is independent per-PRI processing with the sample-only API and fixed factor-two final-output compensation.
Its recorded implementation checks and independent numerical validation passed; see the [DDC evidence ledger](docs/plans/ddc-pri-processing.md#independent-pri-v2-migration-and-verification-2026-10-15).
Julio accepted the architecture diagrams on 2026-10-26.
The full-branch Standards and Spec assessments remain incomplete; MATLAB source review was blocked by Graphify's missing MATLAB extractor.
These results do not establish full-receiver or hardware performance, and historical continuous-state evidence remains separate.

The range brief review uses the [WP6b acceptance criteria](docs/plans/radar-matlab-v1.md#wp6-unit-test-gates), [current data contracts](docs/contracts/radar-v1-data-contracts.md), and [approved responsibility boundaries](docs/adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md).
Range processing follows commanded-look azimuth beamforming and precedes separate pulse accumulation/range-migration handling and Doppler processing.
The four complex elevation streams and calibrated range-bin coordinates are baseline requirements; the batch range seam does not settle a streaming public API.
Range processing owns complete-window validity through DDC startup, blanking, and PRI-end truncation; the caller owns one-time DDC group-delay coordinate mapping.

Next, review with Julio the range algorithm and reference waveform, per-call granularity and API, timing/range origin, complete-window validity representation, and amplitude normalization.
The acceptance brief requires calibrated LFM echo locations and ideal and sampled high-SNR two-peak separation at 50 m; full two-report acceptance remains WP8 work.
No new API, numerical tolerance, filter implementation, compensation algorithm, or ambiguity method is approved by this review.
After those choices are approved, prepare the executable plain-text MATLAB Live Script walkthrough and implementation/evidence work under the component workflow.

AI-infrastructure development remains frozen until radar v1 under [ADR 0023](docs/adr/0023-freeze-ai-infrastructure-until-v1.md).
[ADR 0024](docs/adr/0024-require-plain-text-matlab-live-script-walkthroughs.md) requires executable R2025a+ plain-text `.m` walkthroughs; no repository-wide migration completion is recorded.
See [HISTORY.md](HISTORY.md) for the complete outgoing DDC status and [delivery priorities](docs/plans/v1-delivery-action-plan.md) for the working sequence.
