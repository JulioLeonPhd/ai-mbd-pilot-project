---
status: accepted
---

# Adopt 50 m separability and a narrowband DDC candidate

> Historical note: ADR 0013 supersedes the ADC rate, IF, DDC staging, and raw
> rate stated below. This record remains authoritative for the adopted 50 m
> separability and 10 MHz waveform candidate; its former rate values are kept
> as historical evidence.

## Context

The former 1 m two-target criterion and 250 MHz waveform were too demanding for
the commercial-aircraft demonstrator. A range separation of 50 m is adopted as
the current acceptance target. The nominal bandwidth floor is
\(c/(2R)=2.998\) MHz, but the design candidate uses margin: a 10 MHz complex
chirp spanning -5 to +5 MHz, giving approximately 15 m nominal range
resolution (about 3.3 nominal resolution cells across 50 m).

## Decision

The accepted two-target separability requirement is 50 m. The waveform and DDC
values below remain candidates pending validation.

At the time of this decision, the following was the candidate for WP4/WP6/WP8
validation; ADR 0013 supersedes its ADC/IF/DDC rate path:

- 40 us pulsed LFM, 156.25 MHz IF, and the existing 625 MS/s real, 64-channel
  ADC candidate;
- multistage DDC with total decimation of 25 (for example, /5 followed by /5),
  producing 25 MS/s complex samples per channel;
- two equal-RCS moving targets with shared nonzero velocity and 50 m range
  separation, producing two detection-list reports.

The former 1 m criterion in [ADR 0009](0009-radar-mvp-acceptance-and-ambiguity-requirements.md)
and the 250 MHz, 2× DDC, 312.5 MS/s, and 4× range-grid candidates in
[ADR 0011](0011-adopt-v1-simulation-timing-baseline.md) are superseded only for
these waveform, separability, and post-DDC-rate claims. Their evidence remains
historical; G1 is reopened for the revised waveform and rate claims.

## Consequences and validation

Raw ADC rate and capture volume remain unchanged. Post-DDC sample volume is
approximately 12.5 times lower than the former 312.5 MS/s complex candidate.
PRFs, Doppler processing, velocity unfolding, and 100 km timing remain proposed
only insofar as PRI and blanking constraints continue to hold. Existing PRIs are
not generally divisible by 25, so decimator phase and buffering must be managed
explicitly.

Reopened G1 shall establish analytic/ideal feasibility for the revised bandwidth
and rate claims. G2 shall revalidate filter passband/alias rejection, transient
and group delay, filter state, decimator phase across PRIs, receive-window
gating and near-range coverage, including the 6.80 km edge (about 0.365 us
beyond 40 us blanking plus 5 us guard), and may run a sampled stage proxy.
WP6b shall own ideal and sampled 50 m two-peak range-stage tests. WP6e/WP7
shall own ambiguity and noise/CFAR assessment. WP8 shall own the full
end-to-end two-report test and Doppler/timing acceptance.
Bandwidth reduction alone provides no SNR, Pd, or detection-report guarantee.
The 12.5 MS/s /50 option remains a later aggressive alternative and is not
adopted.
