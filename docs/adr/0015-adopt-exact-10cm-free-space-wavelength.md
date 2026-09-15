---
status: accepted
---

# Adopt exact 10 cm free-space wavelength and carrier

## Context

The earlier 3 GHz baseline used rounded carrier, wavelength, and spacing
values. The physical design needs a stable invariant for antenna geometry and
phase calculations while retaining the accepted 16×4 topology and normalized
beam conclusions.

## Decision

Adopt the exact decimal/rational design relation

$$
c=299792458\ \mathrm{m/s},\qquad \lambda=0.1\ \mathrm{m},\qquad
f_c=\frac{c}{\lambda}=2997924580\ \mathrm{Hz}=2.99792458\ \mathrm{GHz},
$$

with exact half-wave center spacing

$$
d=\frac{\lambda}{2}=0.05\ \mathrm{m}.
$$

“Exact” means the stated decimal/rational design invariant; software binary
floating-point representations remain approximations. The 16×4 array therefore
has center-to-center spans of $15d=0.75$ m horizontally and $3d=0.15$ m
vertically. Effective main-lobe aperture conventions (0.8 m horizontal and
0.2 m vertical) and physical panel dimensions remain distinct.

This ADR partially supersedes [ADR 0007](0007-adopt-3ghz-16x4-half-wave-array-baseline.md)
only for carrier, wavelength, and physical spacing. It retains the 16×4
topology, half-wave ratio, and normalized beam conclusions. It supersedes the
current-candidate “3 GHz” clauses in [ADR 0013](0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md)
and [ADR 0014](0014-adopt-revised-v1-analytic-simulation-baseline.md) only for
the RF carrier; IF, ADC, DDC, waveform, timing, and G1 decisions are unchanged.

## Alternatives and caveats

Alternatives were retaining the rounded 3 GHz value or using a nominal 0.1 m
wavelength independent of $c$. The exact relation is preferred for reproducible
phase and geometry calculations. Free-space wavelength and center spacing do
not specify element dimensions: substrate, dielectric loading, mutual coupling,
radome, manufacturing tolerances, and spectrum constraints remain hardware
design work.

## Consequences

Configuration and generated phase/Doppler calculations use
`rfCarrierHz = 2997924580` and derive wavelength and spacing from the invariant;
they do not add redundant wavelength fields. With 128 pulses,
$\Delta v=\mathrm{PRF}/2560$. The minimum PRF for ±40 m/s is 1600 Hz; the
current native spans are approximately 42.50–67.49 m/s, with a minimum of
42.4997 m/s for the selected PRFs.
