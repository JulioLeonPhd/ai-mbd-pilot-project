# Floating-point radar demonstrator V1

## Summary

This plan defines the first reproducible floating-point MATLAB reference, from
generated ADC test vectors to a detection list. MATLAB MCP is available for the
quantitative feasibility studies. Numerical parameters remain provisional until
WP2 produces evidence.

## Documents and interfaces

- Create tracked `CURRENT.md` with the last verified result, active gate,
  blockers, next ready packages, and evidence links. Update it whenever a
  package or gate changes.
- Write a versioned requirements specification with stable IDs and verification
  links. Specifications define required behavior; ADRs explain consequential
  choices and their reasons.
- Record the V1 clarification to ADR 0009: report Monte Carlo Pd/Pfa estimates
  and confidence bounds, but do not make the numeric Pd/Pfa targets V1 pass
  gates. Preserve its other accepted requirements.
- Define versioned configuration, scenario, MAT test-vector,
  intermediate-processing, and detection-list contracts. Intermediate
  contracts must support independent unit-test fixtures for every WP6 stage.
- Expand the DSP architecture with DUT-boundary, data-shape/processing, and
  timing/PRF/blanking diagrams. Freeze stage order and interfaces at G2, while
  leaving the ambiguity-resolution candidate to WP6e.

## Work packages and gates

Days are indicative working days from plan acceptance. Parallel packages use
separate file ownership and contract fixtures; recalibrate the schedule after
feasibility.

<!-- markdownlint-disable MD013 -->

| Package | Window | Predecessor | Deliverable and exit gate |
| --- | --- | --- | --- |
| WP0 — Baseline and tracking | D1–2 | None | Save this plan, create `CURRENT.md`, and prepare issues with blockers and acceptance criteria. **G0:** scope and status sources agree. |
| WP1 — Requirements | D3–7 | WP0 | Specification, requirement-to-evidence matrix, accepted versus provisional goals, and V1 Pd/Pfa decision record. |
| WP2 — Quantitative feasibility | D3–10 | WP0; parallel with WP1 | MATLAB MCP-backed link budget, waveform/sampling, PRF ambiguity coverage, beam/angle, and timing studies. **G1, with WP1:** approve a feasible baseline or stop for a documented decision. |
| WP3 — Data contracts | D11–15 | G1 | Versioned contracts, examples, and conformance checks. |
| WP4 — DSP architecture | D11–16 | G1; parallel with WP3 | Stage order, dimensions/rates, fixture seams, ambiguity-selection criteria, and diagrams. **G2, with WP3:** independent review finds no unresolved errors or contract conflicts. |
| WP5 — Stimulus and fixtures | D17–24 | G2 | Seeded JSON-driven generator emitting direct 150 MS/s real ADC vectors at 50 MHz IF, with 3 GHz-derived Doppler and array phase present in the generated IF samples. |
| WP6 — Reference processing | D17–38 | G2; split below | Independently tested processing stages and an ambiguity-resolution decision. |
| WP7 — Detection and reports | D17–25 | G2; parallel with WP5 and WP6 | CA-CFAR, near-zero-Doppler handling, clustering, and report formatting against synthetic fixtures. **G3:** each implementation package passes focused tests and contract checks. |
| WP8 — Integration and verification | D39–50 | WP5, all WP6 subpackages, WP7 | End-to-end seeded runs and independent numerical review. **G4:** no unresolved validation errors; measured performance and limitations are reported. |
| WP9 — Documentation and handoff | D51–54 | G4; drafting may begin after G2 | Reproduction guide, evidence index, limitations, updated `CURRENT.md`, and fixed-point/Simulink handoff. **G5:** Markdown lint, diagram rendering, and semantic review pass. |

### WP6 unit-test gates

Each subpackage delivers source, focused `matlab.unittest` tests, MCP Code
Analyzer evidence, and a passing G3 sub-gate. Synthetic inputs conform to the
G2 contracts, allowing independent work.

| Subpackage | Window | Predecessor | Unit-test acceptance |
| --- | --- | --- | --- |
| WP6a — DDC and decimation | D17–22 | G2 | Known 150 MS/s ADC tones at 50 MHz IF produce 50 MS/s complex after /3 and 12.5 MS/s complex after /4, with agreed frequency, amplitude, phase, dimensions, and anti-alias behavior; evaluate complex mixing and staged filtering. |
| WP6b — Range processing | D23–29 | WP6a | Known LFM echoes map to calibrated range bins; ideal and sampled high-SNR fixtures preserve two peaks separated by 50 m using the candidate narrowband waveform. |
| WP6c — Single-PRF Doppler processing | D30–35 | WP6b | Known approaching/receding velocities give the correct bin and sign, and unit tests prove a native unambiguous interval of at least ±40 m/s. |
| WP6d — Receive angle processing | D17–26 | G2; parallel with WP6a–c | Synthetic 16×4 channel data gives correct boresight and specified off-axis azimuth/elevation signs and dimensions. |
| WP6e — Range/velocity ambiguity study | D17–27 | G2; parallel with WP6a–d | Compare executable candidates against known folded cases through ±800 km/h, range aliases, competing targets, and inconsistent measurements. Record failed candidates and evidence. **Selection gate:** one candidate passes the agreed cases; otherwise stop dependent work; root records failed-candidate evidence in the WP6e report and `CURRENT.md`, reopens the affected G1/G2 gate, routes WP2/WP4/contract or ADR revision as needed, reruns the corresponding independent review, and resumes only after the gate passes. |
| WP6f — Ambiguity-resolution implementation | D28–38 | WP6e | The selected method passes independent tests using synthetic per-PRF candidate lists, including alias boundaries and documented ambiguous-input behavior. |

<!-- markdownlint-enable MD013 -->

WP7 may use synthetic resolved candidates, while WP6f may use synthetic
per-PRF candidates; neither waits for the other’s code. WP8 proves that real
outputs compose correctly.

## V1 acceptance and assumptions

WP8 verifies reproducibility, contracts, coordinate and velocity signs, the
100 km, 10 m², common scan-midpoint primary case at approximately 800 km/h,
including
motion and range migration across the CPI; the ideal 50 m two-target case,
velocity-separated and unfolded cases, detection-list fields, and invalid
inputs. Monte Carlo results include seeds, trial counts, confidence method,
estimates, and bounds; the numeric Pd/Pfa targets do not block V1.

MATLAB calculations and plots run through MCP. MATLAB source passes the MCP Code
Analyzer; touched Markdown passes `markdownlint-cli2`, and diagrams render with
`mmdc`. The available installation lists Signal Processing Toolbox and DSP
System Toolbox, but not Radar Toolbox or Phased Array System Toolbox; WP2 must
flag any design that depends on an unavailable product.
