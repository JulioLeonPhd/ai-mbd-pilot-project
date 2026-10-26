---
status: accepted
---
<!-- markdownlint-disable MD033 -->

# Freeze WP4/G2 Phase 0 contract

## Context

WP4/G2 needs executable contract: receive dimensions, finite DDC
acceptance budget, integer-tick scan schedule, five-PRF fusion, clustering
seams. ADR freezes interfaces before executable verification. Does
not pass G2 or select WP6e ambiguity-resolution method or order.

## Decision

ADR 0018 authoritative for WP4/G2 decisions and rationale. Data
contract owns field-level envelopes and invariants; architecture and
requirements summarize decision, must not introduce competing values.

<!-- Decision anchors retained for schedule, DDC, beamforming, fusion, and
clustering rationale. Executable field/invariant selectors belong to data
contract. -->

<a id="wp4-schedule-recurrence"></a>
<a id="ADR0018.schedule"></a>
Use 150 MHz ADC ticks, half-open intervals. Configured PRFs remain
`[1700,1900,2150,2450,2700]` Hz; PRI counts
`[88236,78948,69768,61224,55560]`. Usable pulse counts
`[22,25,28,32,35]`; one `priming` record per PRF; explicit record roles
`priming|usable|transition`. Retain `isTransition` for compatibility:
must be `true` exactly when `role=transition`, false otherwise. Transition
record names destination PRF. Transition gap `106872` ticks.
Total scan `10553388` ticks versus `10597950`-tick cap; leaves `44562`
ticks; common midpoint offset `5276694` ticks.

Schedule: exactly 151 records; five contiguous PRF groups, each
starting with one priming record then declared usable records, plus
four transition records only between adjacent groups. Records use half-open
intervals `[startTick,endTick)`. Pulse record:
`endTick=startTick+durationTicks`; within group, next start equals prior
start plus PRI count. Priming and usable records: `durationTicks` equals
PRI count. Transition: `sampleCount=106872`,
`durationTicks=106872`; interval ends exactly at next group's
priming start. Final end tick `10553388`; midpoint offset
`5276694` from scan start. Grammar determines totals above.

<a id="wp4-ddc-metrics"></a>
<a id="ADR0018.ddc-metrics"></a>
DDC contract: 50 MHz complex intermediate then 12.5 MHz complex
output (`/3`, then `/4`). Accepted finite-filter budget: passband
`[-5,+5] MHz`, ripple `<=0.1 dB`, digital decimation-alias rejection `>=60 dB`,
stage-2 stopband start no later than `6.25 MHz`. Metrics: input-tone
amplitude normalized to unity, amplitude dB `20*log10(abs(H))`, uniform
frequency grid including band endpoints, passband `[-5,+5] MHz`;
stopband in 50 MHz pre-decimation input domain: `|f| >= 6.25 MHz` through
25 MHz. Stage 1 folds into `[-25,25] MHz` after `/3`; stage 2 folds that domain
at 50 MHz input before `/4`. Cascade reference includes mixer, both
filters, both decimators. Use deterministic 1 kHz grid including all
endpoints. Cascade alias rejection: minimum stopband attenuation relative
to maximum passband amplitude.
Numerical comparisons: absolute tolerance `1e-9 dB` after conversion
to dB. 95–105 MHz analog alias
condition remains front-end assumption, not digital-filter claim.

DDC streaming assumptions in Phase 0 baseline describe historical
continuous-state implementation and its G2 evidence. Superseded for
future DDC call boundaries by [ADR 0022](0022-adopt-independent-pri-ddc-processing.md),
preserving filter budget and scan schedule while resetting local DDC
state at each complete physical PRI. Existing G2 streaming evidence remains
scoped to pinned historical baseline.

<a id="wp4-beamforming-shape"></a>
<a id="ADR0018.beamforming"></a>
DDC preserves shape `[N,64]`. Commanded look angle `theta`, positive
radar-left azimuth: row `r` and azimuth element `a` use manifold
`v_a(theta)=exp(-1i*2*pi*(a-1)*0.5*sin(theta))`; beam output:
conjugate sum `y_r=sum(conj(v_a)*x_(a,r))`. Intentionally unnormalized;
boresight matched input amplitude gain 16. Four elevation rows
independent, produce four outputs. Commanded-look beamforming coherently sums
16
azimuth elements in each of four elevation rows, producing `[N,4]`; range and
Doppler consume four streams. Candidate, CFAR, fusion, cluster
records carry `clusterEligible`, one-based `azimuthLookIndex`,
`elevationLookIndex`, and `clusterCell=[rangeCell,dopplerCell]` where applicable.

Clustering: connected components over eligible hypotheses with
same look and one-cell adjacency; executable ordering and edge-case
invariants defined once in data contract.

See data contract for single testable definition of no-wrap, no-bridge,
same-look, deterministic ordering invariants.
Post-CFAR fusion remains 3-of-5. `validityMask`, `supportMask`, `passMask`:
logical vectors length five; `supportMask` subset of validity,
`voteCount=sum(passMask)`, `voteThreshold=3`. Valid fused outcome:
`pass` when at least three valid layers pass; `fail` when at least three valid
layers exist but fewer than three pass; and
<a id="wp4-clustering-components"></a>`invalid` when fewer than three valid
layers exist. Preserve five PRF layers and source identities.

Fused hypothesis fields: `clusterEligible`, look indices, `clusterCell`.
Cluster-stage hypothesis repeats fields.
Aggregate cluster has no single `clusterCell`; carries `hypothesisIds`,
ordered arithmetic-mean `rangeM` and `radialVelocityMps`, statistic equal to
maximum member statistic (stable lowest-ID tie), OR masks, sorted unique
plural `sourceCellIds`. Duplicate cells remain separate hypotheses but belong
to one component when adjacent. Clusters sort by first member's canonical
key; receive sequential IDs starting at one.

Schema `1.0.0-draft.2` supersedes draft.1. Producers must emit draft.2;
consumers may migrate draft.1 only through explicit adapter adding
new role, schedule, DDC metric metadata, masks, provenance fields. No
implicit migration allowed. WP3 examples and checker require
implementation-owned migration update.

## Consequences and validation

Contract implementation-ready; executable checker/tooling not yet
available. WP4 fixture manifest records expected valid, invalid,
zero-result, version-mismatch, dimension-mismatch cases and diagnostic
paths. G2 remains pending until cases execute and timing, DDC, dimensions,
fusion, clustering evidence pass. WP6e retains ambiguity-resolution
authority; may reopen decision.
