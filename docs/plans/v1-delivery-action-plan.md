# V1 delivery action plan

## Rule

Product progress > AI infrastructure progress until v1.

## Now

1. Keep issue #23 open while carrying the approved range-acceptance choices into the WP6b plan; physical one-bin association and the 3 dB power-valley criterion are approved, while numerical tolerances and RCS remain pending.
2. In a future session only, prepare and execute the authorized bounded reference-only study described in the [WP6b range-acceptance plan](radar-matlab-v1.md#wp6b-range-acceptance-planning), then present proposed numerical tolerances for Julio's review.
3. Do not execute the study in this session or begin production implementation; neither study results nor implementation authorization exist.

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
