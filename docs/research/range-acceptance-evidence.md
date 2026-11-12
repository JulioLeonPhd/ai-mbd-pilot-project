# Range-acceptance numerical evidence

## Question and decision boundary

This report describes the reference-only numerical study for the original two-target fixture and its measured observations. Its historical proposed budgets are not universal error bounds; Julio later approved fixture-scoped engineering budgets for the separate 200 m² point-target candidate, recorded in [ADR 0027](../adr/0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md#width-numerical-budgets-and-evidence-ownership).

The original study and its approval did not themselves authorize production implementation, hardware acceptance, or gate advancement.

Julio approved the original fixture assumptions in the [issue 24 approval record](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6474237580).

On 2026-11-10, root posted final resolutions and closed [#24](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6762277382) and [#23](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23#issuecomment-6762278228). The planning and bounded numerical-evidence dispositions are complete; they do not authorize production implementation or advance a gate.

## Durable candidate replay

The active bounded decision uses Julio's approved ideal point-target fixture with actual echo RCS 200 m² at a 20 km midpoint; it does not use the historical common-RCS derivation. This fixture replaces the configured-interval midpoint / derived-RCS fixture only for this decision. The original study report and historical JSON remain unchanged; the fixture-scoped numerical criteria and unchanged physical gates are defined in [ADR 0027](../adr/0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md#width-numerical-budgets-and-evidence-ownership). The correlation, lag, coordinate, and validity formulas remain those in [ADR 0025](../adr/0025-adopt-range-compression-numerical-and-validity-contract.md#reference-and-correlation) and the fixture criteria in ADR 0027. The independent physical gates remain one-bin peak association, a valid valley at least 3 dB below the smaller peak, and at least 30 dB estimated post-compression SNR.

Run the archived candidate snapshot from the repository root:

```matlab
run("evidence/range-20km-200m2/range_acceptance_study.m")
```

This same-basename archival snapshot is deliberately frozen for exact provenance, not a second production algorithm. Its SHA-256 is `c4ff98bb4b3d154e55ba6bb286a5e4457bdc6981044f6c00406b2b0d9405a707`. The snapshot retains its recorded repository root; reproducing the exact run requires that environment. Editing the root for a different checkout changes the runner hash but not the physical constants. This is not a portable API.

On 2026-11-10, root replayed the exact snapshot in MATLAB R2026a Update 5 (PID 18062). All 384/384 stream evaluations passed. Root's recursive comparison against the golden candidate file `evidence/range-20km-200m2-feasibility.json` found exactly one leaf difference, `report_path`; all other JSON content was identical. Code Analyzer returned `code_issues=[]`. The golden candidate JSON remains unchanged.

Replay output is `evidence/range-20km-200m2/range_acceptance_results.json`, distinct from the golden candidate JSON and historical `evidence/range_acceptance_results.json`. Root removed this generated duplicate after comparison; it is not tracked.

This result is finite synthetic point-target feasibility evidence, not the full configured range, an aircraft signature, hardware/ADC or probability-of-detection validation, WP8/two-report acceptance, or production evidence. The issues are closed by the root's final resolutions linked above; that does not change the evidence boundary or authorize production implementation. The next step is to request Julio's explicit production-implementation authorization.

## Reproduce the reference study

From the repository root, run the study-only runner:

```matlab
run("evidence/range_acceptance_study.m")
```

The recorded run used MATLAB R2026a Update 5 and Signal Processing Toolbox, which supplies the FIR design functions used by the DDC; DSP System Toolbox was installed but is not required by this runner.

Communications Toolbox `awgn` is not needed: the runner synthesizes its seeded Gaussian noise in the frequency domain.

The runner writes `evidence/range_acceptance_results.json`; do not treat this study runner as a reusable public interface or the later executable component walkthrough.

The recorded baseline revision was `054d44d60995f635e0f883938ef15722823b6c9f`; the new runner and JSON are working-tree artifacts identified by the hashes below, not files claimed to exist at that baseline revision.

The recorded hashes are: configuration `124ab5cb4ec9f623fd6c060cb05e3b35ebd1f52634563c165f75555ba403f9d8`, `createDesign` `46fc32ebdd8630d5fc91edae95093c7003e9735c4a5d50784409d5422de45a61`, `processFrame` `b5ad70cfc13d39f7b32898256c7ed840028fe50211ea835ca50d32fb9d3b0dfe`, and study runner `f8985dbb877428a64670e80c1f4aeada9a1e7f160eca4f1eecc0e637b98a95c8`.
The supplied primary JSON artifact is identified by SHA-256 `4020f13b8d7d3be80f527bebc4bdb75f3bff0f3dff8db1596fe5856fc39f0239`; working-tree integrity remains unverified.

## Fixture and measured paths

One evaluation is one PRI with four independent complex elevation-row streams, arranged `[sample,4]`; each processed output and its Boolean validity mask are `[rangeBin,4]`.

The configured PRI contains 88,236 real ADC samples at 150 MHz and the DDC produces 7,353 complex samples at 12.5 MHz, decimating by 12.

The 40 µs, 10 MHz rectangular up-chirp has 500 reference samples, with nominal range-bin spacing $\Delta R=c/(2F_s)=11.99169832\,\mathrm{m}$.

| Study parameter | Value | Unit / convention |
| --- | ---: | --- |
| Carrier / wavelength | 2.99792458×10⁹ / 0.1 | Hz / m |
| Real ADC rate / IF center | 150 / 50 | MHz |
| Complex range-input rate | 12.5 | MHz |
| PRI length | 88,236 ADC samples; 7,353 DDC outputs | samples per PRI |
| Pulse width / chirp bandwidth | 40 / 10 | µs / MHz |
| Reference length / bin spacing | 500 / 11.99169832 | samples / m |
| Receding radial velocity / Doppler | +20 / −400 | m/s / Hz |
| Physical target spacing | 50 | m |

For each path, the stimulus crosses four nearer-target offsets (0, 1/4, 1/2, and 3/4 bin), four relative phases (0°, 90°, 180°, and 270°), and three fixed noise seeds: 48 cases per path and 96 path/case/seed records total.

Each case is evaluated on four streams, for 192 stream evaluations per path and 384 total.

The sampled path uses the actual `radardemo.ddc.createDesign`/`processFrame` processing; the ideal path is the study's analytic complex reference.
The boundary is one independent PRI at a time; this evidence makes no cross-PRI state or continuous-stream claim.

The ideal range origin is 0 m; sampled output coordinates use the actual 31-output-sample group delay as an untrimmed negative origin of −371.74264792 m.

Blanking covers the 40 µs transmit pulse plus a 5 µs guard (45 µs total).

The independent masks require whole 500-sample windows, mark blanked or DDC-startup-invalid samples invalid, preserve valid zeros, and do not infer validity from numeric output zeros.

The observed DDC startup is 744 ADC samples / 62 output samples; the combined blanking/startup eligibility gives the study's valid lag masks, and each physical echo window remains wholly valid.

The range contract keeps the full lag array and masks; invalid outputs are complex zero with false validity, while zero-valued valid outputs remain possible.

## Physical waveform, phase, and Doppler scope

Both echoes are generated by evaluating the continuous fixed-delay waveform directly at sample times, with $\tau_i=2R_i/c$; fractional delays are not rounded or interpolated.

The near and far targets are exactly 50 m apart physically, share +20 m/s receding radial velocity, and use relative phase at the common $t=0$ PRI/transmit epoch.

The configured 2.99792458 GHz carrier gives $\lambda=0.1\,\mathrm{m}$ and $f_D=-2v/\lambda=-400\,\mathrm{Hz}$ for the stated sign convention.

This narrowband model applies fixed delay plus carrier Doppler for one PRI; it deliberately omits fast-time dilation and range migration, so it is not a moving-target or full-CPI model.

The correlation comparison is between FFT output and a direct time-domain oracle on the same samples; physical off-grid, Doppler, and sampled-DDC response are reported separately and are not counted as FFT residual.

The caller owns the exactly-once DDC coordinate delay correction; the study leaves the sampled origin untrimmed and does not repeat the existing factor-two output-envelope correction.

## Noise, quantization, and SNR definitions

The fixture sets a single receiver-input-equivalent watt reference per effective elevation row, using the approved 10 kW peak power, 23 dBi transmit and receive gain, one 6 dB signal-path loss, 4 dB noise figure, 290 K, and configured carrier.

For Boltzmann's constant $k_B$ and bandwidth $B=10\,\mathrm{MHz}$, the one-sided noise PSD and real IF noise variance are

$$
N_0=k_B(290\,\mathrm{K})10^{4/10},\qquad N=N_0B.
$$

The real ADC stimulus has two-sided PSD $N_0/2$ in the positive 45–55 MHz band and its negative-frequency mirror; the two bands together yield $N$, not $2N$.

The fixed count scale is $g=32/\sqrt{N}$ counts/$\sqrt{\mathrm{W}}$, mapping a real signal with mean physical power $P_r$ to amplitude $g\sqrt{2P_r}$ counts.
The deterministic seed mapping is $s(p,e,j)=\operatorname{mod}(12345+1000p+10e+j,2^{32})$, with $p=0$ for ideal and $p=1$ for sampled, $e=0,1,2,3$ for streams, and $j=0$ for noise-only or $j=1,2,3$ for separation noise.

Thus the nominal physical real-noise RMS is 32 counts, while the ideal proper-complex input noise has total variance 2,048 counts$^2$ (1,024 counts$^2$ per I/Q component).

| Noise and scale quantity | Value | Unit |
| --- | ---: | --- |
| One-sided PSD $N_0$ | $1.0057297120\times10^{-20}$ | W/Hz |
| Real IF noise variance $N=N_0B$ | $1.0057297120\times10^{-13}$ | W |
| Fixed scale $g$ | $1.0090422196\times10^8$ | counts/$\sqrt{\mathrm{W}}$ |
| Nominal real-noise RMS | 32 | counts |
| Ideal proper-complex input variance | 2,048 | counts$^2$ (1,024 each I/Q) |

The sampled path uses an ideal signed-int16 quantizer with one-count steps, ties-away-from-zero rounding, no dither, and limits [−32,768, 32,767]; the fixed gain is never changed between paths, streams, or cases.

Quantization is applied to the combined real signal-plus-noise before DDC; quantizing components separately would not reproduce the combined quantized signal because quantization is not additive.

A clipping or rounded out-of-range code is a fixture failure; none occurred in the evaluated noise-only and separation records.

Each path's noise comes from a 1 ms periodic Gaussian spectral record with 1 kHz spacing: the ADC record uses a 150,000-point spectrum populated at positive bins 45,000–55,000 and mirrored conjugately, while the ideal record uses a 12,500-point proper-complex spectrum at signed bins −5,000–5,000.

Each stream has one separate fixed noise-only record and three separation records; each separation record is reused across its 16 geometry/phase cells.

No realization normalization, mean removal, spectrum flattening, or case-wise noise/RCS renormalization is applied.

The noise-only estimate is the mean power over the stationary, complete-valid 20–70 km interior ROI (4,170 bins per stream), using one frozen record per path.

Physical receiver-input SNR describes physical signal power relative to receiver noise; range-input SNR uses the frozen input noise-only reference at the range-compressor input; post-compression SNR uses the isolated weaker-target signal-only compressed power at that target's selected bin divided by the frozen noise-only compressed power.

These are different measurement boundaries: the approved 30 dB criterion is estimated post-compression SNR, while physical receiver-input and range-input SNR are reported diagnostics and are not substituted for it.

The range-input estimate uses the repaired result JSON fields and its stationary interior noise reference, not the earlier stale summary note.

The selected-bin SNR numerator is isolated-target signal-only power, not the coherent two-target sum or noisy peak; the separation test itself uses the combined signal-plus-noise response.

The single 1 ms record, 1 kHz spectral grid, one noise-only estimate per path, and three separation seeds do not provide a statistical lower bound, probability-of-detection claim, or exhaustive ensemble.

## Common RCS derivation

The radar-equation fixture uses $P_r=K_r\sigma/R^4$, with

$$
K_r=\frac{P_tG_tG_r\lambda^2}{(4\pi)^3L},
$$

where $P_t=10\,\mathrm{kW}$, $G_t=G_r=10^{23/10}$, $L=10^{6/10}$, and $\lambda=0.1\,\mathrm{m}$.

The receive gain represents one effective beamformed elevation row with azimuth-array gain already included; there is no additional 16-element gain, four-row SNR bonus, slow-time gain, or extra range-compression gain.

One common RCS was derived once before noisy separation, using the farthest tested placement, all complete-valid candidate bins within one bin of truth, the worst actual processing response, fixed per-stream noise estimates, and the sampled-path bounded quantizer contribution.
The study's conservative bound is

$$
\sigma_{\mathrm{bound}}=\frac{R_{\max}^4}{2g^2K_r}\max_{p,e}\left(\frac{\sqrt{1000W_{p,e}}+E_{p,e}}{C_{p,e}}\right)^2,
$$

where $R_{\max}=53{,}434.04299606\,\mathrm{m}$ is the farthest tested range, $W_{p,e}$ is frozen noise-only output power in counts$^2$, $E_{p,e}$ is the bounded quantizer contribution in output counts, and $C_{p,e}$ is the least favorable isolated response in output counts per input count over all admissible bins.
The factor 1000 is the linear power ratio for 30 dB; $p$ indexes path and $e$ indexes stream.
For the limiting sampled-path stream, $W=5.1148269231\,\mathrm{counts}^2$, $E=2.6990080555\,\mathrm{counts}$, and $C=0.3014372400$ counts/count.

The limiting response is sampled DDC, zero-based stream 1, geometry 14, 3/4-bin offset, 90° relative phase, far target at lag 4,486; its least-favorable response is 0.3014372400 output counts per input count.

The resulting 30 dB bound was 48,157.768070245977 m$^2$; the predeclared 1% headroom yields the one frozen fixture value $\sigma=48,639.345750948436\,\mathrm{m}^2$.

This is a conservative study-derived fixture RCS, not minimum RCS, hardware capability, a product threshold, or the standard 10 m$^2$ WP8 case; the range-stage study does not replace WP8's end-to-end requirement for two detection reports.

## Results

| Measured criterion | Ideal reference | Sampled DDC |
| --- | ---: | ---: |
| Completed / passing stream evaluations | 192 / 192 | 192 / 192 |
| Minimum weaker-target selected-bin estimated post-compression SNR | 38.978051 dB | 38.929580 dB |
| Minimum weaker-target range-input SNR | 14.727084 dB | 14.674838 dB |
| Maximum absolute peak localization error | 5.995849 m | 5.995849 m |
| Minimum valley depth below smaller peak | 11.688020 dB | 11.974275 dB |
| ADC clipping records | not applicable | 0 |

Every evaluated stream passed distinct valid near/far peak selection, valley validity, the approved 3 dB valley criterion, the 30 dB post-compression SNR criterion, and no-clipping criterion.

The reported valley depth is the positive power-depth magnitude below the smaller selected peak; it is not the signed dB value of the valley-to-peak power ratio.

Isolated-target FWHM is a sampled-response diagnostic only, measured between interpolated half-peak-power crossings in power versus range; across isolated near- and far-target responses, it ranged 12.698858–23.866866 m for the ideal path and 12.718429–23.888136 m for sampled DDC.

Across known isolated responses, amplitude-ratio magnitude ranged 0.774496–0.999579 (ideal) and 0.773753–0.996838 (sampled); the phase of that complex ratio ranged −0.947209 to −0.944878 rad (ideal) and −0.946992 to −0.944516 rad (sampled).

Those complex response diagnostics include off-grid placement, Doppler and, for sampled DDC, actual filter response; they are physical complex ratios, not floating-point FFT/oracle residuals or approved tolerance limits.

## Numerical comparisons and validity evidence

The study compared every valid public lag of each known-signal stream against an independently computed direct correlation; 402,624 comparisons were valid for ideal and 398,656 for sampled DDC, 801,280 total.

The maximum observed absolute complex FFT/direct residual was $1.0247593\times10^{-13}$ counts.

The maximum coordinate arithmetic residual was $1.4551915\times10^{-11}\,\mathrm{m}$; the proposal compares $R_0+k\Delta R$ with an independently formed $c(k-D)/(2F_s)$ coordinate.
Here $D$ is the output-sample coordinate delay: $D=0$ for the ideal path and $D=31$ for the sampled-DDC path.

The guarded phase comparison reported a maximum residual of $4.5417009\times10^{-13}$ rad for ideal and $4.0481639\times10^{-10}$ rad for sampled DDC, after excluding unguarded near-null values.

The study's numerical proposals and observations above belong to that historical run and retain their recorded values and labels; the later approval does not rewrite the original report or historical JSON.

The approved fixture-scoped budgets, candidate-specific observations, and their limitations are recorded in [ADR 0027](../adr/0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md#width-numerical-budgets-and-evidence-ownership). The separately performed root-side coordinate check is described there as JS binary64 evidence, not as a MATLAB rerun or stored pointwise MATLAB proof.

## Evidence and limitations

The primary machine-readable result is [`evidence/range_acceptance_results.json`](../../evidence/range_acceptance_results.json); it records configuration, source hashes, seeds, noise and quantizer settings, per-case results, RCS derivation, diagnostics, and limitations.

MATLAB Code Analyzer recorded `code_issues=[]`, and the root's completed rerun was byte-identical to the original result JSON.

Independent numerical revalidation by `matlab-validator-deep` completed on 2026-10-28 with no unresolved implementation or evidence errors in its assigned scope; current runner and JSON bytes matched the recorded hashes.
The reviewer independently reconstructed `sampled_g1_seed1` stream 0 using physical echoes, fixed-seed noise, quantization, the public DDC, and manual time-domain correlation at all 6,229 valid lags, and reconstructed `sampled_g6` isolated responses as a quarter-bin/nonzero-phase check.
The repaired isolated FWHM and half-open physical supports, actual range-input powers and frozen noise-only denominator, all 2,004 aligned calibration comparisons, exact peak lags, and physical complex-response diagnostics were corroborated.
The complete 96-cell/384-stream audit is field-level evidence, not independent waveform reconstruction of every realization; neither it nor the bounded reconstruction by itself approves tolerances, RCS, production use, or WP8 acceptance. Julio's later, separately scoped numerical-budget approval is recorded in ADR 0027.

Graphify orientation found no MATLAB source node because MATLAB extraction is unavailable; repository documentation orientation and supplied exact artifact scopes were used, with no graph infrastructure changes.

The result is bounded to the stated fixture, frozen parameters, two paths, four streams, sparse offsets/phases/seeds, fixed-delay one-PRI Doppler model, and sampled DDC implementation; it makes no full-receiver, hardware, Monte Carlo detection, WP8, production API, or gate-advancement claim.
