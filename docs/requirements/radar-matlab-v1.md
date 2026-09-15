---
version: 0.2.0
status: draft
---

# Radar MATLAB demonstrator V1 requirements

This document defines observable V1 behavior for the floating-point MATLAB
reference. It states what must be demonstrated and how it will be evidenced;
the rationale for consequential choices remains in the ADRs. WP2's revised
bounded analytic and ideal baseline is adopted by [ADR 0014](../adr/0014-adopt-revised-v1-analytic-simulation-baseline.md);
ADR 0011 records the historical B250/625 MS/s baseline. The remaining G2 and
implementation decisions are identified below.

## Boundary and conventions

The device under test (DUT) begins with digitized real 16-bit ADC samples on
64 independently digitized receive channels and ends with a detection list.
Stimulus generation is outside the DUT. The radar-centered frame uses metres
and metres per second: positive x is boresight/increasing range, positive y is
radar-left, positive z is up, and positive radial velocity is receding.

## Requirements

<!-- markdownlint-disable MD013 -->
| ID | Requirement | Status | Evidence |
| --- | --- | --- | --- |
| RAD-V1-001 | The reference shall process real 16-bit samples for the accepted 16×4 array channel baseline. | accepted | Contract test and end-to-end run |
| RAD-V1-002 | The DUT shall include DDC and decimation, fast-time and slow-time processing, CA-CFAR over range-Doppler cells, simple clustering, and detection-list conversion. | accepted | Stage unit tests and integration test |
| RAD-V1-003 | The V1 maximum instrumented range shall be 100 km. The primary case shall contain a constant-RCS 10 m² target whose reported range is 100 km at the common five-PRF scan midpoint and whose radial speed is approximately 800 km/h. The G1 analytic guarded-window interpretation shall be proved as a 128-usable-return timing schedule at G2. | accepted, G2 schedule pending | Seeded primary fixture; WP2 coverage study and WP4 timing contract |
| RAD-V1-004 | Native unambiguous radial velocity shall be at least ±40 m/s. | accepted, G1 analytic feasibility passed | WP2 study and Doppler unit test |
| RAD-V1-005 | Range ambiguity shall be resolved and true velocity shall be reported for test cases through ±800 km/h. | accepted, feasibility pending | WP6e study, WP6f tests, integration cases |
| RAD-V1-006 | An ideal mid-range, high-input-SNR fixture shall resolve two equal-RCS moving targets with shared nonzero radial velocity and 50 m range separation, producing two reports. | accepted, waveform/rate validation pending | Ideal and sampled range/end-to-end fixture |
| RAD-V1-007 | The verification set shall include velocity-separated and unfolded-velocity cases. | accepted | Named seeded fixtures |
| RAD-V1-008 | Azimuth and elevation receive beamforming shall operate simultaneously; elevation shall not scan; boresight shall be the first angle-accuracy case. The G1 ideal-array study supports a ≤0.1° per-axis WP6d unit tolerance only for noiseless, matched-manifold fixtures within its tested grid. Noisy boresight tolerance and operational elevation coverage remain WP4/G2 decisions. | accepted, operational tolerance pending | WP2 ideal angle study, WP6d unit tests, and integration fixture |
| RAD-V1-009 | A configurable near-zero-Doppler band shall suppress an abstract, injected stationary-interference component used only for processing-unit testing. This fixture does not model terrain, terrestrial propagation, or clutter physics. Stationary and near-zero-radial-speed targets are outside V1 acceptance cases. The cutoff and suppression tolerance shall be recorded after WP2/WP4 decisions. | accepted, cutoff/tolerance pending | Configuration contract and static-interference processing test |
| RAD-V1-010 | Radar configuration shall be authoritative for waveform, array, RF/ADC, processing, scan, blanking, and random-seed parameters. | accepted | JSON schema and conformance test |
| RAD-V1-011 | A separate target-scenario JSON shall define the target list, including RCS, Cartesian position, and velocity. | accepted | JSON schema and generator test |
| RAD-V1-012 | Every MAT test vector shall record the exact radar-configuration and target-scenario versions used to generate it. | accepted | MAT metadata test and reproducibility run |
| RAD-V1-013 | Each detection report shall contain range, radial velocity, azimuth, elevation, and a documented detection statistic, with units and sign conventions. | accepted | Output contract test |
| RAD-V1-014 | V1 shall report Monte Carlo estimates of probability of detection and per-cell false-alarm probability with trial count, seed, confidence method, and confidence bounds. | accepted | Statistical verification report |
| RAD-V1-015 | The numeric Pd ≥ 0.9 and per-cell Pfa ≤ 10^-6 values from ADR 0009 are demonstration targets and shall not be V1 pass gates. | accepted by ADR 0010 | Reported results and gate record |
| RAD-V1-016 | The MVP shall use one coherent boresight transmit beam and a receiver blanking interval during transmission. | accepted | Configuration and timing evidence |
| RAD-V1-017 | The demonstrator shall assume unobstructed free-space propagation and exclude terrain, occlusion, and terrestrial-clutter modeling. | accepted | Scenario-model review |
| RAD-V1-018 | A 90° azimuth sector (±45°) and one-second sector update shall remain explicitly provisional until illumination and steering are established. | provisional | Architecture review; no V1 pass criterion |
| RAD-V1-019 | The primary moving-target fixture shall account for target range migration within each CPI and shall produce the required primary-case result reported at the common five-PRF scan midpoint. No compensation algorithm or unapproved tolerance is prescribed. | accepted, tolerance pending | Seeded end-to-end primary fixture and WP2/WP4 evidence |
| RAD-V1-020 | Clustering adjacency, merge, and report behavior shall be defined in the WP3/WP4 intermediate and output contracts and verified by WP7 tests. | accepted, contract pending | Contract review and WP7 unit tests |
| RAD-V1-021 | This requirement refines RAD-V1-014's evidence requirements: statistical verification shall record the confidence level, confidence method, random seed, and trial count for each Pd/Pfa estimate, with confidence bounds. The adequacy of the estimates and the numeric targets are not V1 pass gates. | accepted, method/count pending | Statistical verification report for RAD-V1-014 |
| RAD-V1-022 | The reported V1 range domain shall use a common five-PRF scan-midpoint reference epoch. The candidate range domain is 6.80–100.00 km with guarded processing support internally extending to 100.05 km for motion; values below 6.80 km are not claimed. WP4 shall verify 128 usable returns per PRF, receive-window priming, transitions, and narrowband-DDC filter state/delay and near-range gating at G2; if that baseline is disproven, G1 shall reopen. | G2 schedule and DDC validation pending | Revised G1 study, ADR 0014, and WP4 timing contract; ADR 0011 is historical |
| RAD-V1-023 | The current waveform/DDC candidate shall use a 10 MHz complex chirp spanning -5 to +5 MHz, a 50 MHz IF center, and multistage decimation from a 150 MS/s real ADC through 50 MS/s complex (/3) to 12.5 MS/s complex (/4). A real-only /3 followed by IQ recovery is rejected because the IF aliases to DC. The MVP generator emits ADC-rate samples directly while retaining coherent phase derived from the exact ADR 0015 RF invariant. These are candidate parameters pending filter/alias, timing, coverage, SNR/ENOB/jitter, ambiguity, and sampled two-report validation; no automatic SNR or Pd inference is permitted. | revised G1 analytic pass; G2 validation pending | ADR 0012, ADR 0013, ADR 0014, ADR 0015, revised G1 study, and WP4/WP5/WP6/WP8 validation |
| RAD-V1-024 | The radar configuration shall encode `rfCarrierHz = 2997924580` Hz and derive $\lambda=0.1$ m and $d=0.05$ m from $c=299792458$ m/s and $\lambda=c/f_c$; the exact invariant, 16×4 topology, and array spans shall be verified against ADR 0015 and committed configuration/evidence. | accepted | ADR 0015, configuration contract, and exact-baseline evidence |
<!-- markdownlint-enable MD013 -->

## Traceability and gate policy

WP2 owns feasibility evidence for rates, bandwidth, pulse timing, PRFs, CPI,
and ideal processing candidates. WP6 owns independently testable processing stages,
including the ambiguity study and selected resolver. WP8 owns the seeded
end-to-end and statistical report. A requirement marked pending or provisional
cannot become an implementation parameter or V1 pass gate without a recorded
decision and updated evidence link. ADR 0009 remains the historical source for
unchanged requirements, with the V1 Pd/Pfa gate clarification in [ADR 0010](../adr/0010-v1-pd-pfa-demonstration-gate.md)
and the separability and waveform updates in [ADR 0012](../adr/0012-adopt-50m-separability-and-narrowband-ddc-candidate.md),
with current ADC/IF/DDC rates in [ADR 0013](../adr/0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md)
and revised G1 acceptance in [ADR 0014](../adr/0014-adopt-revised-v1-analytic-simulation-baseline.md).
