---
status: accepted
---
# Set radar MVP acceptance and ambiguity requirements

MVP maximum instrumented range: 100 km. Primary case: constant-
RCS 10 m² target at 100 km, approximately 800 km/h radial speed. Native
unambiguous radial velocity shall reach at least ±40 m/s; range ambiguity shall
also resolve, true velocity reported through ±800 km/h. Four or five
distinct PRFs: initial starting point, pending feasibility derivation.

CA-CFAR over range-Doppler cells: first detector. Monte Carlo trials
shall estimate Pd and per-cell Pfa with confidence bounds; targets Pd ≥ 0.9
and Pfa ≤ 10^-6. Ideal test shall resolve two moving equal-RCS targets
separated by 1 m in range, produce two detection-list reports.
Ideal mid-range, high-input-SNR test: equal targets, same nonzero
radial velocity.

MVP target RCS and Cartesian velocity remain constant throughout one
scan; acceleration and RCS fluctuation: separate future cases.

Reference array: 16 × 4 elements, 64 independently digitized real
16-bit receive channels. Receiver blanked during transmission.
MVP: one coherent boresight transmit beam; no transmit scan
selected. 90° sector update remains provisional until illumination and
steering design established.
Scenarios: radar-centered Cartesian frame, metres and metres per second:
positive x: boresight, increasing range; positive y: radar-left; positive
z: up; positive radial velocity: receding.

Azimuth and elevation receive beamforming operate simultaneously; no
elevation scan. Boresight angle accuracy: first acceptance case. 90°
azimuth sector and one-second update: provisional goals, not established
±45° performance requirements. Configurable near-zero-Doppler band removes
static clutter; cutoff remains to be derived.
