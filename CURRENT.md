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
