# Current work

Range-component boundary review is the active milestone within human-led development step 5, on `component/range-processor`.
Julio authorized the status transition and range-processing brief review on 2026-10-26 after reporting PR #17 merged.
WP6b is the roadmap mapping; no formal work-package or gate assignment, or range implementation authorization, is recorded. Range design decisions have now been approved in #19 through #22. The next planning step is #23 for acceptance criteria.

The merged DDC baseline is independent per-PRI processing with the sample-only API and fixed factor-two final-output compensation.
Its recorded implementation checks and independent numerical validation passed; see the [DDC evidence ledger](docs/plans/ddc-pri-processing.md#independent-pri-v2-migration-and-verification-2026-10-15).
Julio accepted the architecture diagrams on 2026-10-26.
The full-branch Standards and Spec assessments remain incomplete; MATLAB source review was blocked by Graphify's missing MATLAB extractor.
These results do not establish full-receiver or hardware performance, and historical continuous-state evidence remains separate.

The range brief review uses the [WP6b acceptance criteria](docs/plans/radar-matlab-v1.md#wp6-unit-test-gates), [current data contracts](docs/contracts/radar-v1-data-contracts.md), and [approved responsibility boundaries](docs/adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md).
Range processing follows commanded-look azimuth beamforming and precedes separate pulse accumulation/range-migration handling and Doppler processing.
The four complex elevation streams and calibrated range-bin coordinates are baseline requirements; the batch range seam does not settle a streaming public API.
Approved decisions are recorded in [#19](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/19#issuecomment-6417700433) (ideal reference, correlation scaling and lag conventions) and [#20](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/20#issuecomment-6421083854) (range mapping and caller-owned exactly-once DDC delay correction). These are planning decisions, not implementation authorization.

Julio approved complete-window eligibility on 2026-10-26: lag `k` requires all 500 input samples from `k` through `k+499`, inclusive, to be valid; a contiguous valid interval `[a,b]` permits `a <= k <= b-499`. Zeros do not imply invalidity, and coordinate correction does not recover missing samples. See the [#21 partial resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425156364).
Julio also approved retaining the full lag grid with an authoritative validity mask, noting that omitting bins would complicate Simulink integration; see the [#21 output-representation resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425209343).
Invalid bins contain complex zero with false mask entries, as [approved by Julio](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425238650); valid bins may also contain zero, and consumers must respect the mask.
Julio approved an explicit caller-supplied Boolean input-validity mask aligned with the input samples; see the [#21 final resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425272561). The caller marks blanked, DDC-startup-invalid, and unavailable supplied samples invalid. Entire correlation windows must exist within the supplied PRI and contain only valid samples; FFT padding cannot create validity. Issue #21 is closed.
Julio approved per-stream Boolean masks in [#22](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/22#issuecomment-6425321892): input `[sample,4]` and output `[rangeBin,4]`, matching their complex sample arrays. Complete-window eligibility applies independently per stream.
Julio confirmed the complete public API after the grilling interview; see the [#22 final resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/22#issuecomment-6425810353). Issue #22 is closed. The approved entry point is `radardemo.rangeCompression.processPri(inputSamples, inputValid, cfg)`, returning complex samples and metadata containing only `valid` and `rangeBinCentersM`.
Proceed to #23 for measurable acceptance criteria and justified tolerances, aligned with the existing cross-component tolerance-policy decision. No numerical tolerance, filter implementation, compensation algorithm, or ambiguity method is approved by this review. These planning decisions do not authorize implementation or settle Simulink Boolean ports, boundary conversion, or scheduling. The accepted numerical, coordinate, validity, and API contracts are consolidated in [ADR 0025](docs/adr/0025-adopt-range-compression-numerical-and-validity-contract.md) and [ADR 0026](docs/adr/0026-adopt-per-pri-range-compression-api.md); implementation remains unauthorized.
After those choices are approved, prepare the executable plain-text MATLAB Live Script walkthrough and implementation/evidence work under the component workflow.

AI-infrastructure development remains frozen until radar v1 under [ADR 0023](docs/adr/0023-freeze-ai-infrastructure-until-v1.md).
[ADR 0024](docs/adr/0024-require-plain-text-matlab-live-script-walkthroughs.md) requires executable R2025a+ plain-text `.m` walkthroughs; no repository-wide migration completion is recorded.
See [HISTORY.md](HISTORY.md) for the complete outgoing DDC status and [delivery priorities](docs/plans/v1-delivery-action-plan.md) for the working sequence.
