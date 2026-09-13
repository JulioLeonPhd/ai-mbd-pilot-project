---
status: accepted
---

# Set radar MVP acceptance and ambiguity requirements

The MVP maximum instrumented range is 100 km. Its primary case is a constant-
RCS 10 m² target at 100 km and approximately 800 km/h radial speed. Native
unambiguous radial velocity shall be at least ±40 m/s; range ambiguity shall
also be resolved, with true velocity reported through ±800 km/h. Four or five
distinct PRFs are the initial starting point, pending feasibility derivation.

CA-CFAR over range-Doppler cells is the first detector. Monte Carlo trials
shall estimate Pd and per-cell Pfa with confidence bounds, targeting Pd ≥ 0.9
and Pfa ≤ 10^-6. An ideal test shall resolve two moving equal-RCS targets
separated by 1 m in range and produce two detection-list reports. This is an
ideal mid-range, high-input-SNR test using equal targets with the same nonzero
radial velocity.

For the MVP, target RCS and Cartesian velocity remain constant throughout one
scan; acceleration and RCS fluctuation are separate future cases.

The reference array has 16 × 4 elements and 64 independently digitized real
16-bit receive channels. The receiver is blanked while transmission is on.
The MVP uses one coherent boresight transmit beam; no transmit scan has been
selected. The 90° sector update remains provisional until its illumination and
steering design is established.
Scenarios use a radar-centered Cartesian frame in metres and metres per second:
positive x is boresight and increasing range, positive y is radar-left, positive
z is up, and positive radial velocity is receding.

Azimuth and elevation receive beamforming operate simultaneously, with no
elevation scan. Boresight angle accuracy is the first acceptance case. A 90°
azimuth sector and one-second update are provisional goals, not established
±45° performance requirements. A configurable near-zero-Doppler band removes
static clutter; its cutoff remains to be derived.
