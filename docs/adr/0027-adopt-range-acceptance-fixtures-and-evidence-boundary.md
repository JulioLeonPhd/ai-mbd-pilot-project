---
status: accepted
accepted: 2026-10-27
---

# Adopt range-acceptance fixtures and evidence boundary

## Context

[ADR 0025](0025-adopt-range-compression-numerical-and-validity-contract.md) fixes the unweighted 500-sample reference, correlation and coordinate conventions, and complete-window validity semantics. [ADR 0026](0026-adopt-per-pri-range-compression-api.md) fixes the independent per-PRI public contract, including four complex elevation streams and per-stream masks. Those decisions do not by themselves define range-acceptance criteria.

Julio approved the criteria and fixture choices below on 2026-10-27. They define the bounded reference study requested by [Establish numerical evidence for range acceptance](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24), a prerequisite to [Define range acceptance criteria](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23). This ADR records those settled definitions and the completed study observations. The original study's numerical proposals and derived common RCS retain their historical status; the separate fixture-scoped numerical budget approval for the 200 m², 20 km candidate is recorded below.

## Decision

### Human-approved fixture conventions (2026-10-28)

Julio approved the following fixture-only conventions in the [range-study approval record](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6474237580); they supplement, and do not revise, the physical acceptance criteria approved on 2026-10-27.

Use one receiver-input-equivalent watt reference, $P_r$, per effective elevation row; apply the 6 dB lumped signal-path loss once.

For Boltzmann's constant $k_B$ in joules per kelvin, noise figure $4$ dB, reference temperature $290$ K, and bandwidth $B=10$ MHz, define the one-sided noise power spectral density $N_0$ and total real-noise variance $N$ as

$$
N_0 = k_B(290\,\mathrm{K})10^{4/10}, \qquad N = N_0 B.
$$

The real ADC-rate noise has two-sided power spectral density $N_0/2$ in each of the positive 45–55 MHz band and its negative-frequency mirror; together they give total variance $N$, not $2N$.

For a fixed ADC-count scale $g=32/\sqrt{N}$ counts per $\sqrt{\mathrm{W}}$, map a real signal of mean physical power $P_r$ to amplitude $g\sqrt{2P_r}$ counts.

Use an ideal signed 16-bit uniform quantizer with one-count steps, round-to-nearest with ties away from zero, and no dither; its representable codes are $[-32768,32767]$.

Hold $g$ fixed across cases, streams, and paths; any evaluated clipping or saturation fails the fixture and must not trigger retuning.

These conventions define a simulation fixture, not ADC volts, impedance, hardware calibration, ENOB, or jitter; keep DDC compensation as already accepted and do not repeat its existing final factor-of-two envelope correction.

### Independent acceptance gates

Treat range calibration, complex gain/phase fidelity, two-target separation, and complete-window validity as independent mandatory gates. A pass in one gate cannot compensate for failure in another.

- **Calibration:** verify known delays against range coordinates, keeping on-grid lag/index behavior and caller-owned exactly-once DDC delay correction distinct from off-grid localization and physical Doppler bias. Preserve the existing ADR 0025/0026 contract; this decision adds no API.
- **Complex fidelity:** for an isolated aligned matched echo, compare the recovered complex amplitude with its known value and compare every valid public lag with an independently implemented direct time-domain correlation from the approved definition. The oracle must not share production FFT or lag-alignment helpers. Use absolute complex error near nulls; phase is meaningful only away from zero. Mismatch, off-grid, and sampled-DDC effects are not automatically numerical error. Use the known signal component for calibration and complex fidelity; there is no separate noise-free separation gate.
- **Complete-window validity:** exercise the existing per-stream mask contract, including blanking, startup and end truncation, internal invalid samples, valid zeros, and differing stream masks. Invalid numeric zeros are not evidence of a valid sample or a separation valley.

### Two-target separation and fixtures

For the current bounded decision only, Julio's 2026-11-09 selection of an ideal point target with actual echo RCS 200 m² at the 20 km midpoint replaces the configured-interval-midpoint/common-derived-RCS fixture above. The prior fixture matrix, physical gates, and historical derived-RCS study remain documented as historical context; this selection does not retroactively approve the derived RCS or claim acceptance across the configured range.

For each path, cross nearer-target fractional-bin offsets of 0, 1/4, 1/2, and 3/4 with relative range-input echo phases of 0, 90, 180, and 270 degrees: 16 combinations per path. Use shared 20 m/s radial velocity for range-compressor fixtures. Use a common range-input epoch for the relative phases and document velocity sign and fractional-delay conventions in the study. A denser phase sweep is deferred to V1 integration verification and is not implied by these cases.

Each target must produce a distinct magnitude local maximum within one output range bin (approximately 12 m) of its true range. The selected peaks and intervening valley must be valid, with the valley at least 3 dB in power below the smaller peak. The physical stimulus spacing is exactly 50 m; measured peak spacing need not be exactly 50 m. Invalid zeros do not count as valley evidence. Use three fixed, documented noise seeds; every required case must pass, with no case replacement or retry/reseeding until pass. This sparse seed set is not a probability-of-detection claim or exhaustive statistical evidence.

Retain the fixed, unweighted 500-sample reference. No weighting, including Hamming, is adopted or authorized by this decision.

### Noise, SNR, and common RCS

Use at least 30 dB **estimated post-compression SNR** for the weaker target in every evaluated stream as the range-fixture reference; report input SNR separately, with no 30 dB input-SNR requirement. Define the numerator using the weaker target's isolated signal-only compressed peak power at its selected bin, not the coherent two-target sum or noisy maximum. Assess separation on the combined signal-plus-noise response.

Assume stationary receiver noise and estimate output-noise power from one fixed-seed noise-only record per path, using the mean over a declared stationary, complete-window-valid interior region. Reuse that estimate across cases only while chain and noise settings are unchanged. This simplified estimate has no statistical lower-bound guarantee. The noise-only record seed is distinct in purpose from the three separation seeds. No covariance model, large per-bin ensemble, confidence-bound calculation, or separate numerical ensemble is an acceptance requirement.

For the sampled path, represent receiver noise as seeded zero-mean real Gaussian noise in the ADC-rate stimulus, bandlimited to 45–55 MHz and its negative-frequency mirror, before quantization and DDC. Preserve downstream noise shaping; baseband noise need not be white. Use one physical-power-to-ADC-counts scale across the matrix, with no clipping in evaluated realizations, and report quantization effects and headroom. This is a fixture assumption, not a calibrated full analog receiver or hardware calibration. The scale, quantizer conventions, and exact seeds remain to be documented before execution.

The 2026-10-28 approval above supersedes the preceding sentence's open scale and quantizer conventions; exact seeds were also frozen before execution and are recorded in the linked study evidence.

Derive one common RCS for both targets and all cases, streams, and paths from explicit radar-equation assumptions to meet the weaker-target SNR reference at the farthest tested placement and verify the least favorable processing response. The illustrative assumptions are 10 kW peak power, 23 dBi transmit and receive gain, 6 dB loss, 4 dB noise figure, and 290 K, together with the configured carrier and waveform and an explicit noise reference. The 23 dBi receive gain is the effective gain of one beamformed elevation-row aperture, with azimuth-array receive gain included. Do not add another 16-element gain, combine four rows for an SNR bonus, add slow-time gain, or double-count range-compression gain. These are simulation assumptions, not hardware claims; surface missing or inconsistent assumptions rather than inventing them or independently normalizing targets, streams, cases, or paths.

### Width, numerical budgets, and evidence ownership

Distinguish nominal bandwidth-derived range-resolution scale from measured mainlobe width and separability. Isolated compressed-response power FWHM is the distance between half-peak-power crossings, approximately −3 dB, with linear interpolation between sampled crossings; report it as a sampled-response diagnostic only, not an additional pass gate.

On 2026-11-09, Julio approved the following numerical budgets solely as fixture-scoped engineering criteria for the 200 m² ideal point-target candidate at the 20 km midpoint. This approval is not a proof of universal floating-point bounds, hardware acceptance, production authorization, issue closure, or gate advancement. The existing physical gates—including one-bin peak association, a valid valley at least 3 dB below the smaller peak, and at least 30 dB estimated post-compression SNR—are unchanged. Exact masks, dimensions, and invalid-zero behavior remain discrete contract assertions; physical Doppler, off-grid placement, and sampled-DDC gain/phase effects are diagnostics, not floating-point errors.

For binary64 calculations, let $u=\mathrm{eps}(\mathrm{double})/2$, $M=500$, and let $L$ be the FFT length. Define

$$
\gamma(n)=\frac{nu}{1-nu},\qquad
q[k]=\frac{1}{M}\sum_{m=0}^{M-1}|x[k+m]||s[m]|,\qquad
F=\frac{\lVert x\rVert_2}{\sqrt{M}},
\qquad
b[k]=\gamma(8M)q[k]+128u(\log_2L+1)F.
$$

Here $x$ is the input record and $s$ is the fixed unweighted reference. For every valid lag, the FFT/direct complex correlation comparison passes when $|y[k]-d[k]|\le b[k]$, where $y$ is the FFT result and $d$ is an independently computed direct correlation.
For phase comparison, include only values satisfying $|d[k]|\ge\sqrt{u}F$ and $|d[k]|\gt b[k]$; the allowed wrapped phase error is $\operatorname{atan2}(b[k],|d[k]|-b[k])$. Near nulls remain governed by the absolute complex-error gate, not an unstable phase comparison.

For independent aligned known-amplitude calibration, require the exact integer peak lag and $|y[d]-a|\le b[d]$ for the known echo $x[d+m]=a\,s[m]$. No additional arbitrary scalar gain or phase epsilon is authorized.
For coordinates, require

$$
\left|(R_0+k\Delta R)-\frac{c(k-D)}{2F_s}\right|
\le 32u\left(|R_0|+|k\Delta R|+\Delta R\right).
$$

Here $R_0$ remains caller supplied, $\Delta R=c/(2F_s)$, and $D$ is the study's output-sample coordinate delay: ideal origin $R_0=0,D=0$, or sampled origin $R_0=-D\Delta R,D=31$. These fixture origins do not impose a universal DDC origin on the generic API.

The candidate evidence records maximum absolute complex residuals of $7.1408661178799732\times10^{-14}$ counts (ideal) and $5.7285786768791163\times10^{-14}$ counts (sampled), maximum coordinate residual $1.4551915228366852\times10^{-11}$ m, and maximum guarded phase residuals of $7.2168355526165674\times10^{-13}$ rad (ideal) and $4.0357825468636982\times10^{-10}$ rad (sampled). Maximum candidate combined noisy localization error was 6.96056702 m on both paths; maximum isolated localization error was 5.99584916 m on both paths. These observations are not universal guarantees or replacements for the fixed physical gates.

The exact candidate runner is archived as `evidence/range-20km-200m2/range_acceptance_study.m` (SHA-256 `c4ff98bb4b3d154e55ba6bb286a5e4457bdc6981044f6c00406b2b0d9405a707`), with the same basename as its source and intentionally duplicated as a frozen archival snapshot, not a second production algorithm. The 2026-11-10 root replay used MATLAB R2026a Update 5, process 18062; all 384 stream evaluations passed. Root's recursive JSON comparison found exactly one leaf difference, `report_path`, versus the golden candidate evidence; Code Analyzer reported `code_issues=[]`. The replay generated `evidence/range-20km-200m2/range_acceptance_results.json`, distinct from the golden `evidence/range-20km-200m2-feasibility.json` and historical results; root removed the generated duplicate after comparison.

The archival runner retains its recorded repository-root path. Exact replay requires that environment; adapting the root for another checkout changes the runner hash, not physical constants. This is a local working-tree artifact, not a pushed commit or remotely available artifact.

Earlier reports and historical JSON retain the values and labels recorded when produced. This later approval does not rewrite those snapshots, retroactively approve the historical derived 48,639.35 m² RCS, or broaden approval beyond the selected fixture.

The 30 dB estimated post-compression reference applies to range-stage fixtures and does not by itself prove two detection reports. The existing two-report requirement remains an end-to-end WP8 obligation, separate from WP6b range-stage peak evidence; Doppler, timing, reporting, and detection demands are unchanged.

## Rationale

Independent gates prevent a successful separation plot from concealing coordinate, complex-response, or validity errors. The fixed matrix varies sub-bin placement and relative phase while preserving the physical 50 m geometry and one common RCS, so it tests the approved physical criterion without per-case normalization. Separating the estimated range-stage SNR condition from input SNR and WP8 report evidence avoids implying equivalence between unlike measurements or ownership boundaries.

## Consequences

The reference-only study and bounded independent numerical review are complete within their recorded scopes. Julio's 2026-11-09 approval of the fixture-scoped budgets above resolves that numerical-budget review only; it does not authorize production implementation or establish broader acceptance.

On 2026-11-10, root posted the final resolutions and closed issues [#24](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6762277382) and [#23](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23#issuecomment-6762278228). The bounded planning/evidence disposition is complete; it does not authorize production implementation or advance a gate. Any production implementation requires Julio's separate explicit authorization.
