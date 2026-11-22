# Pulse accumulation component contract

**Purpose:** Define the public MATLAB batch interface that assembles one
complete CPI into scheduled pulse order before implementation. This contract
supports the MATLAB implementer and independent validator.

**Decision status:** Issue #38 defines the approved behavior. The signature,
MATLAB field names, representations, and error identifiers below record the
architect's implementation recommendation; they were not separately
approved by issue #38. Use this as the implementation and review baseline
unless Julio revises it.

## 1. Scope and decision traceability

The component assembles existing per-PRI range-compression results for one
CPI, commanded azimuth look, and PRF. It preserves range samples, validity,
range-bin centers, and source pulse ticks while ordering records by scheduled
slot. It rejects incomplete slot coverage and incompatible range payloads.

The component does not establish caller-supplied CPI, look, PRF, or source
membership; validate exact PRI spacing; perform range migration compensation;
or run Doppler. Passing accumulation is not proof that a batch is ready for
uniform-spacing Doppler processing, receiver integration, or V1 gate
acceptance.

| Reference | Relevance |
| --- | --- |
| [Issue #38](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/38) | Approved behavior and component acceptance decisions. |
| [Issue #39](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/39) | Implementation, test, walkthrough, and gate acceptance criteria. |
| [ADR 0021](../adr/0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md) | Establishes distinct DSP responsibilities and leaves the specific interface open. |
| [Radar V1 data contracts: stage axes](radar-v1-data-contracts.md#processing-intermediate-envelope) | Defines the range-stage `[rangeBin, pulse, elevation]` convention and range coordinates. |

## 2. Recommended public API

```matlab
ensemble = radardemo.pulseAccumulation.accumulateCpi(priResults, cpiContext)
```

Recommended source path: `src/+radardemo/+pulseAccumulation/accumulateCpi.m`.
The function is a stateless batch call. Keep `processPri` unchanged; each
scheduled record carries its outputs without converting their representation.

`priResults` is a struct vector containing exactly one result for each
scheduled slot. Arrival order is arbitrary. Each record has these fields:

| Field | Required representation and meaning |
| --- | --- |
| `slot` | Integer-valued real `double` scalar in $1 \le s \le P$, where $s$ is the slot and $P$ is `expectedPulseCount`. One-based scheduled slot. |
| `pulseStartTick` | `uint64` scalar source pulse-start tick in 150 MHz ADC clock periods from the radar clock epoch. Tick zero is valid. |
| `rangeSamples` | Finite complex `double` `[R,4]` values from `processPri`, in its original amplitude units. The four columns are the canonical elevation streams. |
| `metadata.valid` | Logical `[R,4]` validity mask corresponding to `rangeSamples`. |
| `metadata.rangeBinCentersM` | Finite real `double` `[R,1]` range-bin coordinate vector in metres, with $R \ge 1$. |

The scalar struct `cpiContext` contains exactly the following fields:

| Field | Required representation and meaning |
| --- | --- |
| `expectedPulseCount` | Finite positive integer-valued `double` scalar no greater than $2^{53}$ (`flintmax`); defines $P$. |
| `azimuthLookIndex` | Finite positive integer-valued `double` scalar no greater than $2^{53}$ (`flintmax`); one-based commanded look index, unitless. |
| `prfNominalHz` | Finite positive real `double` scalar in Hz. |

These context values are caller-supplied declarations, not schedule lookups or
provenance evidence. No separate CPI identity is required by this interface.
The component cannot infer whether all four stream columns retain their
canonical meanings; callers must provide consistently ordered elevation
streams.

Sparse sample arrays and validity masks are accepted. Assembly converts them
to full storage while preserving their values and complex sample type.

## 3. Output contract

`ensemble` is a scalar struct with these fields. Let `P` be the expected pulse
count and `R` the shared range-bin count.

| Field | Required representation and axis order |
| --- | --- |
| `rangeSamples` | Complex `double` `[R,P,4]`; axes are `[rangeBin, pulse, elevation]`. |
| `valid` | Logical `[R,P,4]`, aligned element-for-element with `rangeSamples`. |
| `rangeBinCentersM` | The unchanged `[R,1]` grid from scheduled slot 1. |
| `pulseStartTicks` | `uint64` `[P,1]` ticks in scheduled slot order. |

The singleton case retains all dimensions: samples and validity are `[R,1,4]`.
Copy sample values, masks, grid, and ticks unchanged into their scheduled
positions. Do not combine pulses or elevation streams, collapse invalid
pulses, coerce types, reconstruct the grid, interpolate, sort by time, or
apply timing or range corrections.

## 4. Validation and failure behavior

Validate in this order:

1. Validate the scalar context struct, exact field set, and context values.
2. Validate the record collection and complete slot coverage, build the
   slot-to-record mapping, then check source ticks in scheduled slot order.
3. Validate each range payload and require its range grid to be numerically
   exactly equal to slot 1's grid.

Require exactly $P$ records, with one and only one record for each slot from
$1$ through $P$. Accept arbitrary arrival order. Let $t_k$ be the `uint64`
`pulseStartTicks` entry at scheduled slot $k$. Require $t_k \lt t_{k+1}$ for
$1 \le k \lt P$, using `uint64` comparisons. Do not convert ticks to `double`
or infer order from arrival order. Equal or decreasing ticks are rejected.
Increasing irregular ticks are accepted and returned unchanged.

Raise a MATLAB error with the recommended stable identifier below. A rejected
call returns no ensemble; assign the output only after the batch has passed
validation and assembly.

| Error identifier | Reject for |
| --- | --- |
| `radardemo:pulseAccumulation:InvalidContext` | Non-scalar or non-struct context, missing or unknown context field, or malformed count, look index, or nominal PRF. |
| `radardemo:pulseAccumulation:InvalidSlotsOrTicks` | Empty or wrong-shaped record collection; missing slot or tick field; record-count mismatch; missing, duplicate, or out-of-range slot; malformed tick; or equal/decreasing ticks in scheduled slot order. |
| `radardemo:pulseAccumulation:IncompatibleRangeResults` | Missing/malformed range payload; invalid sample, mask, or coordinate type/shape; real-stored or nonfinite samples; nonfinite coordinates; elevation count other than four; or a grid differing numerically from slot 1. |

A pulse whose validity mask is entirely false is present data, not a missing
slot. A valid zero and invalid zero remain distinguishable through the separate
mask. No all-false-mask rejection is implied.

## 5. Timing and downstream responsibility

Ticks preserve source timing only. Strict monotonicity establishes order, not
uniform spacing or source membership. The caller is responsible for verifying
that records belong to the declared CPI, commanded look, and PRF, and for
checking exact spacing against the configured integer PRI tick count before
any downstream consumer that requires uniform slow-time sampling. Do not
round $150\,\mathrm{MHz}/f_\mathrm{PRF}$ to create or validate the PRI count,
where $f_\mathrm{PRF}$ is `prfNominalHz` in Hz. In particular, successful
assembly with irregular ticks is not a uniform-spacing Doppler precondition
and does not establish Doppler readiness.

## 6. Public-interface acceptance cases

Use the public API with synthetic inputs conforming to the `processPri`
output contract. Compare against independently constructed expected output;
do not use a second implementation of the reordering logic as the oracle.

- **Shuffled complete batch:** Distinguish slots and elevation streams with
  complex samples. Include a valid zero, an invalid zero, and a present pulse
  with an all-false mask. Verify exact sample and mask values, grid, ticks,
  types, and axis order.
- **Ticks:** Preserve an increasing irregular sequence exactly, including
  adjacent `uint64` values above $2^{53}$. Reject equal or decreasing ticks in
  scheduled slot order and wrongly typed ticks. Shuffled arrival alone must
  not reject the batch.
- **Singleton:** Accept slot 1 at tick zero and verify `[R,1,4]` samples and
  mask, unchanged grid, and one `uint64` tick. No spacing comparison is
  implied.
- **Rejection and atomicity:** Check identifiers for malformed context,
  empty or missing slots, a duplicate at the expected record count,
  out-of-range slots, malformed payloads including a real-stored
  `rangeSamples` array, and a same-length grid with one differing coordinate.
  For a late range mismatch, verify the caller's preassigned output sentinel
  remains unchanged.
- **Walkthrough:** Demonstrate one accepted shuffled batch and one rejected
  batch through the public call. Explain why preserved irregular ticks do not
  prove uniform spacing. Do not invoke Doppler.

The cases above are planned acceptance coverage, not executed evidence.
Issue #39 separately requires recorded MATLAB verification evidence and independent
implementation review with no unresolved errors. Neither gate is satisfied by
this contract or its document review. Even after component acceptance, these
cases do not establish source membership, semantic correctness of stream
labels, receiver integration, or V1 gate advancement.
