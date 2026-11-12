# Real-target RCS evidence for the range-fixture review

## Purpose and decision boundary

This note compares measured target returns, illustrative textbook values, ideal reflector formulas, and the root's analytical fixture budget without treating them as interchangeable evidence.

It supports Julio's review of whether the current high-RCS two-target fixture is physically representative; it does not approve a target class, RCS, fixture/API, or acceptance change.

Radar cross section (RCS) is an equivalent scattering area, not an object's silhouette or physical area.

A target's reported RCS is conditional on frequency, aspect, polarization, measurement method, and often a statistical definition; a favorable peak is not an all-aspect guarantee.

## Measured examples: real objects, bounded conditions

Linear conversions below use $\sigma_{\mathrm{m^2}}=10^{\mathrm{dBsm}/10}$; source-rounding limits the precision of converted values.

| Target and reported value | Linear equivalent | Exact source locator and conditions | What the evidence means |
| --- | ---: | --- | --- |
| Small fixed-wing UAV: azimuth median $-11.0$ dBm², reported as $0.08\,\mathrm{m^2}$; IQR $-14.6$ to $-7.5$ dBm², reported as $0.03$–$0.18\,\mathrm{m^2}$. | Median $0.08\,\mathrm{m^2}$; IQR $0.03$–$0.18\,\mathrm{m^2}$. | May et al. [1], §2.7, paragraph beginning “RCS measurement of the UAV,” Fig. 2; 3,050 MHz, chamber, 360° azimuth, 0° elevation. UAV wingspan 2.1 m (§2.3). | Direct chamber measurement and near-3 GHz evidence. Median is over azimuth, not peak, mean, or guaranteed lower bound; IQR is angular variability, not a confidence interval. Chamber polarization, bandwidth, and calibration uncertainty are not specified in the article's main text. |
| Migratory birds, mixed population: average $19.09$ dBscm, equivalently $81.19\,\mathrm{cm^2}$. | $81.19\,\mathrm{cm^2}=0.008119\,\mathrm{m^2}$. | Wang et al. [2], §3.2, Eq. (12), Fig. 8, PDF pp. 9–10; S-band dual-polarization weather radar, observations at 1.5° elevation. | Field-measurement-derived, model-assisted population average, not an individual bird or individual-species measurement. Frequency, exact channel polarization for this scalar, and waveform bandwidth are not established in the article text. The 95% CI 18.92–19.27 dBscm is for the reported estimate, not individual-target spread. |
| Four road vehicles: curves span approximately 2 to almost 25 dBsm. | Approximately $1.6$ to $316\,\mathrm{m^2}$. | Schipper et al. [3], §III, Fig. 4, PDF pp. 2–3; monostatic HH, 23–27 GHz frequency-averaged measurements, 0° elevation, azimuth 0°–180°. | Measured automotive envelope across objects/aspects, not a nominal car value. This is higher-frequency automotive evidence and is explicitly nontransferable as an S-band RCS. Paper identifies support-structure scattering centers in vehicle imagery (Figs. 7–8). |
| Bicycle and motor scooter with clothed mannequin: combined envelope approximately $-12$ to $10$ dBsm. | Approximately $0.063$ to $10\,\mathrm{m^2}$. | [3], §III, Fig. 3, PDF p. 2; monostatic, 23–27 GHz frequency averaging, HH and VV, 0° elevation, azimuth 0°–180°. | Envelope applies jointly to those configurations, not separately to a bicycle, scooter, or human-only target. Same band-transfer limitation as vehicle results. |
| Large naval auxiliary ship: aspect-conditioned median about 40 dBsm near bow and 65 dBsm near 270° broadside aspect. | $10^4$ to $3.16\times10^6\,\mathrm{m^2}$. | NTIA TR-15-513 [4], §4.3, printed p. 17, Fig. 12; measured at 2.8 GHz, horizontal polarization, 2° azimuth increments; median is the 50% exceedance curve. | S-band measured large-platform example near the study carrier, not a compact-target or calibration-standard value. The 25 dB aspect change is a factor of about 316 in RCS; ship return is spatially distributed and must not be equated with one compact range-bin return. |

These results establish that real-target RCS can be modest, aspect-variable, population-defined, or very large for a large ship; none establishes a compact moving target with the fixture's exact value and required motion/aspect conditions.

The vehicle data are included as practical evidence only with their 23–27 GHz conditions prominent; they do not supply an S-band car number.

The bird result is not a value for a single bird, flock, or compact echo.

The ship values describe a measured large target and must not be transferred to a compact point-target model without evidence about scattering extent and resolution-cell response.

## Textbook illustrations: useful scale, not measurements

Rehr's secondary survey attributes microwave-band examples of 20 m² for a medium jet airliner, 40 m² for a large jet airliner, and 100 m² for a jumbo jet to Skolnik [14].

These are secondary-reported textbook class examples, not directly verified passages from *Introduction to Radar Systems*, measurements, 3 GHz values, or A330/B777 RCS values; the source table does not define aspect, polarization, provenance, or statistic.

They indicate only a rough class scale and are not suitable for selecting an aircraft RCS.

The MIT Lincoln Laboratory teaching source [6] presents automobile and small-truck values of 100–200 m² as illustrative examples, not a measurement dataset.

Skolnik's *Radar Handbook* discussion describes RCS variation with orientation and frequency, including aircraft engine-intake and exhaust returns, and presents aircraft-pattern examples [19].

Those qualitative examples reinforce aspect and frequency dependence but do not provide verified numerical near-3 GHz RCS for an A330 or B777.

Richards et al. define thermal receiver noise and single-pulse SNR under receiver thermal-noise assumptions (§§2.3–2.5, pp. 64–66, Eqs. 2.10–2.11), relate matched-filter output SNR to pulse time-bandwidth product (§2.11, pp. 74–75, Eq. 2.28), and describe RCS dependence on viewing angle, frequency, and polarization (ch. 1, pp. 18–19) [8].

Their quantization discussion gives approximately 6 dB SQNR improvement per bit for a given signal power, with quantizer-range and saturation caveats (§14.3, pp. 504–505, Eqs. 14.7–14.8) [8]; this is generic SQNR guidance, not converter performance or a substitute for the full-scale-sine relation.

Knott, Shaeffer, and Tuley's *Radar Cross Section* is a relevant monograph; no numerical claim here depends on it.

## Ideal reflector geometry: orientation-controlled peaks only

Ideal formulas can describe a calibration reflector's coherent peak under specified geometry; they do not predict the typical RCS of a moving ship, aircraft, or vehicle.

For the NASA GPM calibration manual's **triangular trihedral**, $l$ is the triangular front-face edge shown in Fig. 24, not a square-face dimension.

$$
\sigma_{\mathrm{trihedral,max}}=\frac{\pi l^4}{3\lambda^2},\qquad
l=\left(\frac{3\lambda^2\sigma}{\pi}\right)^{1/4}.
$$

The peak is at boresight, manual angles $\theta=35.25^\circ,\,\phi=45^\circ$; the manual reports RCS within 0.2 dB for offsets under 5° (Chandrasekar et al. [9], §3.1.1, pp. 43–46, Fig. 24 and Eq. 24).

For a sufficiently large perfectly conducting flat plate at normal incidence, the Toronto derivation gives the ideal peak:

$$
\sigma_{\mathrm{plate,max}}=\frac{4\pi A^2}{\lambda^2},
$$

where $A$ is plate area (Hum [10], §4.2, p. 7).

Using the study wavelength $\lambda=0.1\,\mathrm{m}$, the formula examples are:

| Desired ideal peak | Triangular trihedral front-edge $l$ | Ideal square-plate side $\sqrt{A}$ | Orientation limit |
| --- | ---: | ---: | --- |
| $4{,}067.46\,\mathrm{m^2}$ | about 2.50 m | about 1.34 m | Trihedral boresight or plate broadside/normal incidence. |
| $48{,}639.35\,\mathrm{m^2}$ | about 4.64 m | about 2.49 m | Same ideal peak orientations. |

These are formula-based ideal PEC geometries, not measured RCS, angularly stable target signatures, or proof of a 20 m/s moving-target response.

A stationary calibrator can inform range/response calibration but cannot establish moving-target Doppler behavior or per-PRI target statistics.

## Root analytic budget: one-PRI idealized tradeoff

The [recorded study budget](range-acceptance-evidence.md#noise-quantization-and-snr-definitions) uses carrier 2.99792458 GHz, $\lambda=0.1\,\mathrm{m}$, peak power $P_t=10\,\mathrm{kW}$, 23 dBi transmit/receive gain, 6 dB path loss, bandwidth $B=10\,\mathrm{MHz}$, pulse width $T_p=40\,\mathrm{\mu s}$, temperature $T_0=290\,\mathrm{K}$, noise figure $\mathrm{NF}=4\,\mathrm{dB}$, and farthest tested range $R=53{,}434.04299606\,\mathrm{m}$.

With dimensionless gains $G_t=G_r=10^{23/10}$, loss $L=10^{6/10}$, and Boltzmann constant $k_B=1.380649\times10^{-23}\,\mathrm{J/K}$, the independent analytic calculation is:

$$
F=10^{\mathrm{NF}/10},\qquad N=k_BT_0FB=1.0057297120\times10^{-13}\,\mathrm{W},
$$

$$
K_r=\frac{P_tG_tG_r\lambda^2}{(4\pi)^3L},\qquad
\mathrm{SNR}_{\mathrm{out}}=\frac{K_r\sigma BT_p}{R^4N},\qquad
R_{30}=\left(\frac{K_r\sigma BT_p}{1000N}\right)^{1/4}.
$$

Here $\sigma$ is target RCS in m², $N$ is input-referred noise power, $\mathrm{SNR}_{\mathrm{out}}$ is a linear power ratio, and $R_{30}$ is range in metres for 30 dB ideal aligned output SNR.

The root's analytic values below are ideal aligned single-pulse output SNR and ideal range for 30 dB, not measured fixture passes:

| RCS $\sigma$ (m²) | Ideal aligned output SNR at 53.434 km (dB) | Ideal range at 30 dB (km) | Relation to configured interval |
| ---: | ---: | ---: | --- |
| 1 | -6.09 | 6.69 | Below 6.8 km start; outside configured interval. |
| 10 | 3.91 | 11.90 | Within interval analytically, but no margin at 30 dB. |
| 100 | 13.91 | 21.16 | Illustrative ideal tradeoff only. |
| 1,000 | 23.91 | 37.63 | Illustrative ideal tradeoff only. |
| 4,067.46 | 30.00 | 53.43 | Aligned 30 dB reference value. |
| 48,639.35 | 40.78 | 99.37 | Conservative all-candidate-bin fixture value. |

The time-bandwidth product is $BT_p=400$, or 26.02 dB; it is already included in the root calculation.
The 500-sample reference instead comes from $T_pF_s=500$ at $F_s=12.5\,\mathrm{MHz}$: its length is not an additional gain.
Normalized correlation preserves aligned signal amplitude; the ideal noise improvement relative to $N=N_0B$ is $BT_p=400$, with no extra range-compression, array, four-row, or slow-time gain to add.

The 48,639.35 m² value is an inflated all-candidate-bin bound: it includes the worst response over admissible candidate bins, sampled-DDC response, bounded quantizer contribution, and 1% RCS headroom, rather than only an aligned selected peak.

Removing that conservatism does not make a 10 m² target achieve 30 dB at 53.434 km: the ideal aligned value is only 3.91 dB there, and its ideal 30 dB range is about 11.90 km.

The sub-6.8 km result is outside the configured range interval; shorter-range, RF/link-budget, or acceptance-criterion changes require Julio's explicit approval and a full valid-matrix rerun.
No MATLAB or fixture rerun was performed for this literature review; a replacement sized from selected peaks rather than all candidate bins remains unverified.

The current runner matches the report's recorded SHA-256; the current JSON differs from its historical recorded hash:

| Artifact | SHA-256 |
| --- | --- |
| Matching study runner | `f8985dbb877428a64670e80c1f4aeada9a1e7f160eca4f1eecc0e637b98a95c8` |
| Current results JSON | `46e8c36c2ca43551f1eed43ade187e4817ef0e5cd7c0fbb370c4a4c8a779b4af` |
| Historical results JSON recorded in the report | `4020f13b8d7d3be80f527bebc4bdb75f3bff0f3dff8db1596fe5856fc39f0239` |

No cause was established for the difference; neither corruption nor byte-identical historical identity is claimed.

## Candidate scenario selected by Julio — 2026-11-09

Julio selected an ideal point-target candidate with actual echo RCS 200 m² and a 20 km midpoint. This resolves the fixture's RCS/range selection for this candidate, not the RCS of an aircraft or another real target.

The [candidate results JSON](../../evidence/range-20km-200m2-feasibility.json) records 16 geometries, four streams, three separation seeds, and two paths (ideal and sampled): 384 stream evaluations total. Near-target ranges were 19,978.1694–19,987.1632 m and far-target ranges 20,028.1694–20,037.1632 m, with 50 m radial separation and 20 m/s radial velocity. The fixed gates were unchanged.

| Path | Passing stream evaluations | Minimum post-compression SNR |
| --- | ---: | ---: |
| Ideal | 192/192 | 30.992853 dB |
| Sampled | 192/192 | 30.932240 dB |

All 384 evaluations passed near/far association, distinct-peak, valid-valley, 3 dB valley, 30 dB SNR, and clipping gates; there were no failed cases. The minimum SNR margin is about 0.93 dB. In the corresponding 100 m² candidate, 288/384 evaluations passed and 96/384 failed; this 200 m² result passes those unchanged gates.

The historical reference runner was not modified: the run used a parameter-only scratch adaptation to place the geometry midpoint at 20 km and set actual echo RCS to 200 m², without using the derived common RCS for echoes. The historical 48,639.35 m² common-RCS fixture and its recorded evidence remain unchanged and unapproved; the new JSON is separate candidate evidence.

This remains point-target fixture feasibility evidence only, not full configured-range proof, an airliner signature, hardware/ADC validation, probability-of-detection evidence, or production authorization. Julio's fixture-scoped numerical budgets for this 200 m² candidate are recorded in [ADR 0027](../adr/0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md#width-numerical-budgets-and-evidence-ownership); they do not approve the historical derived 48,639.35 m² RCS.

Root posted the final resolutions and closed issues [#24](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6762277382) and [#23](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23#issuecomment-6762278228) on 2026-11-10. The bounded dispositions do not authorize production implementation; the next step is Julio's explicit authorization decision.

The result records Julio's selected candidate and the matrix outcome; it does not establish a representative 3 GHz RCS for an aircraft.

## Preferred target class: large commercial airliner

The preferred class for Julio's review is a large commercial aircraft, with A330/B777-class aircraft as the desired examples; this is a class preference, not an approved RCS or a selection of a specific variant.

No primary source cited here establishes a verified A330- or 777-specific monostatic RCS near the study's 3 GHz carrier.

Airbus lists the A330-300 at 63.66 m overall length and 60.30 m geometric wingspan [11], while Boeing lists the 777-300ER at 73.9 m length and 64.8 m span [12].

These dimensions describe physical extent, not RCS, and are several times the study's 14.99 m nominal bandwidth-limited range resolution.

An aircraft therefore has distributed scattering centers whose range-profile occupancy depends on aspect, geometry, waveform bandwidth, scattering, and processing; the aircraft's total RCS is not automatically a one-cell return, and short wideband pulses can resolve separate scattering returns in time [8, §6.3, p. 222].

The TNO study by van der Heiden et al. reports in its abstract that broadside radar range profiles measured from a target-of-opportunity Boeing 737 were compared with high-frequency RAPPORT predictions from a digitized Boeing model at the same aspect angles and frequencies, with reported excellent agreement despite model/code simplifications [13].

The TNO abstract reports neither numerical RCS nor frequency, and this evidence is not an A330 or B777 signature.

Rehr's secondary survey attributes microwave-band examples of 20 m² for a medium jet airliner, 40 m² for a large jet airliner, and 100 m² for a jumbo jet to Skolnik [14].

These secondary-attributed textbook class examples are not directly verified Skolnik passages, measurements, 3 GHz values, or A330/B777 RCS values; no aircraft RCS should be selected from them.

The study's 50 m center-to-center radial separation is not a universal guarantee that two extended aircraft profiles overlap or resolve in a particular way.

Whether returns overlap depends on their aspect-dependent scattering distributions and the waveform/processing response; the point-target fixture does not model that profile.

## What the ideal ADC accounting includes

The sampled path includes ideal 16-bit signed quantization, but it does not model hardware ENOB or SINAD.

TI gives the ideal full-scale sine quantization limit $6.02n+1.76\,\mathrm{dB}$ (Eq. 2, §2.1, p. 2); for $n=16$, this is about 98 dB integrated over the full Nyquist bandwidth [18].

That is ideal full-scale sinusoidal SQNR, not an additive radar-SNR term, measured converter performance, or the actual echo SNR.

The common estimate $q/\sqrt{12}$ for quantization-error RMS assumes uniform error over one step $q$; interpreting the error as white noise additionally requires decorrelation, which is not guaranteed for a deterministic quantizer without dither.

The study uses $q=1$ count, so $q/\sqrt{12}=0.288675$ count RMS is a heuristic reference, not the measured quantization error.

Against the nominal 32-count thermal-noise RMS, this heuristic is about 40.9 dB lower in power and does not replace the study's measured quantized-noise results.

On the sampled path, the combined near-plus-far real echo and thermal-noise record is rounded once to nearest with ties away from zero, converted to signed int16, and then passed through the actual DDC and range compressor [15].

The quantizer has one-count steps, limits $[-32768,32767]$, no dither, and no gain rescaling; the ideal complex path bypasses ADC quantization.

Quantization is nonadditive, so the combined signal-plus-noise path is not reproduced by separately quantizing signal and noise or each target.

The receiver-input thermal SNR $P_r/(N_0B)$ excludes quantization noise and follows the receiver-noise and single-pulse definitions above [8].

For the sampled path, the post-compression denominator is the measured mean power obtained from the noise-only quantized record $Q(n)$ after processing through the actual DDC and compressor.

The isolated far-target numerator uses $Q(s_{\mathrm{far}})$, while the combined-target response is formed from $Q(s_{\mathrm{near}}+s_{\mathrm{far}}+n)$; the study tracks quantizer nonadditivity explicitly, and these quantities are not SINAD [16].

The 30 dB ideal criterion already includes the specified matched-filter time-bandwidth processing; decimation or compression adds no automatic extra gain, and quantization noise is not added a second time to the measured denominator [8, §2.11, pp. 74–75, Eq. 2.28].

The $E=2.699$ output-count bound used in the conservative RCS allowance is a bounded RCS-amplitude contribution, not an extra noise-denominator term [17].

No real ADC datasheet SNR/ENOB, aperture jitter, converter/reference noise, INL/DNL, or calibrated voltage/impedance characterization is available here; the study's counts are fixture units, not hardware calibration.

The 16-bit treatment therefore verifies only the stated ideal quantizer accounting, not a physical converter's performance.

Sources [15]–[17] identify the exact study code locators supporting the quantizer, SNR, and RCS-bound descriptions.

The ADC relationship between ideal sine quantization SNR and in-band filtering is also explained in TI §2.2, p. 3, Eq. 4 [18].

The ideal ADC-accounting caveats do not change the existing numerical fixture, evidence scope, or approval boundary.

The ADC explanation is a literature-note interpretation of the recorded study, not a MATLAB rerun or hardware validation.

The location-specific study citations are implementation evidence, not independent hardware measurements.

## What the fixture does and does not represent

The existing 48,639.35 m² setting is a conservative synthetic link-budget fixture, not a selected aircraft, vehicle, mountain, or typical ship RCS.

A fixed-RCS, matched-polarization, free-space point-target model can be a useful bounded one-PRI algorithm isolation case, but it is not a statistical guarantee for a real target or an all-aspect representation.

Preserve the per-PRI boundary: no hidden slow-time integration or multi-PRI gain is justified by these measurements or the current acceptance context.

The study's 20 m/s value is **radial velocity**, not total speed; only line-of-sight velocity sets monostatic Doppler.

The 50 m target separation is physical radial center-to-center separation for the fixture's range-separation claim, not merely Euclidean distance.

Nominal range-bin spacing is **11.99 m**, while nominal bandwidth-limited range resolution is **14.99 m**; these are distinct quantities, and neither alone establishes the measured two-target acceptance result.

A total ship, terrain, or aircraft RCS is not automatically concentrated in one compressed range bin; target scattering extent, illuminated footprint, aspect, polarization, waveform, and processing response matter.

The A330-300 and 777-300ER are several nominal range-resolution lengths long, but this dimensional comparison does not predict their actual aspect-dependent range profiles or imply that the fixture's two target profiles must overlap at 50 m center separation.

Terrain/mountain returns are distributed backscatter and clutter, not a universal compact point-target RCS.

## Sources and remaining review decisions

1. May, R. et al. (2017), “Performance test and verification of an off-the-shelf automated avian radar tracking system,” *Ecology and Evolution* 7:5930–5938. DOI: [10.1002/ece3.3162](https://doi.org/10.1002/ece3.3162); full text [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC5552925/).
2. Wang, R. et al. (2023), “Quantification of Migration Birds Based on Polarimetric Weather Radar,” *Remote Sensing* 15, 4809. DOI: [10.3390/rs15194809](https://doi.org/10.3390/rs15194809); [publisher PDF](https://mdpi-res.com/d_attachment/remotesensing/remotesensing-15-04809/article_deploy/remotesensing-15-04809.pdf).
3. Schipper, T. et al. (2011), “RCS Measurement Results for Automotive Related Objects at 23–27 GHz,” EuCAP; [ETSI technical-document archive PDF](https://docbox.etsi.org/ERM/ERMTGSRR/05-CONTRIBUTIONS/2017/ERMTGSRR%2817%29030005_RCS_of_vehicles_24GHz.pdf).
4. Achatz, R. et al. (2015), NTIA Report TR-15-513, *Effect of Broadband Radio Service Reallocation on 2900–3100 MHz Band Marine Radars: Background*, §4.3; [official PDF](https://its.ntia.gov/publications/download/TR-15-513.pdf). Fig. 12 is adapted from Skolnik, *Introduction to Radar Systems*, 2nd ed. (1980), Fig. 2.21(a), p. 45.
5. Skolnik, M. I., *Introduction to Radar Systems*, 3rd ed., McGraw-Hill, 2001, §§2.7–2.8 and Table 2.1, printed p. 64.
6. O'Donnell, R. M., MIT Lincoln Laboratory, *Introduction to Radar Systems*, Lecture 4, “Target Radar Cross Section,” slides 4, 8, 11; [official course page](https://www.ll.mit.edu/outreach/web-based-course-radar-introduction-radar-systems), [official PDF](https://www.ll.mit.edu/sites/default/files/outreach/doc/2018-07/lecture%204.pdf).
7. Knott, E. F., J. F. Shaeffer, and M. T. Tuley, *Radar Cross Section*, 2nd ed.; IET/SciTech 2004 reissue.
8. Richards, M. A., J. A. Scheer, and W. A. Holm, *Principles of Modern Radar: Basic Principles*, vol. I, 1st ed., SciTech Publishing, 2010, ISBN 978-1-891121-52-4; ch. 1, pp. 18–19; §§2.3–2.5, 2.11, 6.3, and 14.3.
9. Chandrasekar, V. et al., *Recommended Calibration Procedures for GPM Ground Validation Radars*, v10 (2015), §3.1.1; [NASA GPM PDF](https://gpm-gv.gsfc.nasa.gov/Tier1/Docs/NASA_GPM_GV-cal_10.pdf).
10. Hum, S. V., *Radar Systems*, §4.2, “RCS of a Flat Plate”; [University of Toronto course PDF](https://www.waves.utoronto.ca/prof/svhum/ece422/notes/24-radar.pdf).
11. Airbus, “A330-300 technical data,” “Dimensions,” 63.66 m overall length and 60.30 m geometric wingspan; [manufacturer page](https://www.aircraft.airbus.com/en/aircraft/a330/a330-300).
12. Boeing, “777 technical specifications,” 777-300ER dimensions, 73.9 m length and 64.8 m span; [manufacturer page](https://www.boeing.com/commercial/777).
13. van der Heiden, R., L. J. van Ewijk, and F. C. A. Groen (1997), “In-flight measurements and RCS-predictions: A comparison on broad-side radar range profiles of a Boeing 737,” IEE Radar 97, pp. 444–448; [TNO repository record and abstract](https://repository.tno.nl/SingleDoc?docId=11067), [persistent resolver](https://resolver.tno.nl/uuid:31ee86c9-a618-4223-b4ea-c173f25b3249).
14. Rehr, R. (2021 update), “Aircraft Scatter on VHF, UHF, and Microwave Frequencies: Increasing Understanding and Using Improved Tools to Increase Communications Distance and Maximize Success,” pp. 2–4; [secondary survey PDF](https://ntms.org/files/Jun2021/W3SZ_AircraftScatterPaperJun2021_RogerRehr.pdf).
15. Range study quantizer code, [`evidence/range_acceptance_study.m`](../../evidence/range_acceptance_study.m), lines 1241–1264, 1681–1695, and 1812–1847; recorded quantizer settings are also in [`evidence/range_acceptance_results.json`](../../evidence/range_acceptance_results.json).
16. Range study noise and SNR code, [`evidence/range_acceptance_study.m`](../../evidence/range_acceptance_study.m), lines 475–522, 1000–1016, and 1759–1806.
17. Range study bounded quantizer/RCS allowance code, [`evidence/range_acceptance_study.m`](../../evidence/range_acceptance_study.m), lines 677–705 and 757–763.
18. Texas Instruments, “General Oversampling of MSP ADCs for Higher Resolution,” by Ryan Brown and Sameer Singh, SLAA694A, revised April 2016, §2.1, p. 2, Eq. 2, and §2.2, p. 3, Eq. 4; [PDF](https://www.ti.com/lit/an/slaa694a/slaa694a.pdf).
19. Skolnik, M. I., ed.-in-chief, *Radar Handbook*, 3rd ed., McGraw-Hill, 2008, p. 1.7; and Knott, E. F., “Radar Cross Section,” ch. 14 in the same volume, pp. 14.1–14.3 and 14.13–14.14, Figs. 14.13–14.14.

The literature and root budget inputs were supplied as mutable working-tree/local-note material and were not revision-pinned; provenance is therefore **integrity-unverified**.

Julio retains these review decisions:

- Julio selected the synthetic ideal point-target candidate at 200 m² and approximately 20 km; the desired future aircraft class remains A330/B777. Any aircraft-specific RCS still requires specified band, variant, aspect window, polarization, statistic, and scattering extent.
- Decide whether fixed-RCS matched-polarization free-space single-PRI assumptions are sufficient for the intended review, without implying statistical assurance.
- The selected moderate-RCS candidate has been evaluated at approximately 20 km with unchanged RF parameters and gates; any further range, RF/link-budget, or criterion change requires human approval and a new evaluation, not imported slow-time gain.
- The selected 200 m² fixture value is not a literature-established A330/B777 RCS; no aircraft-specific value is recommended from the cited evidence.

Limitations: no verified exact 3 GHz compact moving-target RCS at 20 m/s radial speed and 50 m radial separation; no A330/B777-specific RCS; no acceptance, hardware, or statistical detection proof; the secondary-reported aircraft-class examples are not aircraft-specific measurements, and the aircraft-pattern figure conditions and values are not established here.
