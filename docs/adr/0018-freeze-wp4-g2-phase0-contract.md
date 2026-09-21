---
status: accepted
---

<!-- markdownlint-disable MD033 -->

# Freeze WP4/G2 Phase 0 contract

## Context

WP4/G2 needs an executable contract for the receive dimensions, finite DDC
acceptance budget, integer-tick scan schedule, five-PRF fusion, and clustering
seams. This ADR freezes those interfaces before executable verification. It does
not pass G2 or select the WP6e ambiguity-resolution method or order.

## Decision

ADR 0018 is authoritative for WP4/G2 decisions and rationale. The data
contract owns field-level envelopes and invariants; architecture and
requirements summarize this decision and must not introduce competing values.

<!-- Decision anchors are retained for schedule, DDC, beamforming, fusion, and
clustering rationale. Executable field/invariant selectors belong to the data
contract. -->

<a id="wp4-schedule-recurrence"></a>
<a id="ADR0018.schedule"></a>
Use 150 MHz ADC ticks and half-open intervals. The configured PRFs remain
`[1700,1900,2150,2450,2700]` Hz with PRI counts
`[88236,78948,69768,61224,55560]`. The usable pulse counts are
`[22,25,28,32,35]`, with one `priming` record per PRF and explicit record roles
`priming|usable|transition`. `isTransition` is retained for compatibility and
must be `true` exactly when `role=transition`, and false otherwise. A transition
record names its destination PRF. The transition gap is `106872` ticks. The
total scan is `10553388` ticks versus the `10597950`-tick cap, leaving `44562`
ticks; the common midpoint offset is `5276694` ticks.

The schedule contains exactly 151 records: five contiguous PRF groups, each
starting with one priming record followed by its declared usable records, plus
four transition records only between adjacent groups. Records use half-open
intervals `[startTick,endTick)`. For a pulse record,
`endTick=startTick+durationTicks`; within a group the next start is the prior
start plus its PRI count. Priming and usable records have `durationTicks` equal
to their PRI count. A transition has `sampleCount=106872`,
`durationTicks=106872`, and its interval ends exactly at the next group's
priming start. The final end tick is `10553388`; midpoint is offset
`5276694` from scan start. This grammar is the source of the totals above.

<a id="wp4-ddc-metrics"></a>
<a id="ADR0018.ddc-metrics"></a>
The DDC contract is a 50 MHz complex intermediate followed by 12.5 MHz complex
output (`/3`, then `/4`). The accepted finite-filter budget is passband
`[-5,+5] MHz`, ripple `<=0.1 dB`, digital decimation-alias rejection `>=60 dB`,
and stage-2 stopband start no later than `6.25 MHz`. Metrics use input-tone
amplitude normalized to unity, amplitude dB `20*log10(abs(H))`, a uniform
frequency grid including band endpoints, passband `[-5,+5] MHz`, and
stopband in the 50 MHz pre-decimation input domain is `|f| >= 6.25 MHz` through
25 MHz. Stage 1 folds into `[-25,25] MHz` after `/3`; stage 2 folds that domain
at its 50 MHz input before `/4`. The cascade reference includes mixer, both
filters, and both decimators. Use a deterministic 1 kHz grid including all
endpoints. Cascade alias rejection is the minimum stopband attenuation relative
to maximum passband amplitude.
Numerical comparisons use an absolute tolerance of `1e-9 dB` after conversion
to dB. The 95–105 MHz analog alias
condition remains a front-end assumption, not a digital-filter claim.

<a id="wp4-beamforming-shape"></a>
<a id="ADR0018.beamforming"></a>
DDC preserves shape `[N,64]`. For commanded look angle `theta`, with positive
radar-left azimuth, row `r` and azimuth element `a` use manifold
`v_a(theta)=exp(-1i*2*pi*(a-1)*0.5*sin(theta))`; the beam output is the
conjugate sum `y_r=sum(conj(v_a)*x_(a,r))`. It is intentionally unnormalized,
so a boresight matched input has amplitude gain 16. The four elevation rows are
independent and produce four outputs. Commanded-look beamforming coherently sums
the 16
azimuth elements in each of four elevation rows, producing `[N,4]`; range and
Doppler consume those four streams. Candidate, CFAR, fusion, and cluster
records carry `clusterEligible`, one-based `azimuthLookIndex`,
`elevationLookIndex`, and `clusterCell=[rangeCell,dopplerCell]` where applicable.

The clustering decision is connected components over eligible hypotheses with
the same look and one-cell adjacency; the executable ordering and edge-case
invariants are defined once in the data contract.

See the data contract for the single testable definition of no-wrap, no-bridge,
same-look, and deterministic ordering invariants.
Post-CFAR fusion remains 3-of-5. `validityMask`, `supportMask`, and `passMask`
are logical vectors of length five; `supportMask` is a subset of validity,
`voteCount=sum(passMask)`, and `voteThreshold=3`. A valid fused outcome is
`pass` when at least three valid layers pass, `fail` when at least three valid
layers exist but fewer than three pass, and
<a id="wp4-clustering-components"></a>`invalid` when fewer than three valid
layers exist. Five PRF layers and source identities are preserved.

For a fused hypothesis, `clusterEligible`, look indices, and `clusterCell` are
fields on the hypothesis. A cluster-stage hypothesis repeats those fields.
An aggregate cluster has no single `clusterCell`; it carries `hypothesisIds`,
ordered arithmetic-mean `rangeM` and `radialVelocityMps`, statistic equal to
the maximum member statistic (stable lowest-ID tie), OR masks, and sorted unique
plural `sourceCellIds`. Duplicate cells remain separate hypotheses but belong
to one component when adjacent. Clusters sort by their first member's canonical
key and receive sequential IDs starting at one.

Schema `1.0.0-draft.2` supersedes draft.1. Producers must emit draft.2;
consumers may migrate draft.1 only through an explicit adapter that adds the
new role, schedule, DDC metric metadata, masks, and provenance fields. No
implicit migration is allowed. The WP3 examples and checker require an
implementation-owned migration update.

## Consequences and validation

The contract is implementation-ready but executable checker/tooling is not yet
available. The WP4 fixture manifest records expected valid, invalid,
zero-result, version-mismatch, and dimension-mismatch cases and their diagnostic
paths. G2 remains pending until those cases execute and timing, DDC, dimensions,
fusion, and clustering evidence pass. WP6e retains authority over ambiguity
resolution and may reopen this decision.
