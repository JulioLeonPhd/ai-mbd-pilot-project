
<!-- markdownlint-disable MD033 -->
<h1 align="center">AI-assisted model-based design pilot</h1>

<p align="center"><strong>Design the system. Learn one component at a
time.</strong></p>

<p align="center">
  A pilot in human-led model-based design with AI. Radar is the test case.
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)"
      srcset="docs/assets/pilot-hero-dark.svg">
    <source media="(prefers-color-scheme: light)"
      srcset="docs/assets/pilot-hero-light.svg">
    <img src="docs/assets/pilot-hero-light.svg" width="488"
      alt="Workflow: the engineer approves system architecture, including
      component boundaries. For each component, the engineer approves the
      design. AI implements it and writes a runnable walkthrough in parallel.
      The engineer approves both before closing via pull request.">
  </picture>
</p>

<p align="center">
  <a href="docs/agents/human-led-workflow.md">Human-led workflow</a> ·
  <a href="docs/examples/ddc-walkthrough.md">See a worked component</a>
</p>
<!-- markdownlint-enable MD033 -->

## Quickstart

Run a synthetic pulse-accumulation walkthrough with MATLAB R2025a or newer
and Base MATLAB. No toolbox, hardware, or external data is required.

From the repository root, with `matlab` on `PATH`:

```sh
matlab -batch "run('examples/runPulseAccumulationWalkthrough.m')"
```

The walkthrough reorders three synthetic range-result records by scheduled
pulse slot and displays the assembled samples, validity mask, range centers,
and ticks. It then shows a duplicate slot being rejected. The sample values
and ticks are teaching inputs, not measurements or acceptance results.

## Project scope

The intended demonstrator boundary runs from digitized ADC samples to a
detection list. Tracking and classification are outside scope. Development is
staged from a floating-point MATLAB reference toward fixed-point design and
then a Simulink representation.

> [!IMPORTANT]
> Available component-level implementations and evidence do not amount to a
> complete end-to-end MATLAB, fixed-point, or Simulink reference. This project
> makes no claims of hardware behavior, real-time performance, or detection
> performance.

The pulse-accumulation API,
`radardemo.pulseAccumulation.accumulateCpi`, orders per-PRI range results and
preserves samples alongside their validity masks, range coordinates, and source
ticks. Successful accumulation does not verify uniform pulse spacing or
establish Doppler readiness. See its
[contract](docs/contracts/pulse-accumulation.md) and
[focused tests](tests/pulseAccumulation/TestAccumulateCpi.m).

## Examples and evidence

| Start with | What it demonstrates |
| --- | --- |
| [Pulse accumulation walkthrough](examples/runPulseAccumulationWalkthrough.m) | Scheduled-slot ordering, preserved masks, and duplicate rejection using synthetic data. |
| [Range-compression walkthrough](examples/runRangeCompressionWalkthrough.m) | One synthetic PRI through the public per-PRI range-compression API. Requires MATLAB R2025a+ and Base MATLAB; run from the repository root with `matlab -batch "run('examples/runRangeCompressionWalkthrough.m')"` or use Live Editor. |
| [DDC walkthrough](docs/examples/ddc-walkthrough.md) | One synthetic ADC record spanning a complete PRI through the DDC, including frequency translation, filtering, decimation, and startup. Requires MATLAB R2025a+ and Signal Processing Toolbox. |
| [Ideal range-resolution study](evidence/radar_v1_range_resolution_study.m) and [saved results](evidence/radar_v1_range_resolution_results.json) | Read the recorded JSON without MATLAB; running the study script rewrites it. This ideal point-spread study is not receiver or hardware evidence. |

The [range-compression fixture report](tests/rangeCompression/range-production-acceptance-results.json)
records 96 completed records and 384 stream evaluations within that fixture's
scope. These counts do not establish end-to-end detection performance.
Walkthroughs explain behavior; consult each test and evidence artifact for its
own scope and limitations.

## Reviewing the project

| Question | Start here |
| --- | --- |
| What is the system boundary and what are the module responsibilities? | [Radar architecture overview](docs/architecture/radar-overview.md) |
| What behavior and data are specified? | [V1 requirements](docs/requirements/radar-matlab-v1.md) and [data contracts](docs/contracts/radar-v1-data-contracts.md) |
| Why were design choices made? | [Architecture decision records](docs/adr/) |
| How do agents work with the human owner? | [Human-led workflow](docs/agents/human-led-workflow.md) and [agent contract](AGENTS.md) |
| What do project terms mean? | [Domain glossary](GLOSSARY.md) |

Julio owns architectural decisions. Agents may investigate, prepare
evidence, and implement within approved choices; independent verification is
evidence, not human approval.

`uv` supports repository tooling only; the MATLAB walkthroughs do not require
a Python package install. Tracked plans and decisions provide durable project
context; an optional local `CURRENT.md` checkpoint may exist in some
worktrees.
