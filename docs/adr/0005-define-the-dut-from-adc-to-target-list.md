---
status: accepted
---
# Define the DUT from ADC samples to a detection list

DUT receives real 16-bit ADC samples per channel; covers DDC and
decimation, fast-time and slow-time processing, CFAR, simple clustering, and
detection-list conversion. Reports contain range, radial velocity,
azimuth, elevation, documented detection statistic. DUT exposes
per-PRF candidate seam. CFAR, clustering, cross-PRF association, ambiguity
resolution, internal order remain subject to WP4/G2 and WP6e
executable selection; this ADR does not place CA-CFAR before
ambiguity resolution. ADR 0009 establishes core requirements and
conventions; ADR 0014 records current revised G1 waveform/rate candidate;
WP3 contract and WP4/G2 own exact interface values and validation.
