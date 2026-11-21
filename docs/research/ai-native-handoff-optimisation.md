# AI-native handoff optimisation pilot

This pilot asks whether a disposable change to specialist handoffs can reduce the token and cost burden of routine engineering work without weakening traceability, validation, or task outcomes. It is an infrastructure-learning record for project contributors; it is not a Radar Demonstrator walkthrough or an architecture decision.

The accepted [AI infrastructure freeze](../adr/0023-freeze-ai-infrastructure-until-v1.md) prioritises radar v1 and defers infrastructure expansion until that milestone. It allows recording limitations and permits minimal maintenance when infrastructure blocks or materially impairs v1 work.

[ADR 0028](../adr/0028-permit-bounded-omp-native-orchestration-simplification.md) records a distinct, bounded exception to that freeze: simplifying the OMP-native specialist inventory under the [OMP-native orchestration simplification plan](../plans/omp-native-orchestration-simplification.md). It does not authorize this handoff-optimisation experiment or adoption of a handoff variant.

The [handoff optimisation plan](../plans/agent-handoff-token-optimisation.md) describes a staged approach; this pilot does not change that plan, project policy, role definitions, or infrastructure.

The user authorised trying a disposable variant for comparison, not adopting it. The measurements below are a one-run baseline, not a before/after result. No savings or improvement have been established.

## Research question

Can a bounded change to handoff instructions or packet use reduce specialist-call input and cost for representative trivial engineering, stateful engineering, and documentation tasks while preserving the expected artifact, checks, and handoff quality?

A formal comparison must run each case as five paired baseline/candidate repetitions, using equivalent tasks and inputs. Pin repository, model, and tool configuration where controllable; use and record alternating or randomised run order and the seeds and settings. Record the candidate's actual configuration and outcomes, and distinguish observed telemetry from estimated or unavailable measures. These baseline observations alone cannot answer the question.

## Baseline observations

Each case was run once. Token counts below are the OMP-reported native JSONL model-usage measurements, summed across specialist calls in that case. “Uncached input” and “cached input” are reported separately; they are not interchangeable measures. The cost figure is presented separately in the chart.

| Pilot case | Specialist calls | Uncached input tokens | Cached input tokens | Output tokens |
| --- | ---: | ---: | ---: | ---: |
| Trivial MATLAB (`BaselineTrivial1`) | 1 | 19447 | 33024 | 250 |
| Stateful MATLAB (`BaselineEngineering1`, `BaselineEngineeringImpl1`, `BaselineEngineeringReview1`) | 3 | 69292 | 73216 | 2437 |
| Documentation (`BaselineDocs1`, `BaselineDocsReview1`) | 2 | 36987 | 58880 | 1289 |

![OMP-reported specialist cost by pilot case](ai-native-handoff-pilot-cost.svg)

The chart shows OMP-reported specialist cost for these same baseline cases. It excludes root-agent cost and is not an invoice or a claim about provider-billed charges.

## Separate smoke observation

In a separate concurrent smoke comparison, the same Terra medium model made two model requests per variant. The task message, including the host wrapper, was 713 bytes for control and 596 bytes for the variant. By inspection, both corrected the same conversion.

This was one unpinned pair, run concurrently. It is not the formal paired benchmark, does not establish equivalent conditions or outcomes beyond that observed correction, and is not evidence of token or cost savings.

## Evidence and limitations

- Runtime logs confirmed the configured model and reasoning level for all six specialist calls, with no fallback observed. Native child spawning was denied. Additive MCP tools were not isolated by that denial.
- Two read-only validators could not resolve the local Git pins independently. The root matched the local glossary byte-for-byte. Baseline task fixtures were inline and unpinned, so the inputs are not reproducible from immutable fixture references.
- Checks were static only; this pilot provides no behavioral or end-to-end verification evidence. Each baseline case ran once, so there are no repetitions or basis for statistical claims. The separate smoke observation is not a formal paired baseline/candidate result.
- The OMP-reported costs are measurements reported by the tooling, not invoices. Root-agent cost is excluded. Do not interpret them as total workflow cost.
- The observations do not establish that the handoffs were equivalent in task difficulty or that any candidate preserves artifact quality, validation coverage, or successful outcomes.

The formal disposable candidate comparison remains pending. Follow the [plan's before/after evaluation](../plans/agent-handoff-token-optimisation.md#beforeafter-evaluation): complete five paired baseline/candidate repetitions for each case, hold repository/model/tool configuration constant where controllable, and record the configuration, order, seeds, task inputs, specialist calls and outcomes, exposed token and cost measurements, and checks against baseline acceptance. Report unavailable metrics explicitly.

The plan's adoption gate is no acceptance or validation regression and a lower median end-to-end cost. Keep results as evidence for a later review; meeting that gate would not itself authorize adoption, which requires a separate decision.

## Sources

- [Handoff token optimisation plan](../plans/agent-handoff-token-optimisation.md) — `791f9c668da3eb08ff8a7589ac361c9893a23baa`.
- [Freeze AI infrastructure until v1 (ADR 0023)](../adr/0023-freeze-ai-infrastructure-until-v1.md) — `791f9c668da3eb08ff8a7589ac361c9893a23baa`.
- Baseline usage and cost figures: task-provided OMP native JSONL usage summary; fixture inputs are inline and unpinned.
