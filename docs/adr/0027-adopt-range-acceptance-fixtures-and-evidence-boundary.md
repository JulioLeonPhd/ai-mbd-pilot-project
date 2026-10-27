---
status: accepted
accepted: 2026-10-27
---

# Adopt range-acceptance fixtures and evidence boundary

## Context

[ADR 0025](0025-adopt-range-compression-numerical-and-validity-contract.md) fixes the unweighted 500-sample reference, correlation and coordinate conventions, and complete-window validity semantics. [ADR 0026](0026-adopt-per-pri-range-compression-api.md) fixes the independent per-PRI public contract, including four complex elevation streams and per-stream masks. Those decisions do not by themselves define range-acceptance criteria.

Julio approved the criteria and fixture choices below on 2026-10-27. They define the bounded reference study requested by [Establish numerical evidence for range acceptance](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24), a prerequisite to [Define range acceptance criteria](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23). This ADR records settled definitions only; the final numerical tolerance values and study evidence remain pending.

## Decision

### Independent acceptance gates

Treat range calibration, complex gain/phase fidelity, two-target separation, and complete-window validity as independent mandatory gates. A pass in one gate cannot compensate for failure in another.

- **Calibration:** verify known delays against range coordinates, keeping on-grid lag/index behavior and caller-owned exactly-once DDC delay correction distinct from off-grid localization and physical Doppler bias. Preserve the existing ADR 0025/0026 contract; this decision adds no API.
- **Complex fidelity:** for an isolated aligned matched echo, compare the recovered complex amplitude with its known value and compare every valid public lag with an independently implemented direct time-domain correlation from the approved definition. The oracle must not share production FFT or lag-alignment helpers. Use absolute complex error near nulls; phase is meaningful only away from zero. Mismatch, off-grid, and sampled-DDC effects are not automatically numerical error. Use the known signal component for calibration and complex fidelity; there is no separate noise-free separation gate.
- **Complete-window validity:** exercise the existing per-stream mask contract, including blanking, startup and end truncation, internal invalid samples, valid zeros, and differing stream masks. Invalid numeric zeros are not evidence of a valid sample or a separation valley.

### Two-target separation and fixtures

Evaluate both the ideal-reference and sampled-DDC paths, with all four elevation streams, near the midpoint of the configured detection interval. Keep both complete echo windows valid and away from blanking, startup, and end truncation. Use equal-RCS targets with shared nonzero radial velocity, preserving physical range-dependent received amplitude and exactly 50 m physical stimulus separation. Do not independently snap the farther target to a range bin.

For each path, cross nearer-target fractional-bin offsets of 0, 1/4, 1/2, and 3/4 with relative range-input echo phases of 0, 90, 180, and 270 degrees: 16 combinations per path. Use shared 20 m/s radial velocity for range-compressor fixtures. Document velocity sign, phase epoch, and fractional-delay conventions in the study; exact phase-epoch implementation remains to be established before execution. A denser phase sweep is deferred to V1 integration verification and is not implied by these cases.

Each target must produce a distinct magnitude local maximum within one output range bin (approximately 12 m) of its true range. The selected peaks and intervening valley must be valid, with the valley at least 3 dB in power below the smaller peak. The physical stimulus spacing is exactly 50 m; measured peak spacing need not be exactly 50 m. Invalid zeros do not count as valley evidence. Use three fixed, documented noise seeds; every required case must pass, with no case replacement or retry/reseeding until pass. This sparse seed set is not a probability-of-detection claim or exhaustive statistical evidence.

Retain the fixed, unweighted 500-sample reference. No weighting, including Hamming, is adopted or authorized by this decision.

### Noise, SNR, and common RCS

Use at least 30 dB **estimated post-compression SNR** for the weaker target in every evaluated stream as the range-fixture reference; report input SNR separately, with no 30 dB input-SNR requirement. Define the numerator using the weaker target's isolated signal-only compressed peak power at its selected bin, not the coherent two-target sum or noisy maximum. Assess separation on the combined signal-plus-noise response.

Assume stationary receiver noise and estimate output-noise power from one fixed-seed noise-only record per path, using the mean over a declared stationary, complete-window-valid interior region. Reuse that estimate across cases only while chain and noise settings are unchanged. This simplified estimate has no statistical lower-bound guarantee. The noise-only record seed is distinct in purpose from the three separation seeds. No covariance model, large per-bin ensemble, confidence-bound calculation, or separate numerical ensemble is an acceptance requirement.

For the sampled path, represent receiver noise as seeded zero-mean real Gaussian noise in the ADC-rate stimulus, bandlimited to 45–55 MHz and its negative-frequency mirror, before quantization and DDC. Preserve downstream noise shaping; baseband noise need not be white. Use one physical-power-to-ADC-counts scale across the matrix, with no clipping in evaluated realizations, and report quantization effects and headroom. This is a fixture assumption, not a calibrated full analog receiver or hardware calibration. The scale, quantizer conventions, and exact seeds remain to be documented before execution.

Derive one common RCS for both targets and all cases, streams, and paths from explicit radar-equation assumptions to meet the weaker-target SNR reference at the farthest tested placement and verify the least favorable processing response. The illustrative assumptions are 10 kW peak power, 23 dBi transmit and receive gain, 6 dB loss, 4 dB noise figure, and 290 K, together with the configured carrier and waveform and an explicit noise reference. The 23 dBi receive gain is the effective gain of one beamformed elevation-row aperture, with azimuth-array receive gain included. Do not add another 16-element gain, combine four rows for an SNR bonus, add slow-time gain, or double-count range-compression gain. These are simulation assumptions, not hardware claims; surface missing or inconsistent assumptions rather than inventing them or independently normalizing targets, streams, cases, or paths.

### Width, numerical budgets, and evidence ownership

Distinguish nominal bandwidth-derived range-resolution scale from measured mainlobe width and separability. Isolated compressed-response power FWHM is the distance between half-peak-power crossings, approximately −3 dB, with linear interpolation between sampled crossings; report it as a sampled-response diagnostic only, not an additional pass gate.

The one-bin peak association and 3 dB valley are accepted physical criteria. Numerical budgets for FFT/direct floating-point comparison, coordinate arithmetic, physical peak localization, and complex response remain to be justified and approved. In particular, correlation, coordinate, and complex gain/phase tolerances are not established here; do not borrow an unrelated DDC tolerance or substitute an arbitrary shared epsilon.

The 30 dB estimated post-compression reference applies to range-stage fixtures and does not by itself prove two detection reports. The existing two-report requirement remains an end-to-end WP8 obligation, separate from WP6b range-stage peak evidence; Doppler, timing, reporting, and detection demands are unchanged.

## Rationale

Independent gates prevent a successful separation plot from concealing coordinate, complex-response, or validity errors. The fixed matrix varies sub-bin placement and relative phase while preserving the physical 50 m geometry and one common RCS, so it tests the approved physical criterion without per-case normalization. Separating the estimated range-stage SNR condition from input SNR and WP8 report evidence avoids implying equivalence between unlike measurements or ownership boundaries.

## Consequences

The authorized next step is the future-session reference-only numerical study in [Establish numerical evidence for range acceptance](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24). It may calculate independent reference evidence and propose numerical budgets for Julio's review; it is not a draft public API, production implementation, production acceptance, or final component walkthrough. Any missing fixture conventions must be explicit before execution, and fixed physical criteria must not be tuned to make cases pass. The eventual component walkthrough must call the actual public per-PRI API.

[Define range acceptance criteria](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23) remains open for the study, Julio's review and approval of remaining tolerances, and a resolution comment. Study completion alone does not resolve that decision, authorize production implementation, or advance a gate. No study result or empirical pass claim is established by this ADR.
