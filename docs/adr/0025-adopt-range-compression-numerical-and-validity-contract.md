---
status: accepted
accepted: 2026-10-26
---

# Adopt range-compression numerical and validity contract

## Context

Range processing follows commanded-look azimuth beamforming and precedes the separate pulse-accumulation and range-migration responsibilities described by [ADR 0021](0021-adopt-dsp-responsibilities-and-ambiguity-baseline.md).
The DDC boundary remains independent per PRI under [ADR 0022](0022-adopt-independent-pri-ddc-processing.md), including its fixed factor-two output compensation and caller-owned exactly-once group-delay correction.
Julio approved the numerical conventions in [issue #19](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/19#issuecomment-6417700433), the coordinate mapping in [issue #20](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/20#issuecomment-6421083854), and complete-window validity and mask semantics in [issue #21](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/21#issuecomment-6425272561).
These are planning decisions and do not authorize implementation or establish acceptance evidence.

## Decision

### Reference and correlation

Use the ideal unit-amplitude complex-baseband up-chirp at the decimated sample rate, with sample-zero time and phase origin, a rectangular envelope, and no additional weighting.

| Parameter | Symbol | Value |
| --- | --- | --- |
| Sample rate | $F_s$ | 12.5 MS/s |
| Pulse duration | $T$ | 40 µs |
| Sweep bandwidth | $B$ | 10 MHz |
| Reference length | $M = F_sT$ | 500 samples |

For zero-based $n = 0,\ldots,499$, define the sample times and reference by

$$
t_n = \frac{n}{F_s},
\qquad
s[n] = \exp\!\left(j2\pi\left[-\frac{B}{2}t_n + \frac{B}{2T}t_n^2\right]\right).
$$

The pulse starts at zero phase and sweeps instantaneously from $-5\,\mathrm{MHz}$ toward $+5\,\mathrm{MHz}$ over the half-open interval

$$
0 \le t \lt T = 40\,\mu\mathrm{s}.
$$

For the mathematical full correlation only, treat $x$ as zero outside the supplied samples; this convention does not make padded or unavailable samples valid.
For each of the four complex elevation streams, define correlation at integer lag $k$ as

$$
y[k] = \frac{1}{500}\sum_{m=0}^{499}x[k+m]\,\overline{s[m]}.
$$

The normalization is the reference energy:

$$
E_s = \sum_{m=0}^{499}\lvert s[m]\rvert^2 = 500.
$$

An otherwise isolated exactly aligned echo $x[d+m] = a\,s[m]$ therefore has complex output $y[d] = a$.
The result retains input amplitude units and complex phase and is neither magnitude, power, nor calibrated RCS.
Do not apply another factor of two for DDC compensation.

### FFT and lag convention

For an input of $N$ samples, use the smallest power of two $L$ satisfying $L\ge N+499$, with forward FFTs and the inverse FFT all taken along the sample dimension.
The full linear correlation has $N+499$ values at lags $-499,\ldots,N-1$; public lag $k$ is the zero-based physical correlation lag, not an array index shifted by 499.
A reference beginning at input index $d$ peaks at lag $d$, not $d+499$.
Any equivalent reversed-conjugate convolution implementation must remove its 499-sample indexing offset when reporting lag.

### Coordinates and timing ownership

For zero-based lag $k$, assign the local or folded range coordinate

$$
R[k] = R_0 + k\,\Delta R,
\qquad
\Delta R = \frac{c}{2F_s} = 11.99169832\,\mathrm{m},
$$

where $c = 299792458\,\mathrm{m/s}$ and $R_0$ is the caller-supplied physical range label for lag zero.
The caller computes $R_0$ from the input time origin, trimming, and upstream DDC delay and remains responsible for the exactly-once DDC group-delay correction.

For untrimmed input whose sample zero is the PRI/transmit timing origin,

$$
R_0 = -31\,\Delta R = -371.74264792\,\mathrm{m}.
$$

This is an example, not a universal default.
The DDC delay of 31 output samples is not itself a range origin in metres.
Correlation lag indexing, physical DDC group delay, and execution latency are distinct quantities.
Range coordinates do not perform ambiguity unfolding and do not recover unavailable samples.

### Validity

For every stream independently, output lag $k$ is valid only when all supplied input samples $k$ through $k+499$, inclusive, exist and the corresponding 500 validity-mask entries are true.
For a contiguous inclusive valid input interval $[a,b]$, eligible lags satisfy

$$
a \le k \le b-499.
$$

Internal gaps are supported and invalidate only windows that include a false mask entry.
The caller's input mask is authoritative for blanked, DDC-startup-invalid, and unavailable supplied samples; numerical zeros do not imply invalidity.
FFT padding does not make absent samples valid, and coordinate correction does not restore them.
Retain exactly the fixed public grid of $N$ nonnegative lag bins and report validity separately.
Invalid outputs are complex zero with false validity; valid outputs may also be zero.
For $N\ge500$, the last 499 output bins are necessarily invalid, and nonempty inputs with $N\lt500$ return no valid bins.
Short inputs, all-false masks, and internal gaps are ordinary data conditions, not errors.

### Decision boundary

These decisions fix the numerical reference, lag convention, coordinate mapping, delay ownership, and validity semantics only.
The per-PRI public API is specified in [ADR 0026](0026-adopt-per-pri-range-compression-api.md); approved separation and fixture choices are recorded in [ADR 0027](0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md).
Final numerical tolerances and numerical-study evidence remain pending for [Define range acceptance criteria](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/issues/23).
The accepted decisions do not authorize production implementation, establish acceptance or performance results, or make hardware claims.

## Rationale

The explicit reference, normalization, and lag convention make complex amplitude and sample indexing unambiguous across an implementation and its independent reference.
Caller ownership keeps range processing from duplicating the DDC's already-defined delay compensation.
An explicit per-stream mask preserves the distinction between a valid zero and an unavailable or invalid sample while retaining stable bin positions for integration.

## Consequences

Implementations must keep the full linear-correlation lag convention and return only the fixed nonnegative public lag grid defined by the API decision.
Callers must provide the correctly delay-adjusted range origin and validity mask.
No weighted waveform, ambiguity-unfolding behavior, missing-sample recovery, acceptance tolerance, or implementation authorization follows from this ADR.
