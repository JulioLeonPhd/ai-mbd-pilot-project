# Radar V1 feasibility study

## Purpose and status

This report records the WP2 simulation baseline adopted at G1 and its MATLAB
MCP evidence. The results are analytic or idealized studies; they are not a
simulated DUT result, hardware feasibility claim, or real-time implementation.
The bounded-memory streaming proxy completed; the full streaming design remains
WP4 work. Noisy multi-target ambiguity unfolding remains a downstream risk.

## Candidate baseline

The candidate uses a 3 GHz carrier and a 250 MHz, 40 us LFM. The proposed IF is
156.25 MHz, sampled at 625 MS/s as real 16-bit data on 64 channels. DDC would
produce complex samples at 312.5 MS/s. Each of five PRFs targets 128 usable
returns per PRF, unverified until G2; the even ADC-sample PRI counts and
resulting PRFs are:

| PRI samples | PRF (Hz) |
| ---: | ---: |
| 367648 | 1699.99565 |
| 328948 | 1899.99635 |
| 290698 | 2149.99759 |
| 255102 | 2450.00039 |
| 231482 | 2699.99395 |

Transmission is blanked for 40 us with a 5 us guard. The acquisition schedule
uses a design target of 128 usable pulses per PRF, one priming PRI per PRF, and
four 0.712462 ms quiet gaps. Under those assumptions, the analytic scan
acquisition duration before processing and steering is 0.307058 s.

These are the G1 simulation baseline parameters, subject to the G2 timing and
contract checks. They are not yet a frozen implementation contract.

## Range, timing, and coverage evidence

At the common scan midpoint, the public reported reference-epoch range domain
is 6.80–100.00 km. Internal generation and search extend to 100.05 km. At
±800 km/h, the midpoint-to-edge motion is at most 34.117585 m. MATLAB MCP
continuous endpoint partitioning found at most two invalid PRFs and at least
three PRFs outside guarded blind bands over the stated domain. The 100 km
primary case is clear on all five PRFs. Using the full +50 m internal headroom,
its smallest
adjusted margin is 28.280646 us; using the ±34.117585 m motion allowance, it is
28.386602 us. These are analytic timing margins under the stated model.

No coverage claim is made below 6.80 km. Receive-window priming and transition
handling must be explicit in WP4, including the relationship between blanking,
guard time, and the reference epoch.

The [tracked executable coverage script](../../evidence/radar_v1_coverage_study.m)
and [JSON result](../../evidence/radar_v1_coverage_results.json) ran through
MATLAB MCP; MATLAB Code Analyzer evidence was also collected. The result proves
that every range in the closed 6.80–100.00 km domain has at least three valid
PRFs under the analytic continuous guarded-coverage model. It does not prove
noisy detection or ambiguity unfolding. Priming, 128 usable returns per PRF,
and PRF transition scheduling remain WP4/G2 verification items; a failure
reopens G1.

## Doppler ambiguity

For a monostatic radar, radial velocity and Doppler frequency follow

\[
f_d = \frac{2v}{\lambda}, \qquad \lambda = \frac{c}{f_c}.
\]

Correct transmit-to-return association, all 128 usable returns, and PRF
transitions are unverified until WP4/G2; a failure reopens G1. The candidate has
a single-PRF conflict: native coverage of ±40 m/s requires a
PRF of at least 1601.11 Hz, while 100 km unambiguous range requires a PRF no
higher than 1498.96 Hz. The five-PRF candidate native spans are approximately
±42.47 to ±67.45 m/s, so multi-PRF fusion is required for the stated velocity
domain.

Noisy multi-target unfolding remains unresolved and is WP6e study work. WP4
should preserve zero-folded candidates through multi-PRF fusion, align range
under each true-velocity hypothesis before coherent Doppler processing, and
apply the near-zero-Doppler veto only after velocity unfolding. The expected
range migration is approximately 10.5–16.7 m per dwell.

## Range resolution and angle evidence

For the B250 candidate, the nominal range resolution is 0.5996 m and the
baseband sample spacing is 0.4797 m. The [tracked ideal range-resolution
study](../../evidence/radar_v1_range_resolution_study.m) and [results
JSON](../../evidence/radar_v1_range_resolution_results.json) ran through MATLAB
MCP with no Code Analyzer issues. The finite ideal coherent sinc model sweeps
relative phase and 16 native-grid offsets using a study-only split criterion.

On the native grid, B250 passes 4273/5760 cases; its 4× output-grid candidate
passes 5760/5760 with a least-deep valley of −6.901 dB. The fine B250 4× sweep
passes 3232/3232 cases. B200 passes 1508/5760 native cases and 3440/5760 at
4×. Each bandwidth comparison uses its own native spacing \(c/(2.5B)\): B200
corresponds to a 500 MS/s real ADC and 250 MS/s complex baseband candidate,
while B250 uses 625 and 312.5 MS/s. The JSON's `worstValleyDb` includes
two-peak cases that fail the split criterion; all B250 4× cases pass. The 4×
output grid is the candidate for further study. Independent MATLAB MCP
recomputation matched the finite-sweep results with no numerical error. This
does not prove every real-valued phase or sampled ADC/DDC processing, CFAR
behavior, or two detection reports.

The receive array remains 16 × 4 with simultaneous azimuth and elevation
processing. The [tracked ideal angle study](../../evidence/radar_v1_angle_feasibility.m)
and [JSON result](../../evidence/radar_v1_angle_feasibility_results.json) ran
through MATLAB MCP with no Code Analyzer issues. An independent MATLAB MCP
calculation reproduced its 6.36° azimuth and 26.32° elevation half-power widths,
boresight and signed off-axis estimates, and maximum 0.04° error in four
noiseless matched-manifold grid fixtures. It supports a proposed ≤0.1°
per-axis **noiseless WP6d unit-test** tolerance over the tested ±5° azimuth and
±15° elevation search grid. Noisy accuracy and operational elevation coverage
remain WP4/G2 decisions. The provisional ±45° sector is not demonstrated: an
ideal fixed boresight transmit beam is about −24 dB at +45° and has nulls.

## Illustrative RF budget

The following is an illustrative boresight calculation, not a hardware
feasibility result: peak transmit power 10 kW, transmit and receive gains
23 dBi each, 6 dB loss, 4 dB noise figure, 290 K temperature, 10 m² RCS, and
100 km range. It gives monostatic received power −132.98 dBm, one-pulse SNR
−6.99 dB, and ideal 128-pulse coherent SNR 14.09 dB before additional
processing losses. Average
transmit power is approximately 848 W averaged over the five 128-pulse dwell
intervals (approximately 0.301850 s), excluding priming and quiet gaps. This is
an illustrative simulation/RF assumption; hardware, implementation, and
real-time claims require separate evidence.

## Data volume and streaming evidence

Raw input is approximately 80 GB/s. Five 128-pulse full-PRI ADC dwells over
0.30185 s total 24.148 GB under the candidate sample-count model; this is not a
separately evidenced receive-only volume. With 16 GB host RAM and 533 GiB free
disk, a full vector cannot fit in RAM; a pulse slab is approximately 47 MB raw.
The [tracked high-entropy
streaming benchmark](../../evidence/streaming_feasibility.m) and [results
JSON](../../evidence/streaming_feasibility_results.json) completed through
MATLAB MCP with no Code Analyzer errors or warnings (two informational notices).

The representative 1700 Hz dwell measured 6.023544832 GB raw and 6.110324039
GB in MAT v7.3 (compression ratio 1.0144). It completed 128 exact pulse-slab
round trips: 170.286 s write, 58.773 s read/proxy processing, and 229.059 s
total. A linear proxy for five identical representative dwells is 1145.295 s
(approximately 19.1 minutes), not a measured result and not the candidate
five-PRF acquisition time. The candidate five-PRF acquisition figure is
0.3018502144 s for 128 returns per distinct PRF, excluding priming and quiet
gaps, and remains conditional on G2. Maximum sampled RSS was 1,709,632 KiB
(about 1.63 GiB) over 254 samples, and temporary-file cleanup succeeded. One
local seeded
RandStream generates pulse slabs sequentially per benchmark run.

The initial compressible benchmark was rejected and corrected. This proxy does
not prove handling of the complete 24 GB vector, production filtering, or
real-time capture; the one-second sector update remains provisional. WP4 must
define slab boundaries, intermediate persistence, and processing order before
WP5 fixtures and WP6 integration are frozen.

## G1 decision and next work

G1 passed for the bounded simulation baseline in
[ADR 0011](../adr/0011-adopt-v1-simulation-timing-baseline.md). The four
tracked MATLAB MCP studies ran and passed Code Analyzer without errors or
warnings; independent numerical review confirmed the coverage, range,
angle, and streaming evidence without unresolved errors. Independent semantic
review found no unresolved errors. G1 accepts the 250 MHz waveform, sampled
rates, five quantized PRIs, reference-epoch range domain, and a target of 128
usable returns per PRF for WP3/WP4 contract work. It does not certify the full
128-return schedule, priming, or transitions; WP4 must prove those at G2 and
reopen G1 if the baseline fails. The 4× range output grid and ≤0.1° ideal angle
unit tolerance are study-backed candidates for WP4/WP6, with the narrow scopes
stated above.

The WP6e noisy multi-target unfolding study and sampled end-to-end confirmation
of the 1 m two-target result are downstream validation risks. They belong to the
G3/G4 gates after G2; a failure may reopen G1 or G2 through the documented gate
process, but neither is a predecessor of G1.

WP4 should incorporate receive-window priming, true-velocity range alignment,
candidate retention, post-unfolding clutter veto, and streaming boundaries.
WP3 and WP4 may begin after the user's package-level go-ahead. No downstream
performance claim is implied by G1 acceptance.
