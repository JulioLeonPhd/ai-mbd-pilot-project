---
status: accepted
---
# Adopt revised V1 analytic simulation baseline at G1

> Historical carrier wording superseded by ADR 0015. IF, ADC, DDC, waveform,
> timing, and G1 decisions remain current.

Records revised G1 result for bounded analytic and ideal
simulation candidate. Does not accept finite-filter, hardware, sampled
end-to-end, or real-time behavior deferred to G2 and later gates.

## Context

Revised candidate: 10 MHz chirp over -5 to +5 MHz, 50 MHz IF,
150 MS/s real ADC, then ideal image removal, complex /3 to 50 MS/s,
candidate complex /4 to 12.5 MS/s. MVP generator emits direct ADC-rate
vectors, preserving phase derived from exact ADR 0015 carrier.

## Decision

Accept revised G1 for WP3 data contracts and WP4 DSP/timing architecture,
within evidence scope below. Revised study passed all 5760 of 5760
ideal finite-LFM 50 m cases. Native range grid: 11.99169832 m;
worst reported valley: -11.164950851 dB. Five actual PRFs provide at
least three complete guarded coverage PRFs throughout 6.8–100 km.
42.4703 m/s minimum native unambiguous speed: historical result generated
under former 3 GHz carrier; ADR 0015 and regenerated current evidence
supersede with 42.4997 m/s. Analytic schedule retains
128 usable returns per PRF, one priming PRI, transitions as G2 checks.

Ideal real-ADC DDC identity passes after image removal before /3.
Unfiltered image failure demonstrated. Finite filters, /4 behavior,
filter state and delay, alias rejection, near-range gating remain G2 work.
6.8 km case: only approximately 0.1371 us post-guard edge after
guard and motion allowance.

## Evidence and limits

Decision traced to [revised G1 study](../../evidence/radar_v1_revised_g1_study.m)
and [results](../../evidence/radar_v1_revised_g1_results.json),
candidate definitions in [ADR 0012](0012-adopt-50m-separability-and-narrowband-ddc-candidate.md)
and [ADR 0013](0013-adopt-150msps-50mhz-if-and-direct-adc-stimulus.md).
Independent numerical validation reported no errors. No hardware, ENOB,
clock-jitter, SNR, Pd, Pfa, or real-time claim made. Sampled two-report
separability, ambiguity resolution, complete 128-return schedule
pending downstream gates. Ideal front-end bandpass excludes
95–105 MHz alias case; finite alias rejection remains unverified.

ADR 0011 remains historical record for former 250 MHz and 625 MS/s
baseline; not evidence for revised candidate.
