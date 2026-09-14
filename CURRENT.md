# Current project status

## Last verified result

On 2026-09-14, WP2 completed and G1 passed for the bounded floating-point
simulation baseline in [ADR 0011](docs/adr/0011-adopt-v1-simulation-timing-baseline.md).
WP0/G0 and WP1 were previously reviewed. MATLAB MCP ran the tracked coverage,
streaming, ideal range-resolution, and ideal angle studies; Code Analyzer found
no errors or warnings. Independent numerical and document reviews found no
unresolved errors. The [V1 plan](docs/plans/radar-matlab-v1.md) remains the work
package source of truth.

## Active gate

Paused after WP2/G1 for the user's go-ahead. WP3 data contracts and WP4 DSP
architecture are ready to start in parallel. G2 is the next technical gate.

## Blockers and retained risks

Authenticated `gh` access works outside the sandbox. The
[issue drafts](docs/plans/radar-matlab-v1-issue-drafts.md) are ready but have not
been published; issue publication does not block technical work.

G1 adopted a simulation baseline, not verified DUT, hardware, or real-time
performance. WP4/G2 must prove 128 usable returns per PRF, receive-window
priming, and PRF transitions; a failure reopens G1. The noisy multi-target
ambiguity method remains WP6e study work. Sampled end-to-end 1 m separation,
noisy angle accuracy, and detection performance remain downstream gates.
The ±45° sector and one-second update are provisional.

## Next ready packages

- On user go-ahead, begin WP3 versioned data contracts and WP4 DSP/timing
  architecture in parallel, with G2 as their shared exit gate.
- Keep the ambiguity-resolution candidate open for WP6e; do not freeze it at G2.

## Evidence

- [Requirements](docs/requirements/radar-matlab-v1.md) and
  [V1 Pd/Pfa decision](docs/adr/0010-v1-pd-pfa-demonstration-gate.md)
- [WP2 feasibility report](docs/research/radar-v1-feasibility.md)
- [G1 simulation baseline decision](docs/adr/0011-adopt-v1-simulation-timing-baseline.md)
- [Coverage script](evidence/radar_v1_coverage_study.m) and
  [result](evidence/radar_v1_coverage_results.json)
- [Streaming benchmark](evidence/streaming_feasibility.m) and
  [result](evidence/streaming_feasibility_results.json)
- [Range-resolution study](evidence/radar_v1_range_resolution_study.m) and
  [result](evidence/radar_v1_range_resolution_results.json)
- [Angle study](evidence/radar_v1_angle_feasibility.m) and
  [result](evidence/radar_v1_angle_feasibility_results.json)
