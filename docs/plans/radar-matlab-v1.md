# Floating-point radar demonstrator V1

## Summary

This plan defines the first reproducible floating-point MATLAB reference, from
generated ADC test vectors to detection list. MATLAB MCP is available for the
quantitative feasibility studies. Numerical parameters remain provisional until
WP2 produces evidence.

## Documents and interfaces

- Create tracked `CURRENT.md` with the last verified result, active gate,
  blockers, next ready packages, and evidence links. Update it whenever a
  package or gate changes.
- Write versioned requirements specification with stable IDs and verification
  links. Specifications define required behavior; ADRs explain consequential
  choices and their reasons.
- Record V1 clarification to ADR 0009: report Monte Carlo Pd/Pfa estimates
  and confidence bounds, but do not make numeric Pd/Pfa targets V1 pass
  gates. Preserve its other accepted requirements.
- Define versioned configuration, scenario, MAT test-vector,
  intermediate-processing, and detection-list contracts. Intermediate
  contracts must support independent unit-test fixtures for every WP6 stage.
- Expand DSP architecture with DUT-boundary, data-shape/processing, and
  timing/PRF/blanking diagrams. Freeze stable stage interfaces and fixture
  seams at G2; leave internal CFAR, clustering, association, and
  ambiguity-resolution order to WP6e selection.

## Work packages and gates

Days are indicative working days from plan acceptance. Parallel packages use
separate file ownership and contract fixtures; recalibrate schedule after
feasibility.

<!-- markdownlint-disable MD013 -->

| Package | Window | Predecessor | Deliverable and exit gate |
| --- | --- | --- | --- |
| WP0 — Baseline and tracking | D1–2 | None | Save this plan, create `CURRENT.md`, and prepare issues with blockers and acceptance criteria. **G0:** scope and status sources agree. |
| WP1 — Requirements | D3–7 | WP0 | Specification, requirement-to-evidence matrix, accepted versus provisional goals, and V1 Pd/Pfa decision record. |
| WP2 — Quantitative feasibility | D3–10 | WP0; parallel with WP1 | MATLAB MCP-backed link budget, waveform/sampling, PRF ambiguity coverage, beam/angle, and timing studies. **G1, with WP1:** approve feasible baseline or stop for documented decision. |
| WP3 — Data contracts | D11–15 | G1 | Versioned contracts, examples, and conformance checks. |
| WP4 — DSP architecture | D11–16 | G1; parallel with WP3 | Stage order, dimensions/rates, fixture seams, ambiguity-selection criteria, and diagrams. WP4 selects and verifies `[22,25,28,32,35]` usable pulses under the 70.653 ms cell-time cap at G2; downstream WP6e may reject schedule and reopen G2. **G2, with WP3:** independent review finds no unresolved errors or contract conflicts. |
| WP5 — Stimulus and fixtures | D17–24 | G2 | Seeded JSON-driven generator emitting direct 150 MS/s real ADC vectors at 50 MHz IF, with exact ADR 0015 carrier-derived Doppler and array phase present in generated IF samples. |
| WP6 — Reference processing | D17–38 | G2; split below | Independently tested processing stages and ambiguity-resolution decision. |
| WP7 — Detection and reports | D17–25 | G2; parallel with WP5 and WP6 | CA-CFAR, near-zero-Doppler handling, clustering, and report formatting against synthetic fixtures. **G3:** each implementation package passes focused tests and contract checks. |
| WP8 — Integration and verification | D39–50 | WP5, all WP6 subpackages, WP7 | End-to-end seeded runs and independent numerical review. **G4:** no unresolved validation errors; measured performance and limitations are reported. |
| WP9 — Documentation and handoff | D51–54 | G4; drafting may begin after G2 | Reproduction guide, evidence index, limitations, updated `CURRENT.md`, and fixed-point/Simulink handoff. **G5:** Markdown lint, diagram rendering, and semantic review pass. |

### WP6 unit-test gates

Each subpackage delivers source, focused `matlab.unittest` tests, MCP Code
Analyzer evidence, and passing G3 sub-gate. Synthetic inputs conform to the
G2 contracts, allowing independent work.

| Subpackage | Window | Predecessor | Unit-test acceptance |
| --- | --- | --- | --- |
| WP6a — DDC and decimation | D17–22 | G2 | Known 150 MS/s ADC tones at 50 MHz IF produce 50 MS/s complex after /3 and 12.5 MS/s complex after /4, with agreed frequency, amplitude, phase, dimensions, and anti-alias behavior; evaluate complex mixing and staged filtering. |
| WP6b — Range processing | D23–29 | WP6a | Known LFM echoes map to calibrated range bins; ideal and sampled high-SNR fixtures preserve two peaks separated by 50 m using candidate narrowband waveform. |
| WP6c — Single-PRF Doppler processing | D30–35 | WP6b | Known approaching/receding velocities give correct bin and sign, and unit tests prove native unambiguous interval of at least ±40 m/s. |
| WP6d — Receive angle processing | D17–26 | G2; parallel with WP6a–c | Synthetic 16×4 data gives correct commanded-look summation (16 azimuth elements per elevation row), four-stream dimensions, boresight, and specified elevation signs. Sub-beam azimuth estimation is out of V1. |
| WP6e — Range/velocity ambiguity study | D17–27 | G2; parallel with WP6a–d | Compare executable candidates against known folded cases through ±800 km/h, range aliases, competing targets, and inconsistent measurements. Record failed candidates and evidence. **Selection gate:** one candidate passes agreed cases; otherwise stop dependent work; root records failed-candidate evidence in WP6e report and `CURRENT.md`, reopens affected G1/G2 gate, routes WP2/WP4/contract or ADR revision as needed, reruns corresponding independent review, and resumes only after gate passes. |
| WP6f — Ambiguity-resolution implementation | D28–38 | WP6e | selected method passes independent tests using synthetic per-PRF candidate lists, including alias boundaries and documented ambiguous-input behavior. |

### WP6b range-acceptance planning

Issue #23 remains open; these approved acceptance definitions guide a bounded reference-only design study, not production implementation or acceptance evidence.

The mandatory gates are independent: range calibration, complex gain/phase fidelity, 50 m two-target separation, and complete-window validity, with no compensation between a failed gate and a passing one.

| Area | Approved criterion or convention | Boundary or pending choice |
| --- | --- | --- |
| Calibration | Known delays map to the correct range coordinates, with on-grid lag/index behavior and caller-owned exactly-once DDC delay correction kept distinct from off-grid localization and physical Doppler bias. | Follow ADRs 0025 and 0026; do not create a new API. |
| Complex fidelity | For an isolated aligned matched echo, recover known complex amplitude within a justified numerical budget and compare complex output at every valid public lag against an independently implemented direct time-domain correlation from the approved definition. | Use absolute complex error near nulls; phase is meaningful only away from zero. Mismatch, off-grid effects, and sampled-DDC departures are not pure numerical error; the known signal component supports calibration and fidelity, with no separate noise-free separation gate. Numerical tolerances remain pending. |
| Two-target separation | Test ideal-reference and sampled-DDC paths under noisy high-SNR conditions. In each case, both complete echo windows, both distinct magnitude local maxima, and the intervening valley must be valid; each peak must be within one output range bin (about 12 m) of its true range and the valley at least 3 dB in power below the smaller peak. | Physical stimulus spacing is exactly 50 m; measured peak spacing need not be quantized to exactly 50 m. Invalid zeros are not valley evidence. No automatic threshold relaxation, replacement case or seed, or weighting is allowed after a required case fails. |
| Fixture matrix | Use one common RCS for both targets, all cases, streams, and paths, preserving range-dependent received amplitude; derive it from explicit radar-equation assumptions to meet the weaker-target condition at the farthest tested placement and verify the worst processing response. Place the pair near the configured detection-interval midpoint with complete windows valid. | The 6.8–100 km example and 53.4 km midpoint are illustrative, not new domain limits. Do not independently normalize cases, streams, or targets. RCS value and explicit assumptions are for the future study, not benchmark results. |
| Offsets and phase | Use nearer-target fractional-bin offsets 0, 1/4, 1/2, and 3/4; keep the second target physically 50 m farther rather than independently snapping it. Test relative input echo phases 0, 90, 180, and 270 degrees, giving 16 combinations per path, and shared 20 m/s radial velocity for range-compressor fixtures. | Document sign convention and phase epoch; exact phase-epoch implementation remains a study convention. Dense phase sweep is deferred to V1 integration verification and is not exhaustive evidence. Doppler-induced range bias is distinct from coordinate error. |
| Noise and SNR | The reference is at least 30 dB estimated post-compression SNR for the weaker target in every evaluated stream; report input SNR separately, without a 30 dB input-SNR requirement. Use the weaker target's isolated compressed peak power at its signal-only selected bin as numerator, then assess separation on the combined signal-plus-noise response. | Reconcile the existing high-input-SNR requirement wording traceably with the approved post-compression reference; requirement text has not changed. “High enough” refers to intended detection purpose, not equivalence of input and output SNR. |
| Noise estimate | Use one fixed-seed noise-only record per path with the same chain and noise settings; estimate mean output-noise power over a declared stationary, complete-window-valid interior region and reuse it across cases only while settings are unchanged. | This simplified stationary-noise estimate is not a statistical lower-bound guarantee. It replaces the earlier covariance and fixed-size per-bin ensemble proposal; covariance propagation, K=4096, confidence-bound calculations, and a separate numerical ensemble are not approved requirements. Noise-only seed IDs are not selected; the three fixed separation seeds are distinct in purpose. |
| Sampled-path noise and scale | Represent receiver noise as seeded zero-mean real Gaussian noise in the ADC-rate stimulus, bandlimited to 45–55 MHz and its negative-frequency mirror, before quantization and DDC. Use one physical-power-to-ADC-counts scale across the matrix, with no clipping in evaluated realizations, and report quantization and headroom. | This is not a calibrated full analog receiver model; bandlimited baseband noise need not be white. The scale and quantizer conventions must be documented before execution and are fixture assumptions, not hardware calibration. No physical absolute ADC scale is selected. |
| Gain assumptions | The illustrative ADR 0011 budget is 10 kW peak, 23 dBi transmit and receive, 6 dB loss, 4 dB noise figure, and 290 K. The selected 23 dBi receive gain is the effective gain of one beamformed elevation-row aperture, with azimuth-array receive gain already included. | Do not add another 16-element gain, four-row combining, slow-time integration bonus, or double-count range-compression gain. These are simulation assumptions, not hardware claims; surface missing or inconsistent assumptions rather than inventing them. |
| Width and tolerances | Distinguish nominal bandwidth-derived range-resolution scale from measured mainlobe width and separability. Isolated compressed-response power FWHM is the distance between half-peak-power crossings, approximately −3 dB, linearly interpolated between sampled crossings and reported as a sampled-response width estimate for diagnosis only. | FWHM is not an additional pass gate. Propose separate justified budgets for FFT/direct floating-point comparison, coordinate arithmetic, physical peak localization, and complex response; do not substitute an unrelated DDC bound or arbitrary shared epsilon. One-bin association and 3 dB valley are approved, while final correlation, complex gain/phase, and coordinate numerical tolerances remain pending. |

The direct-correlation oracle must not share production FFT or lag-alignment helpers.

Three fixed documented noise seeds apply to separation; every required case must pass, with no retry or reseeding, and this is neither a probability-of-detection claim nor exhaustive statistical evidence. Hamming is only a possible future experiment, not authorized, planned, or presumed beneficial for V1; the existing unweighted reference remains the baseline.

The bounded reference-only MATLAB study is authorized for a future session only; it may evaluate the approved ideal and sampled fixtures, matrix, and seeds, derive RCS, report SNR, headroom, and quantization, measure localization, valley, and FWHM, compare independent direct and reference FFT correlation, and propose justified numerical tolerances for Julio's later approval. Do not execute the study, simulation, acceptance suite, or production implementation in the current session; missing fixture conventions must be explicit before execution, fixed separation limits must not be tuned to pass, and no study result exists from this session.

Use the configured carrier and waveform with an explicit noise reference in the study; use the applicable AWGN skill's explicit power conventions without allowing instantaneous measured signal power to retune receiver noise by target or case.
The next authorized action is preparation and execution of this scoped study in a future session, followed by human review of proposed tolerances; it does not resolve #23 or advance a gate.
<!-- markdownlint-enable MD013 -->

WP7 may use synthetic resolved candidates, while WP6f may use synthetic
per-PRF candidates; neither waits for the other’s code. WP8 proves that real
outputs compose correctly.

## V1 acceptance and assumptions

WP8 verifies reproducibility, contracts, coordinate and velocity signs, the
100 km, 10 m², common scan-midpoint primary case at approximately 800 km/h,
including
motion and range migration across CPI; ideal 50 m two-target case,
velocity-separated and unfolded cases, detection-list fields, and invalid
inputs. Monte Carlo results include seeds, trial counts, confidence method,
estimates, and bounds; numeric Pd/Pfa targets do not block V1.

MATLAB calculations and plots run through MCP. MATLAB source passes MCP Code
Analyzer; touched Markdown passes `markdownlint-cli2`, and diagrams render with
`mmdc`. available installation lists Signal Processing Toolbox and DSP
System Toolbox, but not Radar Toolbox or Phased Array System Toolbox; WP2 must
flag any design that depends on unavailable product.
