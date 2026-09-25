# Radar V1 data contracts

<!-- markdownlint-disable MD033 -->

**Status:** WP3 accepted; WP4/G2 Phase 0 frozen; Phase 4 independently passed;
Phase 5 independent document review and Phase 6 root gate passed; G2 accepted
for the frozen WP4 evidence. Issue #3 remains open for checker hardening.
**Contract family:** `radar-v1`
**Contract version:** `1.0.0-draft.2`

This document defines the interchange contracts for the floating-point MATLAB
reference. The five versioned envelopes are configuration, target scenario,
MAT test vector, processing intermediate, and detection list. JSON numbers are
finite IEEE-754
double values unless a field says otherwise. JSON object keys are case
sensitive and additional keys are invalid unless explicitly marked `extensions`.

<a id="wp4-decision-status"></a>

## Decision status

<a id="wp4-contract-authority"></a>

The accepted WP4/G2 Phase 0 values are defined in
[ADR 0018](../adr/0018-freeze-wp4-g2-phase0-contract.md). Independent Phase 4
validation passed 54/54 strict manifest rows with provenance and 54 tests.
Phase 5 independent document review passed and the Phase 6 root gate accepted
G2 for this evidence scope.

The field names, dimensions, units, signs, and provenance rules in this
document are the WP3 contract. The Phase 0 alias budget, receive schedule,
dimensions, fusion, and clustering seams are frozen decisions with Phase 4
independently passed. Phase 5 independent document review and Phase 6 root
closure passed. The two-stage DDC group delay is 372 ADC ticks, equal to 31
output samples. The remaining unresolved choices are
ambiguity method/order, angle and Doppler tolerances, near-zero-Doppler cutoff,
and downstream method parameters; their owning packages retain authority.
WP6e must select the ambiguity method and compare candidate processing orders.

## Common rules

<a id="common.version"></a>
Each JSON envelope has `schemaName`, `schemaVersion`, `documentVersion`, and
`id`. The MAT envelope carries the same provenance fields as MAT variables.
`schemaVersion` identifies the field schema; `documentVersion` identifies the
exact immutable document snapshot. Both use semantic versioning. A consumer
accepts the same schema major version and rejects a higher major version. It
may accept a lower minor version only after applying
the documented compatibility rules. It must reject unknown required fields,
non-finite values, wrong types, wrong dimensions, and unit/sign violations.
Every producer records `createdUtc` and `producer`; these are provenance, not
algorithm inputs. `timeEpoch` is an identifier for the simulation-time origin
at ADC tick zero, not a UTC timestamp. Reports also identify their common
five-PRF scan-midpoint tick or offset; `createdUtc` never enters DSP arithmetic.

The radar-centered frame is metres and metres per second: +x is boresight and
increasing range, +y is radar-left, +z is up, and positive radial velocity is
receding. ADC channel order is one-based in documentation and MATLAB indexing:
channel `k = 1..64` maps to row-major `(azimuthIndex, elevationIndex)` with
`azimuthIndex = floor((k-1)/4)+1` and `elevationIndex = mod(k-1,4)+1`. This map
is authoritative until an ADR changes it. A target's radial velocity is the
projection of its velocity onto the line of sight from the radar to its
position at the scenario reference epoch; a zero-range position is invalid.

<a id="wp4-configuration-envelope"></a>

## Configuration envelope

The radar configuration is authoritative for generator, DUT, and fixture
parameters. Required top-level fields are:

<!-- markdownlint-disable MD013 -->
| Field | Type/shape | Units and rule |
| --- | --- | --- |
| `schemaName` | string | `radar.configuration` |
| `schemaVersion` | string | `1.x`; this contract is `1.0.0-draft.2` |
| `id` | string | stable configuration identifier |
| `createdUtc`, `producer` | string | ISO-8601 timestamp; producer name/version |
| `rfCarrierHz` | number | Hz; exact current baseline `2997924580` (derive $\lambda=0.1$ m and $d=0.05$ m from ADR 0015) |
| `ifCenterHz` | number | Hz; current candidate `50e6` |
| `adcSampleRateHz` | number | samples/s; current candidate `150e6` |
| `adcBits` | integer | `16` |
| `channelCount` | integer | `64` |
| `array` | object | `azimuthElements: 16`, `elevationElements: 4`, `elementSpacingWavelengths: 0.5` |
| `waveform` | object | `pulseWidthSec: 40e-6`, `chirpBandwidthHz: 10e6`, `chirpStartHz: -5e6`, `chirpStopHz: 5e6` |
| `ddc` | object | `complexIntermediateRateHz: 50e6`, `outputRateHz: 12.5e6`, `decimationFactors: [3,4]`; passband `[-5e6,5e6]`, ripple `<=0.1 dB`, digital alias rejection `>=60 dB`, stage-2 stopband starts no later than `6.25e6` |
| `prfsHz` | array[5] | frozen `[1700,1900,2150,2450,2700]`; Phase 4 verified integer-tick schedule |
| `priSampleCounts` | integer array[5] | accepted `[88236,78948,69768,61224,55560]`; one-based 150 MHz ADC ticks; Phase 4 verified |
| `processing` | object | `maxInstrumentedRangeM: 100000`, `rangeDomainM: [6800,100000]`, and stage settings |
| `scan` | object | `azimuthSectorDeg: [-45,45]`, `updatePeriodSec: 1`; both provisional |
| `blanking` | object | configured `transmitBlankingSec: 40e-6` and `guardSec: 5e-6`; Phase 4 independently verified receive-window priming and guarded leading-edge timing |
| `random` | object | integer `seed`; all stochastic fixtures use it |
<!-- markdownlint-enable MD013 -->

Record requirements are exact: candidate records require `candidateId`,
`prfIndex`, `azimuthLookIndex`, `elevationLookIndex`, `rangeM`,
`foldedVelocityMps`, `statistic`, `sourceId`, `clusterEligible`, and
`clusterCell`; CFAR records require those look fields plus `rangeBin`,
`dopplerBin`, `sourceCellId`, `threshold`, `pass`, and `decisionState`; fused
hypotheses require length-five `validityMask`, `supportMask`, and `passMask`,
`voteCount`, `voteThreshold`, named `outcome`, `rangeM`,
`radialVelocityMps`, `statistic`, and plural `sourceCellIds`. Cluster-stage
hypotheses repeat the eligibility/look/cell fields. Aggregate clusters require
`clusterId`, `hypothesisIds`, `rangeM`, `radialVelocityMps`, `statistic`,
`validityMask`, `supportMask`, `passMask`, and sorted unique `sourceCellIds`;
they have no single `clusterCell`.

<a id="clustering.order"></a>
Clustering is input-order independent. The canonical member key is
`(sorted(sourceCellIds), hypothesisId)`; members are emitted in ascending key
order. Means use IEEE-754 double arithmetic in that order. Masks are exact
elementwise ORs. The aggregate statistic is the maximum member statistic,
breaking ties by lowest hypothesis ID. The canonical cluster key is its first
member key, and cluster IDs are assigned sequentially after sorting.

Draft.1 records are legacy regression inputs. A draft.1 record is accepted only
through an explicit adapter: derive `durationTicks` from the configured PRI,
derive `role` from legacy transition state (one priming record per group is
required), set missing `clusterEligible` to true only for eligible candidate
and fused hypotheses, derive look indices from commanded-look metadata, and
reject records when any value cannot be derived. WP3 examples and checker stay
legacy inputs; the WP4 checker owns adapter and migration tests.

`clusterEligible`, look indices, and `clusterCell` are required on candidate
records, CFAR records, fused hypotheses, and cluster-stage hypotheses. An
aggregate cluster has no single `clusterCell`; it carries `hypothesisIds`,
ordered arithmetic-mean range and velocity, statistic equal to the maximum
member statistic with lowest-ID tie break, OR-combined masks, and sorted unique
plural `sourceCellIds`. Duplicate cells remain distinct hypotheses but are
connected when adjacent. Cluster records sort by first-member canonical key and
receive sequential IDs from one.

<a id="fusion.mask-length"></a>
Fusion masks (`validityMask`, `supportMask`, and `passMask`) all have length five;
<a id="fusion.mask-subset"></a>
support is a subset of validity, `voteCount=sum(passMask)`, and threshold is
<a id="fusion.threshold"></a>
three. <a id="fusion.outcome"></a>Outcome is `pass` for at least three valid
passing layers, `fail` for at
least three valid layers but fewer than three passes, and `invalid` for fewer
than three valid layers. The diagnostic for a wrong mask length is
`DIMENSION_MISMATCH` at the mask path.

`processing` must also carry `nearZeroDoppler.enabled` and a numeric
`nearZeroDoppler.cutoffMps` once WP4 decides it. Until then, a fixture may set
`enabled: false`; it must not invent a cutoff. `processing.cfar`,
`processing.clustering`, and `processing.ambiguity` contain named method and
parameters only after their owning WP6/WP7 decision. A method value of
`pending-wp6e` or `pending-wp7` is valid in a draft fixture and cannot be used
as an acceptance result. No tolerance is implied by a missing field.

## Target-scenario envelope

The separate scenario contains a constant target list for one scan. Required
fields are `schemaName: "radar.target-scenario"`, `schemaVersion`, `id`,
`createdUtc`, `producer`, `timeEpoch`, `frame: "radar-centered"`,
`scanDurationSec`, and
`targets`. Each target has:

| Field | Type/shape | Units and rule |
| --- | --- | --- |
| `id` | string | unique within the scenario |
| `rcsM2` | number | strictly positive m² |
| `positionM` | number[3] | `[x,y,z]` in metres |
| `velocityMps` | number[3] | `[vx,vy,vz]` in m/s |

The generator derives radial velocity from the target state and preserves the
exact ADR 0015 carrier-derived Doppler and array phase. RCS and velocity remain
constant during the scan. Acceleration, RCS fluctuation, terrain, occlusion,
and terrestrial clutter are outside this contract.

## MAT test-vector envelope

The MAT file is a versioned test-vector envelope, not a JSON serialization.
Its required scalar metadata is `schemaName`, `schemaVersion`, `id`,
`createdUtc`, `producer`, `configurationId`, `configurationSchemaVersion`,
`configurationDocumentVersion`, `scenarioId`, `scenarioSchemaVersion`,
`scenarioDocumentVersion`, `configurationSnapshot`, `scenarioSnapshot`,
`generatorRevision`, `generatorVersion`, `generatorSeed`,
`generationParameters`,
`sampleRateHz`, `channelCount`, `sampleFormat`, `timeEpoch`, `fixtureScope`, and
`channelMap`. `sampleFormat` is exactly `real-int16`; `sampleRateHz` is
`150e6` for the current candidate.

The repository example `contracts/wp3/examples/test-vector.mat` contains a
`radarTestVector` struct with one `32x64` zero-valued `int16` slab. It is a
`unit-only` shape/provenance fixture; it does not represent a complete scan,
PRI schedule, or V1 acceptance case. Its metadata includes exact
`configurationSnapshot` and `scenarioSnapshot` UTF-8 JSON bytes and
`documentVersion` values. `generatorRevision` identifies the Git commit used
for generation, `generatorVersion` identifies the generator interface,
`generatorSeed` is an integer, and `generationParameters` is a scalar struct.
The hand-maintained canonical shape example uses `fixture-only` as its revision
until WP5 supplies a generator. Acceptance fixtures require a committed
revision. Replay compares sample arrays and meaningful metadata, not MAT-file
bytes.

Storage uses ordered pulse slabs, so a full scan need not be one giant matrix.
Routine generated vectors belong under `data/testVectors/` and are ignored by
Git. Deliberately retained large reference vectors belong under
`data/retainedTestVectors/` and may use Git LFS. The tiny canonical shape
example remains tracked until WP5 supplies a generation check.
`pulseRecords` contains records with `role` (`priming|usable|transition`),
`adcSamples` (`int16`, shape
`[samplesInPulse,64]`), `adcTick` (`uint64`, shape `[samplesInPulse,1]`),
`pulseStartTick`, `pulseSampleCount`, `durationTicks`, `prfIndex`, and
`prfNominalHz`. `pulseSampleCount` describes retained ADC samples and may be
smaller than the schedule duration; `adcTick` maps retained sample `j` to
`pulseStartTick+j` (or the declared `sampleTickOffset+j` when capture is
windowed). Schedule arithmetic uses `durationTicks`, never capture count.
Full-scan records also require logical scalar `isTransition`, which is true
exactly when `role=transition` and false otherwise. Each PRF has one priming
record and the accepted usable counts are `[22,25,28,32,35]`. A transition
retains `prfIndex` and `prfNominalHz` for its destination PRF and uses the
accepted `transitionGapTicks: 106872`. The unit-only shape example may omit
these schedule fields.
`prfIndex` is one-based and indexes the configured `prfsHz` array.
`adcTick` is the global ADC tick epoch and records may be consumed incrementally.
For each record after the first, `pulseStartTick` is the actual integer ADC tick
at which that record begins; its PRI is the difference from the preceding
record's start tick. For non-transition, same-PRF records, this difference must
equal `priSampleCounts(prfIndex)`. The derived actual PRF is
`adcSampleRateHz/priSampleCounts(prfIndex)`; the fifth candidate is therefore
`2699.784...` Hz by design. Transition records declare
`isTransition: true`; no inferred quantization is permitted. Optional
generator truth is under `truth`, with `targetId`, `rangeM`,
`radialVelocityMps`, `azimuthDeg`, and `elevationDeg`; truth is never read by
the DUT. Missing or mismatched configuration/scenario versions or snapshots
are invalid.

<a id="schedule.recurrence"></a>
<a id="wp4-schedule-recurrence"></a>
The complete schedule grammar is five groups of `(one priming, usableCount
usable)` records, with usableCount `[22,25,28,32,35]`, and four transitions only
between adjacent groups: exactly 151 records. Every interval is half-open;
`endTick = startTick + durationTicks`. Priming and usable records have
`durationTicks` equal to their PRF PRI; transitions have
`sampleCount=106872` and `durationTicks=106872`. Within a group, successive
starts differ
by the group's PRI count. Each transition has `sampleCount=106872`,
`durationTicks=106872`, and ends at the next priming start. The final end tick
is `10553388`; midpoint offset is `5276694` ticks. Any deviation is
`TICK_DISCONTINUITY`.

<a id="timing.delay-priming"></a>
Independent TIM-001 validation confirmed guarded leading-edge timing applied to
delay-compensated output timestamps, with a 372 ADC-tick (31 output-sample)
group delay. Verified derived metrics are `nominalRawMarginTicks=54`,
`motionBoundRawMarginTicks=46`, and `motionBoundAlignedMarginTicks=40`. The
schedule has 151 records: five priming records and 142 usable records. This
timing evidence does not claim full FIR precursor or waveform retention, or
detection performance.

<a id="DDC.passband-ripple"></a>
<a id="DDC.alias-rejection"></a>
<a id="wp4-ddc-metrics"></a>
DDC acceptance uses unity input-tone normalization and amplitude
`20*log10(abs(H))`. The frequency grid is uniform and includes endpoints.
Passband is `[-5,+5] MHz`; stage-2 stopband is `|f| >= 6.25 MHz` in the 50 MHz
pre-decimation input domain through 25 MHz. Stage-1 folding is into
`[-25,25] MHz` after `/3`; stage 2 folds that 50 MHz input before `/4`.
The cascade reference includes mixer, both filters, and both decimators.
Evaluate a deterministic 1 kHz grid including endpoints. Cascade digital alias
rejection is the minimum stopband attenuation relative to maximum passband
amplitude. Compare each metric with absolute tolerance `1e-9 dB`.

<a id="DDC.streaming-state"></a>
Streaming DDC validation shall process a real mixer input in unequal chunks
while preserving mixer, FIR, and decimator state continuously from scan start
across PRIs and transitions; the `/3` then `/4` decimator phases shall remain
continuous across those boundaries. Independent full-CPI evidence covers one
channel, 10,553,388 ticks, 150 PRI/transition boundaries, and 2,189 chunks.
It compares 19,480 observed output samples/timestamps selected across startup,
end, and boundary observation windows. Maximum absolute complex output-sample
discrepancy against independent direct convolution is `1.5e-15`. The zero-input
fixture separately verifies exact-zero output with the 64-channel shape.

<a id="DDC.zero-input"></a>
For a nonempty input whose samples are exactly zero, the DDC shall return an
output with the expected nonempty shape and every output sample exactly zero.
The acceptance fixture confirms this for the 64-channel DDC shape; full-CPI
streaming evidence is one channel and is not a detection-performance claim.

<a id="wp4-processing-intermediate"></a>

## Processing-intermediate envelope

Each stage fixture uses a common envelope with `schemaName:
"radar.processing-intermediate"`, `schemaVersion`, `id`, `stage`,
`createdUtc`, `producer`, `configurationId`, `testVectorId`, `timeEpoch`,
`sampleRateHz`, `shape`,
`units`, `channelMap`, `data`, and `metadata`. Dense signal stages use numeric
MATLAB arrays whose shapes are exactly declared by `shape`; each dense stage
declares axis arrays whose lengths equal the corresponding entries of `shape`;
complex values use
MATLAB complex arrays in MAT files. Row-oriented stages use typed struct
arrays. `metadata` records the fixture seed, axis names,
and stage-specific calibration or index origin. Every fixture declares
`fixtureScope` as one of `acceptance`, `out-of-domain`, `unit-only`, or
`provisional`; only `acceptance` fixtures can support a V1 gate. Every fixture carries
`sourceId`, `sourceSchemaVersion`, and `sourceDocumentVersion`. Generated
fixtures also carry generator revision, version, seed, and parameters; hashes
are not required when code permits semantic replay.

The supported stage seams are `ddc`, `azimuth-beamformed`, `range`, `doppler`, `angle`,
`candidate-list`, `ambiguity-projection`, `cfar`, `fusion`, and `cluster`.
Projection preserves five separate PRF layers; CFAR emits one decision per
layer, including explicit invalid/fail states, and fusion votes across those
five distinct decisions. Their minimum data contracts are:

<a id="beamforming.shape"></a>
The authoritative beamforming shape invariant is `[sample,64]` at DDC input
and `[sample,4]` after commanded-look summation, as shown by the
`azimuth-beamformed` stage below.

<a id="clustering.components"></a>
<a id="clustering.no-wrap"></a>
<a id="clustering.no-bridge"></a>
<a id="clustering.same-look"></a>
The authoritative clustering invariant is connected components over eligible
hypotheses using same-look one-cell Chebyshev adjacency with ordinary integer
differences, without edge wrapping or ineligible bridging; different looks are
never deduplicated.

<!-- markdownlint-disable MD013 -->
| Stage | `data` shape and meaning | Required units |
| --- | --- | --- |
| `ddc` | `[sample, channel]` complex baseband | V or normalized ADC units; producer must state one |
| `azimuth-beamformed` | `[sample, elevation]` complex after commanded-look coherent summation of 16 azimuth elements per row | four elevation streams; commanded `azimuthLookIndex` and steering metadata |
| `range` | `[rangeBin, pulse, elevation]` complex after azimuth beamforming | range-bin index plus `rangeBinCentersM` |
| `doppler` | `[rangeBin, dopplerBin, elevation]` complex after azimuth beamforming; any real statistic is a separate named field or seam | `rangeBinCentersM`, `dopplerBinCentersMps`; commanded `azimuthLookIndex` |
| `angle` | typed struct array shape `[N,1]` with fields `rangeM`, `radialVelocityMps`, `azimuthDeg`, `elevationDeg`, `statistic` | one-based row indices; scalar numeric fields and statistic units are declared |
| `candidate-list` | typed struct array shape `[N,1]` with unique one-based `candidateId`, one-based `prfIndex`, `azimuthLookIndex`, `elevationLookIndex`, `rangeM`, `foldedVelocityMps`, `statistic`, `sourceId`, `clusterEligible`, `clusterCell=[rangeCell,dopplerCell]` | PRF and angle-look indices are one-based and preserved; no resolver method implied |
| `ambiguity-projection` | typed struct array preserving five PRF layers, with common hypothesis coordinates, per-PRF `validityMask`, and `sourceCellId` identities | each hypothesis retains its five-layer eligibility and source-cell provenance before per-PRF CFAR; invalid layers are explicit |
| `cfar` | typed struct array shape `[N,1]` with one-based `prfIndex`, `azimuthLookIndex`, `elevationLookIndex`, `rangeBin`, `dopplerBin`, `sourceCellId`, `statistic`, `threshold`, logical `pass`, and `decisionState` | `decisionState` is one of `pass`, `fail`, or `invalid`; invalidity is recorded in the CFAR record and mirrored in the fusion masks |
| `fusion` | typed struct array shape `[N,1]` with `validityMask`, `supportMask`, `voteCount`, `voteThreshold`, `residual`, `ambiguityStatus`, `sourceCellIds`, and fused `rangeM`/`radialVelocityMps` | masks distinguish eligible, pass, fail, and invalid PRF decisions; source identities preserve contributing PRFs/cells; `voteThreshold` is 3 for the full-domain 3-of-5 baseline; residual and status are declared for unresolved hypotheses |
| `cluster` | typed struct arrays of fused hypotheses with shape `[H,1]` and cluster records with shape `[C,1]`; records carry fused coordinates, `supportMask`, `validityMask`, `clusterEligible`, one-based look indices, `clusterCell=[rangeCell,dopplerCell]`, and contributing `sourceCellIds` | connected components use same-look one-cell Chebyshev adjacency with ordinary integer differences, no edge wrap, no ineligible bridging, and no cross-look deduplication |
<!-- markdownlint-enable MD013 -->

For the `cluster` stage, `H` is the number of fused hypotheses and `C` is the
number of cluster records; `H` and `C` are independent cardinalities. For the
cluster stage, the top-level `shape` must equal
`metadata.clusterShape: [C,1]`. `hypothesisShape: [H,1]` independently
describes the fused hypotheses; both shapes validate their corresponding
arrays independently.
Many-to-one clustering, including `H != C`, is valid. Every entry in each
cluster record's `hypothesisIds` must reference a
hypothesis in the same cluster-stage envelope.

The baseline stage order is ambiguity projection/unfolding, per-PRF CFAR,
M-of-5 binary fusion, then clustering. Migration alignment and CFAR
window/threshold remain open WP4 decisions. WP6e may compare alternatives, but
must preserve the five PRF layers and this fusion seam. The full-domain baseline
is 3-of-5; 4-of-5 is a comparator. Unresolved
hypotheses produce diagnostics without a definitive report. A confidence score
may break ties only if WP6e evidence validates it.
Migration handling preserves a declared pulse axis and source pulse ticks; the
contract does not prescribe compensation, interpolation, or hypothesis
iteration. A fixture marked `out-of-domain`, `unit-only`, or `provisional`
cannot be used as V1 acceptance evidence.
Implementations must preserve these seams and record the selected method in
`metadata`; they must not infer an order from an example.
Candidate PRF and angle-look provenance must remain available through
association and be preserved in any final report that exposes PRF evidence.
ADR 0016 records the five-PRF decision and reopened CPI pulse-count trade;
ADR 0017 is historical; its rounded schedule arithmetic is superseded by ADR
0018, which owns the frozen Phase 0 schedule and receive seam.

<a id="wp4-detection-list"></a>

## Detection-list envelope

The output has `schemaName: "radar.detection-list"`, `schemaVersion`,
`documentVersion`, `id`, `createdUtc`, `producer`, `configurationId`,
`testVectorId`, `timeEpoch`,
`fixtureScope`, `detections`, and `metadata`. Detection examples carry the
same configuration and test-vector document versions in metadata;
the repository empty example declares a shape-only unit scope and is therefore
unit-only,
not V1 acceptance evidence.
Each detection has required fields `detectionId` (string), `rangeM`,
`radialVelocityMps`, `azimuthDeg`, `elevationDeg`, and `detectionStatistic`.
`detectionStatistic` is an object with `name`, `value`, and `units`; its name
and units are pending the WP7 detector decision. Acceptance-scope reports must
include `metadata.scanMidpointTick`, identifying the common five-PRF
scan-midpoint reference. Unit-only shape examples may omit this field. Optional
provenance fields
`clusterId`, `prfEvidence`, and `ambiguityStatus` are present only when the
selected method defines them. Empty `detections: []` is valid. Duplicate
`detectionId` values, non-finite values, and reports outside the configured
range domain are invalid.

<a id="wp4-invalid-input"></a>

## Invalid-input behavior

Schema or type errors, missing provenance, invalid dimensions, non-finite
numbers, non-monotonic ticks, unknown channel mapping, inconsistent rates, and
version major mismatch must fail before processing with a structured error
containing `code`, `path`, and `message`.
<a id="processing.zero-result"></a>
A valid zero-result input returns an
empty detection list. Out-of-domain range, stationary/near-zero-speed cases,
or provisional sector values are valid only when the fixture declares the
applicable scope; they are not silently clipped, relabeled, or accepted as V1
performance evidence. Unsupported pending methods return `code:
"METHOD_PENDING"`.

<a id="fusion.zero-result"></a>
Fusion accepts an empty hypothesis list and returns an empty hypothesis list
and empty result set.

<a id="clustering.zero-result"></a>
Clustering accepts `H=0,C=0` (zero hypotheses and zero clusters). It also
accepts `H>0,C=0` when all hypotheses are ineligible for clustering.

<a id="clustering.mask-length"></a>
Each cluster-stage hypothesis carries a logical `validityMask` of length five,
one entry for each PRF layer.

<a id="wp4-examples-compatibility"></a>

## Examples and compatibility

Configuration and scenario snapshots are exact UTF-8 JSON bytes, including
their `documentVersion`; hashes are optional and are not required when
generator code and metadata permit semantic replay.

Canonical JSON examples belong under `contracts/wp3/examples/` and must use
the exact field names and versions above. The MAT example must contain the
metadata and arrays described here. Every example must cross-reference an
existing configuration and scenario identifier; a detection example must
cross-reference its test vector.

Prerelease versions, including this draft, require exact schema-version
matching. For released versions, minor-version additions may add optional fields.
A producer introducing a
required field or changing type, units, sign, shape, channel map, or stage
meaning must increment the major version and provide a migration note. A
consumer must reject a major mismatch and report the expected and received
versions.

<a id="wp4-conformance-matrix"></a>

## Conformance checklist and matrix

<!-- markdownlint-disable MD013 -->
| Contract | Producer check | Consumer check | Status/evidence owner |
| --- | --- | --- | --- |
| Configuration | required fields, finite values, candidate/pending status | schema, units, rates, array/channel count | WP3; Phase 4 verified frozen schedule, timing, priming, and finite-filter values |
| Scenario | unique IDs, positive RCS, 3-vectors, constant-state declaration | frame, types, finite values, signs | WP3/WP5 |
| MAT vector | exact provenance, `int16 [N,64]`, monotonic global ticks | versions, epoch, shape, channel map | WP3/WP5 |
| DDC/range/Doppler/angle intermediates | declared shape, rate, units, stage metadata | seam and dimensions; no method inference | WP6a–d |
| Candidate/CFAR/cluster intermediates | explicit method and statistic metadata | pending methods rejected for acceptance | WP6e/WP7 |
| Detection list | required fields, statistic object, unique IDs | units, domain, provenance, empty-list behavior | WP7/WP8 |
| Compatibility | semantic version and migration note | major mismatch rejection | WP3 |
<!-- markdownlint-enable MD013 -->

Phase 4 independently validated the WP4-owned frozen schedule, finite-filter,
timing, priming, and executable fixture evidence. Phases 5 and 6 passed; G2 is
accepted for this evidence scope. Open WP6e/WP7 choices, including ambiguity
processing and downstream method parameters, stay
with those packages; they may trigger a recorded G2 reopening and must not
silently change field meanings. Issue #3 remains open; Git independently
verified the current committed source/evidence pair.
