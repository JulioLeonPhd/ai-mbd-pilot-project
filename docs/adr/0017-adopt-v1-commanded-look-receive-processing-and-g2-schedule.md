---
status: accepted
---

# Adopt V1 commanded-look receive processing and G2 schedule

## Context

WP3 and WP4 need stable seams while timing, ambiguity, and noisy performance
remain measurable. The array has 64 receive channels: 16 azimuth elements in
each of four elevation rows. The provisional broadside cell-time cap is
70.653 ms, and the five retained PRFs are `1700, 1900, 2150, 2450, 2700` Hz.

## Decision

For each commanded azimuth look, DDC preserves all 64 channels, then coherent
receive beamforming sums the 16 azimuth elements independently for each
elevation row. Range and Doppler operate on the resulting four complex
elevation streams; elevation processing follows at selected range-Doppler
cells. V1 reports the commanded look as azimuth and does not claim sub-beam
azimuth estimation. Multi-beam and monopulse refinement are future work.

WP4 provisionally selects and verifies equal-CPI usable pulses
`[22,25,28,32,35]` for the five PRFs, with no separate initial steering reserve.
The current arithmetic is 65.147760 ms usable dwell + 2.358240 ms priming +
2.849847 ms transitions = 70.355847 ms, leaving 0.297153 ms under the
70.653 ms cap. Downstream WP6e validates noisy
ambiguity, missed PRFs, ghosts, competing targets, and timing; it may reject
the schedule and reopen G2. The 45–55 MHz band-limited ADC-input assumption is
ideal for V1; ENOB and jitter are downstream sensitivity studies. Noisy angular
accuracy and operational sector coverage are reported measurements, not V1
gates. Clustering is one-cell Chebyshev adjacency within a single look only,
with no edge wrapping, invalid bridging, or cross-look deduplication.

## Alternatives and consequences

Processing all 64 channels independently through range and Doppler would retain
more azimuth information but is unnecessary for the commanded-beam V1 and
would multiply the processing seams. Summing only four channels would discard
the known 16-element azimuth aperture and its coherent gain. The selected
64-to-4 reduction preserves the azimuth steering operation and keeps elevation
information for downstream estimation, while making the loss of sub-beam
azimuth explicit.

The pulse schedule is a measurable provisional allocation, not a performance
claim. It resolves the WP4/WP6e dependency cycle by giving WP4 a contract
candidate while preserving WP6e authority to reject it and reopen G2 if
downstream evidence fails. Ambiguity-resolution
method and internal ordering remain deferred to WP6e.

This ADR supersedes the simultaneous azimuth/elevation receive-beamforming
clause in ADR 0009 for the V1 implementation seam; all other ADR 0009
decisions remain unchanged.

## Validation and reopen policy

G2 must verify integer tick timing, blanking, priming, transitions, filter
state/delay, the 70.653 ms cap, four-stream dimensions, steering signs, and
within-look clustering behavior. WP6e must provide noisy ambiguity and ghost /
competing-target evidence. Any failed timing, ambiguity, or contract criterion
reopens the affected G2 decision and triggers revision of the plan, contract,
or ADR before dependent implementation resumes.
