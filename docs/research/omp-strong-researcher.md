# Proposed strong Researcher role and evidence flow

**Status: proposal for Julio's decision.** This note evaluates a research
responsibility and handoff topology; it does not change routing policy or
authorize implementation.

## Research question

How should evidence collection, analysis and Markdown authoring be assigned so
that analysis has an explicit owner, sources and uncertainty remain traceable,
and Julio's and the root's authority boundaries are preserved?

## First-party findings

GitHub Copilot CLI documents `/research` as an orchestrator/subagent workflow;
its current built-in-agent reference names `claude-haiku-4.5` as the research
agent's default. That establishes a precedent for research-owned fan-out, not a
fixed two-model pair or a separate writer role. The CLI guide says the research
model is independent of the main-session model and cannot be changed with
`/model`. The CLI's `rubber-duck` critic is a separate complementary-model
feature, not a documented `/research` pairing. These are product documents, not
evidence of the model used by every participant in a particular run. Microsoft
365 Researcher's Critique and Model Council are different product features,
not evidence of a GitHub CLI model pair. ([GitHub CLI research guide](https://docs.github.com/en/copilot/how-tos/copilot-cli/use-copilot-cli/research-with-copilot-cli);
[CLI built-in agents](https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-command-reference#built-in-agents);
[CLI v1.0.40 release notes](https://github.com/github/copilot-cli/releases/tag/v1.0.40);
[CLI second opinion](https://docs.github.com/en/copilot/concepts/agent-capabilities/choosing-and-delegating-agent-work/getting-a-second-opinion#second-opinion-from-another-model);
[Microsoft 365 model choice](https://support.microsoft.com/en-us/office/use-model-choice-in-the-researcher-agent).)

OMP v19.1.0 supports native Markdown-defined specialist roles with model and
thinking-level settings, tools, and spawn policy. Runtime selection can be
affected by per-role overrides and enabled per-call selectors; a configured
default alone does not prove the effective model or effort. An empty `spawns`
setting denies native child spawning, but additive MCP, extension, or custom
tools mean this is not an operating-system sandbox. Native OMP can technically
express a scout child (`spawns: scout`), subject to depth and plan-mode gates;
the setting restricts child identity, not run count, cost, or filesystem access.
This capability is not authorization to use it. ([OMP v19.1.0 role
discovery and model selection](https://github.com/can1357/oh-my-pi/blob/v19.1.0/docs/task-agent-discovery.md#agent-definition-shape);
[model precedence and per-call model](https://github.com/can1357/oh-my-pi/blob/v19.1.0/docs/task-agent-discovery.md#model-and-structured-output-precedence);
[parent spawn policy](https://github.com/can1357/oh-my-pi/blob/v19.1.0/docs/task-agent-discovery.md#parent-spawn-policy);
[spawn-policy implementation](https://github.com/can1357/oh-my-pi/blob/v19.1.0/packages/coding-agent/src/task/spawn-policy.ts#L18-L48).)

Project authority is narrower than technical capability. ADR 0023 freezes new
roles and orchestration layers until radar v1. ADR 0028 permits only its
specified six-role simplification and explicitly leaves other infrastructure
work unauthorized. Issue #28 requires non-writer evidence collection and
root-routed cited findings to the existing `technical-writer`; the writer may
consult supplied references for accuracy but returns evidence gaps rather than
researching. Neither #28 nor these ADRs authorizes a seventh role or nested
delegation. ([ADR 0023](../adr/0023-freeze-ai-infrastructure-until-v1.md);
[ADR 0028](../adr/0028-permit-bounded-omp-native-orchestration-simplification.md);
[issue #28](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/28).)

## Proposed responsibility

A strong Researcher owns the research question, evidence plan, analysis,
conflicting-source adjudication, insights, and uncertainty. It can inspect
primary sources directly when decisive. Optional scouts collect only bounded
source evidence and return citations and observations; they do not own synthesis
or conclusions. The technical-writer drafts from the Researcher's cited
handoff, flags missing evidence to root, and does not expand into research. Root
retains routing, sequencing, acceptance, and overall conflict resolution; the
Researcher adjudicates conflicting evidence. Julio retains consequential
architecture authority.

## Flow alternatives

| Flow | Handoff | Trade-off and boundary |
| --- | --- | --- |
| **A — Researcher dispatches scouts** | Root assigns Researcher; Researcher may dispatch bounded scouts, synthesize evidence, and return cited findings to root; root assigns the writer. Scouts do not spawn children. | Removes the root-to-scout relay and allows Researcher to request follow-up directly. This does not uniquely enable adaptation or establish gains. Native OMP can express this, but it requires Julio's approval both for a seventh role and an exception to root-only dispatch/no-spawn constraints, plus guardrails. `spawns: scout` does not limit run count, cost, or filesystem access. It is not authorized or tested. ([OMP task tool outputs and notes](https://github.com/can1357/oh-my-pi/blob/v19.1.0/docs/tools/task.md#outputs)) |
| **B — root dispatches optional scouts** | Researcher frames evidence questions; root alone dispatches optional scouts and the writer, and relays scout results to Researcher; Researcher synthesizes and returns cited findings to root. | Keeps dispatch root-only and preserves the current no-spawn constraint for Researcher and scouts, at the cost of another handoff and possible context or latency overhead. A new named Researcher identity needs Julio's approval. |

## Recommendation and approval boundary

**Recommend B as the first proposal to evaluate**, not as approved policy. It
preserves the Researcher as analysis owner while keeping routing and dispatch
with root; scouts remain optional, and Researcher may inspect decisive primary
sources directly. Root retains routing, sequencing, and acceptance. Consider A
only after a separate decision by Julio, based on observed friction; it needs
approval for both the new identity and exceptions to root-only dispatch and
no-spawn constraints. Technical expressibility is not permission. No fixed
scout count, model pair, or new router is proposed.

If Julio approves a B trial, use one representative question involving
conflicting evidence. Assess whether handoffs distinguish direct observations,
cited claims, inferences, and unresolved points; record effective model and
effort, packet ownership, and scout bounds; confirm only root dispatches scouts
and the writer, neither Researcher nor scouts spawn children, and the writer
does not research. This is a proposed acceptance exercise, not evidence of
quality or savings. Keep implementation, independent validation, and human
approval distinct.

## Execution evidence and limits

For this investigation, the observed generic evaluation-worker session metadata
was selected model `openai-codex/gpt-6.2-astra:xhigh`, with runtime
`thinking_level_change` at `xhigh`. This was not a deployed Researcher and does
not evaluate model quality. No Copilot CLI execution or prototype role dispatch
was performed. Source and policy claims above are bounded to the cited first-
party materials; they do not establish runtime behavior for a proposed role.
