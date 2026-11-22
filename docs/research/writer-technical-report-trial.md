# Technical-report genre trial evidence

## 1. TL;DR

Two blinded, one-draft-per-arm comparisons provide exploratory evidence only.
Mermaid readers scored baseline 3/4 and candidate 2/4; architecture readers
scored both 3/3. Aggregate scores are 6/7 versus 5/7. Retain baseline technical
report guidance: the candidate did not improve the frozen reader answers, even
though its bodies supplied relevant facts. No material false claim or lost
consequential caveat was found. This is not adoption approval, a benchmark, or
independent verification of the underlying work.

## 2. Method and limits

Each arm used a fresh native technical-writer session on the common #33 role,
with Luna/high settings. The baseline received common guidance; the candidate
also received the separate technical-report guidance below. Each pair used the
same case fixture. Reviewers received randomized opaque labels, drafts, and the
frozen scoring key—not arm names or drafting instructions. Scores are ordered
by the four Mermaid questions or the three architecture questions; each bit is
1 only when all required facts can be recovered without guessing.

There was one draft per arm per case. These small, fixture-specific samples
cannot establish a general writing benefit, model capability, or adoption
outcome. Numbering was checked separately from reader usefulness. The opening
criterion was applied as written; facts elsewhere in a draft do not make an
opening satisfy it. Formatting is not a scoring criterion.

## 3. Mermaid case

**Fixture and evidence.** The pinned smoke at commit
[`7ec2b716258efa0b048093dc0e314b4a753662e0`](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/blob/7ec2b716258efa0b048093dc0e314b4a753662e0/docs/research/mermaid-authoring-and-rendering.md#implementation-smoke-for-issues-29-and-30)
reports that backtick-fenced `accepted.md` produced a nonempty SVG. The CLI
skipped the tilde fence in `missed.md`; with zero SVGs, the gate exited 1 as
intended. Link resolution, legibility, alt text, and SVG metadata were human
inspection observations, not automated assertions. A separate `fallback.mmd`
render was not a fix or rerun of `missed.md`. GitHub preview and cross-platform
behavior were unchecked. Raw transcripts and a complete pinned dependency
manifest were not supplied. The matching [Mermaid guidance](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/blob/7ec2b716258efa0b048093dc0e314b4a753662e0/docs/agents/task-guidance.md#mermaid-diagrams)
suggests standalone `.mmd` extraction for ambiguous fences; this remains a
suggestion, not a completed action or result.

**Frozen rubric results.** Baseline Q4 scored **3/4 [1,0,1,1]**; candidate B9
scored **2/4 [0,0,1,1]**. For Q1, Q4's opening states separately that the CLI
skipped the tilde fence and the gate rejected zero SVGs; B9's opening reports
the rejection and no SVG, but does not explicitly say that the CLI skipped the
tilde fence (that fact appears in its body). For Q2, both openings state the
successful backtick case, but neither explicitly says both environments were
unchecked. Q4 omits both environment caveats; B9 says the smoke does not
establish behavior there, rather than explicitly saying they were unchecked.
For Q3, both drafts separate human inspection from automated gate results. For
Q4, both identify what remains unverified for `missed.md` and recommend
standalone rendering without claiming it was done. Neither made a material
false claim or omitted a consequential caveat from the baseline.

**Numbering, separately scored.** Q4 baseline: fail; its section headings are
unnumbered. B9 candidate: pass; its actual sections are numbered, including the
final “Blockers and next steps.” The title and TL;DR label are excluded by the
frozen rule.

## 4. Architecture case

**Fixture and evidence.** The pinned documentation snapshots at commit
[`6e1476558c1c7c9034803219a662c5ea23297323`](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/tree/6e1476558c1c7c9034803219a662c5ea23297323)
link the navigation page to the current overview and distinguish it from the
historical WP4/G2 topology. The supplied evidence distinguishes confirmed
responsibilities, bounded implementation evidence, and unresolved choices.
Independent semantic review and Julio's visual diagram acceptance are recorded;
visual approval does not demonstrate full implementation, complete code review,
MATLAB verification, end-to-end receiver behavior, or closure of open decisions.
This is a report on pinned documents, not an independent verification. No
operational or design specifics are inferred here.

**Frozen rubric results.** Baseline P8 scored **3/3 [1,1,1]**; candidate D3
scored **3/3 [1,1,1]**. Both direct the reader to the current overview, separate
confirmed/bounded/unresolved evidence with examples, and explain why diagram
approval is not implementation or verification. Neither introduced a material
false claim or lost a consequential caveat.

**Numbering, separately scored.** P8 baseline: fail; its actual section
headings are unnumbered. D3 candidate: pass; its actual section headings are
numbered. The title and TL;DR label are excluded. D3's raw draft also had an
MD013 finding on a 301-column line containing chained links; this is a separate
format limitation, not a semantic or numbering result. The exact draft remains
unchanged.

## 5. Candidate guidance evaluated

The candidate-only addition was the following exact text; the baseline used
common guidance without this addition:

> Use this experimental guidance in addition to the common root writer
> guidance. Begin with a standalone TL;DR stating the result and its
> consequential limit. After the opening, always use numbered, descriptive
> section headings. Connect motivation and goal, work carried out, observations
> (distinguish automated checks from human observations), findings, and
> conclusion; combine sections when it helps the reader. If the work encountered
> a blocker or failure, finish after the conclusion with a numbered **Blockers
> and next steps** section that states the outstanding blocker and suggested
> action without implying it was performed. Use tables for meaningful
> comparisons and the existing drawing-mermaid-diagrams skill for useful
> relationships, never as a quota. Support material claims from the supplied
> sources and preserve checked-versus-unchecked limits. These exact structural
> choices are house guidance, not publisher requirements.

**Draft provenance.** SHA-256: Q4 `616d974faab43d80102db8534db06f0fc61c0fa02268c52b6d83db178c610fa1`;
B9 `4f7da78e5b86214b3f1fc514c7c96878fa49837e166d6aa3d5b0a00b60cfeec9`;
P8 `99555097b844e837ba3f9687724a1036969b753a837444a47f6572a61c98a97d`;
D3 `d12bed9a95b5c40b89b6ff6b0c43d905f8da5c6945acf55c9128eed694d05bb0`.

## 6. Interpretation and disposition

For Mermaid, the candidate's reader score is lower despite its numbered body:
its opening does not explicitly say the CLI skipped the tilde fence. Although
it reports successful backtick rendering, it does not explicitly say GitHub
preview and cross-platform behavior were unchecked. For architecture, the
reader scores tie; numbering improved, but D3 has the noted long-line lint
limitation. Across both cases, the candidate did not improve the frozen reader
answers, so retain baseline technical-report guidance on this evidence. This
disposition is limited to these trial drafts and rubric; it is not a claim that
numbering or other house conventions are harmful.

The experimental TL;DR, numbered headings, and final blocker section are
project house preferences, not universal publisher mandates. Google advises
summarizing key points early; NASA distinguishes purpose/scope in an introduction
from a conclusion and varies report body by subject and complexity. Those
sources support compatible practices, not this exact template or a measured
quality gain. See [Google Technical Writing One](https://developers.google.com/tech-writing/one/documents#summarize_key_points_at_the_start)
and [NASA/SP–2015–7602 Rev. 2, §4.2](https://ntrs.nasa.gov/api/citations/20150013303/downloads/20150013303.pdf#page=22).

## 7. Evidence boundaries

Scores and draft descriptions above are the supplied blinded-review findings;
this report did not rerun the trials, smoke, or underlying architecture checks.
The source snapshots establish only their stated scope and observations. The
aggregate is descriptive, not statistical. Julio retains the adoption decision.
