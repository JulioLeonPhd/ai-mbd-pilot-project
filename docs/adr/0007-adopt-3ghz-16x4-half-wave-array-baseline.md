---
status: accepted
---
# Adopt the 3 GHz 16×4 half-wave array baseline

> Historical baseline. ADR 0015 supersedes decision only for carrier,
> wavelength, and physical spacing; 16×4 topology, half-wave ratio, and
> normalized beam conclusions remain current.

Reference project adopts 3 GHz baseline (approximately 0.1 m
wavelength), approximately 0.05 m half-wave spacing, 16-horizontal by
4-vertical single-panel array. Gives demonstrator more useful
azimuth aperture than 4×4 panel; keeps elevation dimension small.
Choice supported by ideal beam-pattern study in [MATLAB
source](../../evidence/beam_pattern_study.m) and [plot](../../evidence/beam-pattern-study.png):
uniform 3 dB widths approximately 6.36° at boresight,
9.02° at +45°; Hamming widths approximately 9.74° and 13.88° at those
angles. Ideal array-factor results do not guarantee coverage,
detection, or angle performance; 90° azimuth sector remains provisional.
