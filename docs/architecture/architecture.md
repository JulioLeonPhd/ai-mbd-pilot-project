# Radar Demonstrator Architecture

This document records the current direction for a public AI-assisted
model-based design reference project. The architecture is deliberately
provisional: unresolved radar requirements must be settled before an
implementation is treated as a reference design.

## Scope

The radar is a demonstrator for the workflow, rather than the primary mission
system. The intended processing boundary is from ADC samples through a target
list. Tracking and classification are outside the current scope.

## Agreed decisions

Related decisions: [ADR 0002](../adr/0002-radar-demonstrator-scope.md),
[ADR 0003](../adr/0003-stage-floating-point-fixed-point-simulink.md),
[ADR 0004](../adr/0004-separate-json-driven-stimulus-generation.md),
[ADR 0005](../adr/0005-define-the-dut-from-adc-to-target-list.md),
[ADR 0006](../adr/0006-limit-the-mvp-propagation-model.md),
[ADR 0007](../adr/0007-adopt-3ghz-16x4-half-wave-array-baseline.md), and
[ADR 0008](../adr/0008-defer-hdl-generation-and-cosimulation.md).

- Develop a floating-point MATLAB reference first, followed by fixed-point
  design and analysis, and then a Simulink representation.
- Use a real 16-bit ADC for each channel.
- Use a pulsed LFM chirp as the stimulus waveform.
- Use a 3 GHz carrier. This gives an approximate wavelength of 0.1 m and
  half-wavelength element spacing of approximately 0.05 m.
- Use the accepted 16×4 single-panel array baseline, with 16 horizontal
  azimuth elements and 4 vertical elements; see [ADR 0007](../adr/0007-adopt-3ghz-16x4-half-wave-array-baseline.md).
- At 3 GHz and approximately 0.05 m half-wave spacing, the horizontal
  center-to-center aperture span is 15 × 0.05 m = 0.75 m. This is an aperture
  span, not a claim about the physical panel width.
- Assume an unobstructed free-space path for the MVP, with no terrain, line of
  sight/occlusion, or terrestrial-clutter modeling.
- Keep signal generation in MATLAB. Drive it with a JSON target scenario
  containing RCS in m², Cartesian position, and velocity; save generated test
  vectors in MAT files.
- Include DDC and decimation, fast-time and slow-time processing, CFAR,
  simple clustering, and conversion to a target list in the DUT boundary.
- Defer HDL work.

## Provisional proposals

- Use a provisional 90° azimuth sector (±45°), pending angle and coverage
  performance requirements and evaluation.
- Use a 100 km reference scenario with a 10 m² large jet.
- Treat 1 m range separability as a provisional reference objective. An ideal
  c/(2B) range-resolution estimate gives approximately 150 MHz of chirp
  bandwidth; this omits windowing and implementation losses and is not a
  guarantee of separability or an approved requirement.
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

The planned data flow is:

1. MATLAB generates waveform and scenario-driven test vectors.
2. ADC inputs provide digitized samples for each channel.
3. The DUT applies DDC and decimation.
4. Fast-time and slow-time processing produces detection features.
5. CFAR produces detections, simple clustering groups them, and the DUT emits a
   target list.

The exact algorithms, interfaces, rates, units, and numerical settings remain
open unless stated above as an agreed decision.

## Open questions

- What scan and angle-performance targets should be established after the beam
  pattern study?
- What sampled IF and sample rate are required?
- What power, noise, and link-budget assumptions apply?
- What probability-of-detection and probability-of-false-alarm targets apply?
- What PRF, pulse width, and CPI should be used?
- What velocity envelope and unfolding behavior are required?
- What are the exact semantics and fields of the report and target-list outputs?

Decisions on these questions should be recorded before they are presented as
implementation requirements.
