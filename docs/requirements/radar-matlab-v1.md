---
version: 0.2.0
status: draft
---

# Radar MATLAB demonstrator V1 requirements

<!-- markdownlint-disable MD033 -->

WP4/G2 Phase 0 contract values are frozen in
[ADR 0018](../adr/0018-freeze-wp4-g2-phase0-contract.md): 150 MHz integer
ticks, the
`[22,25,28,32,35]` usable-pulse schedule, DDC ripple/alias budgets,
`[N,64]` to `[N,4]` commanded-look dimensions, 3-of-5 fusion, and same-look
clustering seams. Independent Phase 4 validation passed. Phase 5 independent
document review and the Phase 6 root gate passed; G2 is accepted for the frozen
WP4 evidence. Downstream WP6e may reopen G2 through a recorded decision.

<a id="requirements-wp4-obligations"></a>
ADR 0018 owns frozen design decisions; the data contract owns field-level
invariants. These requirements state observable obligations and do not create
additional schedule, filter, or clustering values.

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
| <a id="RAD-V1-003"></a>RAD-V1-003 | The V1 maximum instrumented range shall be 100 km. The primary case shall contain a constant-RCS 10 m² target whose reported range is 100 km at the common five-PRF scan midpoint and whose radial speed is approximately 800 km/h. The frozen WP4 schedule and fixture matrix are independently validated; the target-report performance claim remains an end-to-end requirement and is not established by Phase 4 timing/DDC evidence. WP6e may reopen G2 through a recorded decision. | Phase 4 schedule/fixture validation and Phase 5/6 root gate passed; G2 accepted for frozen WP4 evidence; target-report performance remains an end-to-end limitation | Seeded primary fixture; ADR 0018 and WP4 manifest |
| RAD-V1-004 | Native unambiguous radial velocity shall be at least ±40 m/s. | accepted, G1 analytic feasibility passed | WP2 study and Doppler unit test |
| RAD-V1-005 | Range ambiguity shall be resolved and true velocity shall be reported for test cases through ±800 km/h. | accepted, feasibility pending | WP6e study, WP6f tests, integration cases |
| RAD-V1-006 | An ideal mid-range, high-input-SNR fixture shall resolve two equal-RCS moving targets with shared nonzero radial velocity and 50 m range separation, producing two reports. | accepted, waveform/rate validation pending | Ideal and sampled range/end-to-end fixture |
| RAD-V1-007 | The verification set shall include velocity-separated and unfolded-velocity cases. | accepted | Named seeded fixtures |
| <a id="RAD-V1-008"></a>RAD-V1-008 | For each commanded azimuth look, receive beamforming shall coherently sum the 16 azimuth elements independently for each of the 4 elevation rows before range/Doppler processing, yielding 4 complex elevation streams. Elevation shall not scan; V1 azimuth is the commanded-look assignment, not sub-beam azimuth estimation. Boresight shall be the first angle-accuracy case. The G1 ideal-array study supports a ≤0.1° per-axis WP6d unit tolerance only for noiseless, matched-manifold fixtures within its tested grid. Noisy angular accuracy and operational sector coverage are reported measurements, not V1 gates. Multi-beam or monopulse refinement is out of V1. | accepted; measurement pending | WP2 ideal angle study, WP6d unit tests, and integration measurement report |
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
| <a id="RAD-V1-020"></a>RAD-V1-020 | Clustering adjacency, merge, and report behavior is defined in the WP4 contract and verified by executable WP4/WP7 tests. | Phase 4 and 5 passed; Phase 6 root gate accepted G2 | ADR 0018 and WP4 manifest |
| RAD-V1-021 | This requirement refines RAD-V1-014's evidence requirements: statistical verification shall record the confidence level, confidence method, random seed, and trial count for each Pd/Pfa estimate, with confidence bounds. The adequacy of the estimates and the numeric targets are not V1 pass gates. | accepted, method/count pending | Statistical verification report for RAD-V1-014 |
| <a id="RAD-V1-022"></a>RAD-V1-022 | The reported V1 range domain shall use a common five-PRF scan-midpoint reference epoch. The frozen Phase 0 schedule has usable pulses `[22,25,28,32,35]`, 151 records, 150 MHz integer ticks, total `10553388` ticks, cap `10597950`, margin `44562`, transition gap `106872`, and midpoint offset `5276694`; exact time values are 2.849920 ms transitions and 70.355920 ms total, leaving 0.297080 ms. Independent Phase 4 timing uses guarded leading-edge output timestamps with 372-tick delay compensation and verifies nominal raw 54, motion-bound raw 46, and motion-bound aligned 40 ADC-tick margins. Schedule evidence has five priming and 142 usable records; it does not establish full FIR precursor/waveform retention or detection performance. WP6e may still reject the schedule and reopen G2. | Phase 4/5 passed; Phase 6 root gate accepted G2; downstream WP6e may reopen it | ADR 0014, ADR 0018, and WP4 fixture manifest; ADR 0017 is historical |
| RAD-V1-023 | The V1 ideal input assumption is a band-limited 45–55 MHz ADC input centered at the 50 MHz IF, with a 10 MHz complex chirp spanning -5 to +5 MHz and multistage decimation from a 150 MS/s real ADC through 50 MS/s complex (/3) to 12.5 MS/s complex (/4). A real-only /3 followed by IQ recovery is rejected because the IF aliases to DC. The MVP generator emits ADC-rate samples directly while retaining coherent phase derived from the exact ADR 0015 RF invariant. ENOB and jitter are downstream sensitivity studies, not pending V1 assumptions; Phase 4 independently verified finite-filter/alias behavior and full-CPI streaming boundaries on one channel. The zero-input fixture separately verifies 64-channel shape. Hardware performance and automatic SNR or Pd inference remain outside this evidence. | Phase 4/5 passed; Phase 6 root gate accepted G2; hardware/system performance outside this evidence | ADR 0012, ADR 0013, ADR 0014, ADR 0015, ADR 0017, revised G1 study, and WP4/WP5/WP6/WP8 validation |
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
