---
status: accepted
---
# Adopt exact 10 cm free-space wavelength and carrier

## Context

Earlier 3 GHz baseline used rounded carrier, wavelength, spacing.
Physical design needs stable antenna-geometry and phase invariant,
retaining accepted 16×4 topology and normalized beam conclusions.

## Decision

Adopt exact decimal/rational design relation

$$
c=299792458\ \mathrm{m/s},\qquad \lambda=0.1\ \mathrm{m},\qquad
f_c=\frac{c}{\lambda}=2997924580\ \mathrm{Hz}=2.99792458\ \mathrm{GHz},
$$

with exact half-wave center spacing

$$
d=\frac{\lambda}{2}=0.05\ \mathrm{m}.
$$

“Exact” means stated decimal/rational design invariant; software binary
floating-point representations remain approximations. 16×4 array
center-to-center spans: $15d=0.75$ m horizontal, $3d=0.15$ m
vertical. Effective main-lobe aperture conventions (0.8 m horizontal,
0.2 m vertical) and physical panel dimensions remain distinct.

ADR partially supersedes [ADR 0007](0007-adopt-3ghz-16x4-half-wave-array-baseline.md)
only for carrier, wavelength, physical spacing. Retains 16×4
topology, half-wave ratio, normalized beam conclusions. Supersedes
current-candidate “3 GHz” clauses in [ADR 0013](0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md)
and [ADR 0014](0014-adopt-revised-v1-analytic-simulation-baseline.md) only for
RF carrier; IF, ADC, DDC, waveform, timing, G1 decisions unchanged.

## Alternatives and caveats

Alternatives: retain rounded 3 GHz or nominal 0.1 m
wavelength independent of $c$. Exact relation preferred for reproducible
phase and geometry calculations. Free-space wavelength and center spacing do
not specify element dimensions: substrate, dielectric loading, mutual coupling,
radome, manufacturing tolerances, spectrum constraints remain hardware
design work.

## Consequences

Configuration and generated phase/Doppler calculations use
`rfCarrierHz = 2997924580`, derive wavelength and spacing from invariant;
do not add redundant wavelength fields. With 128 pulses,
$\Delta v=\mathrm{PRF}/2560$. Minimum PRF for ±40 m/s: 1600 Hz;
current native spans approximately 42.50–67.49 m/s, minimum
42.4997 m/s for selected PRFs.
