# V1 delivery action plan

## Rule

Product progress > AI infrastructure progress until v1.

## Now

1. Range-acceptance issues #24 and #23 closed on 2026-11-10; see the final [#24 resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/24#issuecomment-6762277382) and [#23 resolution](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23#issuecomment-6762278228). The candidate evidence remains bounded to the approved 200 m², 20 km point-target fixture; historical reports and JSON remain unchanged.
2. Next, request Julio's explicit production-implementation authorization. Issue closure and evidence do not authorize implementation or advance a gate; no new milestone or gate assignment is recorded.

Completed context: the DDC PRI baseline merged in PR #17, and Julio accepted
the redrawn architecture diagrams on 2026-10-26; neither result grants range
implementation authorization or settles open architecture choices.

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
