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

---

## Joint findings and dispositions — 2026-09-29

**Attribution:** Original review notes above are Julio's, preserved verbatim
from the archived review at
[`ff16d41b8886c4a4570c25e95dc343bdcc55e911`](https://github.com/JulioLeonPhd/ai-mbd-pilot-project/commit/ff16d41b8886c4a4570c25e95dc343bdcc55e911).
The original notes themselves said the implementation commit was TBD; they are
not retroactively attributed to a pinned source revision. Codex inspected the
walkthrough at `58b3d3a80170d413aa88dd4408490e2056f49379` and the current
walkthrough history includes last change `2389af89f05adf058b0939fe7a62a8cbfe2a8ab1`.
The findings and technical analysis below are agent contributions. Decisions
identified as Julio's were explicitly confirmed on 2026-09-29. The archived
original remains the source for the initial review text.

### Data flow and mixer

- **Complex mixing before `/3` — accepted.** A real-only `/3` aliases the
  50 MHz IF to DC; complex mixing or an equivalent operation must precede it.
- **Three-phase/polyphase mixer — candidate; optimization deferred.** The
  oscillator is three-sample periodic at 150 MS/s. Keep the current clear
  implementation for the first refactor.
- **Repeated processing view — accepted for a future diagram update.** Show
  the repeated PRI boundary and state reset. The existing diagram still shows
  current code until revised.

### Filters and diagrams

- **Frequency responses — accepted for walkthrough update.** Show each
  response, the overall response, and a passband zoom; prefer `gramm` where
  suitable.
- **Cascade budgets — retained.** Evaluate candidates against 0.1 dB passband
  ripple and 60 dB alias rejection, including the 6.25 MHz stage-2 stopband
  constraint. The budget applies to final 12.5 MS/s complex output.
- **Moving-average checks — resolved.** `/3` at 150 MS/s gives −0.127469 dB
  at 5 MHz and −3.521825 dB at 25 MHz. `/4` at 50 MS/s gives −2.276721 dB
  at 5 MHz. CIC compensation cannot undo aliasing already introduced.
- **Final `/4` filtering — clarified.** Filter before `/4`, at 50 MS/s. The
  final 25 MS/s half-band stage centers at 6.25 MHz and cannot alone meet the
  60 dB stopband requirement. Keep filter and decimator separate in the
  pedagogical diagram.

### State, timing, and scan

- **Stateful DDC question — superseded for future calls.** The current
  implementation consumes and returns oscillator, FIR, and decimation state
  across calls; this was not an unused-state defect. Julio approved one
  complete physical PRI per call with fresh local state. MATLAB prepares the
  complete ADC matrix before DUT calls. See [ADR 0022](../adr/0022-adopt-independent-pri-ddc-processing.md).
- **Delay and tail — accepted with distinct meanings.** Group delay is 372
  ADC ticks, 31 output periods, or 2.48 microseconds. Full memory is 744 ticks,
  62 output periods, or 4.96 microseconds. Optional zero-flush exposes causal
  tail only; it is not acquired input, cannot recreate blanked/missing samples,
  and is not equivalent to next-PRI physical samples.
- **Whole scan and future model — retained direction.** ADC ticks, five
  priming records, four transition gaps, and prior-pulse echoes remain
  physical. Future Simulink multishot resets per PRI and keeps startup
  transient in blind range; topology remains open. Start serially; parallel
  demonstration is optional.
- **Glossary units — accepted.** MHz names frequency; MS/s names sample rate.
  The output is 12.5 MS/s complex.

### Scope and closure

Julio closed the design discussion for the dispositions above on 2026-09-29.
This closes the joint design review only. The implementation is pending Phase 0
resolution of the exact API, output shape, metadata, tail representation, and
window-validity ownership, followed by Julio's explicit go-ahead. Implementation
review, targeted verification, and end-to-end detection evidence remain pending.
The first refactor retains the existing five priming records and four transition
gaps; removing or changing them is deferred. Padding can expose a causal FIR
tail but is not acquired input and cannot repair missing or blanked samples.

The bounded exploratory MATLAB comparison documented in ADR 0022 is evidence
about one-channel local-state equivalence after the cascade memory. It is not a
reusable test, full-scan verification, or detection proof. Historical G2
streaming evidence applies only to the former continuous-state baseline.
The implementation sequence and acceptance evidence are captured in the
[per-PRI DDC plan](../plans/ddc-pri-processing.md).
