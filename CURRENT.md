# Current project status

## Last verified result

WP4/G2 Phase 1 documentation consolidation was independently validated and
committed in `da1e301`. Phase 2 numerical-fixture architecture is complete and
root-approved; the durable ledger is [the WP4/G2 recovery plan](docs/plans/wp4-g2-recovery-plan-2026-09-21.md).
No executable WP4 evidence exists yet, and G2 remains open.

On 2026-09-19, WP3 was independently accepted. The current checker passes 18
Python tests and 30 executable manifest rows. Ruff check/format, Markdown lint,
and `git diff --check` pass. Independent deep validation passed 24 semantic
probes plus malformed-input probes, with no implementation errors. The
normative cluster contract also passed independent semantic review.

The MATLAB checks recorded below are historical evidence from earlier work; they
were not rerun in this repair cycle. See the WP3 checker and manifest under
`contracts/wp3/`.

On 2026-09-14, WP2 completed and revised G1 passed for the bounded analytic and
ideal simulation candidate in [ADR 0014][adr0014].
WP0/G0 and WP1 were previously reviewed. MATLAB MCP ran the tracked coverage,
streaming, ideal range-resolution, and ideal angle studies; Code Analyzer found
no errors or warnings. Independent numerical and document reviews found no
unresolved errors. The revised G1 evidence is the [study](evidence/radar_v1_revised_g1_study.m)
and [results](evidence/radar_v1_revised_g1_results.json). The [V1 plan](docs/plans/radar-matlab-v1.md)
remains the work package source of truth.

WP3 now has accepted interface semantics for the five envelopes, canonical
examples, an architecture channel-map visual, a clock-epoch glossary entry,
replay provenance, and ignored/LFS vector storage rules: [data contracts](docs/contracts/radar-v1-data-contracts.md),
[architecture](docs/architecture/architecture.md), and [WP3 examples](contracts/wp3/examples/).
[The five-PRF decision and reopened CPI pulse-count rationale](docs/adr/0016-retain-five-prfs-and-reopen-cpi-pulse-count.md)
are recorded in ADR 0016. The provisional clustering and cross-PRF approach
remains subject to WP4 verification at G2; downstream WP6e may reject it and
reopen G2. The frozen schedule is `[22,25,28,32,35]` usable pulses with 151
records, 150 MHz integer ticks, transition gap `106872`, total `10553388`
ticks, cap `10597950`, margin `44562`, midpoint offset `5276694`, 2.849920 ms
transitions, 70.355920 ms total, and 0.297080 ms margin.
Clustering is frozen as
one-cell Chebyshev adjacency within a look only, with no edge wrap, invalid
bridging, or cross-look deduplication; WP6e selects the ambiguity order and
method.
WP3 is independently accepted. WP4/G2 Phase 0 is frozen by
[ADR 0018](docs/adr/0018-freeze-wp4-g2-phase0-contract.md): integer-tick
schedule, DDC budget, receive dimensions, fusion, and clustering seams are
accepted as contracts.
Executable WP4 verification remains pending, including complete valid, invalid,
zero-result, version-mismatch, and dimension-mismatch coverage; G2 is not
passed.

The JSON subset, MAT example, MATLAB Code Analyzer, Ruff, Markdown lint, and
Mermaid render checks passed. Independent documentation and code reviews found
no unresolved errors, with a coverage warning retained for incomplete fixture
coverage.

## Active gate

Revised G1 passed for the bounded analytic and ideal candidate. WP3 is
independently accepted. Active next work is Phase 3 WP4/G2 executable evidence
generation; G2 is the
shared technical gate for the WP3 data contracts and WP4 DSP/timing
architecture.

## Blockers and retained risks

Authenticated `gh` access works outside the sandbox. The
[issue drafts](docs/plans/radar-matlab-v1-issue-drafts.md) are ready but have not
been published; issue publication does not block technical work.

Revised G1 adopted an analytic and ideal simulation baseline, not verified DUT,
hardware, or real-time
performance. WP4 must verify usable pulses per PRF and prove timing,
receive-window priming, PRF transitions, and post-CFAR 3-of-5 fusion;
downstream WP6e evaluates performance and may reject the schedule, reopening
G2. The 128-pulse setting remains reopened by ADR 0016. The revised 10 MHz waveform
and DDC rate claims passed only their bounded G1 analytic checks. The noisy multi-target
ambiguity method remains WP6e study work. Sampled end-to-end 50 m separation,
noisy angle accuracy and detection performance remain downstream measurements,
not V1 gates.
The ±45° sector and one-second update are provisional. The V1 ideal input is a
band-limited 45–55 MHz ADC input centered at 50 MHz with a 150 MS/s ADC; ENOB
and jitter are downstream sensitivity studies. The MVP generator emits direct ADC-rate
vectors without sampling RF or modeling analog downconversion; coherent phase
uses the exact ADR 0015 carrier invariant.

## Next ready packages

- Implement the approved Phase 2 MATLAB-only architecture under `contracts/wp4/`.
- Generate and test temporarily first, then stop for root authorization of the
  immutable generator-source commit before regenerating tracked fixtures.
- Run the exact 54 acceptance tests, MATLAB Code Analyzer, and preserve the
  no-Python and no-WP6e-method constraints.
- Keep the ambiguity-resolution candidate open for WP6e; do not freeze its
  order or method at G2.

## Session handoff

The detailed continuation note is [the WP4/G2 recovery plan](docs/plans/wp4-g2-recovery-plan-2026-09-21.md).

The accepted receive-processing decision is recorded in [ADR 0017](docs/adr/0017-adopt-v1-commanded-look-receive-processing-and-g2-schedule.md):
64 channels remain through DDC, commanded-azimuth beamforming sums 16 elements
per elevation row to four streams, and range/Doppler operate on those four
streams. The documentation bundle has passed independent semantic review.

Do not redo the completed documentation or WP3 repairs. The latest independent
WP3 result is the authoritative continuation point: WP3 is accepted with no
unresolved implementation errors. Proceed with WP4/G2 verification; G2 is not
passed.

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
- [WP3 data contracts](docs/contracts/radar-v1-data-contracts.md) and
  [examples/checker directory](contracts/wp3/examples/)
- [WP4/G2 recovery plan](docs/plans/wp4-g2-recovery-plan-2026-09-21.md)

[adr0014]: docs/adr/0014-adopt-revised-v1-analytic-simulation-baseline.md
