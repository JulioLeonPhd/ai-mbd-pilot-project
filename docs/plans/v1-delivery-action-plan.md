# V1 delivery action plan

## Rule

Product progress > AI infrastructure progress until v1.

## Now

### Completed evidence

- Range-acceptance issues [#24] and [#23] closed on 2026-11-10. Candidate
  evidence remains bounded to the approved 200 m², 20 km point-target fixture.
- Julio approved the per-PRI MATLAB range compressor and walkthrough.
  [PR #26] merged on 2026-11-13. The implementation is
  `radardemo.rangeCompression.processPri`; see the [focused tests],
  [walkthrough], and [fixture-scoped production results]. Independent reviews
  found no unresolved errors within scope. Root ran MATLAB; the numerical
  reviewer did not independently rerun it. The merge does not establish
  full-range, hardware, or WP8 acceptance.
- The DDC PRI baseline merged in PR #17. Julio accepted the redrawn architecture
  diagrams on 2026-10-26; visual approval did not settle open design choices.

### Next decision

Julio selects the next component question and confirms its expected behavior
and acceptance observation using [step 5 of the human-led development plan].
Do not infer implementation authorization or gate advancement from PR #26.

[#24]: https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6762277382
[#23]: https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23#issuecomment-6762278228
[PR #26]: https://github.com/JulioLeonPhd/ai-mbd-pilot-project/pull/26
[focused tests]: ../../tests/rangeCompression/TestProcessPri.m
[walkthrough]: ../../examples/runRangeCompressionWalkthrough.m
[fixture-scoped production results]: ../../tests/rangeCompression/range-production-acceptance-results.json
[step 5 of the human-led development plan]: human-led-development.md#5-repeat-the-component-workflow

## Then

1. Freeze AI infrastructure.
2. Fix AI infra only if v1 blocked or materially impaired.
3. No new agents.
4. No new orchestration.
5. No new workflow machinery.
6. Build radar.
7. One component at a time.
8. Human understands component first.
9. Walkthrough tells engineering story.
10. Tests prove behaviour.
11. Evidence bounds claims.
12. Simulink after MATLAB reference and fixed-point design.
13. Finish v1.

## Review order

Requirement.

Then decision.

Then walkthrough.

Then public API.

Then tests and evidence.

Then internals where risk, uncertainty, or learning value demands.

## Walkthrough rule

Verbose on purpose.

Show units.

Show dimensions.

Show rates.

Show stages.

Show assumptions.

Show expected behaviour.

Show intermediate engineering meaning.

Show evidence boundaries.

Keep public API as execution boundary.

Do not hide algorithm behind convenience calls.

Do not copy private production implementation into example.

One implementation. One execution boundary. Transparent engineering story.

## After v1

Stop.

Look back.

Measure friction.

Delete machinery that earned no keep.

Improve only what evidence justifies.
