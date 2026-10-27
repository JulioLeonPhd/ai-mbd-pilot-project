---
status: accepted
accepted: 2026-10-26
---

# Adopt per-PRI range-compression API

## Context

The range-processing responsibility follows commanded-look azimuth beamforming and precedes separate pulse accumulation and range-migration handling under [ADR 0021](0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md).
The independent per-PRI processing boundary and caller-owned DDC delay correction remain as specified by [ADR 0022](0022-adopt-independent-pri-ddc-processing.md).
The fixed waveform, complex correlation convention, range-coordinate mapping, and complete-window validity rules are specified in [ADR 0025](0025-adopt-range-compression-numerical-and-validity-contract.md).
Julio confirmed this API in [issue #22](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/22#issuecomment-6425810353), following the per-stream mask decision in [issue #22](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/22#issuecomment-6425321892).
This API approval is planning only and does not authorize implementation, Simulink implementation, or gate advancement.

## Decision

### Public call

The nonexecutable API signature is `[rangeSamples, metadata] = radardemo.rangeCompression.processPri(inputSamples, inputValid, cfg)`.
This inline signature specifies the call contract and is not runnable MATLAB code.
Each call processes one supplied PRI independently, with no persistent signal state or pulse accumulation.
The API has no timestamps or PRF in its inputs or outputs.

### Inputs

| Input | Contract |
| --- | --- |
| `inputSamples` | Nonempty, finite `double` array of size `[N,4]`; complex values are supported, and real values represent zero quadrature. |
| `inputValid` | Logical array of size `[N,4]`, exactly matching `inputSamples`; each column gives validity for its corresponding elevation stream. |
| `cfg` | Scalar structure containing exactly one field, `rangeOriginM`. |
| `cfg.rangeOriginM` | Required finite real `double` scalar in metres; negative values are allowed and there is no default. |

Reject samples that are nonfinite even when their corresponding validity entries are false.
Reject unknown configuration fields.
Do not automatically cast values, transpose arrays, broadcast masks, or sanitize NaN or Inf values.
The caller incorporates the input time origin, any trimming, and exactly-once upstream DDC delay correction into `rangeOriginM`.
The waveform is fixed to the unweighted 500-sample ideal reference defined in [ADR 0025](0025-adopt-range-compression-numerical-and-validity-contract.md); there is no custom-reference or weighting option.

### Outputs

| Output | Contract |
| --- | --- |
| `rangeSamples` | Complex `double` array of size `[N,4]`, retaining input amplitude units and complex phase. |
| `metadata.valid` | Logical array of size `[N,4]`, authoritative and computed independently for each stream. |
| `metadata.rangeBinCentersM` | Real `double` column vector of size `[N,1]`, shared across the four streams. |

The metadata structure contains exactly `valid` and `rangeBinCentersM`.
Return exactly $N$ bins at zero-based lags $k=0,\ldots,N-1$, with $R[k]=\texttt{cfg.rangeOriginM}+k\,c/(2F_s)$ under [ADR 0025](0025-adopt-range-compression-numerical-and-validity-contract.md).
Coordinates are retained for every bin, including invalid bins and negative range labels.
Apply no additional DDC-delay correction or ambiguity unfolding.

### Validity and boundary behavior

For each stream, lag $k$ is valid only when all 500 input samples from $k$ through $k+499$, inclusive, exist in the supplied PRI and have true entries in `inputValid`.
Invalid outputs contain complex zero and false mask entries; valid outputs may also contain zero, so consumers must use the mask.
FFT padding cannot make missing samples valid.
Nonempty inputs shorter than 500 samples are accepted and produce all-zero outputs and all-false masks.
All-false masks and internal gaps are normal data conditions, not errors.
For $N\ge500$, the final 499 output rows are necessarily invalid.

### Stable error identifiers

| Identifier | Approved rejection categories |
| --- | --- |
| `radardemo:rangeCompression:InvalidInput` | Empty input, wrong sample type or shape, or nonfinite samples. |
| `radardemo:rangeCompression:InvalidValidity` | Wrong validity-mask type or shape. |
| `radardemo:rangeCompression:InvalidConfiguration` | Wrong configuration structure or fields, or invalid `rangeOriginM`. |

These stable identifiers are contractual; exact message text is not.

### Boundary and unresolved matters

MATLAB logical validity does not settle Simulink Boolean ports, boundary conversions, or execution scheduling.
Acquisition timing remains outside this API seam, not abolished system-wide.
The API includes no fixed waveform metadata or configurable waveform options, custom reference, weighting, timestamps, or PRF.
Approved separation and fixture choices are recorded in [ADR 0027](0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md); final numerical tolerances and study evidence remain pending for [Define range acceptance criteria](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23).
No production implementation, acceptance result, performance result, or hardware claim is authorized or established by this ADR.

## Rationale

A single-PRI API aligns range processing with the established independent-per-PRI DDC responsibility without introducing hidden signal history or accumulation.
Matching sample and validity dimensions preserve per-stream meaning and make complete-window eligibility explicit.
A small fixed metadata contract exposes the authoritative mask and physical coordinate grid while leaving acquisition timing ownership with the caller.

## Consequences

Callers provide finite double samples, a matching logical per-stream mask, and the required range origin in metres.
Consumers must inspect `metadata.valid` rather than infer eligibility from numeric output values.
The approved interface and error identifiers do not specify implementation details, acceptance tolerances, or Simulink boundary behavior.
