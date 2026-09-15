---
status: accepted
---

# Define the DUT from ADC samples to a detection list

The DUT receives real 16-bit ADC samples for each channel and covers DDC and
decimation, fast-time and slow-time processing, CFAR, simple clustering, and
conversion to a detection list. Reports contain range, radial velocity,
azimuth, elevation, and a documented detection statistic. The DUT exposes a
per-PRF candidate seam. CFAR, clustering, cross-PRF association, ambiguity
resolution, and their internal order remain subject to WP4/G2 and WP6e
executable selection; this ADR does not make CA-CFAR first relative to
ambiguity resolution. ADR 0009 establishes the core requirements and
conventions; ADR 0014 records the current revised G1 waveform/rate candidate,
while the WP3 contract and WP4/G2 own exact interface values and validation.
