# Current project status

## Last verified result

On 2026-09-14, WP2 completed and revised G1 passed for the bounded analytic and
ideal simulation candidate in [ADR 0014][adr0014].
WP0/G0 and WP1 were previously reviewed. MATLAB MCP ran the tracked coverage,
streaming, ideal range-resolution, and ideal angle studies; Code Analyzer found
no errors or warnings. Independent numerical and document reviews found no
unresolved errors. The revised G1 evidence is the [study](evidence/radar_v1_revised_g1_study.m)
and [results](evidence/radar_v1_revised_g1_results.json). The [V1 plan](docs/plans/radar-matlab-v1.md)
remains the work package source of truth.

## Active gate

Revised G1 passed for the bounded analytic and ideal candidate. WP3 data
contracts and WP4 DSP/timing architecture may proceed; G2 is their shared
technical gate.

## Blockers and retained risks

Authenticated `gh` access works outside the sandbox. The
[issue drafts](docs/plans/radar-matlab-v1-issue-drafts.md) are ready but have not
been published; issue publication does not block technical work.

Revised G1 adopted an analytic and ideal simulation baseline, not verified DUT,
hardware, or real-time
performance. WP4/G2 must prove 128 usable returns per PRF, receive-window
priming, and PRF transitions; a failure reopens G1. The revised 10 MHz waveform
and DDC rate claims passed only their bounded G1 analytic checks. The noisy multi-target
ambiguity method remains WP6e study work. Sampled end-to-end 50 m separation,
noisy angle accuracy, and detection performance remain downstream gates.
The ±45° sector and one-second update are provisional. The current 50 MHz IF
and 150 MS/s ADC are candidates; the MVP generator emits direct ADC-rate
vectors without sampling 3 GHz or modeling analog downconversion.

## Next ready packages

- Begin WP3 versioned data contracts and WP4 DSP/timing architecture, with G2
  as their shared exit gate.
- Keep the ambiguity-resolution candidate open for WP6e; do not freeze it at G2.

## Evidence

- [Requirements](docs/requirements/radar-matlab-v1.md) and
  [V1 Pd/Pfa decision](docs/adr/0010-v1-pd-pfa-demonstration-gate.md)
- [WP2 feasibility report](docs/research/radar-v1-feasibility.md)
- [G1 simulation baseline decision](docs/adr/0011-adopt-v1-simulation-timing-baseline.md)
- [50 m separability and narrowband DDC candidate](docs/adr/0012-adopt-50m-separability-and-narrowband-ddc-candidate.md)
- [150 MS/s ADC, 50 MHz IF, and direct sampled stimulus](docs/adr/0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md)
- [Revised G1 analytic simulation baseline](docs/adr/0014-adopt-revised-v1-analytic-simulation-baseline.md)
- [Coverage script](evidence/radar_v1_coverage_study.m) and
  [result](evidence/radar_v1_coverage_results.json)
- [Streaming benchmark](evidence/streaming_feasibility.m) and
  [result](evidence/streaming_feasibility_results.json)
- [Range-resolution study](evidence/radar_v1_range_resolution_study.m) and
  [result](evidence/radar_v1_range_resolution_results.json)
- [Angle study](evidence/radar_v1_angle_feasibility.m) and
  [result](evidence/radar_v1_angle_feasibility_results.json)

[adr0014]: docs/adr/0014-adopt-revised-v1-analytic-simulation-baseline.md
