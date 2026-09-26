# AI-assisted model-based design pilot

This public reference project explores how AI agents can support model-based
design while a human engineer retains architectural authority. A radar
processing demonstrator gives the workflow a concrete engineering problem and
supports learning about requirements, architecture, data contracts, quantitative
evidence, implementation, and independent review. It is a demonstrator, not a
mission system.

## Learning goals

- Follow decisions from system requirements through data contracts and
  implementation evidence.
- Compare analytic studies, ideal simulations, and measured implementation
  behavior without treating them as interchangeable evidence.
- Learn how bounded agent tasks, explicit human decisions, and independent
  validation support a reviewable engineering workflow.

## System boundary and current capability

The planned device under test (DUT) processes digitized ADC samples into a
detection list. Its processing path includes DDC and decimation, fast-time range
processing, slow-time Doppler processing, receive beamforming, CFAR, clustering,
and report conversion. Stimulus generation is outside the DUT and uses
versioned JSON radar configuration and target-scenario data; generated test
vectors are MAT files. Tracking and classification are outside the current
scope.

The bounded analytic and ideal simulation baseline passed revised G1. WP3 data
contracts and WP4 DSP/timing evidence are accepted at G2. The current WP4
evidence verifies schedule timing, priming, post-CFAR 3-of-5 fusion, and
single-channel DDC streaming within stated limits. It does not establish
hardware or real-time performance, full FIR precursor/waveform retention, or
detection performance. Partial production-like floating-point modules, fixture
generation, an independent oracle, and adapters are present; the complete
ADC-to-detection floating-point reference is not complete. Fixed-point design
and the Simulink representation also remain incomplete. See [CURRENT.md](CURRENT.md)
for active questions and the
[dated evidence handoff](docs/reference/current-evidence-2026-09-25.md) for
detailed replay instructions and historical results.

## Architecture

The [radar overview](docs/architecture/radar-overview.md) presents context,
processing, data, and timing views. The existing
[architecture document](docs/architecture/architecture.md) records the system
boundary, processing stages, and interfaces. The human-confirmed module and
ADC decisions are recorded in [ADR 0019](docs/adr/0019-adopt-human-led-module-design-and-simulink-staging.md),
[ADR 0020](docs/adr/0020-adopt-pilot-adc-storage-and-sample-integrity.md), and
[ADR 0021](docs/adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md);
independent document review passed on 2026-09-26 with no unresolved semantic
findings. Julio's visual review of the redrawn diagrams remains pending. These
decisions do not claim the complete ADC-to-detection implementation exists.
Proposed architecture changes
require Julio's review before code is restructured.

## Human and agent roles

Julio owns architecture decisions, including system decomposition, interfaces,
algorithm choices, state and timing behavior, and consequential requirement
changes. Agents may investigate, propose concrete alternatives, prepare
evidence, and implement within decisions Julio has approved. Routine work
inside an approved design can proceed autonomously. Independent verification
supplies evidence; it does not imply human approval. Historical decisions stay
in force until Julio explicitly revises them. See the
[human-led workflow](docs/agents/human-led-workflow.md) and
[agent orchestration contract](AGENTS.md).

## Start here

1. Read [CURRENT.md](CURRENT.md) for the present capability, limits, and next
   open question.
2. Start with the [ideal range-resolution sweep](evidence/radar_v1_range_resolution_study.m)
   and its [recorded results](evidence/radar_v1_range_resolution_results.json).
   The finite coherent sinc point-spread study varies bandwidth in Hz, range
   grid spacing in meters, relative phase in degrees, and reports valley depth
   in dB. It shows how those ideal assumptions affect a two-target valley
   criterion; it does not exercise sampled ADC data, DDC, matched filtering, or
   measured hardware. To run it without rewriting the tracked result, copy the
   script to a temporary directory and run it there (MATLAB with a valid
   license must be available on `PATH`):

   ```sh
   study_dir="$(mktemp -d)"
   cp evidence/radar_v1_range_resolution_study.m "$study_dir/"
   (cd "$study_dir" && matlab -batch radar_v1_range_resolution_study)
   ```

   The run should print `B250 Q4: 5760/5760 ideal-grid cases; headline match: 1.`
   and write the JSON result beside the temporary copy. That observation
   reproduces the saved headline for the ideal model; it is not evidence of
   end-to-end receiver or detection performance. If MATLAB is unavailable,
   inspect the checked-in source and result instead.
3. Use the [V1 implementation plan](docs/plans/radar-matlab-v1.md) for work
   packages and gates, then consult the [architecture](docs/architecture/architecture.md),
   [requirements](docs/requirements/radar-matlab-v1.md), and [data contracts](docs/contracts/radar-v1-data-contracts.md)
   when you need their specific details.
4. For domain vocabulary and equations, see [CONTEXT.md](CONTEXT.md) and its
   linked [radar equations reference](docs/reference/radar-equations.md).

## Repository guide

- [CURRENT.md](CURRENT.md) — concise current state and next decision.
- [docs/reference](docs/reference) — dated evidence snapshots and technical
  reference material.
- [docs/architecture](docs/architecture) — system boundary, stages, and
  interfaces.
- [docs/requirements](docs/requirements) — observable V1 requirements and
  evidence.
- [docs/plans](docs/plans) — work packages, gates, and delivery sequence.
- [docs/contracts](docs/contracts) — versioned interchange contracts.
- [docs/adr](docs/adr) — accepted decisions and their rationale.
- [docs/agents](docs/agents) — contribution workflow, agent guidance, and
  handoffs.
- [AGENTS.md](AGENTS.md) — routing, authority, validation, and completion
  contract for AI-assisted contributions.
- [LICENSE](LICENSE) — Apache License 2.0.

The project uses `uv` for repository tooling. MATLAB and Simulink setup
instructions will be added as those artifacts are built.

## License

Copyright © Julio León. Released under the [Apache License 2.0](LICENSE).
