---
status: accepted
---

# Adopt revised V1 analytic simulation baseline at G1

> Historical carrier wording superseded by ADR 0015. IF, ADC, DDC, waveform,
> timing, and G1 decisions remain current.

This decision records the revised G1 result for the bounded analytic and ideal
simulation candidate. It does not accept finite-filter, hardware, sampled
end-to-end, or real-time behavior deferred to G2 and later gates.

## Context

The revised candidate uses a 10 MHz chirp over -5 to +5 MHz, a 50 MHz IF, and
a 150 MS/s real ADC followed by ideal image removal, complex /3 to 50 MS/s,
and candidate complex /4 to 12.5 MS/s. The MVP generator emits direct ADC-rate
vectors while preserving phase derived from the exact ADR 0015 carrier.

## Decision

Accept revised G1 for WP3 data contracts and WP4 DSP/timing architecture,
within the evidence scope below. The revised study passed all 5760 of 5760
ideal finite-LFM 50 m cases. Its native range grid is 11.99169832 m and the
worst reported valley is -11.164950851 dB. The five actual PRFs provide at
least three complete guarded coverage PRFs throughout 6.8–100 km. The
42.4703 m/s minimum native unambiguous speed is the historical result generated
under the former 3 GHz carrier; ADR 0015 and regenerated current evidence
supersede it with 42.4997 m/s. The analytic schedule retains
128 usable returns per PRF, one priming PRI, and transitions as G2 checks.

The ideal real-ADC DDC identity passes after image removal before /3. The
unfiltered image failure is demonstrated. Finite filters, /4 behavior,
filter state and delay, alias rejection, and near-range gating remain G2 work.
The 6.8 km case has only approximately 0.1371 us of post-guard edge after
guard and motion allowance.

## Evidence and limits

The decision is traced to the [revised G1 study](../../evidence/radar_v1_revised_g1_study.m)
and its [results](../../evidence/radar_v1_revised_g1_results.json), with the
candidate definitions in [ADR 0012](0012-adopt-50m-separability-and-narrowband-ddc-candidate.md)
and [ADR 0013](0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md).
Independent numerical validation reported no errors. No hardware, ENOB,
clock-jitter, SNR, Pd, Pfa, or real-time claim is made. Sampled two-report
separability, ambiguity resolution, and the complete 128-return schedule are
pending their downstream gates. The ideal front-end bandpass excludes the
95–105 MHz alias case; finite alias rejection remains unverified.

ADR 0011 remains the historical record for the former 250 MHz and 625 MS/s
baseline; it is not evidence for this revised candidate.
