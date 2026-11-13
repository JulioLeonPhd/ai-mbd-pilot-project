---
status: accepted
---
# Adopt 50 m separability and a narrowband DDC candidate

> Historical note: ADR 0013 supersedes ADC rate, IF, DDC staging, and raw
> rate below. Record remains authoritative for adopted 50 m
> separability and 10 MHz waveform candidate; former rates retained
> as historical evidence.

## Context

Former 1 m two-target criterion and 250 MHz waveform too demanding for
commercial-aircraft demonstrator. Adopt 50 m range separation as
current acceptance target. Nominal bandwidth floor
\(c/(2R)=2.998\) MHz; design candidate adds margin: 10 MHz complex
chirp spanning -5 to +5 MHz, giving approximately 15 m nominal range
resolution (about 3.3 nominal resolution cells across 50 m).

## Decision

Accepted two-target separability requirement: 50 m. Waveform and DDC
values below remain candidates pending validation.

The approved range-fixture definitions and evidence boundary are recorded in [ADR 0027](0027-adopt-range-acceptance-fixtures-and-evidence-boundary.md); unresolved numerical tolerances and study evidence remain pending.

At decision time, following candidate for WP4/WP6/WP8
validation; ADR 0013 supersedes its ADC/IF/DDC rate path:

- 40 us pulsed LFM, 156.25 MHz IF, existing 625 MS/s real, 64-channel
  ADC candidate;
- multistage DDC, total decimation 25 (e.g., /5 followed by /5),
  producing 25 MS/s complex samples per channel;
- two equal-RCS moving targets, shared nonzero velocity, 50 m range
  separation, producing two detection-list reports.

Former 1 m criterion in [ADR 0009](0009-radar-mvp-acceptance-and-ambiguity-requirements.md)
and 250 MHz, 2× DDC, 312.5 MS/s, and 4× range-grid candidates in
[ADR 0011](0011-adopt-v1-simulation-timing-baseline.md) superseded only for
these waveform, separability, and post-DDC-rate claims. Evidence remains
historical; G1 reopened for revised waveform and rate claims.

## Consequences and validation

Raw ADC rate and capture volume remain unchanged. Post-DDC sample volume
approximately 12.5 times lower than former 312.5 MS/s complex candidate.
PRFs, Doppler processing, velocity unfolding, and 100 km timing remain proposed
only insofar as PRI and blanking constraints hold. Existing PRIs
not generally divisible by 25; decimator phase and buffering must be managed
explicitly.

Reopened G1 shall establish analytic/ideal feasibility for revised bandwidth
and rate claims. G2 shall revalidate filter passband/alias rejection, transient
and group delay, filter state, decimator phase across PRIs, receive-window
gating and near-range coverage, including 6.80 km edge (about 0.365 us
beyond 40 us blanking plus 5 us guard); may run sampled stage proxy.
WP6b shall own ideal and sampled 50 m two-peak range-stage tests. WP6e/WP7
shall own ambiguity and noise/CFAR assessment. WP8 shall own full
end-to-end two-report test and Doppler/timing acceptance.
Bandwidth reduction alone provides no SNR, Pd, or detection-report guarantee.
12.5 MS/s /50 option remains later aggressive alternative; not
adopted.
