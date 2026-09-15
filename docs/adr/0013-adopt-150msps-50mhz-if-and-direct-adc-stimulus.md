---
status: accepted
---

# Adopt 150 MS/s ADC and direct sampled stimulus abstraction

> Historical carrier wording superseded by ADR 0015. IF, ADC, DDC, waveform,
> and timing decisions remain current.

This decision supersedes [ADR 0012](0012-adopt-50m-separability-and-narrowband-ddc-candidate.md)
only for its current-candidate ADC rate, IF, DDC staging, and raw-rate
consequence. ADR 0012 remains the historical decision record for the 50 m
separability and 10 MHz waveform candidate.

## Context

The 625 MS/s real ADC candidate was inherited from the historical 250 MHz
waveform. The current candidate is a 10 MHz complex chirp, so the MVP can use
a lower-rate first-Nyquist-zone IF. The physical RF carrier is now the exact
2.99792458 GHz invariant from ADR 0015;
50 MHz is the proposed IF center.

## Decision

For reopened G1 validation, use a 150 MS/s real, 16-bit ADC per channel and a
50 MHz IF center for the 45--55 MHz band. Use multistage DDC to produce 12.5
MS/s complex samples: complex-mix and filter while decimating by /3 to a
50 MS/s complex intermediate, then filter and decimate by /4. The 50 MHz IF is
a frequency, not the 50 MS/s intermediate rate. A three-phase complex mixer
or polyphase equivalent is an implementation candidate; a real-only /3
decimator followed by IQ recovery is invalid because the IF aliases to DC.
Filtering must precede each decimation stage.

The MVP target generator emits the 64 real int16 ADC channels directly at
150 MS/s. It preserves coherent delay, Doppler, and array phase derived from
the exact carrier parameter without generating sampled RF or explicit analog
downconversion. Configuration distinguishes `rfCarrierHz`, `ifCenterHz`,
`adcSampleRateHz`, and `ddcOutputRateHz`, with one global time epoch.

## Consequences and validation

Raw capture is 19.2 GB/s for 64 channels at 16 bits, before framing. An ideal
front-end bandpass assumption or explicit analog rejection requirement is
needed: energy around 95--105 MHz also aliases into 45--55 MHz at 150 MS/s. A
20 MHz Nyquist guard alone does not prove alias safety.

G1/G2 must validate filter alias rejection, mixer phase/amplitude, SNR/ENOB and
clock-jitter sensitivity, phase continuity across PRIs, delay and near-range
gating, and the 128-return schedule. The 50 m two-target separation is the
accepted test requirement from ADR 0012. The 10 MHz chirp, 40 us pulse, and
12.5 MS/s complex output remain candidates pending that work. Its Nyquist
interval is +/-6.25 MHz, leaving 1.25 MHz beyond the nominal +/-5 MHz chirp;
the final transition width and attenuation remain filter-budget decisions.
