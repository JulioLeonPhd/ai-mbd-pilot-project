# DDC walkthrough review

This document contains the review notes of the owner regarding the DDC
implementation at commit # (TBD).

## Data Flow

- The current flow mixes the real input at 150 MS/s. The computational cost may
  be reducible, but removing this complex mixing is not compatible with the
  current 50 MHz IF architecture.
- A real-only /3 decimator aliases the 50 MHz IF to DC, so IQ recovery after
  that decimation cannot reconstruct the desired complex envelope. The complex
  mixer must therefore precede the first /3 decimation, or an equivalent
  polyphase implementation must perform the same operation.
- The 50 MHz mixer is a particularly good candidate for a three-phase or
  polyphase implementation because 50 MHz sampled at 150 MS/s produces a
  three-sample periodic oscillator.
- The data flow depicted in `ddc-algorithm-state.svg` looks correct, but it
  would be better if we could present the next frame (e.g. Frame 2) processing
  as a loop instead, so we can generalise for all the subsequent frames.

## Anti Aliasing Filters

- The current anti-aliasing filters seem expensive, especially the 241-tap
  second FIR. The 25-tap first FIR does not appear to have an especially steep
  transition relative to the desired +/-5 MHz baseband; its main role is to
  reject mixer images and prevent /3 aliasing.
- It would be good to have frequency response plots of all of the filters that
  we're going to be using.
- CIC or moving-average stages should be evaluated for computational efficiency,
  but they cannot replace the FIR stages without qualification. A /3 moving
  average may only have about -0.13 dB attenuation at 5 MHz and about -3.5 dB at
  25 MHz (check). A /4 moving average has about -2.3 dB attenuation at 5 MHz, so
  CIC passband droop and compensation must be included in the comparison.
- A practical alternative is a CIC or moving-average stage followed by a
  compensating FIR. Each candidate must still meet the existing 0.1 dB
  passband-ripple and 60 dB digital alias-rejection requirements. This spec
  should be for the final 12.5 MS/s complex signal (so the overall filter) and
  not per-stage.
- The final anti-alias FIR must run before the /4 decimator, while the signal is
  still at the 50 MS/s complex intermediate rate. A filter after the signal
  reaches 12.5 MS/s cannot undo aliasing introduced by /4. The diagrams must
  reflect filtering and decimation in different blocks for illustration.
- Because /4 can be factored into /2 followed by /2, efficient half-band filters
  should also be evaluated.

## Statefulness

- Why do we need a stateful DDC? From what I've understood so far, we process
  independent Frames, which would make it stateless, right? Confirm.
- `ADR-0018` talks about preserving the DDC-state, but nothing so far resets it
  or makes use of it.

## Glossary / `CONTEXT.md`

- We should clarify MHz versus MS/s, and use each term consistently:
  - MHz describes frequency quantities such as IF, tone frequency, bandwidth,
    cutoff, and stopband edges.
  - MS/s describes sample rates, so the output should be called 12.5 MS/s
    complex rather than 12.5 MHz samples.
- I may already have some terminology wrong in this document and the related
  walkthrough/ADR text.
