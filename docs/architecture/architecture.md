# Radar Demonstrator Architecture

<!-- markdownlint-disable MD033 -->

WP4/G2 Phase 0 is frozen by [ADR 0018](../adr/0018-freeze-wp4-g2-phase0-contract.md).
Independent Phase 4 validation passed. Phase 5 independent document review and
the Phase 6 root gate passed; G2 is accepted for the frozen WP4 evidence.
Downstream WP6e may still reject the schedule and reopen G2 by recorded decision.

<a id="architecture-wp4-topology"></a>
This document summarizes topology only. ADR 0018 owns WP4/G2 decisions, the
data contract owns fields and invariants, and the requirements document owns
observable obligations.

This document records the current direction for a public AI-assisted
model-based design reference project. The architecture is deliberately
provisional: unresolved radar requirements must be settled before an
implementation is treated as a reference design.

## Scope

The radar is a demonstrator for the workflow, rather than the primary mission
system. The intended processing boundary is from ADC samples through a
detection list. Tracking and classification are outside the current scope.

## Agreed decisions

Related decisions: [ADR 0002](../adr/0002-radar-demonstrator-scope.md),
[ADR 0003](../adr/0003-stage-floating-point-fixed-point-simulink.md),
[ADR 0004](../adr/0004-separate-json-driven-stimulus-generation.md),
[ADR 0005](../adr/0005-define-the-dut-from-adc-to-target-list.md),
[ADR 0006](../adr/0006-limit-the-mvp-propagation-model.md),
[ADR 0007](../adr/0007-adopt-3ghz-16x4-half-wave-array-baseline.md), and
[ADR 0008](../adr/0008-defer-hdl-generation-and-cosimulation.md).
The five-PRF and CPI decision is recorded in [ADR 0016](../adr/0016-retain-five-prfs-and-reopen-cpi-pulse-count.md).

- Develop a floating-point MATLAB reference first, followed by fixed-point
  design and analysis, and then a Simulink representation.
- Use a real 16-bit ADC for each channel.
- Use a pulsed LFM chirp as the stimulus waveform.
- Use the exact ADR 0015 carrier $f_c=2.99792458$ GHz, giving exact free-space
  wavelength $\lambda=0.1$ m and half-wavelength center spacing $d=0.05$ m.
- Use the accepted 16×4 single-panel array baseline, with 16 horizontal
  azimuth elements and 4 vertical elements; see [ADR 0007](../adr/0007-adopt-3ghz-16x4-half-wave-array-baseline.md).
- Use a single coherent boresight transmit beam for the MVP. Transmit scan and
  the method for illuminating the provisional 90° sector remain undecided.
- At the exact carrier and 0.05 m half-wave spacing, the horizontal
  center-to-center aperture span is 15 × 0.05 m = 0.75 m. This is an aperture
  span, not a claim about the physical panel width.
- Assume an unobstructed free-space path for the MVP, with no terrain, line of
  sight/occlusion, or terrestrial-clutter modeling.
- Keep signal generation in MATLAB. Drive it with a JSON target scenario
  containing RCS in m², Cartesian position, and velocity; save generated test
  vectors in MAT files.
- Include DDC and decimation, fast-time and slow-time processing, CFAR,
  simple clustering, and conversion to a detection list in the DUT boundary.
- Use the authoritative row-major channel map: four elevation channels for
  each azimuth element, with `k = 1..64` mapping to
  `(floor((k-1)/4)+1, mod(k-1,4)+1)`.
- Defer HDL work.

## Accepted MVP requirements

- Maximum instrumented range is 100 km; the primary case is a constant-RCS
  10 m² target at 100 km and approximately 800 km/h radial speed.
- Native unambiguous radial velocity is at least ±40 m/s. Range ambiguity must
  also be resolved, and true velocity must be reported after unfolding through
  ±800 km/h.
- CA-CFAR over range-Doppler cells is the first detector. Monte Carlo trials
  estimate Pd and per-cell Pfa with confidence bounds, targeting Pd ≥ 0.9 and
  Pfa ≤ 10^-6.
- An ideal mid-range, high-input-SNR test resolves two moving equal-RCS targets
  with shared nonzero radial velocity, separated by 50 m in range, and emits two
  detection-list reports. Additional velocity-separated and
  unfolded-velocity cases are required.
- Commanded-look azimuth summation precedes range/Doppler processing; elevation
  processing follows selected range-Doppler candidates and does not scan.
- A 90° azimuth sector (±45°) and one-second sector update are provisional
  timing/coverage goals, not established ±45° performance requirements, until
  illumination and steering are established.
- A configurable near-zero-Doppler band removes static clutter. Its cutoff is
  unresolved; stationary and near-zero-radial-speed targets are out of scope.
- Radar-configuration JSON is authoritative for reproducible waveform, array,
  RF/ADC, processing, scan, blanking, and random-seed parameters. A separate
  target-scenario JSON contains the target list. Test vectors record exact
  radar-configuration and target-scenario versions. The DUT output is a
  detection list with range, radial velocity, azimuth, elevation, and a
  documented detection statistic.

These decisions are recorded in [ADR 0009](../adr/0009-radar-mvp-acceptance-and-ambiguity-requirements.md),
with the separability and waveform/rate candidates updated by [ADR 0012](../adr/0012-adopt-50m-separability-and-narrowband-ddc-candidate.md)
and [ADR 0013](../adr/0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md).

## Provisional proposals

- The current waveform/DDC candidate is a 10 MHz complex chirp spanning -5 to
  +5 MHz, a 50 MHz IF center, and multistage decimation from 150 MS/s real ADC
  samples through 50 MS/s complex to 12.5 MS/s complex. The nominal range
  resolution is approximately 15 m; sampled separation, filter response, and
  two detection reports remain WP6b/WP8 acceptance work under [ADR 0012](../adr/0012-adopt-50m-separability-and-narrowband-ddc-candidate.md).
- Use the following scenario assumptions: 0.05 m² drone, 2 m² helicopter,
  5 m² small jet, and 10 m² large jet.

These proposals describe an initial demonstrator direction. They do not define
complete array, waveform, detection, or performance requirements.

## Beam-pattern study

The [beam-pattern study plot](../../evidence/beam-pattern-study.png) and
[MATLAB source](../../evidence/beam_pattern_study.m) were run through MATLAB MCP
on R2026a Update 5. The study is an ideal 16×4 half-wave-spaced isotropic array
azimuth cut. It uses the 16 horizontal elements for azimuth and compares
uniform and Hamming weighting while steering to 0°, +45°, and +60°. Each curve
is independently peak-normalized in an ideal isotropic, uncoupled array-factor
model, so the study does not show scan loss, element pattern, or mutual
coupling.

Analytic model results give approximate 3 dB widths for uniform weighting of
6.36° at 0°, 9.02° at +45°, and 12.99° at +60°. Hamming weighting gives 9.74°,
13.88°, and 20.58° at those steering angles. These results indicate that an
approximately 5° width is optimistic for this study configuration. The results
are analytic model outputs, not coverage or detection acceptance criteria; the
90° azimuth sector remains provisional pending performance requirements and
evaluation.

## Processing boundary

<a id="architecture-processing-boundary"></a>

The planned data flow is:

1. MATLAB generates waveform and scenario-driven test vectors, recording exact
   configuration and scenario versions.
2. ADC inputs provide digitized samples for each channel.
3. The DUT applies DDC and decimation.
4. For each commanded azimuth look, receive beamforming coherently sums the 16
   azimuth elements independently for each of the four elevation rows, reducing
   64 DDC channels to four complex elevation streams. Fast-time processing then
   produces per-pulse range data. Before coherent
   slow-time processing, those results receive migration-aware alignment or
   handling for the moving-target hypotheses under consideration. Slow-time
   processing then forms Doppler data from the usable pulse ensemble for each
   azimuth look.
5. Ambiguity projection/unfolding preserves the five PRF layers. Per-PRF CFAR
   decisions feed non-coherent 3-of-5 binary integration; clustering consumes
   the fused hypotheses and the DUT emits a detection list.

The proposed signal chain and its current rate boundaries are shown below.
The RF/stimulus path is external to the DUT; the DUT boundary begins with the
ADC samples. Fast-time/range processing precedes slow-time/Doppler processing.
A Doppler map for an azimuth look is formed only after the usable pulses for
that look are available and migration-aware alignment or handling has been
applied for the relevant candidate hypotheses. Implementations may stream and
accumulate per-pulse fast-time results while the look is being collected.
Whether migration compensation uses candidate true-velocity hypotheses,
iteration, or another approved method, along with its exact sequencing, is an
open WP6e choice.

<!-- markdownlint-disable MD013 -->
```mermaid
flowchart LR
    GEN["MVP target generator<br/>direct 64-channel ADC vectors<br/>2.99792458 GHz RF phase model"] --> ADC["DUT input: 64 real 16-bit ADC channels<br/>150 MS/s/channel; 50 MHz IF"]
    ADC --> DDC["Multistage DDC<br/>complex mix/filter + /3 to 50 MS/s<br/>filter + /4 to 12.5 MS/s"]
    DDC --> BB["Complex baseband candidate<br/>12.5 MS/s/channel; Nyquist +/-6.25 MHz"]
    BB --> ABF["Commanded-look azimuth beamforming<br/>16 elements summed per row<br/>64 channels -> 4 elevation streams"]
    ABF --> FT["Fast-time/range processing<br/>10 MHz waveform; nominal ~15 m resolution"]
    FT --> ST["Migration-aware alignment/handling<br/>then slow-time/Doppler processing<br/>usable fast-time pulse results for each azimuth look;<br/>five PRFs: 1700, 1900, 2150, 2450, 2700 Hz<br/>Phase 4 verified [22,25,28,32,35] usable-pulse schedule"]
    ST --> RD["Range-Doppler feature formation<br/>aligned pulse ensemble to Doppler map"]
    RD --> EL["Elevation processing at selected range-Doppler candidates"]
    EL --> CAND["Per-PRF candidate seam<br/>folded range/velocity + PRF identity<br/>azimuth = commanded look"]
    CAND --> UNFOLD["Ambiguity projection/unfolding<br/>five PRF layers retained"]
    UNFOLD --> CFAR["Per-PRF CFAR decisions"]
    CFAR --> FUSE["Non-coherent binary fusion<br/>3-of-5 baseline; masks and source cells"]
    FUSE --> CLUST["Clustering<br/>consumes fused hypotheses"]
    CLUST --> DL["Detection list<br/>range, radial velocity, azimuth,<br/>elevation, detection statistic"]
    CAND -. "design-time decision boundary" .-> ORDER["WP6e compares alternative<br/>orders and ambiguity methods"]

    subgraph DUT["DUT boundary: ADC samples to detection list"]
        ADC
        DDC
        BB
        ABF
        FT
        ST
        RD
        EL
        CAND
        UNFOLD
        CFAR
        FUSE
        CLUST
        DL
    end
```
<!-- markdownlint-enable MD013 -->

The channel order is row-major across the 16 azimuth by 4 elevation array:

```text
azimuth 1:   ch 1  ch 2  ch 3  ch 4
azimuth 2:   ch 5  ch 6  ch 7  ch 8
...
azimuth 16:  ch 61 ch 62 ch 63 ch 64
             el1   el2   el3   el4
```

The solid path records the V1 receive shape: `[sample,64]` through DDC, then
`[sample,4]` after commanded-look azimuth summation, followed by range and
Doppler processing on the four elevation streams. V1 reports the commanded look
as azimuth; it does not estimate a sub-beam azimuth. The dotted link remains a
design-time decision boundary for WP6e ambiguity order and method. Exact
clustering adjacency is the WP4/G2 one-cell within-look rule: no edge wrapping,
invalid bridging, or cross-look deduplication.

The generator abstracts the exact ADR 0015 RF waveform and analog conversion;
it emits
sampled 50 MHz IF directly with coherent delay, Doppler, and array phase. The
five-PRF set is retained; the historical 128-return count is not frozen and
usable pulses per PRF per azimuth look is a
scheduling target, not verified performance. The diagram does not freeze the
sampled DDC implementation, DSP interfaces, or the full transition schedule.
The 50 MHz IF is distinct from the 50 MS/s complex intermediate; a real-only /3
followed by IQ recovery is rejected because it aliases the IF to DC. Phase 4
independently verified digital filter alias rejection, the 372-tick group
delay, continuous decimator phase across PRIs and transitions, and near-range
timing. The timing check used guarded leading-edge output timestamps with delay
compensation and verified margins `nominalRawMarginTicks=54`,
`motionBoundRawMarginTicks=46`, and `motionBoundAlignedMarginTicks=40`. The
detailed schedule evidence covers 151 records, including five priming and 142
usable records. It does not claim full FIR precursor or waveform retention, or
detection performance. Phase 5 independent document review and the Phase 6 root
gate passed; G2 is accepted for this evidence scope.

The two-stage DDC group delay is 372 ADC ticks, or 31 output samples. The
contract requires mixer, FIR, and decimator state to be zero-initialized at
scan start and retained across PRIs and transitions, including continuous `/3`
then `/4` decimator phase. Independent full-CPI evidence covers one channel,
10,553,388 ticks, 150 PRI/transition boundaries, and 2,189 chunks. It compares
19,480 observed output samples/timestamps selected across startup, end, and
boundary observation windows; maximum absolute complex output-sample
discrepancy against independent direct convolution is `1.5e-15`. The
zero-input fixture separately verifies exact-zero output with the 64-channel
shape. Other exact
algorithms, interfaces, rates, units, and numerical settings remain open unless
stated above as an agreed decision.

## Downstream items still open

- Phase 4 independently verified the frozen `[22,25,28,32,35]` allocation,
  151-record grammar, and integer-tick cap. The arithmetic is 2.849920 ms
  transitions plus 70.355920 ms total, leaving 0.297080 ms under the 70.653 ms
  cap. G2 accepted this schedule evidence; downstream WP6e may still reject
  the schedule and reopen G2 through a recorded decision.
- What look spacing follows from the ideal 3 dB beamwidth, and what noisy
  angle and elevation-sector measurements should be reported?
- What clutter cutoff and detection-statistic definition make results
  reproducible, including Monte Carlo trial and confidence methods?

WP2's revised bounded simulation baseline passed G1 review on 2026-09-14;
see [ADR 0014](../adr/0014-adopt-revised-v1-analytic-simulation-baseline.md)
and the [feasibility report](../research/radar-v1-feasibility.md). [ADR 0011](../adr/0011-adopt-v1-simulation-timing-baseline.md)
is the historical record for the former baseline. ADR 0014 accepted revised
G1 for WP3 data contracts and WP4 DSP/timing architecture.
WP3 is accepted. WP4 Phases 4 and 5 passed independent validation, and the
Phase 6 root gate accepted G2 for the frozen schedule, finite-filter
response/alias behavior, timing, and priming evidence. Issue #3 remains open
for future checker provenance hardening; Git verified the current evidence pair.
