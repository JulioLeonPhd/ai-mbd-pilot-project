# AI-assisted model-based design pilot

This repository is a public reference project for an AI-assisted model-based
design (MBD) workflow. A radar processing demonstrator provides a concrete,
technically meaningful system on which to exercise requirements, architecture,
data contracts, quantitative studies, implementation, and independent review.
The radar is a workflow demonstrator, not a mission system.

## Current status

The project is in pre-build V1 development. The bounded analytic and ideal
simulation baseline has passed the revised G1 feasibility gate, and the WP3
data contracts and WP4 DSP/timing architecture are being prepared for G2.
The repository currently emphasizes decisions, contracts, studies, and agent
workflow; the floating-point MATLAB reference, fixed-point design, and
Simulink representation are not yet complete. Candidate values and open gates
are identified in the [current status](CURRENT.md).

## Demonstrator boundary

The planned device under test (DUT) runs from digitized ADC samples to a
detection list. Its processing path includes DDC and decimation, fast-time
range processing, slow-time Doppler processing, receive beamforming, CFAR,
clustering, and report conversion. Stimulus generation is outside the DUT and
is driven by versioned JSON radar configuration and target-scenario data;
generated test vectors are stored as MAT files. Tracking and classification are
outside the current scope.

The architecture is deliberately provisional while unresolved timing, filter,
migration, ambiguity, clustering, and performance decisions are settled. See
the [architecture overview](docs/architecture/architecture.md), [V1
requirements](docs/requirements/radar-matlab-v1.md), [implementation
plan](docs/plans/radar-matlab-v1.md), and [data contracts](docs/contracts/radar-v1-data-contracts.md).

## Repository guide

- [CONTEXT.md](CONTEXT.md) — project glossary, radar conventions, and equations.
- [CURRENT.md](CURRENT.md) — verified results, active gate, risks, and next work.
- [CHANGELOG.md](CHANGELOG.md) — release history.
- [docs/architecture](docs/architecture) — system boundary, stages, and interfaces.
- [docs/requirements](docs/requirements) — observable V1 requirements and evidence.
- [docs/plans](docs/plans) — work packages, gates, and delivery sequence.
- [docs/contracts](docs/contracts) — versioned interchange contracts and examples.
- [docs/adr](docs/adr) — decisions and their rationale, including scope and workflow.
- [evidence](evidence) — quantitative study scripts, results, and plots.
- [AGENTS.md](AGENTS.md) — orchestration contract for AI-assisted contributions.
- [LICENSE](LICENSE) — Apache License 2.0.

## Getting oriented

Start with [CURRENT.md](CURRENT.md) for the latest maturity and open work,
then read the [architecture](docs/architecture/architecture.md) and
[requirements](docs/requirements/radar-matlab-v1.md). The [plan](docs/plans/radar-matlab-v1.md)
maps the work packages and gates; the [contracts](docs/contracts/radar-v1-data-contracts.md)
define the interfaces that implementation must satisfy. Quantitative evidence
and reproducibility artifacts are collected under [evidence](evidence).

For contribution work, follow [AGENTS.md](AGENTS.md): it defines routing,
allowed specialist responsibilities, validation gates, MATLAB standards, and
documentation checks. The repository uses `uv` for the small set of development
tools described in [pyproject.toml](pyproject.toml). Portable MATLAB and Simulink
setup instructions will be added as those artifacts are built.

Validate the agent handoff contract and flat specialist registry with:

```sh
uv run --frozen python scripts/check_agent_handoffs.py
```

## License

Copyright © Julio León. Released under the [Apache License 2.0](LICENSE).
