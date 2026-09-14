# Radar V1 data contracts

**Status:** WP3 draft for G2 review
**Contract family:** `radar-v1`
**Contract version:** `1.0.0-draft.1`

This document defines the interchange contracts for the floating-point MATLAB
reference. The five versioned envelopes are configuration, target scenario,
MAT test vector, processing intermediate, and detection list. JSON numbers are
finite IEEE-754
double values unless a field says otherwise. JSON object keys are case
sensitive and additional keys are invalid unless explicitly marked `extensions`.

## Decision status

The field names, dimensions, units, signs, and provenance rules in this
document are the WP3 contract. Candidate values are recorded for traceability,
not as accepted implementation defaults. A value marked **G2-pending** is an
interface placeholder and is not a pass criterion. WP4/G2 must resolve filter
delay and alias rejection, receive
window priming and transitions, the usable-return schedule, migration handling,
angle and Doppler tolerances, near-zero-Doppler cutoff and suppression
tolerance, and the exact detection statistic. WP6e must select the ambiguity
method; this contract does not select clustering, CFAR, ambiguity, or processing
order beyond the stage seams below.

## Common rules

Each JSON envelope has `schemaName`, `schemaVersion`, `documentVersion`, and
`id`. The MAT envelope carries the same provenance fields as MAT variables.
`schemaVersion` identifies the field schema; `documentVersion` identifies the
exact immutable document snapshot. Both use semantic versioning. A consumer
accepts the same schema major version and rejects a higher major version. It
may accept a lower minor version only after applying
the documented compatibility rules. It must reject unknown required fields,
non-finite values, wrong types, wrong dimensions, and unit/sign violations.
Every producer records `createdUtc` and `producer`; these are provenance, not
algorithm inputs.

The radar-centered frame is metres and metres per second: +x is boresight and
increasing range, +y is radar-left, +z is up, and positive radial velocity is
receding. ADC channel order is one-based in documentation and MATLAB indexing:
channel `k = 1..64` maps to row-major `(azimuthIndex, elevationIndex)` with
`azimuthIndex = floor((k-1)/4)+1` and `elevationIndex = mod(k-1,4)+1`. This map
is authoritative until an ADR changes it. A target's radial velocity is the
projection of its velocity onto the line of sight from the radar to its
position at the scenario reference epoch; a zero-range position is invalid.

## Configuration envelope

The radar configuration is authoritative for generator, DUT, and fixture
parameters. Required top-level fields are:

<!-- markdownlint-disable MD013 -->
| Field | Type/shape | Units and rule |
| --- | --- | --- |
| `schemaName` | string | `radar.configuration` |
| `schemaVersion` | string | `1.x`; this draft is `1.0.0-draft.1` |
| `id` | string | stable configuration identifier |
| `createdUtc`, `producer` | string | ISO-8601 timestamp; producer name/version |
| `rfCarrierHz` | number | Hz; current candidate `3e9` |
| `ifCenterHz` | number | Hz; current candidate `50e6` |
| `adcSampleRateHz` | number | samples/s; current candidate `150e6` |
| `adcBits` | integer | `16` |
| `channelCount` | integer | `64` |
| `array` | object | `azimuthElements: 16`, `elevationElements: 4`, `elementSpacingWavelengths: 0.5` |
| `waveform` | object | `pulseWidthSec: 40e-6`, `chirpBandwidthHz: 10e6`, `chirpStartHz: -5e6`, `chirpStopHz: 5e6` |
| `ddc` | object | `complexIntermediateRateHz: 50e6`, `outputRateHz: 12.5e6`, `decimationFactors: [3,4]` |
| `prfsHz` | array[5] | nominal candidate `[1700,1900,2150,2450,2700]`; G2 verifies tick schedule |
| `priSampleCounts` | integer array[5] | candidate `[88236,78948,69768,61224,55560]`; `12*round(adcSampleRateHz/(12*prfsHz(i)))`; one-based; G2 pending |
| `processing` | object | `maxInstrumentedRangeM: 100000`, `rangeDomainM: [6800,100000]`, and stage settings |
| `scan` | object | `azimuthSectorDeg: [-45,45]`, `updatePeriodSec: 1`; both provisional |
| `blanking` | object | candidate `transmitBlankingSec: 40e-6` and `guardSec: 5e-6`; G2 pending |
| `random` | object | integer `seed`; all stochastic fixtures use it |
<!-- markdownlint-enable MD013 -->

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
3 GHz-derived Doppler and array phase. RCS and velocity remain constant during
the scan. Acceleration, RCS fluctuation, terrain, occlusion, and terrestrial
clutter are outside this contract.

## MAT test-vector envelope

The MAT file is a versioned test-vector envelope, not a JSON serialization.
Its required scalar metadata is `schemaName`, `schemaVersion`, `id`,
`createdUtc`, `producer`, `configurationId`, `configurationSchemaVersion`,
`configurationDocumentVersion`, `configurationHash`, `scenarioId`,
`scenarioSchemaVersion`, `scenarioDocumentVersion`, `scenarioHash`,
`sampleRateHz`, `channelCount`, `sampleFormat`, `timeEpoch`, `fixtureScope`, and
`channelMap`. `sampleFormat` is exactly `real-int16`; `sampleRateHz` is
`150e6` for the current candidate.

The repository example `contracts/wp3/examples/test-vector.mat` contains a
`radarTestVector` struct with one `32x64` zero-valued `int16` slab. It is a
`unit-only` shape/provenance fixture; it does not represent a complete scan,
PRI schedule, or V1 acceptance case. Its metadata includes exact
`configurationSnapshot` and `scenarioSnapshot` UTF-8 JSON bytes,
`documentVersion` values, and SHA-256 hashes.

Storage uses ordered pulse slabs, so a full scan need not be one giant matrix.
`pulseRecords` contains records with `adcSamples` (`int16`, shape
`[samplesInPulse,64]`), `adcTick` (`uint64`, shape `[samplesInPulse,1]`),
`pulseStartTick`, `pulseSampleCount`, `prfIndex`, and `prfNominalHz`.
Full-scan records also require logical scalar `isTransition`: false for an
ordinary pulse and true for a transition. A transition retains `prfIndex` and
`prfNominalHz` for its destination PRF; its duration rule remains WP4/G2
pending. The unit-only shape example may omit `isTransition`.
`prfIndex` is one-based and indexes the configured `prfsHz` array.
`adcTick` is the global ADC tick epoch and records may be consumed incrementally.
For each record after the first, `pulseStartTick` is the actual integer ADC tick
at which that record begins; its PRI is the difference from the preceding
record's start tick. For non-transition, same-PRF records, this difference must
equal `priSampleCounts(prfIndex)`. The derived actual PRF is
`adcSampleRateHz/priSampleCounts(prfIndex)`; the fifth candidate is therefore
`2699.784...` Hz by design. Transition records declare
`isTransition: true`; their timing rule is deferred to WP4/G2. No inferred
quantization is permitted. Optional
generator truth is under `truth`, with `targetId`, `rangeM`,
`radialVelocityMps`, `azimuthDeg`, and `elevationDeg`; truth is never read by
the DUT. Missing or mismatched configuration/scenario versions or hashes are
invalid.

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
`sourceId`, `sourceSchemaVersion`, `sourceDocumentVersion`, and `sourceHash`.
`sourceHash` is SHA-256 of the exact stored source MAT-file bytes, or of the
exact source-content snapshot bytes when the source is not a file; it never
hashes the envelope containing the hash.

The supported stage seams are `ddc`, `range`, `doppler`, `angle`,
`candidate-list`, `cfar`, and `cluster`. Their minimum data contracts are:

<!-- markdownlint-disable MD013 -->
| Stage | `data` shape and meaning | Required units |
| --- | --- | --- |
| `ddc` | `[sample, channel]` complex baseband | V or normalized ADC units; producer must state one |
| `range` | `[rangeBin, pulse, channel]` complex | range-bin index plus `rangeBinCentersM` |
| `doppler` | `[rangeBin, dopplerBin, azimuthLook, elevationLook]` complex or real statistic | `rangeBinCentersM`, `dopplerBinCentersMps` |
| `angle` | typed struct array shape `[N,1]` with fields `rangeM`, `radialVelocityMps`, `azimuthDeg`, `elevationDeg`, `statistic` | one-based row indices; scalar numeric fields and statistic units are declared |
| `candidate-list` | typed struct array shape `[N,1]` with `prfIndex`, `rangeM`, `foldedVelocityMps`, `statistic`, `sourceId` | one-based `prfIndex`; scalar numeric fields; no resolver method implied |
| `cfar` | typed struct array shape `[N,1]` with `rangeBin`, `dopplerBin`, `statistic`, `threshold`, logical `pass` | one-based bin indices; scalar fields; `pass` is logical |
| `cluster` | typed struct arrays `members` and `candidates`, each shape `[N,1]`; members have string `clusterId`/`memberId`, candidates have one-based `candidateId` | string IDs remain strings; cardinality and merge rules remain WP7-pending |
<!-- markdownlint-enable MD013 -->

Stage order, migration alignment, CFAR window/threshold, clustering adjacency
and merge behavior, and ambiguity method remain open WP4/WP6e/WP7 decisions.
Migration handling preserves a declared pulse axis and source pulse ticks; the
contract does not prescribe compensation, interpolation, or hypothesis
iteration. A fixture marked `out-of-domain`, `unit-only`, or `provisional`
cannot be used as V1 acceptance evidence.
Implementations must preserve these seams and record the selected method in
`metadata`; they must not infer an order from an example.

## Detection-list envelope

The output has `schemaName: "radar.detection-list"`, `schemaVersion`,
`documentVersion`, `id`, `createdUtc`, `producer`, `configurationId`,
`testVectorId`, `timeEpoch`,
`fixtureScope`, `detections`, and `metadata`. Detection examples carry the
same configuration and test-vector document versions and hashes in metadata;
the repository empty example declares a shape-only unit scope and is therefore
unit-only,
not V1 acceptance evidence.
Each detection has required fields `detectionId` (string), `rangeM`,
`radialVelocityMps`, `azimuthDeg`, `elevationDeg`, and `detectionStatistic`.
`detectionStatistic` is an object with `name`, `value`, and `units`; its name
and units are pending the WP7 detector decision. Optional provenance fields
`clusterId`, `prfEvidence`, and `ambiguityStatus` are present only when the
selected method defines them. Empty `detections: []` is valid. Duplicate
`detectionId` values, non-finite values, and reports outside the configured
range domain are invalid.

## Invalid-input behavior

Schema or type errors, missing provenance, invalid dimensions, non-finite
numbers, non-monotonic ticks, unknown channel mapping, inconsistent rates, and
version major mismatch must fail before processing with a structured error
containing `code`, `path`, and `message`. A valid zero-result input returns an
empty detection list. Out-of-domain range, stationary/near-zero-speed cases,
or provisional sector values are valid only when the fixture declares the
applicable scope; they are not silently clipped, relabeled, or accepted as V1
performance evidence. Unsupported pending methods return `code:
"METHOD_PENDING"`.

## Examples and compatibility

`configurationHash` and `scenarioHash` are SHA-256 hex digests of the exact
UTF-8 JSON snapshot bytes, including its `documentVersion`.

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

## Conformance checklist and matrix

<!-- markdownlint-disable MD013 -->
| Contract | Producer check | Consumer check | Status/evidence owner |
| --- | --- | --- | --- |
| Configuration | required fields, finite values, candidate/pending status | schema, units, rates, array/channel count | WP3; G2 for timing/filter values |
| Scenario | unique IDs, positive RCS, 3-vectors, constant-state declaration | frame, types, finite values, signs | WP3/WP5 |
| MAT vector | exact provenance, `int16 [N,64]`, monotonic global ticks | versions, epoch, shape, channel map | WP3/WP5 |
| DDC/range/Doppler/angle intermediates | declared shape, rate, units, stage metadata | seam and dimensions; no method inference | WP6a–d |
| Candidate/CFAR/cluster intermediates | explicit method and statistic metadata | pending methods rejected for acceptance | WP6e/WP7 |
| Detection list | required fields, statistic object, unique IDs | units, domain, provenance, empty-list behavior | WP7/WP8 |
| Compatibility | semantic version and migration note | major mismatch rejection | WP3 |
<!-- markdownlint-enable MD013 -->

Before G2 exit, the root conformance checks must prove every row with valid,
invalid, zero-result, version-mismatch, and dimension-mismatch fixtures. WP4
must then resolve all G2-pending seams listed above; WP6e and WP7 must record
their method decisions without changing field meanings silently.
