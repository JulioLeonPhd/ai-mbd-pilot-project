# #34 Research-Report Trial: Evidence and Recommendation

## 1. Executive Summary

The candidate scored 4/4 against the baseline's 3/4 on the frozen reader
questions. Both drafts retained the principal limits; the candidate uniquely
identified the assigning Researcher as the source of the recommendation. The
candidate also numbered all six actual section headings. No material false
claim or lost consequential caveat was reported in the candidate.

This is one draft per arm, with unequal parent-task packaging as a confound.
It is an exploratory result, not causal proof, a benchmark, or adoption
approval. The evidence supports recommending the candidate research wording
to Julio for his adoption decision—not deploying it or claiming it is
approved.

## 2. Question, Protocol, and Scoring

**Question:** Should maintainers adopt the old generic writer patch? For this
research-report trial, the frozen fixture supplied that prior result and the
Researcher's recommendation to retain baseline guidance, then asked whether
the candidate genre wording better supported reader answers.

The frozen protocol called for one fresh native Researcher-to-writer run per
arm, using the same substantive fixture, audience, goal, source facts and
output constraints. Writers used `gpt-6-luna/high`; Researcher parents used
`gpt-6.2-sol/xhigh`. Reviewers received randomized opaque labels, the two
artifacts and the frozen key, not the arm mapping or drafting instructions.
Each question scored 1 only when all required facts were recoverable without
guessing. Reviewers also checked material errors and lost caveats. Their
recommendation criteria required a higher reader score, a candidate numbering
pass, and no new material error or lost consequential caveat. Julio retains the
adoption decision. One draft per arm is exploratory.

The same substantive fixture was not packaged identically: the baseline
Researcher parent received its verbatim text plus a link; the candidate parent
received a reference to the fixture plus an addendum, which the writer read.
This packaging difference is a confound. The mapped draft hashes are supplied
as recorded; source packets and rubric are not independently hash-pinned here.

| Arm | Draft | SHA-256 | Reader vector | Score |
| --- | --- | --- | --- | --- |
| Baseline (N7) | `trial-n7.md` | `3d5db97c861c2079fb25838586a469a97414ece145b0b10d5f8f47d5bd42de60` | `[1, 1, 1, 0]` | 3/4 |
| Candidate (K2) | `trial-k2.md` | `07667aa4a7a29d7edc41a9df3b32acc281745d80532cd3dc4cde012f78f0a8c7` | `[1, 1, 1, 1]` | 4/4 |

Vector order: (1) answer whether to adopt the generic patch; (2) source-backed
reason; (3) evidentiary limit; (4) whose recommendation and what next. The
baseline omitted recommendation ownership: naming Julio as decision owner did
not identify the assigning Researcher as recommender. The candidate did.
Root's separate `grep -E '^#{1,6} ' trial-{n7,k2}.md` result found six
consecutive numbered body headings in K2 and three unnumbered body headings in
N7; the title and abstract label were excluded. This numbering observation is
separate from the blind semantic scores.

## 3. Evidence and Limits

The candidate gave the direct answer, attributed the recommendation to the
assigning Researcher, explained the single-comparison rationale, and stated
that it was not proof of general performance. Its next step was a separate
genre-specific evaluation under frozen fixtures and blind review. The reviewer
reported no material false claim or consequential caveat omission against the
key. The baseline likewise retained the main evidence limits and did not make
a material false claim, but missed the ownership criterion.

Issue #32 reported baseline 1/2 versus generic patch 0/2. This supplied prior
result was not replicated here and is distinct from the #34 scores above;
original #32 drafts and score sheet were not inspected in this trial. The
pinned Mermaid smoke supplies case context, not comparative scoring. As
reported, the backtick case produced an SVG; the CLI skipped the tilde fence
and the gate rejected zero SVGs. GitHub preview and cross-platform rendering
were unchecked. This trial cannot isolate wording from run variation or the
packaging confound, and says nothing general about other runs, genres,
instructions, or audience inference. No current adoption was shown.

Root's `markdownlint-cli2` command/report recorded a separate raw-draft
Markdown result: N7 was clean; K2 had MD052 for adjacent `[1][2]` and MD018 at
the reference continuation `#30.*`. These lint findings do not change the
blind semantic reader scores; the drafts were not edited. The heading-numbering
observations above are also separate from those scores.

## 4. Source Grounding

The proposed form uses IEEE conventions selectively; it does not claim that
IEEE mandates this report structure. IEEE's author manual calls section
enumeration desirable, not required, and gives abstract requirements for its
journal scope. IEEE's Transactions on Professional Communication citation
guide specifies numbering references by order of first mention. The numbered
Markdown sections and the reader criteria—abstract question, main finding and
material limit—are project choices. A published survey illustrates, but does
not prescribe, an abstract, scope and comparison with earlier surveys,
organized synthesis, open problems and conclusion. None of these sources
establishes that this wording improves writer performance.

1. IEEE, *Editorial Style Manual for Authors*, 29 July 2024, §§II, II.B;
   pp. 5, 10–11, 13–14. [Author Center PDF](https://journals.ieeeauthorcenter.ieee.org/wp-content/uploads/sites/7/IEEE-Editorial-Style-Manual-for-Authors.pdf).
2. IEEE Transactions on Professional Communication, *Citation Style*, rev.
   2020-09-15, p. 1. [Venue guide](https://procomm.ieee.org/wp-content/uploads/2020/10/TPC-Citation-Style.pdf#page=1).
3. Lu et al., “Semantics-Empowered Communication: A Survey,” *IEEE
   Communications Surveys & Tutorials*, 26(1), 41–79, 2024.
   [DOI](https://doi.org/10.1109/COMST.2023.3333342); [published text](https://rongpeng.info/images/pdfs/papers/2024_Lu_Semantics-empowered%20communication.pdf).
4. [Issue #32, Testing Decisions and Further Notes](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/32).
5. [Pinned Mermaid smoke and evidence limits](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/blob/7ec2b716258efa0b048093dc0e314b4a753662e0/docs/research/mermaid-authoring-and-rendering.md#implementation-smoke-for-issues-29-and-30).
6. [ADR 0031, Decision](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/blob/597ca338b0d4a748440d9744c77e146fb6913c66/docs/adr/0031-authorize-bounded-technical-writing-trial.md#decision).

## 5. Recommendation to Julio (Not an Approval)

Recommend adopting the candidate research-report wording for Julio's
consideration: it improved the frozen reader score by one point, passed the
separate numbering check, and had no reported material error or lost critical
caveat. This is a conditional recommendation from this sample only. The
unequal packaging, single draft per arm, and unreplicated issue #32 evidence
preclude causal or general claims. Adoption remains Julio's decision; this
report records no approval and authorizes no deployment.

## 6. Historically Evaluated Candidate Text (Non-Operational)

The following is the exact sealed addendum used for the candidate arm. It is
preserved as historical trial evidence, not active writer guidance:

> Use this experimental guidance in addition to common root writer guidance.
> Open with a short, standalone survey-style abstract stating the commissioned
> question, main answer/finding and material limit. Always use numbered,
> descriptive section headings for the sections that follow, including
> references. Introduce the question and scope; describe the evidence base or
> state of the art; synthesize comparative findings; make limits explicit;
> conclude with a direct answer, distinguish and attribute the assigning
> Researcher's recommendation, explain why it follows, and state next steps.
> Use bracketed IEEE-style numbers for source references in order of first
> citation, reusing the number on subsequent citations. Do not add research or
> invent an opinion; return material gaps to the assigner. The structural and
> numbering requirements are house guidance, not IEEE mandates.
