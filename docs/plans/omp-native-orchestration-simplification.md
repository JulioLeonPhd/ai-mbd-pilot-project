# OMP-native orchestration simplification

**Status:** The bounded implementation and runtime probes are complete for Julio's review under the authorization in [ADR 0028](../adr/0028-permit-bounded-omp-native-orchestration-simplification.md); final static, documentation, and independent semantic/evidence checks passed. This is not human approval or gate advancement.

## Problem Statement

The project previously maintained nine OMP specialist identities and nine Codex specialist definitions, including three standard/deep pairs that duplicated responsibility while encoding capability level in identity.

The agreed simplification removes duplicate role machinery; no measured savings or quantified quality/latency improvement is claimed.

The accepted infrastructure freeze prioritises radar V1, and this work is a narrowly scoped exception rather than general authorization to resume infrastructure development.

The original proposed success criterion required demonstrated net payback before radar V1.
On 2026-11-13, Julio explicitly revised that criterion through the `approve_structural_simplification` decision: structural simplification is approved without requiring demonstrated pre-V1 payback.
This supersedes the earlier payback-as-a-condition decision, while retaining effort accounting, the two-evening target, one-week hard cap, correctness and safety requirements, and rollback.

The work must still preserve domain ownership, runtime-specific safety, independent review, and higher-capability escalation for consequential work.

## Solution

After the specified prerequisite and explicit decision gates, replace the nine OMP project specialist identities with exactly six self-contained OMP-native identities: `matlab-architect`, `matlab-implementer`, `simulink-implementer`, `matlab-validator`, `technical-writer`, and `technical-writer-validator`.

Keep the three standard/deep pairs as one identity each, and express higher capability through an exact approved task-specific native execution selection rather than a second project identity.

Retain distinct MATLAB-source and Simulink-model implementation responsibilities, and make the boundary actionable for ambiguous work.

Use OMP's existing native provider, model, and subscription-backed authentication support; do not add an external-agent launcher or orchestration/provider layer.

Retain Codex only as a direct single-agent fallback for bounded investigation, approved implementation, and prescribed checks; do not maintain a parallel Codex project-specialist topology or deep profiles. Preserve applicable platform safety controls and do not claim role declarations reproduce an operating-system sandbox.
Permit generic workers for bounded reconnaissance, source-evidence collection, mechanical comparison, and prescribed check execution, while reserving domain design, authorized domain mutation, independent engineering judgement, and consequential documentation responsibility for the proper project specialist and root-led workflow.

Keep the existing task/result packet and governance. The root owns routing and adjudication, Julio retains consequential architecture authority, and validation remains independent and nonrepairing.

The plan records a specific conditional exception to the infrastructure freeze: after the entry gate and human authorization, the bounded simplification may proceed under the preserved safety, effort, correctness, acceptance, and rollback limits.

The rationale is removing duplicated role machinery after a complete engineering milestone; this approval is structural and does not claim measured savings or quantified improvement.

**Entry gate:** the range-compressor PR must be merged into `main` and its GitHub release published.

The entry gate is verified: [PR #26](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/pull/26) merged into `main` at 2026-11-13T10:29:25Z as `64ed326b06041973e7fff71272c77f525c4ee600`, and [release v0.9.0](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/releases/tag/v0.9.0) was published at 2026-11-13T10:43:29Z.

The scoped exception and implementation authorization are recorded in [ADR 0028](../adr/0028-permit-bounded-omp-native-orchestration-simplification.md).
OMP 18.20.0, the configured model routes, operator permission for the probed per-task selection, and the configured effort maximum were observed for these probes; recheck them after configuration changes or before using a different route.

Disposable read-only routing probes completed for each of the six retained OMP roles.
Runtime-owned `session_init` records show each has `spawns: ""` and only its declared built-in read-only or read-write tool set, with no `task` builtin.
Additive mounted tools, including mutation-capable MCP tools on inspection-only roles, remain available; inspection-only status is a policy and built-in restriction, not an enforced full-tool or operating-system boundary.

The bounded public-dispatch probes also exercised the same `matlab-architect` identity for ordinary and escalated tasks.
Runtime-owned records show OMP 18.20.0, the configured ordinary default resolving to `openai-codex/gpt-5.6-sol` at `high`, and explicit selection resolving to `openai-codex/gpt-6.1-sol` at `max`; both reported `resolvedModelIsFallback=false`.
The records include native `model_change` and `thinking_level_change` events.
This establishes the observed probe behavior only; it is not evidence of provider-internal reasoning or acceptance of other runtime scenarios.

The same generic bundled task-worker identity used the native provider probes; it has `spawns: "*"` and a `task` builtin.
The probe instructions prohibited child spawning and no children were spawned, but the runtime configuration does not enforce that prohibition.
Generic provider probes resolved to `openai-codex/gpt-6.1-sol` at `medium` and `github-copilot/auto-mai-code-1.1-flash` at `high`; the latter actual provider response model was `mai-code-1.1-flash`.
The runtime-owned records reported no fallback.
These observations establish neither equal capability, independent quota pools, strict packet adherence, nor cross-route reliability.
The runtime acceptance record at [evidence/omp-native-orchestration-runtime-acceptance.json](../../evidence/omp-native-orchestration-runtime-acceptance.json) contains exact public-dispatch inputs and runtime metadata. The six retained identities routed their representative tasks; ordinary and escalated architecture dispatch preserved identity and resolved to `openai-codex/gpt-5.6-sol`/`high` and `openai-codex/gpt-6.1-sol`/`max`. Generic native provider probes also completed. Negative probes rejected an unavailable approved route, disabled per-task selection, a project-excluded model, and the removed deep role. A request for `max` resolved to `high`, which root rejected as proof of the required `max` capability. User-provided direct Codex transcript evidence records a bounded read-only inventory check; it is not an OMP-executed or independently verified test. Its session completed despite nonblocking model-catalog refresh connection warnings and an ignored user-feature setting.

If native escalation cannot preserve required capability using supported controls and observable execution results, stop and return the unresolved choice to Julio; do not restore removed identities under new names or create a custom router.

If authority boundaries leak, the acceptance or correctness bar changes, the cap is exceeded or at risk, or rollback cannot be performed safely, restore the known-good active configuration or defer/revert the migration and seek a new human decision.

A ready-for-agent issue label means specification readiness only; it does not waive the entry gate, recorded exception, operator grants, Julio's authority, independent validation, or release governance.

## User Stories

1. As Julio, I want the exception and its prerequisites stated explicitly, so that a ready-for-agent issue cannot be mistaken for authority to start work during the freeze.
2. As Julio, I want implementation to begin only after the range-compressor PR is merged and its GitHub release is published, so that the proposal does not interrupt an unfinished engineering milestone.
3. As Julio, I want the actual PR and release identities recorded at the entry gate, so that implementation is traceable to the completed prerequisite.
4. As Julio, I want the formal scoped exception and applicable decision recorded, so that the proposal does not silently reinterpret the accepted freeze.
5. As a project maintainer, I want exactly six project-specific OMP identities, so that the active specialist inventory reflects the agreed responsibility boundaries without duplicate deep profiles.
6. As a root orchestrator, I want MATLAB architecture tasks routed to `matlab-architect`, so that domain design ownership remains explicit.
7. As a root orchestrator, I want MATLAB source and test changes routed to `matlab-implementer`, so that ordinary source mutation has a clear owner.
8. As a root orchestrator, I want model topology, interface, sample-time, or configuration changes routed to `simulink-implementer`, so that model-level work remains distinct from source implementation.
9. As a root orchestrator, I want ambiguous MATLAB-versus-Simulink implementation tasks surfaced for routing judgement, so that overlapping mutation authority is not left to competing agents.
10. As a root orchestrator, I want MATLAB engineering validation routed to `matlab-validator`, so that validation is a domain responsibility rather than a second implementation assignment.
11. As a root orchestrator, I want consequential Markdown authoring routed to `technical-writer`, so that technical meaning and evidence boundaries are maintained.
12. As a root orchestrator, I want consequential document review routed to `technical-writer-validator`, so that authors do not approve their own claims.
13. As an architect, I want the same architecture identity available for ordinary and escalated work, so that execution capability does not create a second semantic profession.
14. As a validator, I want the same validation identity available for ordinary and escalated work, so that more demanding review retains the same independent responsibility.
15. As a document reviewer, I want the same reviewer identity available for ordinary and escalated work, so that review independence is not coupled to a separate deep-role identity.
16. As a root orchestrator, I want high-risk or consequential criteria to trigger an appropriately capable execution request, so that risk changes the execution tier without renaming the responsibility.
17. As a project specialist, I want assigned boundaries, permissions, and completion conditions to remain stable across execution tiers, so that escalation cannot silently expand authority.
18. As a root orchestrator, I want the resolved model and effort observed for escalated tasks, so that a requested tier is not mistaken for evidence that it actually ran.
19. As a root orchestrator, I want a task stopped or escalated when observed capability is below the task's approved need, so that a runtime-clamped or provider-altered selection is not accepted silently.
20. As an operator, I want model and provider selection to use OMP's supported native mechanisms, so that changing configured routes does not require rewriting specialist responsibilities.
21. As an operator, I want per-task model selection to require the applicable operator permission and configured support, so that project policy does not pretend to grant global runtime capabilities.
22. As an operator, I want the specification to distinguish native model-selection behavior from provider, quota, and capability guarantees, so that route flexibility is not mistaken for equal models or independent allowance pools.
23. As a root orchestrator, I want unavailable or unapproved per-call models not to silently fall back for the native main-loop worker case where OMP documents no fallback, so that a consequential task does not unknowingly run on a different model.
24. As a root orchestrator, I want defaults and maintenance paths treated according to their own observed behavior rather than generalized from per-call main-loop behavior, so that the no-fallback claim is not broader than its evidence.
25. As a root orchestrator, I want generic workers usable for bounded reconnaissance and source-evidence collection, so that simple evidence work does not require inventing another project role.
26. As a root orchestrator, I want generic workers usable for mechanical comparisons and explicitly prescribed checks, so that deterministic evidence gathering can remain separate from engineering judgement.
27. As Julio, I want generic workers returned to the root when asked to choose architecture or change consequential requirements, so that workers cannot assume decision authority.
28. As Julio, I want generic workers returned to the root when asked to perform unauthorized domain mutation, so that gathering evidence cannot silently become implementation.
29. As a human reviewer, I want generic workers unable to claim independent engineering validation or approve consequential evidence, so that acceptance remains in the governed review path.
30. As an implementer, I want validators to report findings and hand off required repairs without editing the artifact they validate, so that implementation and independent validation remain separate.
31. As a root orchestrator, I want the existing task/result packet and traceability rules retained, so that bounded authority, evidence scope, unknown metadata, and handoffs remain auditable.
32. As a root orchestrator, I want bounded worker assignments to explicitly prohibit child spawning and the root to verify actual enforcement rather than assume it, so that task scope and authority remain observable.
33. As a Codex user, I want a direct single-agent fallback for bounded investigation, approved implementation, and prescribed checks, so that Codex remains useful without a second maintained specialist topology.
34. As a Codex user, I want the direct fallback to remain subject to the same human authority, repository standards, and applicable runtime safety controls, without claiming role declarations reproduce an operating-system sandbox.
35. As a root orchestrator, I want Codex implementation to remain distinct from required independent validation, so that the implementation session cannot approve its own output.
36. As a project maintainer, I want the static checker to validate the new six-identity contract while retaining drift and protection checks, so that migration updates the policy guard rather than disabling it.
37. As an independent reviewer, I want public task-dispatch scenarios to exercise actual routing and resolved execution metadata, so that declared configuration is not presented as live runtime proof.
38. As Julio, I want implementation, review, verification, repair, and rollback effort accounted for, so that the bounded effort cap remains auditable.
39. As Julio, I want any before-and-after observations to disclose task, acceptance, model, setting, and context differences, so that model upgrades or changed conditions are not misattributed to policy simplification.
40. As the project team, I want a target of two evenings of Julio's work and a hard maximum of one week of work effort, so that review, retries, repairs, and rollback do not expand this into an open-ended infrastructure project.
41. As the project team, I want automated waiting, unattended checks, and subscription allowance windows reported separately from human work effort, so that elapsed time does not silently enlarge the approved effort cap.
42. As Julio, I want the approved structural simplification to proceed without a pre-V1 payback test, while retaining correctness, safety, effort accounting, the cap, and rollback.
43. As an issue triager, I want ready-for-agent to communicate specification readiness only, so that dependency, release, authority, and independent review gates remain binding.

## Implementation Decisions

1. **Role inventory:** The active OMP project specialist inventory contains exactly six identities: `matlab-architect`, `matlab-implementer`, `simulink-implementer`, `matlab-validator`, `technical-writer`, and `technical-writer-validator`.
2. **Escalation:** Architecture, MATLAB validation, and document validation retain one identity each across ordinary and higher-capability execution. High-risk criteria select a higher-capability native execution only when the route and permission are available and the resolved execution satisfies the task's approved need.
3. **Runtime behavior:** Use OMP's native task dispatch and model-selection mechanisms. Per-task model selection requires operator-level permission; project configuration cannot grant that permission. Use a single exact selector, not arrays or a fallback list.
4. **Effort semantics:** Treat the requested effort as a request, not a guarantee. OMP may clamp it to supported effort or a configured maximum, and endpoint negotiation may further affect the effective selection. Observe resolved model and effort where exposed; if the observed result is below the approved task need, stop and return to the root for a decision rather than silently continuing at lower capability.
5. **Fallback semantics:** The documented no-fallback behavior for an unavailable per-call model applies to the native main-loop worker case, not every default or maintenance call. Do not generalize it into a blanket guarantee. Do not rely on unavailable settings or a less-capable retry model to complete consequential work.
6. **Provider and subscription scope:** The design uses only native supported and authenticated routes. It does not launch Codex CLI, OpenCode, Claude Code, another external agent CLI, or claim support for every vendor subscription. Provider choice does not promise independent quota pools, equal capability, or uniform effort behavior.
7. **Generic-worker boundary:** Generic workers may perform bounded reconnaissance, gather source evidence, summarize deterministic output, mechanically compare established artifacts, or execute explicitly prescribed checks within granted scope. The root owns routing and adjudication. Project specialists retain domain design, authorized domain mutation, independent domain judgement, and consequential documentation responsibilities. Generic workers must hand consequential decisions or unauthorized work back to the root and must not spawn children under their assigned task instructions; the runtime may not enforce that policy.
8. **Implementation boundary:** Keep MATLAB source implementation and Simulink topology/interface/configuration implementation distinct. The root resolves ambiguous ownership before delegating overlapping mutation.
9. **Authority and review:** Julio retains consequential architecture and requirement authority. Recommendations, implementation evidence, independent validation, and human approval remain distinct. Validators do not repair what they validate. Project specialists do not spawn children under their native configuration; generic-worker assignments prohibit child spawning, but their native task capability is not denied by that configuration.
10. **Codex fallback:** Codex is a direct single-agent route for bounded investigation, approved implementation, and prescribed checks. It has no maintained project-specialist inventory or deep profiles; it follows the same authority and repository standards, and cannot replace required independent validation. Preserve applicable platform safety controls; do not claim role declarations enforce operating-system isolation.
11. **Compatibility and history:** Migrate active registries, governance/routing descriptions, checker assumptions, checker tests, and active references coherently. Preserve historical records as historical; do not rewrite prior evidence or decisions to imply the old identities never existed. Do not leave a mixed, unverified active registry at cutover.
12. **Exception and rollback:** The accepted freeze remains the baseline outside the recorded exception. Preserve the known-good active configuration until the proposed cutover is demonstrated; on a stop condition, restore it or defer migration. A branch or worktree is not operating-system isolation.
13. **Effort and success criterion:** Target two evenings of Julio's work, with a hard maximum of one week of work effort; do not convert evenings into invented hours. Count implementation, review, verification, retries, repairs, and rollback. Separate elapsed waiting, unattended work, and quota waits from human effort. Julio's 2026-11-13 decision supersedes the original pre-V1 payback requirement; no measured savings or quantified improvement is claimed.
14. **Instruction ownership:** The six self-contained OMP-native definitions are the sole sources of specialist instructions. Their responsibility bodies remain vendor-neutral; supported native model and effort defaults may be concrete. Shared repository governance and engineering standards remain applicable.
15. **Safety boundaries:** Preserve inspection-only instructions, bounded mutation authority, built-in tool restrictions, and no-child-spawning policy. OMP built-in tool allowlists do not constrain additive MCP, extension, or custom tools, and OMP frontmatter does not reproduce Codex's operating-system sandbox. Role definitions alone do not establish filesystem isolation or enforce external-service authorization; preserve applicable platform controls and disclose what was actually verified.

## Testing Decisions

Use two existing seams: OMP's public task-dispatch interface for behavioral acceptance and the existing handoff consistency checker for static policy and inventory checks. Do not add a router wrapper, mock test interface, or alternate dispatch abstraction.

Bounded public-dispatch runtime probes are complete and recorded in [the runtime acceptance evidence](../../evidence/omp-native-orchestration-runtime-acceptance.json), including exact inputs, fixture digest, and runtime-owned metadata. The six retained identities routed representative tasks; same-identity architecture escalation resolved ordinary `high` and requested `max` to `high`/`max`; generic provider probes ran; and the planted fixture defect was identified and handed back without repair. Negative probes rejected the unavailable approved route, disabled per-task selection, project-excluded model, and removed deep identity. A capped `max` request resolved `high`; root rejected it as proof of `max` capability. The user-provided direct Codex read-only transcript is provenance-limited, and its catalog-refresh connection warnings and ignored user-feature setting were nonblocking. These observations do not establish provider-internal effort or negotiation, default/maintenance reliability, numerical or Simulink behavior, or OS/MCP isolation. Do not infer broader guarantees.
The following are acceptance criteria, not claims that every runtime guarantee was tested. Bounded runtime evidence and its explicit unverified scope are recorded above and in the linked evidence record; the criteria remain binding for any broader acceptance claim.

1. Exactly six project-specific OMP identities are discovered, with no three separate deep identities active in routing; generic built-in workers are not counted as extra project identities.
2. Public dispatch routes representative architecture, MATLAB implementation, Simulink implementation, MATLAB validation, technical writing, and document validation tasks to the correct identity.
3. Ordinary and escalated tasks use the same architecture and validation identities, and each result records the requested selection and observable resolved model/effort where available.
4. A high-risk task selects higher capability without changing identity, and effective capability is compared with the task's approved need rather than inferred from a request or role label.
5. A configured native provider or subscription route can be changed without rewriting role responsibilities when the route is supported and authorized; disclose provider/model differences and do not infer independent quota pools.
6. Missing operator permission, unavailable or unapproved models, unsupported or capped effort, endpoint negotiation, and other unmet capability conditions do not silently proceed as if the approved tier had run. Where native behavior is not an unconditional rejection, the orchestration must stop, escalate, or return to the root based on the observable resolved result.
7. Verify the documented per-call main-loop no-fallback case only within that scope; test default and maintenance behavior separately if making claims about them, and otherwise state that they remain unverified.
8. A generic worker receiving a consequential architecture, requirement, unauthorized mutation, acceptance, or independent validation request returns it to the root rather than assuming that authority.
9. A validator asked to repair the artifact it is reviewing refuses or hands the repair back for a separately authorized implementation task.
10. The Codex direct single-agent fallback remains usable for its bounded scope, and its implementation result cannot substitute for required independent review.
11. Existing task/result packet integrity, traceability, unknown-metadata treatment, bounded no-child policy, and relevant runtime-specific safety protections remain in effect and are checked within their stated scope. Project-role frontmatter or generic-worker instructions must not be presented as proof of operating-system isolation, MCP authorization enforcement, or tool-level child-spawn denial; additive tools and generic worker spawn capabilities remain disclosed above.
12. The consistency checker validates the new six-role contract and retains its inventory, declaration-drift, packet, policy-marker, and Markdown-file-list protections; update its tests for the changed contract rather than disabling failing parity checks.

Record the runtime version and relevant settings/grants, task identity, exact public-dispatch inputs, disposable artifact identities and revisions, requested and resolved selection, observable result, limitations, and failure behavior for each positive and negative scenario. Use existing records and evidence fields rather than adding a packet schema. A self-reported agent name or model is not proof of resolved execution. Do not claim scenarios not exercised.

As an effort-accounting record, report implementation, review, verification, retries, repairs, and rollback effort, and separate elapsed waiting, unattended work, and quota waits from human effort. Disclose differences if comparative observations are made; no before/after payback comparison or improvement threshold is required for acceptance.

Root reports all final static code/checker gates passed: Ruff check and format-check, 14 unit tests, six handoff-checker checks (including 16 Markdown files), and Pyright with zero errors or warnings. The checker SHA256 is `27e36f819567de0626341d7ab64d4c6b3da73ccab4924becfff225bb2736f8b8`; its test SHA256 is `e1ab4400c69036a334377af52f6702dd5ea60d161e46e8cef03bfecf0ac04299`. These commands were run after `source .venv/bin/activate`:

```sh
uv run --frozen ruff check scripts/check_agent_handoffs.py scripts/test_check_agent_handoffs.py
uv run --frozen ruff format --check scripts/check_agent_handoffs.py scripts/test_check_agent_handoffs.py
uv run --frozen python -m unittest discover -s scripts -p test_check_agent_handoffs.py
uv run --frozen python scripts/check_agent_handoffs.py
uv run --frozen pyright contracts scripts
```

The code reviewer completed focused review of the final authorization-token matching repair with no findings. The independent final semantic/evidence review found no unresolved errors. Root reports full touched-document Markdown lint passed on 14 files with zero issues and the handoff checker passed all six checks, including 16-file lint. No further checks are pending; this evidence does not itself approve the change or advance a gate.

Stop and return to Julio if native escalation cannot preserve required capability, authority leaks, acceptance or correctness is reduced, the new inventory or routing is inconsistent, the cap is exceeded or at risk, or rollback is unsafe. The approved structural simplification does not depend on demonstrated payback; do not claim optimization success, measured savings, or quantified improvement without evidence. Defer or revert on a stop condition, or seek a new human decision. A one-off smoke test proves possibility only, not reliability across routes or work.

## Out of Scope

- Implementation before the range-compressor PR is merged and its release published; this entry gate is now verified.
- Treating the reference-only numerical study or any other incomplete prerequisite as satisfying the entry gate.
- Adopting or amending ADR 0023 as part of authoring this plan; the scoped exception is recorded in ADR 0028.
- A canonical-role directory, generated adapters, duplicated Codex specialist definitions, runtime indirection, or an external CLI/provider/orchestration layer.
- More than the six agreed project identities, renaming the six current identities, restoring separate deep identities under new names, adding an engineering-explorer role, or adding a future Simulink visual-validator role without a new decision.
- A new lightweight query packet, extra result metadata, broad extraction of global policy, or changes to the existing task/result packet contract.
- Benchmarks, telemetry frameworks, token-count optimization as a success criterion, or claims that latency, quota capacity, model quality, provider independence, or runtime isolation improved without evidence.
- Changes to MATLAB/Simulink algorithms, models, numerical acceptance, analyzer/test rules, engineering standards, ownership/session serialization, or production radar artifacts solely to exercise routing.
- Rewriting historical evidence or ADRs to erase prior role identities or make the proposal appear previously approved.
- Treating a GitHub issue label, specialist output, checker pass, runtime smoke, or independent validation as Julio's architecture approval or as a release/dependency gate bypass.

## Further Notes

### Evidence and traceability

- Historical research citation: its prior record names local source `docs/research/ai_mbd_orchestration_optimisation_plan.md` and SHA256 `96e42911f2accd3a6b2f4b25fa6b7279a380cc810faaff2a7c62a9ea72415668`; that source is absent from the current worktree, so the citation is historical, not freshly verified.
- Accepted freeze baseline: [ADR 0023](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/blob/main/docs/adr/0023-freeze-ai-infrastructure-until-v1.md). The scoped exception and authorization are recorded in ADR 0028.
- Repository authority, packet, routing, history, and role-selection contract: [AGENTS.md](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/blob/main/AGENTS.md).
- Domain language reference: [GLOSSARY.md](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/blob/main/GLOSSARY.md).
- Initial inventory observations and checker seams came from the approved brief and research; they are historical evidence, not current inventory or runtime verification.
- Static feasibility research reports an installed Homebrew OMP receipt for version 18.18.2 and matching published source/docs for per-task model selection and effort precedence; this is not proof of the active session's version, settings, provider behavior, or resolved selections. Relevant source references: [task tool](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.18.2/docs/tools/task.md), [task-agent discovery](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.18.2/docs/task-agent-discovery.md), [task executor](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.18.2/packages/coding-agent/src/task/executor.ts), and [model resolver](https://raw.githubusercontent.com/can1357/oh-my-pi/v18.18.2/packages/coding-agent/src/config/model-resolver.ts). Treat source-described behavior as feasibility evidence only; verify the active version and settings at the authorized implementation gate.
- Matching-source details distinguish operator-level permission for per-call models, per-agent model override interactions, supported effort and task maximum caps, provider negotiation, and effective resolved model/effort. Do not assume a project can grant permission or force a requested effort to be honored.
- Existing static checker coverage addresses parsing, inventory, and drift rather than live routing. The task-dispatch scenarios above are required to exercise runtime behavior without replacing the checker or claiming that its pass proves live dispatch.
- Session-contamination research is a separate concern and is not solved by this role simplification.

### Handoff and authorization

Julio confirmed the target choices and conditional freeze exception during the 2026-11-08 discussion. On 2026-11-13, Julio approved `approve_structural_simplification`, explicitly removing demonstrated pre-V1 payback as an acceptance condition while retaining effort accounting, the cap, rollback, safety, and correctness. ADR 0028 records the scoped exception and authorization. The bounded implementation, runtime probes, final static gates, and independent semantic/evidence review are complete for Julio's review; they do not constitute human approval or gate advancement. Julio reported zero evenings invested at kickoff; actual human effort this session was not measured. Automated work, retries, repairs, and quota waiting are distinct from measured human effort; no savings, hours, or cap compliance are claimed.

Code review found no issues in the final authorization-token matching repair; independent final semantic/evidence review found no unresolved errors. The checker SHA256 is `27e36f819567de0626341d7ab64d4c6b3da73ccab4924becfff225bb2736f8b8`. Julio's review is the next step within the freeze. No release, commit, issue-state change, or human gate advancement follows from implementation evidence alone.

The entry prerequisite and scoped exception are recorded. Runtime probes are complete within the evidence scope above; static verification, independent validation, Julio's consequential authority, and effort and stop limits remain binding. No formal work-package or gate assignment is recorded.
