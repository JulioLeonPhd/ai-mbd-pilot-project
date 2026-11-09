# AI-MBD Pilot: Orchestration Policy Optimisation and OMP/Codex Simplification Plan

## Purpose

This plan is written for an AI agent to **evaluate before changing anything**, then execute only the changes that remain justified by the repository's current state and observed runtime behaviour.

The goal is not to redesign agent infrastructure for its own sake. The repository explicitly prioritises radar V1 delivery, so this work should be treated as a bounded orchestration-maintenance change and should not expand into a new AI-infrastructure programme.

The plan addresses two connected objectives:

1. **Optimise the orchestration policy** so project specialists represent genuinely distinct engineering responsibilities, generic work can use the harness's generic agents, escalation is separated from role identity, and delegation remains observable and reviewable.
2. **Simplify OMP/Codex support** so Oh My Pi (OMP) is the primary interactive orchestration runtime while Codex remains a useful compatibility/safety runtime without requiring two independently maintained copies of every semantic role.

The intended end-state is simpler than the current system, but it must preserve the strongest existing properties: human architectural authority, bounded handoffs, implementation/validation separation, explicit evidence limitations, runtime-specific safety controls, and reproducibility.

---

## Non-negotiable principles

The executing agent must preserve these unless Julio explicitly changes them:

1. **Human architectural authority.** Julio owns consequential system decomposition, interfaces, algorithm choices, state/timing behaviour, acceptance decisions, and consequential requirement changes.
   - **Rationale:** This is the core governance boundary of the pilot. Simplifying agents must not silently transfer engineering authority to the harness.

2. **Recommendations, implementation evidence, independent validation, and human approval are distinct states.**
   - **Rationale:** Collapsing these states would weaken the evidentiary discipline that the repository is intended to demonstrate.

3. **Validators do not repair the artefact they are validating.** A failed validation returns to the root for a separately authorised implementation/fix task.
   - **Rationale:** This preserves practical independence and prevents an agent from silently fixing and then approving its own work.

4. **Bounded context and task authority.** Specialists receive only the context, sources, mutation scope, and acceptance criteria needed for their assignment.
   - **Rationale:** This reduces context cost, limits accidental scope expansion, and makes specialist outputs easier to audit.

5. **Runtime evidence must not be overstated.** Tool restrictions, prompt rules, and declared models do not automatically prove execution-time isolation, routing, or model selection.
   - **Rationale:** The current policy correctly distinguishes declared configuration from observed execution. Preserve that distinction during simplification.

6. **Do not build infrastructure merely because it is architecturally attractive.** Prefer the smallest change that fixes a demonstrated overlap, gap, maintenance burden, or runtime-routing problem.
   - **Rationale:** The repository has already frozen discretionary AI-infrastructure work in favour of radar V1. This optimisation should remain maintenance-sized.

---

## Part I - Evaluation before implementation

### Phase 0 - Establish current truth

Before editing files, inspect the current default branch and do not assume this plan exactly matches it.

#### 0.1 Read the governing artefacts

At minimum inspect:

- `AGENTS.md`
- `CURRENT.md`
- the ADR that freezes AI-infrastructure development until radar V1
- the human-led workflow documentation
- `.omp/agents/*`
- `.codex/agents/*`
- `.agents/skills/*` relevant to agent orchestration
- `scripts/check_agent_handoffs.py`
- any tests or scripts which assert the current nine-role inventory

**Rationale:** The proposed simplification changes the structure used by the checker and both runtimes. Editing definitions before finding all assumptions would create policy/configuration drift.

#### 0.2 Build a current role matrix

For every OMP and Codex specialist, record:

- semantic responsibility;
- model and reasoning/thinking setting;
- mutation permission;
- tools/sandbox declaration;
- spawn/delegation permission;
- inputs expected;
- completion conditions;
- which other role(s) substantially overlap it;
- whether the distinction is semantic or merely an escalation/model choice.

Expected roles to investigate include the existing writer, architecture, implementation, Simulink implementation, validation, and `-deep` variants.

**Rationale:** Do not remove an agent because its name sounds redundant. Demonstrate that its independent responsibility is duplicated before merging it.

#### 0.3 Observe the unexplained OMP generic-agent behaviour

Reproduce or inspect at least a few representative delegations where OMP chooses a bundled/generic task agent rather than a named project specialist.

Classify each case:

- generic reconnaissance/search;
- deterministic command/test execution;
- summarisation;
- project-domain architecture;
- mutation;
- engineering validation;
- consequential documentation.

Record whether the generic choice was actually inappropriate.

**Rationale:** The optimisation should not assume that use of a generic OMP worker is a failure. Generic agents may be the correct abstraction for generic reconnaissance or execution. We only need routing controls when a generic worker crosses a project governance boundary.

#### 0.4 Decide whether this maintenance work is currently authorised

Check the AI-infrastructure freeze and current milestone. Classify proposed changes into:

- **defect/maintenance:** correcting overlap, routing ambiguity, drift, or a demonstrated OMP/Codex maintenance problem;
- **optional infrastructure:** new framework machinery with no current delivery benefit.

Execute only the first category unless Julio explicitly authorises broader infrastructure work.

**Rationale:** A good orchestration redesign that violates the project's own prioritisation policy would be self-defeating.

#### Phase 0 exit criteria

Do not proceed until the agent can state:

- which roles are semantically distinct;
- which roles differ mainly by model/escalation;
- what OMP generic agents are doing in observed cases;
- which runtime differences are real and need preserving;
- which proposed edits qualify as bounded maintenance.

---

## Part II - Orchestration policy optimisation

### Phase 1 - Separate engineering role from execution tier

#### Phase 1: Proposed change

Stop treating `deep` as a separate semantic profession.

Target semantic roles:

1. `matlab-architect`
2. `matlab-implementer`
3. `simulink-implementer`
4. `matlab-validator`
5. `technical-writer`
6. `document-reviewer` (or retain the existing `technical-writer-validator` name if renaming would create needless churn)

Remove `-deep` from the **semantic model** for:

- MATLAB architecture;
- MATLAB validation;
- document review.

Instead classify execution separately, for example:

- standard;
- deep/consequential.

Current/default mappings may still select different models per tier.

#### Phase 1: Rationale

The existing normal/deep pairs largely describe **how much model capability is required**, not a different responsibility. A MATLAB architect remains responsible for architecture whether it runs on Sol or Astra. Encoding capability tier into the role name creates unnecessary role multiplication and makes future provider/model routing harder.

The separation should conceptually become:

```text
semantic role -> complexity/escalation tier -> runtime/provider/model
```

rather than:

```text
semantic role + model tier -> separate agent identity
```

#### Phase 1: Evaluation guard

Do not merge a `-deep` role if inspection shows that it contains materially different authority, validation independence, tool access, or completion semantics. Move genuinely distinct semantics into the canonical role before deleting the duplicate identity.

---

### Phase 2 - Keep MATLAB and Simulink implementation distinct

#### Phase 2: Proposed change

Retain separate `matlab-implementer` and `simulink-implementer` roles.

Define the boundary more explicitly:

- **MATLAB implementer:** `.m`/MATLAB source, tests, fixtures, scripts, and only simple/localised Simulink-related edits when the model topology/configuration is not substantively changed.
- **Simulink implementer:** model topology, interfaces, sample-time/configuration work, model-level changes, and multi-step Simulink MCP editing.

#### Phase 2: Rationale

This distinction is semantic rather than merely a model tier. Source-code mutation and model-topology/configuration mutation have different tools, review surfaces, and failure modes. The difference will become more valuable as the pilot moves further into Simulink, fixed-point, and code-generation work.

#### Phase 2: Improvement

Add explicit examples of ambiguous tasks and which role owns them. If ownership remains unclear, the root must resolve the boundary before spawning a writer/implementer rather than letting both modify overlapping artefacts.

---

### Phase 3 - Formalise generic-agent use instead of fighting it

#### Phase 3: Proposed change

Permit OMP bundled/generic agents for narrowly scoped **generic work**. Do not require every delegation to use a project specialist.

Recommended allowed generic work:

- repository reconnaissance;
- locating definitions/references;
- collecting file/line evidence;
- summarising deterministic output;
- running explicitly specified non-consequential commands/checks when mutation authority is not expanded;
- mechanical comparison of already-defined artefacts.

Generic/bundled agents must **not independently**:

- choose or approve architecture;
- modify an engineering interface or consequential requirement;
- choose acceptance tolerances or redefine acceptance criteria;
- perform authorised implementation mutation unless explicitly allowed by the root policy;
- declare independent engineering validation complete;
- approve consequential documentation or evidence claims.

#### Phase 3: Rationale

OMP already possesses generic workers and may select them naturally for generic tasks. Duplicating these capabilities as project specialists increases maintenance and confuses project responsibility with harness mechanics. Project specialists should exist when the repository needs **domain-specific responsibility or governance**, not simply because work can be delegated.

#### Phase 3: Important policy wording

Prefer a rule equivalent to:

> Generic workers may gather or execute bounded evidence. Project specialists own domain design, authorised mutation, independent validation, and consequential engineering documentation. The root owns routing and adjudication.

This is preferable to a blanket rule such as "always use a named project agent".

---

### Phase 4 - Decide whether an explicit engineering-explorer role is needed

#### Phase 4: Proposed change

Do **not** add an `engineering-explorer` immediately.

First evaluate the generic-agent observations from Phase 0.

Add a project `engineering-explorer` only if generic OMP reconnaissance repeatedly fails because domain-specific engineering constraints are required, for example if it routinely:

- confuses evidence scopes;
- proposes architecture while merely investigating;
- overlooks MATLAB/Simulink domain references required for factual reconnaissance;
- cannot be reliably bounded by the root task packet.

If created, make it inspection-only and evidence-oriented. It should return facts, sources, contradictions, unknowns, and a handoff. It should not approve or mutate.

#### Phase 4: Rationale

There is a real conceptual activity called engineering reconnaissance, but OMP may already cover the generic part well. Adding an agent before demonstrating the gap would reproduce the over-specialisation we are trying to remove.

---

### Phase 5 - Split lightweight queries from governed tasks

#### Phase 5: Proposed change

Retain the existing full task/result packet for consequential delegation, but introduce a smaller read-only **query packet** for simple reconnaissance.

Suggested semantics:

```yaml
query:
  objective: "one bounded factual question"
  scope:
    - "allowed sources/paths"
  return:
    - "facts/evidence required"
```

Use the full task packet for:

- mutation;
- architecture/design proposals;
- validation;
- consequential documentation;
- tasks with acceptance criteria or requested checks;
- work that can return `needs-input` because authority is missing.

#### Phase 5: Rationale

The current task packet is excellent for governed engineering work but unnecessarily expensive and ceremonious for questions such as "where is startup validity defined?" A lightweight query mode lowers context/token overhead without weakening governance where it matters.

#### Phase 5: Constraint

A query may not silently become a mutation or design task. If exploration reveals such a need, return a handoff to the root, which creates a full task.

---

### Phase 6 - Separate test execution from validation judgement

#### Phase 6: Proposed change

Clarify that deterministic evidence collection and engineering validation are different activities.

A generic worker, root, or implementation agent may execute an explicitly prescribed check and return raw evidence when authorised. The `matlab-validator` is responsible for independent judgement about whether the evidence and implementation establish a defined claim.

Examples:

- **Execution:** run the named MATLAB suite and capture exact results.
- **Validation:** determine whether the suite, fixtures, implementation, and results satisfy the approved acceptance claim without circularity or unsupported inference.

#### Phase 6: Rationale

Executing a test does not require the same reasoning capability as deciding whether the test is the right independent evidence. Separating these activities improves model efficiency and makes the evidence chain clearer.

#### Phase 6: Preserve

The validator must still not repair the implementation it is adjudicating.

---

### Phase 7 - Make escalation explicit and root-owned

#### Phase 7: Proposed change

Define escalation criteria independently of role names.

Possible criteria for `deep` execution include:

- solver interactions;
- sample-time/timing subtleties;
- difficult numerical stability/precision issues;
- code-generation or HDL implications;
- safety/consequential architecture;
- ambiguous evidence where an incorrect judgement could change a contract;
- repeated failure or unexplained disagreement at the standard tier.

The root records:

- selected semantic role;
- complexity tier;
- observable reason for escalation;
- selected runtime/model when observable.

#### Phase 7: Rationale

Model choice should follow task difficulty rather than creating duplicate organisational roles. Recording the reason also turns escalation into inspectable project evidence rather than invisible harness behaviour.

---

## Part III - Simplify OMP and Codex support

### Phase 8 - Establish OMP as primary, Codex as compatibility runtime

#### Phase 8: Proposed change

Document support asymmetrically:

#### Phase 8: OMP: primary interactive orchestration runtime

Use OMP for the full day-to-day workflow, including visible project-agent dispatch and permitted generic workers.

#### Phase 8: Codex: supported compatibility/safety runtime

Retain Codex support for:

- direct project work;
- fallback if OMP is unavailable/regresses;
- runtime comparison;
- tasks benefiting from Codex's declared sandbox modes;
- workflows where a Codex-native agent definition is valuable.

Do not promise that Codex's internally spawned multi-agent topology maps one-to-one onto the project's named specialists when that is not observable.

#### Phase 8: Rationale

OMP better supports the project's goal of transparent, inspectable orchestration, while Codex remains valuable and should not be discarded. Equal implementation status, however, creates duplicated maintenance for little additional engineering value.

---

### Phase 9 - Create runtime-neutral canonical semantic roles

#### Phase 9: Proposed change

Evaluate introducing a canonical directory such as:

```text
.agents/roles/
  matlab-architect.md
  matlab-implementer.md
  simulink-implementer.md
  matlab-validator.md
  technical-writer.md
  document-reviewer.md
```

Each canonical role should contain only runtime-neutral semantics, for example:

- purpose;
- authority;
- responsibilities;
- explicit non-responsibilities;
- required handoff behaviour;
- completion conditions;
- independence requirements.

Do not put provider-specific model IDs, OMP tool syntax, or Codex sandbox syntax in these files.

#### Phase 9: Rationale

Today the OMP and Codex definitions duplicate role instructions. A canonical semantic layer reduces drift and turns `.omp`/`.codex` files into runtime adapters rather than independent policy copies.

#### Phase 9: Evaluation requirement

Before applying this structure, verify that both runtimes can reliably instruct the spawned specialist to load the canonical role file. If either runtime cannot do so reliably, do not force the abstraction. Prefer generated adapters or a checker-based synchronisation approach instead.

---

### Phase 10 - Reduce OMP definitions to rich runtime adapters

#### Phase 10: Proposed change

If Phase 9 proves reliable, make `.omp/agents/*.md` contain:

- OMP agent name/description;
- default model selector;
- thinking level;
- built-in tool allowlist;
- spawn restriction;
- concise OMP-specific access/safety notes;
- instruction to apply the canonical semantic role and repository orchestration contract.

Do not repeat the complete semantic role text if it can be loaded reliably from the canonical source.

#### Phase 10: Rationale

OMP requires runtime-specific configuration, but that configuration should not become a second source of truth for what a MATLAB architect or validator means.

#### Phase 10: Safety requirement

Retain the current warning that OMP tool restrictions/instructions are not the same as an OS-level sandbox. Do not claim filesystem isolation merely because mutation tools are omitted.

---

### Phase 11 - Reduce Codex TOMLs to thin compatibility adapters

#### Phase 11: Proposed change

If Phase 9 proves reliable, retain `.codex/agents/*.toml`, but minimise them to:

- agent name and description;
- Codex-required/default model setting;
- reasoning effort;
- sandbox mode;
- concise instructions to load the canonical role and `AGENTS.md` contract;
- any Codex-specific safety/runtime instructions that cannot live elsewhere.

#### Phase 11: Rationale

Codex TOML requires runtime configuration such as model selection and sandbox policy. Keeping thin TOMLs preserves Codex support without maintaining a parallel semantic policy corpus.

---

### Phase 12 - Treat Codex `-deep` TOMLs as launch profiles, not roles

#### Phase 12: Proposed change

Where Codex needs separate TOML definitions to select a different model, it is acceptable to retain files such as:

```text
matlab-architect.toml
matlab-architect-deep.toml
```

but both should load the same canonical semantic `matlab-architect` role.

Likewise for validator or document-review escalation if technically necessary.

Document clearly that `-deep` is a **runtime execution profile**, not a separate engineering responsibility.

#### Phase 12: Rationale

This accommodates Codex's model-pinning configuration without allowing a runtime limitation to dictate the repository's conceptual agent organisation.

---

### Phase 13 - Reduce `AGENTS.md` to constitutional orchestration policy

#### Phase 13: Proposed change

Evaluate shrinking `AGENTS.md` so it primarily contains:

- human/agent authority boundary;
- root ownership and routing principles;
- generic-worker vs project-specialist boundary;
- query and task packet contracts;
- implementation/validation independence;
- escalation policy;
- completion semantics;
- runtime support statement;
- links to specialised procedures/skills.

Move detailed procedures that are only relevant on demand into focused policy/skill/reference files when an existing appropriate location exists.

Candidates to evaluate for extraction include detailed:

- Markdown rendering procedures;
- release procedure;
- issue-tracker command conventions;
- MATLAB coding-standard content already present in the standards bundle;
- Python lint procedure;
- specialised MCP operational procedures.

Do not extract a rule if doing so would make it materially less likely to be loaded when needed.

#### Phase 13: Rationale

A root policy document should emphasise the rules that must remain salient across every session. Very detailed tool procedures compete for attention and consume context even when unrelated to the task. On-demand policy loading should improve both attention and token efficiency.

---

## Part IV - Observability and evidence improvements

### Phase 14 - Add runtime/orchestration metadata to results

#### Phase 14: Proposed change

Extend result metadata only if doing so remains lightweight and useful. Suggested fields:

```yaml
agent:
  runtime: "omp | codex | unknown"
  name: "semantic-role-or-generic-agent"
  model: "observed model or unknown"
  reasoning_effort: "observed effort or unknown"
  definition_source: "path or unknown"

orchestration:
  role_kind: "project-specialist | generic-worker"
  complexity_tier: "standard | deep | unknown"
  routing_reason: "short observable reason"
```

Do not require fields that the runtime cannot actually observe.

#### Phase 14: Rationale

The pilot is partly about reviewable AI-assisted engineering. Recording runtime, role kind and escalation reason is more useful than pretending OMP and Codex have identical orchestration visibility. `unknown` is preferable to invented certainty.

---

### Phase 15 - Make generic-agent use auditable, not prohibited

#### Phase 15: Proposed change

When a generic worker is used for a consequential workflow, the root should record:

- what it was asked to do;
- why a project specialist was unnecessary for that bounded step;
- what evidence it returned;
- which project specialist or the root, if any, performed the consequential interpretation.

Do not require this metadata for trivial exploratory queries if it adds more overhead than value.

#### Phase 15: Rationale

The goal is transparent delegation, not bureaucracy. A visible generic worker gathering facts is acceptable; an unrecorded generic worker making an architecture decision is not.

---

## Part V - Migration strategy

### Phase 16 - Perform migration in reversible stages

Do not delete all old agents in one commit.

Recommended sequence:

#### Stage A - Policy clarification only

1. Define semantic roles and boundaries.
2. Define generic-worker permissions.
3. Define standard/deep escalation independently of roles.
4. Define OMP primary / Codex compatibility status.
5. Update checker expectations only as needed for these semantics.

**Rationale:** Establish the intended architecture before changing runtime files.

#### Stage B - Canonical-role experiment

1. Convert **one** low-risk role, preferably `matlab-architect` or `technical-writer`, to the canonical-role + adapter pattern.
2. Exercise it in OMP.
3. Exercise it directly in Codex.
4. Verify that role instructions, authority, task/result packet, and runtime settings are actually observed.
5. Compare outputs with the pre-migration role.

**Rationale:** The largest technical uncertainty is whether indirection to a canonical role is reliably loaded by both runtimes. Test that assumption cheaply before migrating the complete registry.

#### Stage C - Convert remaining roles

Only after Stage B succeeds, migrate the remaining project specialists.

#### Stage D - Reclassify/remove semantic `-deep` roles

1. Convert deep definitions into runtime execution profiles where needed.
2. Remove references that describe them as separate semantic roles.
3. Verify standard-to-deep escalation still works.

#### Stage E - Trim `AGENTS.md`

Extract only details proven safe to load on demand.

**Rationale:** Document slimming should happen after routing stabilises, otherwise policy movement and role changes become difficult to debug separately.

---

## Part VI - Required validation

### Phase 17 - Static consistency checks

Update and run `scripts/check_agent_handoffs.py` (or its successor) so it validates the new architecture rather than merely the old nine-role inventory.

It should check, where practical:

- canonical semantic role inventory;
- every primary OMP project specialist maps to one canonical role;
- every Codex compatibility adapter maps to a canonical role;
- no semantic role silently gains self-delegation;
- validator roles remain non-mutating by policy;
- implementer roles have appropriate mutation authority;
- OMP spawn restrictions are as intended;
- Codex sandbox declarations are present where required;
- standard/deep profiles map to the same semantic role;
- stale references to removed semantic `-deep` roles do not remain in governing docs.

**Rationale:** The checker should enforce semantic invariants, not preserve historical file duplication.

---

### Phase 18 - Behavioural routing scenarios

Run a small routing test matrix in OMP. The test does not need to modify production artefacts; use inspection or disposable/scratch tasks where possible.

#### Scenario 1 - Generic reconnaissance

Prompt requiring location of a specific contract/definition.

Expected: generic worker is acceptable; no architecture specialist required.

#### Scenario 2 - Architecture decision support

Prompt requiring alternatives for a consequential MATLAB/DSP interface.

Expected: `matlab-architect`; user decision boundary preserved.

#### Scenario 3 - Approved MATLAB implementation

Provide a bounded approved design and writable target.

Expected: `matlab-implementer`.

#### Scenario 4 - Simulink topology/configuration mutation

Expected: `simulink-implementer`.

#### Scenario 5 - Independent implementation validation

Expected: `matlab-validator`; no repair by validator.

#### Scenario 6 - Complex documentation

Expected: `technical-writer`, followed by independent `document-reviewer` when policy classifies it as complex.

#### Scenario 7 - Deep escalation

Provide a deliberately difficult numerical/timing problem.

Expected: same semantic architect/validator role but deep execution tier/profile, with observable escalation reason.

#### Phase 18: Rationale

Static definitions cannot prove that the root actually routes work according to policy. These scenarios test the conceptual boundaries that motivated the redesign.

---

### Phase 19 - Codex compatibility scenarios

Run at least:

1. one read-only architecture invocation;
2. one mutation-capable implementation invocation;
3. one validator invocation;
4. one deep execution profile if retained.

Verify:

- canonical role instructions are loaded;
- model/profile defaults are correct where observable;
- sandbox declarations remain configured correctly;
- result packets do not invent unobservable orchestration metadata.

#### Phase 19: Rationale

Codex is being downgraded from equal orchestration implementation to compatibility runtime, not abandoned. Compatibility therefore needs a smaller but explicit acceptance suite.

---

## Part VII - Suggested target policy

The executing agent should refine this wording against actual runtime behaviour before adopting it.

### Root

The root owns decomposition, sequencing, routing, authority checks, escalation, conflict resolution, and final synthesis. Julio retains consequential architecture and acceptance authority.

### Generic workers

Use harness-provided generic workers for bounded reconnaissance, deterministic evidence collection, and other generic operations that do not require project-domain authority. Generic workers do not independently make consequential engineering decisions, perform authorised domain mutation, or declare independent engineering validation.

### Project specialists

Use project specialists when a task exercises a distinct engineering responsibility:

- `matlab-architect`: design and engineering decision support;
- `matlab-implementer`: MATLAB/source implementation;
- `simulink-implementer`: substantive model topology/configuration implementation;
- `matlab-validator`: independent engineering validation;
- `technical-writer`: engineering documentation authoring;
- `document-reviewer`: independent review of complex/consequential engineering documentation.

### Complexity/model tier

`standard` and `deep` are execution tiers, not semantic roles. The root chooses a tier from observable task difficulty and records the reason. Runtime adapters map the tier to an appropriate available model/profile.

### Runtime support

OMP is the primary interactive orchestration runtime. Codex is a supported compatibility/safety runtime. Equivalent engineering semantics are required; identical internal orchestration is not.

---

## Part VIII - Decisions the executing agent must surface to Julio

Do not silently decide these if repository inspection does not already establish them:

1. Whether to rename `technical-writer-validator` to `document-reviewer` or preserve the existing name for compatibility.
2. Whether canonical runtime-neutral role files are reliable enough in both OMP and Codex to become the source of truth.
3. Whether observed generic OMP agents need any additional restrictions beyond the proposed governance boundary.
4. Whether an `engineering-explorer` specialist is actually needed after observing real generic-agent failures.
5. Whether new result metadata is valuable enough to justify schema churn.
6. Whether any stage exceeds the existing AI-infrastructure maintenance exception and therefore should be deferred until after radar V1.

**Rationale:** These choices affect repository architecture or workflow governance. The simplification should not bypass the human boundary it is meant to strengthen.

---

## Part IX - Anti-goals

Do not turn this work into:

- a new orchestration framework;
- a provider-routing system;
- a PAYG integration project;
- an automatic model benchmark programme;
- a replacement for OMP's generic-agent machinery;
- an attempt to make Codex and OMP internally identical;
- a large refactor of unrelated radar engineering policy;
- a change to approved radar architecture or numerical acceptance criteria.

**Rationale:** Each would materially expand scope beyond the two problems this plan is intended to solve.

---

## Part X - Completion criteria

The optimisation is complete only when all applicable conditions below are true:

- The project has one documented set of semantic specialist responsibilities.
- `deep` is represented as an execution/escalation tier rather than a distinct engineering responsibility.
- MATLAB and Simulink implementation ownership has an explicit boundary.
- Generic OMP workers have a documented, bounded role and are neither banned unnecessarily nor allowed to cross consequential governance boundaries.
- Lightweight reconnaissance can avoid unnecessary full task-packet overhead without gaining mutation/design authority.
- Test execution is distinguished from independent validation judgement.
- OMP is documented as the primary orchestration runtime.
- Codex remains a tested compatibility/safety runtime.
- Semantic role instructions have a single source of truth **or** the evaluation demonstrates why duplication must remain and supplies a reliable synchronisation/checking mechanism.
- Runtime-specific safety settings remain runtime-specific and are not falsely presented as equivalent.
- The validator cannot silently repair and approve its own findings.
- Static consistency checks pass.
- Representative OMP routing scenarios behave according to the new policy.
- Representative Codex compatibility scenarios pass.
- `CURRENT.md`, history, ADRs, or other governing artefacts are updated only where required by the repository's established status/decision lifecycle.
- No unrelated AI-infrastructure work is introduced.
- All limitations, unobservable runtime details, and deferred decisions are explicitly recorded.

---

## Recommended implementation priority

If only a small maintenance window is justified now, prioritise in this order:

1. **Clarify policy:** project specialist vs generic worker, role vs execution tier.
2. **Stop semantic proliferation:** treat existing `-deep` variants as execution profiles conceptually.
3. **Make OMP primary and Codex compatibility-oriented in documentation.**
4. **Pilot one canonical semantic role + OMP/Codex adapters.**
5. **Update the checker around semantic invariants.**
6. **Migrate remaining roles only after the pilot is demonstrably reliable.**
7. **Trim `AGENTS.md` last.**

This order deliberately favours reversible policy improvement over infrastructure churn.

---

## Final instruction to the executing agent

Treat this document as a proposed migration plan, not pre-approved permission to change repository architecture. Start by evaluating the current repository and observed OMP/Codex behaviour. Preserve the existing human authority boundary and radar-V1 priority. Challenge any recommendation in this plan that does not survive inspection. When a change is justified, implement the smallest reversible form, validate it in both the primary OMP runtime and the required Codex compatibility surface, and record evidence and limitations without overstating what configuration alone proves.
