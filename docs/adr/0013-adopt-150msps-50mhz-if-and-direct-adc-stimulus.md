---
status: accepted
---
# Adopt 150 MS/s ADC and direct sampled stimulus abstraction

> Historical carrier wording superseded by ADR 0015. IF, ADC, DDC, waveform,
> and timing decisions remain current.

Supersedes [ADR 0012](0012-adopt-50m-separability-and-narrowband-ddc-candidate.md)
only for current-candidate ADC rate, IF, DDC staging, and raw-rate
consequence. ADR 0012 remains historical decision record for 50 m
separability and 10 MHz waveform candidate.

## Context

625 MS/s real ADC candidate inherited from historical 250 MHz
waveform. Current candidate: 10 MHz complex chirp; MVP can use
lower-rate first-Nyquist-zone IF. Physical RF carrier now exact
2.99792458 GHz invariant from ADR 0015;
50 MHz proposed IF center.

## Decision

For reopened G1 validation, use 150 MS/s real, 16-bit ADC per channel and
50 MHz IF center for 45--55 MHz band. Multistage DDC produces 12.5
MS/s complex samples: complex-mix and filter while decimating by /3 to
50 MS/s complex intermediate, then filter and decimate by /4. 50 MHz IF:
frequency, not 50 MS/s intermediate rate. Three-phase complex mixer
or polyphase equivalent: implementation candidate; real-only /3
decimator followed by IQ recovery invalid because IF aliases to DC.
Filtering must precede each decimation stage.

MVP target generator emits 64 real int16 ADC channels directly at
150 MS/s. Preserves coherent delay, Doppler, and array phase derived from
exact carrier parameter without generating sampled RF or explicit analog
downconversion. Configuration distinguishes `rfCarrierHz`, `ifCenterHz`,
`adcSampleRateHz`, and `ddcOutputRateHz`, with one global time epoch.

## Consequences and validation

Raw capture: 19.2 GB/s for 64 channels at 16 bits, before framing. Ideal
front-end bandpass assumption or explicit analog rejection requirement
needed: energy around 95--105 MHz also aliases into 45--55 MHz at 150 MS/s.
20 MHz Nyquist guard alone does not prove alias safety.

G1/G2 must validate filter alias rejection, mixer phase/amplitude, SNR/ENOB and
clock-jitter sensitivity, phase continuity across PRIs, delay and near-range
gating, and 128-return schedule. 50 m two-target separation:
accepted test requirement from ADR 0012. 10 MHz chirp, 40 us pulse, and
12.5 MS/s complex output remain candidates pending that work. Output Nyquist
interval: +/-6.25 MHz, leaving 1.25 MHz beyond nominal +/-5 MHz chirp;
final transition width and attenuation remain filter-budget decisions.
